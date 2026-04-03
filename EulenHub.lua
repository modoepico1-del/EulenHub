-- ENVY HUB Style
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP = character:WaitForChild("HumanoidRootPart", 5)
local Camera = workspace.CurrentCamera

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    HRP = newChar:WaitForChild("HumanoidRootPart", 5)
end)

-- ─── AUTO STEAL ────────────────────────────────────────────────
local stealEnabled = false
local stealCooldown = 0.2
local HOLD_DURATION = 0.5
local stealThread = nil

local function getPromptPart(prompt)
    local p = prompt.Parent
    if p:IsA("BasePart") then return p end
    if p:IsA("Model") then return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart") end
    if p:IsA("Attachment") then return p.Parent end
    return p:FindFirstChildWhichIsA("BasePart", true)
end

local function findNearestStealPrompt()
    if not HRP then return nil end
    local nearest, minDist = nil, math.huge
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, desc in pairs(plots:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
            local part = getPromptPart(desc)
            if part then
                local dist = (HRP.Position - part.Position).Magnitude
                if dist < minDist then minDist = dist; nearest = desc end
            end
        end
    end
    return nearest
end

local function triggerStealPrompt(prompt)
    if not prompt or not prompt:IsDescendantOf(workspace) then return end
    prompt.MaxActivationDistance = 9e9
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    local ok = pcall(function() fireproximityprompt(prompt, 9e9, HOLD_DURATION) end)
    if not ok then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(HOLD_DURATION)
            prompt:InputHoldEnd()
        end)
    end
end

local function startAutoSteal()
    if stealThread then return end
    stealThread = task.spawn(function()
        while stealEnabled do
            local p = findNearestStealPrompt()
            if p then triggerStealPrompt(p) end
            task.wait(stealCooldown)
        end
        stealThread = nil
    end)
end

local function stopAutoSteal()
    stealEnabled = false
    stealThread = nil
end

-- ─── ANTI RAGDOLL ──────────────────────────────────────────────
local antiRagdollEnabled = false
local RAGDOLL_SPEED = 16
local currentCharacter = nil
local ragdollRemoteConnection = nil
local moveConnection = nil
local playerModule, controls = nil, nil

pcall(function()
    playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    controls = playerModule:GetControls()
end)

local function cleanupRagdoll()
    if currentCharacter then
        local root = currentCharacter:FindFirstChild("HumanoidRootPart")
        if root then
            local anchor = root:FindFirstChild("RagdollAnchor")
            if anchor then anchor:Destroy() end
        end
    end
    if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
end

local function disconnectRemote()
    if ragdollRemoteConnection then ragdollRemoteConnection:Disconnect(); ragdollRemoteConnection = nil end
end

local function setupAntiRagdoll(char)
    currentCharacter = char
    cleanupRagdoll()
    disconnectRemote()
    local humanoid = char:WaitForChild("Humanoid", 5)
    local root = char:WaitForChild("HumanoidRootPart", 5)
    local head = char:WaitForChild("Head", 5)
    if not (humanoid and root and head) then return end
    local ragdollRemote
    pcall(function()
        ragdollRemote = ReplicatedStorage:WaitForChild("Packages", 8)
            :WaitForChild("Ragdoll", 5)
            :WaitForChild("Ragdoll", 5)
    end)
    if not ragdollRemote or not ragdollRemote:IsA("RemoteEvent") then return end
    ragdollRemoteConnection = ragdollRemote.OnClientEvent:Connect(function(arg1, arg2)
        if not antiRagdollEnabled then return end
        if arg1 == "Make" or arg2 == "manualM" then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            Camera.CameraSubject = head
            root.CanCollide = false
            if controls then pcall(controls.Enable, controls) end
            cleanupRagdoll()
            local anchor = Instance.new("BodyPosition")
            anchor.Name = "RagdollAnchor"; anchor.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            anchor.Position = root.Position; anchor.D = 200; anchor.P = 5000
            anchor.Parent = root
            moveConnection = RunService.Heartbeat:Connect(function()
                if not antiRagdollEnabled then cleanupRagdoll(); return end
                local moveDir = Vector3.zero
                if controls then pcall(function() moveDir = controls:GetMoveVector() end) end
                if moveDir.Magnitude > 0.1 then
                    local cf = Camera.CFrame
                    local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
                    local rgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
                    anchor.Position = root.Position + (fwd * -moveDir.Z + rgt * moveDir.X).Unit * RAGDOLL_SPEED * 0.1
                else
                    anchor.Position = root.Position
                end
            end)
        elseif arg1 == "Destroy" or arg2 == "manualD" then
            cleanupRagdoll()
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            root.CanCollide = true
            Camera.CameraSubject = humanoid
            if controls then pcall(controls.Enable, controls) end
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    if antiRagdollEnabled then task.wait(1); setupAntiRagdoll(newChar) end
end)

-- ─── XRAY ──────────────────────────────────────────────────────
local unwalkEnabled = false
local originalTransparency = {}
local unwalkDescConn = nil
local unwalkCharConn = nil

local function startUnwalk()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness = 3
        Lighting.FogEnd = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.Plastic
                end
            end)
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and
                (obj.Name:lower():find("base") or obj.Name:lower():find("claim") or
                    (obj.Parent and (obj.Parent.Name:lower():find("base") or obj.Parent.Name:lower():find("claim")))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
    unwalkDescConn = workspace.DescendantAdded:Connect(function(obj)
        if not unwalkEnabled then return end
        pcall(function()
            if obj:IsA("BasePart") and obj.Anchored and
                (obj.Name:lower():find("base") or obj.Name:lower():find("claim") or
                    (obj.Parent and (obj.Parent.Name:lower():find("base") or obj.Parent.Name:lower():find("claim")))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end)
    end)
    unwalkCharConn = player.CharacterAdded:Connect(function()
        task.wait(0.5); if unwalkEnabled then startUnwalk() end
    end)
end

local function stopUnwalk()
    if unwalkDescConn then unwalkDescConn:Disconnect(); unwalkDescConn = nil end
    if unwalkCharConn then unwalkCharConn:Disconnect(); unwalkCharConn = nil end
    for obj, val in pairs(originalTransparency) do
        pcall(function() obj.LocalTransparencyModifier = val end)
    end
    originalTransparency = {}
end

-- ─── DARK MODE ─────────────────────────────────────────────────
local darkmodeEnabled = false
local SKYBOX_ID = "rbxassetid://120677415283673"
local originalSky = nil
local originalAmbient = nil
local originalBrightness = nil
local originalFogColor = nil

local function startDarkmode()
    pcall(function()
        originalAmbient = Lighting.Ambient
        originalBrightness = Lighting.Brightness
        originalFogColor = Lighting.FogColor
        local existingSky = Lighting:FindFirstChildOfClass("Sky")
        if existingSky then originalSky = existingSky; existingSky.Parent = nil end
        local newSky = Instance.new("Sky")
        newSky.Name = "KMoneyDarkSky"
        newSky.SkyboxBk = SKYBOX_ID; newSky.SkyboxDn = SKYBOX_ID; newSky.SkyboxFt = SKYBOX_ID
        newSky.SkyboxLf = SKYBOX_ID; newSky.SkyboxRt = SKYBOX_ID; newSky.SkyboxUp = SKYBOX_ID
        newSky.Parent = Lighting
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.Brightness = 0
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)
    end)
end

local function stopDarkmode()
    pcall(function()
        local darkSky = Lighting:FindFirstChild("KMoneyDarkSky")
        if darkSky then darkSky:Destroy() end
        if originalSky then originalSky.Parent = Lighting; originalSky = nil end
        if originalAmbient then Lighting.Ambient = originalAmbient end
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalFogColor then Lighting.FogColor = originalFogColor end
    end)
end

-- ─── CONFIG ────────────────────────────────────────────────────
local CONFIG_FILE = "EulenHub_config.json"
local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            AutoSteal = stealEnabled,
            AntiRagdoll = antiRagdollEnabled,
            XRAY = unwalkEnabled,
            Darkmode = darkmodeEnabled,
        }))
    end)
end
local savedCfg = {}
pcall(function() savedCfg = HttpService:JSONDecode(readfile(CONFIG_FILE)) end)

-- ════════════════════════════════════════════════════════════════
-- GUI - ENVY HUB STYLE
-- ════════════════════════════════════════════════════════════════
if CoreGui:FindFirstChild("EulenHub") then CoreGui:FindFirstChild("EulenHub"):Destroy() end

local C = {
    BG       = Color3.fromRGB(18, 18, 22),
    SIDEBAR  = Color3.fromRGB(24, 24, 30),
    PANEL    = Color3.fromRGB(30, 30, 38),
    CARD     = Color3.fromRGB(38, 38, 48),
    ACTIVE   = Color3.fromRGB(255, 255, 255),
    INACTIVE = Color3.fromRGB(130, 130, 145),
    TEXT     = Color3.fromRGB(255, 255, 255),
    SUBTEXT  = Color3.fromRGB(160, 160, 175),
    ACCENT   = Color3.fromRGB(255, 255, 255),
    BADGE    = Color3.fromRGB(50, 50, 62),
    BORDER   = Color3.fromRGB(55, 55, 68),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EulenHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = CoreGui end)

-- Shadow
local Shadow = Instance.new("Frame", ScreenGui)
Shadow.Size = UDim2.new(0, 574, 0, 424)
Shadow.Position = UDim2.new(0.5, -283, 0.5, -208)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.5
Shadow.BorderSizePixel = 0
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 14)

-- Main container
local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 570, 0, 420)
Main.Position = UDim2.new(0.5, -285, 0.5, -210)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.BORDER; mainStroke.Thickness = 1; mainStroke.Transparency = 0

-- ─── TOP BAR ───────────────────────────────────────────────────
local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.SIDEBAR
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

-- fix bottom corners of topbar
local TopBarFix = Instance.new("Frame", TopBar)
TopBarFix.Size = UDim2.new(1, 0, 0.5, 0)
TopBarFix.Position = UDim2.new(0, 0, 0.5, 0)
TopBarFix.BackgroundColor3 = C.SIDEBAR
TopBarFix.BorderSizePixel = 0

local TopStroke = Instance.new("Frame", TopBar)
TopStroke.Size = UDim2.new(1, 0, 0, 1)
TopStroke.Position = UDim2.new(0, 0, 1, -1)
TopStroke.BackgroundColor3 = C.BORDER
TopStroke.BorderSizePixel = 0

-- Title
local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Size = UDim2.new(0, 160, 1, 0)
TitleLbl.Position = UDim2.new(0, 16, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "EULEN HUB"
TitleLbl.TextColor3 = C.TEXT
TitleLbl.Font = Enum.Font.GothamBlack
TitleLbl.TextSize = 15
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Discord label
local DiscordLbl = Instance.new("TextLabel", TopBar)
DiscordLbl.Size = UDim2.new(0, 200, 1, 0)
DiscordLbl.Position = UDim2.new(0, 170, 0, 0)
DiscordLbl.BackgroundTransparency = 1
DiscordLbl.Text = "discord.gg/eulenhub"
DiscordLbl.TextColor3 = C.INACTIVE
DiscordLbl.Font = Enum.Font.Gotham
DiscordLbl.TextSize = 12
DiscordLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -40, 0.5, -14)
MinBtn.BackgroundColor3 = C.CARD
MinBtn.Text = "—"
MinBtn.TextColor3 = C.TEXT
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 13
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local minStroke = Instance.new("UIStroke", MinBtn)
minStroke.Color = C.BORDER; minStroke.Thickness = 1

-- ─── BODY ──────────────────────────────────────────────────────
local Body = Instance.new("Frame", Main)
Body.Size = UDim2.new(1, 0, 1, -44)
Body.Position = UDim2.new(0, 0, 0, 44)
Body.BackgroundTransparency = 1

-- ─── SIDEBAR ───────────────────────────────────────────────────
local Sidebar = Instance.new("Frame", Body)
Sidebar.Size = UDim2.new(0, 148, 1, 0)
Sidebar.BackgroundColor3 = C.SIDEBAR
Sidebar.BorderSizePixel = 0

local SidebarFix = Instance.new("Frame", Sidebar)
SidebarFix.Size = UDim2.new(1, 0, 0.5, 0)
SidebarFix.BackgroundColor3 = C.SIDEBAR
SidebarFix.BorderSizePixel = 0

local SideStroke = Instance.new("Frame", Sidebar)
SideStroke.Size = UDim2.new(0, 1, 1, 0)
SideStroke.Position = UDim2.new(1, -1, 0, 0)
SideStroke.BackgroundColor3 = C.BORDER
SideStroke.BorderSizePixel = 0

-- ─── CONTENT PANEL ─────────────────────────────────────────────
local ContentPanel = Instance.new("Frame", Body)
ContentPanel.Size = UDim2.new(1, -148, 1, 0)
ContentPanel.Position = UDim2.new(0, 148, 0, 0)
ContentPanel.BackgroundColor3 = C.PANEL
ContentPanel.BorderSizePixel = 0

-- Fix bottom-right corner
Instance.new("UICorner", ContentPanel).CornerRadius = UDim.new(0, 12)
local CPFix = Instance.new("Frame", ContentPanel)
CPFix.Size = UDim2.new(0.5, 0, 0.5, 0)
CPFix.BackgroundColor3 = C.PANEL
CPFix.BorderSizePixel = 0

-- ════════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════════════════════════
local tabs = {}
local activeTab = nil

local tabNames = {"Steal", "Anti Ragdoll", "XRAY", "Visual", "Settings"}
local tabYStart = 14

local function makeTabBtn(name, index)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -16, 0, 38)
    btn.Position = UDim2.new(0, 8, 0, tabYStart + (index - 1) * 46)
    btn.BackgroundColor3 = C.CARD
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = C.INACTIVE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local page = Instance.new("Frame", ContentPanel)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false

    -- Section title
    local sectionTitle = Instance.new("TextLabel", page)
    sectionTitle.Size = UDim2.new(1, -24, 0, 22)
    sectionTitle.Position = UDim2.new(0, 16, 0, 14)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = name:upper() .. " CONFIGURATION"
    sectionTitle.TextColor3 = C.TEXT
    sectionTitle.Font = Enum.Font.GothamBlack
    sectionTitle.TextSize = 12
    sectionTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Divider
    local div = Instance.new("Frame", page)
    div.Size = UDim2.new(1, -32, 0, 1)
    div.Position = UDim2.new(0, 16, 0, 40)
    div.BackgroundColor3 = C.BORDER
    div.BorderSizePixel = 0

    tabs[name] = {btn = btn, page = page}
    return btn, page
end

local function setTab(name)
    for n, t in pairs(tabs) do
        local isActive = (n == name)
        t.page.Visible = isActive
        TweenService:Create(t.btn, TweenInfo.new(0.15), {
            BackgroundTransparency = isActive and 0 or 1,
            TextColor3 = isActive and C.TEXT or C.INACTIVE,
        }):Play()
    end
    activeTab = name
end

-- Create all tabs
for i, name in ipairs(tabNames) do
    local btn, page = makeTabBtn(name, i)
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end

-- ════════════════════════════════════════════════════════════════
-- CARD HELPERS
-- ════════════════════════════════════════════════════════════════
local function makeCard(parent, yOffset, titleText, subtitleText, badgeText)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, -32, 0, 56)
    card.Position = UDim2.new(0, 16, 0, yOffset)
    card.BackgroundColor3 = C.CARD
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cs = Instance.new("UIStroke", card)
    cs.Color = C.BORDER; cs.Thickness = 1; cs.Transparency = 0.3

    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -90, 0, 20)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = C.TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    if subtitleText then
        local sub = Instance.new("TextLabel", card)
        sub.Size = UDim2.new(1, -90, 0, 16)
        sub.Position = UDim2.new(0, 14, 0, 30)
        sub.BackgroundTransparency = 1
        sub.Text = subtitleText
        sub.TextColor3 = C.SUBTEXT
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end

    if badgeText then
        local badge = Instance.new("Frame", card)
        badge.Size = UDim2.new(0, 52, 0, 28)
        badge.Position = UDim2.new(1, -66, 0.5, -14)
        badge.BackgroundColor3 = C.BADGE
        badge.BorderSizePixel = 0
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
        local bs = Instance.new("UIStroke", badge)
        bs.Color = C.BORDER; bs.Thickness = 1

        local badgeLbl = Instance.new("TextLabel", badge)
        badgeLbl.Size = UDim2.new(1, 0, 1, 0)
        badgeLbl.BackgroundTransparency = 1
        badgeLbl.Text = badgeText
        badgeLbl.TextColor3 = C.TEXT
        badgeLbl.Font = Enum.Font.GothamBold
        badgeLbl.TextSize = 13
        return card, badgeLbl
    end

    return card, nil
end

local function makeToggleCard(parent, yOffset, titleText, subtitleText, defaultState, onToggle)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, -32, 0, 56)
    card.Position = UDim2.new(0, 16, 0, yOffset)
    card.BackgroundColor3 = C.CARD
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local cs = Instance.new("UIStroke", card)
    cs.Color = C.BORDER; cs.Thickness = 1; cs.Transparency = 0.3

    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -90, 0, 20)
    title.Position = UDim2.new(0, 14, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = titleText
    title.TextColor3 = C.TEXT
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left

    if subtitleText then
        local sub = Instance.new("TextLabel", card)
        sub.Size = UDim2.new(1, -90, 0, 16)
        sub.Position = UDim2.new(0, 14, 0, 30)
        sub.BackgroundTransparency = 1
        sub.Text = subtitleText
        sub.TextColor3 = C.SUBTEXT
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Toggle switch
    local togBtn = Instance.new("TextButton", card)
    togBtn.Size = UDim2.new(0, 46, 0, 24)
    togBtn.Position = UDim2.new(1, -60, 0.5, -12)
    togBtn.BackgroundColor3 = defaultState and Color3.fromRGB(80, 80, 100) or C.BADGE
    togBtn.Text = ""
    togBtn.BorderSizePixel = 0
    Instance.new("UICorner", togBtn).CornerRadius = UDim.new(1, 0)
    local ts = Instance.new("UIStroke", togBtn)
    ts.Color = C.BORDER; ts.Thickness = 1

    local knob = Instance.new("Frame", togBtn)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = C.TEXT
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    togBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        TweenService:Create(togBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(80, 80, 100) or C.BADGE
        }):Play()
        onToggle(state)
    end)

    return card
end

-- ════════════════════════════════════════════════════════════════
-- TAB CONTENTS
-- ════════════════════════════════════════════════════════════════

-- ── STEAL TAB ──────────────────────────────────────────────────
do
    local page = tabs["Steal"].page
    makeToggleCard(page, 52, "Auto Steal", "Automatically steals nearby items", savedCfg.AutoSteal or false, function(state)
        stealEnabled = state
        if state then startAutoSteal() else stopAutoSteal() end
        saveConfig()
    end)
    if savedCfg.AutoSteal then stealEnabled = true; startAutoSteal() end

    local card2, badge2 = makeCard(page, 118, "Steal Cooldown", "Time between each steal attempt", "0.2s")
    local card3, badge3 = makeCard(page, 184, "Hold Duration", "How long the prompt is held", "0.5s")
end

-- ── ANTI RAGDOLL TAB ───────────────────────────────────────────
do
    local page = tabs["Anti Ragdoll"].page
    makeToggleCard(page, 52, "Anti Ragdoll", "Prevents your character from ragdolling", savedCfg.AntiRagdoll or false, function(state)
        antiRagdollEnabled = state
        if state then task.wait(0.5); setupAntiRagdoll(character)
        else cleanupRagdoll(); disconnectRemote() end
        saveConfig()
    end)
    if savedCfg.AntiRagdoll then antiRagdollEnabled = true; task.delay(1, function() setupAntiRagdoll(character) end) end

    local card2, badge2 = makeCard(page, 118, "Ragdoll Speed", "Movement speed while ragdolled", "16")
end

-- ── XRAY TAB ───────────────────────────────────────────────────
do
    local page = tabs["XRAY"].page
    makeToggleCard(page, 52, "XRAY / Unwalk", "Makes bases and claims semi-transparent", savedCfg.XRAY or false, function(state)
        unwalkEnabled = state
        if state then startUnwalk() else stopUnwalk() end
        saveConfig()
    end)
    if savedCfg.XRAY then unwalkEnabled = true; startUnwalk() end

    local card2, badge2 = makeCard(page, 118, "Transparency", "How transparent the bases appear", "85%")
    local card3, badge3 = makeCard(page, 184, "Quality Level", "Rendering quality for better visibility", "Low")
end

-- ── VISUAL TAB ─────────────────────────────────────────────────
do
    local page = tabs["Visual"].page
    makeToggleCard(page, 52, "Dark Mode", "Replaces skybox with solid black", savedCfg.Darkmode or false, function(state)
        darkmodeEnabled = state
        if state then startDarkmode() else stopDarkmode() end
        saveConfig()
    end)
    if savedCfg.Darkmode then darkmodeEnabled = true; startDarkmode() end
end

-- ── SETTINGS TAB ───────────────────────────────────────────────
do
    local page = tabs["Settings"].page

    -- Save config card
    local saveCard = Instance.new("Frame", page)
    saveCard.Size = UDim2.new(1, -32, 0, 44)
    saveCard.Position = UDim2.new(0, 16, 0, 52)
    saveCard.BackgroundColor3 = C.CARD
    saveCard.BorderSizePixel = 0
    Instance.new("UICorner", saveCard).CornerRadius = UDim.new(0, 8)
    local scs = Instance.new("UIStroke", saveCard)
    scs.Color = C.BORDER; scs.Thickness = 1; scs.Transparency = 0.3

    local saveBtn = Instance.new("TextButton", saveCard)
    saveBtn.Size = UDim2.new(1, 0, 1, 0)
    saveBtn.BackgroundTransparency = 1
    saveBtn.Text = "SAVE CONFIGURATION"
    saveBtn.TextColor3 = C.TEXT
    saveBtn.Font = Enum.Font.GothamBlack
    saveBtn.TextSize = 13
    saveBtn.BorderSizePixel = 0
    saveBtn.MouseButton1Click:Connect(function()
        saveConfig()
        saveBtn.Text = "✓  SAVED!"
        task.wait(1.5)
        saveBtn.Text = "SAVE CONFIGURATION"
    end)

    local versionLbl = Instance.new("TextLabel", page)
    versionLbl.Size = UDim2.new(1, -32, 0, 30)
    versionLbl.Position = UDim2.new(0, 16, 0, 108)
    versionLbl.BackgroundTransparency = 1
    versionLbl.Text = "Eulen Hub  •  v1.0  •  discord.gg/eulenhub"
    versionLbl.TextColor3 = C.INACTIVE
    versionLbl.Font = Enum.Font.Gotham
    versionLbl.TextSize = 11
    versionLbl.TextXAlignment = Enum.TextXAlignment.Center
end

-- ════════════════════════════════════════════════════════════════
-- DRAGGABLE
-- ════════════════════════════════════════════════════════════════
do
    local dragging, dragStart, startPos = false, nil, nil
    TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = Main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            Shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X - 2, startPos.Y.Scale, startPos.Y.Offset + d.Y + 4)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- MINIMIZE
-- ════════════════════════════════════════════════════════════════
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "—"
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 570, 0, 44) or UDim2.new(0, 570, 0, 420)
    }):Play()
end)

-- ════════════════════════════════════════════════════════════════
-- OPEN ANIMATION + DEFAULT TAB
-- ════════════════════════════════════════════════════════════════
setTab("Steal")
Main.Size = UDim2.new(0, 0, 0, 0)
Shadow.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 570, 0, 420)}):Play()
TweenService:Create(Shadow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 574, 0, 424)}):Play()
