local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP       = character:WaitForChild("HumanoidRootPart", 5)
local Camera    = workspace.CurrentCamera

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    HRP       = newChar:WaitForChild("HumanoidRootPart", 5)
end)

-- ─── AUTO STEAL ────────────────────────────────────────────────
local stealEnabled  = false
local stealCooldown = 0.2
local HOLD_DURATION = 0.5
local stealThread   = nil

local function getPromptPart(prompt)
    local p = prompt.Parent
    if p:IsA("BasePart")   then return p end
    if p:IsA("Model")      then return p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart") end
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
    prompt.RequiresLineOfSight   = false
    prompt.ClickablePrompt       = true
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
    stealThread  = nil
end

-- ─── ANTI RAGDOLL ──────────────────────────────────────────────
local antiRagdollEnabled      = false
local RAGDOLL_SPEED           = 16
local currentCharacter        = nil
local ragdollRemoteConnection = nil
local moveConnection          = nil
local playerModule, controls  = nil, nil

pcall(function()
    playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    controls     = playerModule:GetControls()
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
    local root     = char:WaitForChild("HumanoidRootPart", 5)
    local head     = char:WaitForChild("Head", 5)
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
            anchor.Name = "RagdollAnchor"; anchor.MaxForce = Vector3.new(1e5,1e5,1e5)
            anchor.Position = root.Position; anchor.D = 200; anchor.P = 5000
            anchor.Parent = root
            moveConnection = RunService.Heartbeat:Connect(function()
                if not antiRagdollEnabled then cleanupRagdoll(); return end
                local moveDir = Vector3.zero
                if controls then pcall(function() moveDir = controls:GetMoveVector() end) end
                if moveDir.Magnitude > 0.1 then
                    local cf = Camera.CFrame
                    local fwd = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
                    local rgt = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                    anchor.Position = root.Position + (fwd*-moveDir.Z+rgt*moveDir.X).Unit*RAGDOLL_SPEED*0.1
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
local unwalkEnabled        = false
local originalTransparency = {}
local unwalkDescConn       = nil
local unwalkCharConn       = nil

local function startUnwalk()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness    = 3
        Lighting.FogEnd        = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material   = Enum.Material.Plastic
                end
            end)
        end
    end)
    local function cleanCharacter(char)
        if char == player.Character then return end
        pcall(function()
            for _, a in ipairs(char:GetChildren()) do
                if a:IsA("Accessory") then a:Destroy() end
            end
            char.ChildAdded:Connect(function(c)
                if unwalkEnabled and c:IsA("Accessory") then c:Destroy() end
            end)
        end)
    end
    pcall(function()
        for _, h in ipairs(workspace:GetDescendants()) do
            if h:IsA("Humanoid") then cleanCharacter(h.Parent) end
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

-- ─── SAVE / LOAD ───────────────────────────────────────────────
local CONFIG_FILE = "KMoneyHub_config.json"

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            AutoSteal   = stealEnabled,
            AntiRagdoll = antiRagdollEnabled,
            XRAY        = unwalkEnabled,
        }))
    end)
end

local savedCfg = {}
pcall(function() savedCfg = HttpService:JSONDecode(readfile(CONFIG_FILE)) end)

-- ═══════════════════════════════════════════════════
-- ─── PALETA VLX STYLE ──────────────────────────────
-- ═══════════════════════════════════════════════════
local C_BG        = Color3.fromRGB(240, 240, 242)   -- fondo principal
local C_WHITE     = Color3.fromRGB(255, 255, 255)   -- tarjetas/rows
local C_SECTION   = Color3.fromRGB(228, 228, 232)   -- header de sección
local C_BORDER    = Color3.fromRGB(200, 200, 205)   -- bordes suaves
local C_TEXT      = Color3.fromRGB(30,  30,  35)    -- texto principal
local C_SUBTEXT   = Color3.fromRGB(120, 120, 130)   -- texto secundario
local C_ACCENT    = Color3.fromRGB(99,  179, 237)   -- azul toggle ON
local C_ACCENTDIM = Color3.fromRGB(180, 215, 240)   -- azul claro knob on
local C_OFF       = Color3.fromRGB(190, 190, 198)   -- toggle OFF track
local C_KNOBOFF   = Color3.fromRGB(255, 255, 255)   -- knob OFF
local C_TOPBAR    = Color3.fromRGB(255, 255, 255)   -- barra superior
local C_ACCENT2   = Color3.fromRGB(234, 179, 8)     -- amarillo acento top (como VLX)
local C_SAVEBTN   = Color3.fromRGB(99,  179, 237)
local FULL_HEIGHT = 340

-- ═══════════════════════════════════════════════════
-- ─── GUI ROOT ──────────────────────────────────────
-- ═══════════════════════════════════════════════════
if CoreGui:FindFirstChild("KMoneyHub") then
    CoreGui:FindFirstChild("KMoneyHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KMoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function() ScreenGui.Parent = CoreGui end)

-- Sombra del main
local Shadow = Instance.new("Frame", ScreenGui)
Shadow.Size             = UDim2.new(0, 286, 0, FULL_HEIGHT + 8)
Shadow.Position         = UDim2.new(0.5, -143, 0.5, -FULL_HEIGHT/2 + 4)
Shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
Shadow.BackgroundTransparency = 0.82
Shadow.BorderSizePixel  = 0
Instance.new("UICorner", Shadow).CornerRadius = UDim.new(0, 14)

local Main = Instance.new("Frame", ScreenGui)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 278, 0, FULL_HEIGHT)
Main.Position         = UDim2.new(0.5, -139, 0.5, -FULL_HEIGHT/2)
Main.BackgroundColor3 = C_BG
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color       = C_BORDER
mainStroke.Thickness   = 1
mainStroke.Transparency = 0

-- ─── TOP ACCENT BAR (amarillo como VLX) ────────────────────────
local TopAccent = Instance.new("Frame", Main)
TopAccent.Size             = UDim2.new(0, 60, 0, 6)
TopAccent.Position         = UDim2.new(0.5, -30, 0, 0)
TopAccent.BackgroundColor3 = C_ACCENT2
TopAccent.BorderSizePixel  = 0
Instance.new("UICorner", TopAccent).CornerRadius = UDim.new(0, 3)

-- ─── TITLE BAR ─────────────────────────────────────────────────
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 52)
TitleBar.Position         = UDim2.new(0, 0, 0, 6)
TitleBar.BackgroundColor3 = C_WHITE
TitleBar.BorderSizePixel  = 0

local titleBotLine = Instance.new("Frame", TitleBar)
titleBotLine.Size             = UDim2.new(1, 0, 0, 1)
titleBotLine.Position         = UDim2.new(0, 0, 1, -1)
titleBotLine.BackgroundColor3 = C_BORDER
titleBotLine.BorderSizePixel  = 0

-- Hub name
local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size                   = UDim2.new(1, -80, 1, 0)
TitleLbl.Position               = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "KMONEY HUB"
TitleLbl.TextColor3             = C_TEXT
TitleLbl.Font                   = Enum.Font.GothamBlack
TitleLbl.TextSize               = 15
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Credits
local CreditsLbl = Instance.new("TextLabel", TitleBar)
CreditsLbl.Size                   = UDim2.new(1, -80, 0, 14)
CreditsLbl.Position               = UDim2.new(0, 14, 1, -16)
CreditsLbl.BackgroundTransparency = 1
CreditsLbl.Text                   = "credits: kmoney"
CreditsLbl.TextColor3             = C_SUBTEXT
CreditsLbl.Font                   = Enum.Font.Gotham
CreditsLbl.TextSize               = 10
CreditsLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Botón minimizar
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size                   = UDim2.new(0, 24, 0, 24)
MinBtn.Position               = UDim2.new(1, -58, 0.5, -12)
MinBtn.BackgroundColor3       = C_SECTION
MinBtn.Text                   = "−"
MinBtn.TextColor3             = C_SUBTEXT
MinBtn.Font                   = Enum.Font.GothamBold
MinBtn.TextSize               = 14
MinBtn.BorderSizePixel        = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local minStroke = Instance.new("UIStroke", MinBtn)
minStroke.Color = C_BORDER; minStroke.Thickness = 1

-- Botón cerrar (solo oculta)
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size                   = UDim2.new(0, 24, 0, 24)
CloseBtn.Position               = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3       = Color3.fromRGB(252, 100, 100)
CloseBtn.Text                   = "×"
CloseBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 14
CloseBtn.BorderSizePixel        = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0,0,0,0)
    }):Play()
    task.wait(0.22)
    ScreenGui:Destroy()
end)

-- ─── SCROLL CONTENT ────────────────────────────────────────────
local ScrollFrame = Instance.new("ScrollingFrame", Main)
ScrollFrame.Size                   = UDim2.new(1, 0, 1, -58)
ScrollFrame.Position               = UDim2.new(0, 0, 0, 58)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel        = 0
ScrollFrame.ScrollBarThickness     = 3
ScrollFrame.ScrollBarImageColor3   = C_ACCENT
ScrollFrame.CanvasSize             = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize    = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", ScrollFrame)
ListLayout.FillDirection  = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.Padding        = UDim.new(0, 0)
ListLayout.SortOrder      = Enum.SortOrder.LayoutOrder

local Padding = Instance.new("UIPadding", ScrollFrame)
Padding.PaddingBottom = UDim.new(0, 10)

-- ─── HELPER: SECTION HEADER ────────────────────────────────────
local function makeSectionHeader(text, order)
    local F = Instance.new("Frame", ScrollFrame)
    F.Size             = UDim2.new(1, 0, 0, 32)
    F.BackgroundColor3 = C_SECTION
    F.BorderSizePixel  = 0
    F.LayoutOrder      = order
    local L = Instance.new("TextLabel", F)
    L.Size                   = UDim2.new(1, -16, 1, 0)
    L.Position               = UDim2.new(0, 14, 0, 0)
    L.BackgroundTransparency = 1
    L.Text                   = text
    L.TextColor3             = C_TEXT
    L.Font                   = Enum.Font.GothamBold
    L.TextSize               = 12
    L.TextXAlignment         = Enum.TextXAlignment.Left
    return F
end

-- ─── HELPER: SUB LABEL ─────────────────────────────────────────
local function makeSubLabel(text, order)
    local F = Instance.new("Frame", ScrollFrame)
    F.Size             = UDim2.new(1, 0, 0, 22)
    F.BackgroundColor3 = C_WHITE
    F.BorderSizePixel  = 0
    F.LayoutOrder      = order
    local topLine = Instance.new("Frame", F)
    topLine.Size             = UDim2.new(1, -28, 0, 1)
    topLine.Position         = UDim2.new(0, 14, 0.5, 0)
    topLine.BackgroundColor3 = C_BORDER
    topLine.BorderSizePixel  = 0
    local L = Instance.new("TextLabel", F)
    L.Size                   = UDim2.new(0, 100, 1, 0)
    L.Position               = UDim2.new(0, 14, 0, 0)
    L.BackgroundColor3       = C_WHITE
    L.BackgroundTransparency = 0
    L.Text                   = "  "..text.."  "
    L.TextColor3             = C_SUBTEXT
    L.Font                   = Enum.Font.Gotham
    L.TextSize               = 10
    L.TextXAlignment         = Enum.TextXAlignment.Left
    L.ZIndex                 = 2
    return F
end

-- ─── HELPER: TOGGLE ROW ────────────────────────────────────────
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeToggleRow(icon, labelText, descText, order)
    local Row = Instance.new("Frame", ScrollFrame)
    Row.Size             = UDim2.new(1, 0, 0, 50)
    Row.BackgroundColor3 = C_WHITE
    Row.BorderSizePixel  = 0
    Row.LayoutOrder      = order

    local botLine = Instance.new("Frame", Row)
    botLine.Size             = UDim2.new(1, -28, 0, 1)
    botLine.Position         = UDim2.new(0, 14, 1, -1)
    botLine.BackgroundColor3 = C_BORDER
    botLine.BorderSizePixel  = 0

    -- Icono izquierda (cuadradito con inicial)
    local IconBox = Instance.new("Frame", Row)
    IconBox.Size             = UDim2.new(0, 28, 0, 28)
    IconBox.Position         = UDim2.new(0, 14, 0.5, -14)
    IconBox.BackgroundColor3 = C_SECTION
    IconBox.BorderSizePixel  = 0
    Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 6)
    local IconStroke = Instance.new("UIStroke", IconBox)
    IconStroke.Color = C_BORDER; IconStroke.Thickness = 1
    local IconLbl = Instance.new("TextLabel", IconBox)
    IconLbl.Size                   = UDim2.new(1, 0, 1, 0)
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text                   = icon
    IconLbl.TextSize               = 13
    IconLbl.Font                   = Enum.Font.GothamBold
    IconLbl.TextColor3             = C_TEXT

    -- Texto principal
    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1,-110,0,18); Lbl.Position = UDim2.new(0,52,0,8)
    Lbl.BackgroundTransparency = 1; Lbl.Text = labelText
    Lbl.TextColor3 = C_TEXT; Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 12; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Descripción
    local Desc = Instance.new("TextLabel", Row)
    Desc.Size = UDim2.new(1,-110,0,14); Desc.Position = UDim2.new(0,52,0,27)
    Desc.BackgroundTransparency = 1; Desc.Text = descText
    Desc.TextColor3 = C_SUBTEXT; Desc.Font = Enum.Font.Gotham
    Desc.TextSize = 10; Desc.TextXAlignment = Enum.TextXAlignment.Left

    -- Toggle track
    local Track = Instance.new("TextButton", Row)
    Track.Size = UDim2.new(0,44,0,22); Track.Position = UDim2.new(1,-58,0.5,-11)
    Track.BackgroundColor3 = C_OFF; Track.Text = ""; Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1,0)

    -- Toggle knob
    local Knob = Instance.new("Frame", Track)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,2,0.5,-9)
    Knob.BackgroundColor3 = C_KNOBOFF; Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    local knobShadow = Instance.new("UIStroke", Knob)
    knobShadow.Color = C_BORDER; knobShadow.Thickness = 1; knobShadow.Transparency = 0.3

    return Track, Knob, Row, IconBox
end

local function setToggleOn(track, knob, iconBox)
    TweenService:Create(track, ti, {BackgroundColor3 = C_ACCENT}):Play()
    TweenService:Create(knob,  ti, {Position = UDim2.new(1,-20,0.5,-9), BackgroundColor3 = C_WHITE}):Play()
    TweenService:Create(iconBox, ti, {BackgroundColor3 = C_ACCENTDIM}):Play()
end

local function setToggleOff(track, knob, iconBox)
    TweenService:Create(track, ti, {BackgroundColor3 = C_OFF}):Play()
    TweenService:Create(knob,  ti, {Position = UDim2.new(0,2,0.5,-9), BackgroundColor3 = C_KNOBOFF}):Play()
    TweenService:Create(iconBox, ti, {BackgroundColor3 = C_SECTION}):Play()
end

-- ═══════════════════════════════════════════════════
-- ─── SECCIÓN: STEAL SETTINGS ───────────────────────
-- ═══════════════════════════════════════════════════
makeSectionHeader("Steal Settings", 1)
makeSubLabel("Auto Steal", 2)

local T1, K1, R1, IB1 = makeToggleRow("S", "Auto Steal", "Steal automáticamente del plot más cercano", 3)
if savedCfg.AutoSteal then stealEnabled = true; startAutoSteal(); setToggleOn(T1,K1,IB1) end
T1.MouseButton1Click:Connect(function()
    stealEnabled = not stealEnabled
    if stealEnabled then startAutoSteal(); setToggleOn(T1,K1,IB1)
    else stopAutoSteal(); setToggleOff(T1,K1,IB1) end
    saveConfig()
end)

-- ═══════════════════════════════════════════════════
-- ─── SECCIÓN: PLAYER SETTINGS ──────────────────────
-- ═══════════════════════════════════════════════════
makeSectionHeader("Player Settings", 10)
makeSubLabel("Combat", 11)

local T2, K2, R2, IB2 = makeToggleRow("R", "Anti Ragdoll", "Evita que tu personaje caiga al suelo", 12)
if savedCfg.AntiRagdoll then antiRagdollEnabled=true; task.delay(1,function() setupAntiRagdoll(character) end); setToggleOn(T2,K2,IB2) end
T2.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        task.wait(0.5); setupAntiRagdoll(character); setToggleOn(T2,K2,IB2)
    else
        cleanupRagdoll(); disconnectRemote(); setToggleOff(T2,K2,IB2)
    end
    saveConfig()
end)

makeSubLabel("Visual", 13)

local T3, K3, R3, IB3 = makeToggleRow("X", "X-Ray", "Hace transparentes las bases y claims", 14)
if savedCfg.XRAY then unwalkEnabled=true; startUnwalk(); setToggleOn(T3,K3,IB3) end
T3.MouseButton1Click:Connect(function()
    unwalkEnabled = not unwalkEnabled
    if unwalkEnabled then startUnwalk(); setToggleOn(T3,K3,IB3)
    else stopUnwalk(); setToggleOff(T3,K3,IB3) end
    saveConfig()
end)

-- ═══════════════════════════════════════════════════
-- ─── SECCIÓN: CONFIG ───────────────────────────────
-- ═══════════════════════════════════════════════════
makeSectionHeader("Configuration", 20)

local SaveOuter = Instance.new("Frame", ScrollFrame)
SaveOuter.Size             = UDim2.new(1, 0, 0, 56)
SaveOuter.BackgroundColor3 = C_WHITE
SaveOuter.BorderSizePixel  = 0
SaveOuter.LayoutOrder      = 21

local SaveBtn = Instance.new("TextButton", SaveOuter)
SaveBtn.Size             = UDim2.new(1, -28, 0, 36)
SaveBtn.Position         = UDim2.new(0, 14, 0.5, -18)
SaveBtn.BackgroundColor3 = C_ACCENT
SaveBtn.Text             = "Save Config"
SaveBtn.Font             = Enum.Font.GothamBold
SaveBtn.TextSize         = 13
SaveBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
SaveBtn.BorderSizePixel  = 0
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    TweenService:Create(SaveBtn, ti, {BackgroundColor3 = Color3.fromRGB(72,180,100)}):Play()
    SaveBtn.Text = "Saved!"
    task.wait(1.2)
    TweenService:Create(SaveBtn, ti, {BackgroundColor3 = C_ACCENT}):Play()
    SaveBtn.Text = "Save Config"
end)

SaveBtn.MouseEnter:Connect(function()
    TweenService:Create(SaveBtn, ti, {BackgroundColor3 = Color3.fromRGB(79,163,224)}):Play()
end)
SaveBtn.MouseLeave:Connect(function()
    TweenService:Create(SaveBtn, ti, {BackgroundColor3 = C_ACCENT}):Play()
end)

-- ═══════════════════════════════════════════════════
-- ─── DRAGGABLE ─────────────────────────────────────
-- ═══════════════════════════════════════════════════
do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
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
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
            Main.Position   = newPos
            Shadow.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset-7, newPos.Y.Scale, newPos.Y.Offset+4)
        end
    end)
end

-- ─── MINIMIZAR ─────────────────────────────────────────────────
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "−"
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0,278,0,58) or UDim2.new(0,278,0,FULL_HEIGHT)
    }):Play()
end)

-- ─── OPEN ANIMATION ────────────────────────────────────────────
Main.Size    = UDim2.new(0,0,0,0)
Shadow.Size  = UDim2.new(0,0,0,0)
TweenService:Create(Main,   TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,278,0,FULL_HEIGHT)}):Play()
TweenService:Create(Shadow, TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,286,0,FULL_HEIGHT+8)}):Play()

-- ═══════════════════════════════════════════════════
-- ─── GUADAÑA EXTERIOR (derecha del hub) ────────────
-- ═══════════════════════════════════════════════════
local ScytheFrame = Instance.new("Frame", ScreenGui)
ScytheFrame.Name                    = "Scythe"
ScytheFrame.Size                    = UDim2.new(0, 80, 0, 320)
ScytheFrame.BackgroundTransparency  = 1
ScytheFrame.BorderSizePixel         = 0
ScytheFrame.ZIndex                  = 5

-- Mango (palo largo, madera oscura)
local Handle = Instance.new("Frame", ScytheFrame)
Handle.Size             = UDim2.new(0, 8, 0, 260)
Handle.Position         = UDim2.new(0, 38, 0, 55)
Handle.BackgroundColor3 = Color3.fromRGB(55, 32, 12)
Handle.BorderSizePixel  = 0
Instance.new("UICorner", Handle).CornerRadius = UDim.new(0, 4)
Instance.new("UIGradient", Handle).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 28, 10)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 18, 6)),
})

-- Vendas del mango
for _, yp in ipairs({0.18, 0.34, 0.52, 0.70, 0.87}) do
    local wr = Instance.new("Frame", Handle)
    wr.Size             = UDim2.new(1, 6, 0, 5)
    wr.Position         = UDim2.new(-0.3, 0, yp, 0)
    wr.BackgroundColor3 = Color3.fromRGB(110, 80, 18)
    wr.BorderSizePixel  = 0
    Instance.new("UICorner", wr).CornerRadius = UDim.new(0, 2)
end

-- Punta inferior metálica
local BottomCap = Instance.new("Frame", ScytheFrame)
BottomCap.Size             = UDim2.new(0, 12, 0, 12)
BottomCap.Position         = UDim2.new(0, 35, 0, 308)
BottomCap.BackgroundColor3 = Color3.fromRGB(75, 75, 88)
BottomCap.BorderSizePixel  = 0
Instance.new("UICorner", BottomCap).CornerRadius = UDim.new(0, 4)
Instance.new("UIGradient", BottomCap).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130,130,145)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,60)),
})

-- Hoja trasera (forma de hoz)
local BladeBack = Instance.new("Frame", ScytheFrame)
BladeBack.Size             = UDim2.new(0, 70, 0, 75)
BladeBack.Position         = UDim2.new(0, 0, 0, 0)
BladeBack.BackgroundColor3 = Color3.fromRGB(185, 185, 200)
BladeBack.BorderSizePixel  = 0
BladeBack.Rotation         = 15
Instance.new("UICorner", BladeBack).CornerRadius = UDim.new(0.5, 0)
Instance.new("UIGradient", BladeBack).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(215, 215, 230)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 245, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(85,  85, 100)),
})

-- Hueco interior (da la forma curva de la hoz)
local BladeSharp = Instance.new("Frame", ScytheFrame)
BladeSharp.Size             = UDim2.new(0, 55, 0, 55)
BladeSharp.Position         = UDim2.new(0, 6, 0, 11)
BladeSharp.BackgroundColor3 = Color3.fromRGB(240, 240, 242) -- mismo que C_BG para "recortar"
BladeSharp.BorderSizePixel  = 0
BladeSharp.Rotation         = 15
Instance.new("UICorner", BladeSharp).CornerRadius = UDim.new(0.6, 0)

-- Brillo filo
local BladeShine = Instance.new("Frame", ScytheFrame)
BladeShine.Size                    = UDim2.new(0, 4, 0, 38)
BladeShine.Position                = UDim2.new(0, 9, 0, 8)
BladeShine.BackgroundColor3        = Color3.fromRGB(255, 255, 255)
BladeShine.BackgroundTransparency  = 0.35
BladeShine.BorderSizePixel         = 0
BladeShine.Rotation                = 30
Instance.new("UICorner", BladeShine).CornerRadius = UDim.new(1, 0)

-- Skull en la unión mango-hoja
local SkullTop = Instance.new("TextLabel", ScytheFrame)
SkullTop.Size                   = UDim2.new(0, 28, 0, 28)
SkullTop.Position               = UDim2.new(0, 26, 0, 43)
SkullTop.BackgroundTransparency = 1
SkullTop.Text                   = "💀"
SkullTop.TextSize               = 20
SkullTop.Font                   = Enum.Font.GothamBold
SkullTop.ZIndex                 = 6

-- Gotas de sangre en el filo
for _, pos in ipairs({{7,36},{17,26},{27,17}}) do
    local drop = Instance.new("Frame", ScytheFrame)
    drop.Size             = UDim2.new(0, 5, 0, 8)
    drop.Position         = UDim2.new(0, pos[1], 0, pos[2])
    drop.BackgroundColor3 = Color3.fromRGB(175, 0, 0)
    drop.BorderSizePixel  = 0
    Instance.new("UICorner", drop).CornerRadius = UDim.new(1, 0)
    -- Animación de goteo
    task.spawn(function()
        task.wait(math.random(0,20)/10)
        while ScreenGui.Parent do
            TweenService:Create(drop, TweenInfo.new(1.2+math.random(0,8)/10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, pos[1], 0, pos[2]+18),
                Size = UDim2.new(0, 5, 0, 14),
            }):Play()
            task.wait(1.5)
            drop.Position = UDim2.new(0, pos[1], 0, pos[2])
            drop.Size     = UDim2.new(0, 5, 0, 8)
            task.wait(0.8 + math.random(0,15)/10)
        end
    end)
end

-- Animación de flotación + seguir al hub
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.035
        local wave = math.sin(t) * 7
        ScytheFrame.Position = UDim2.new(
            Main.Position.X.Scale,
            Main.Position.X.Offset + 278 + 10,   -- a la DERECHA del hub
            Main.Position.Y.Scale,
            Main.Position.Y.Offset - 20 + wave
        )
        -- Pulso sutil en el brillo del filo
        BladeShine.BackgroundTransparency = 0.3 + math.abs(math.sin(t*0.7)) * 0.4
        task.wait(0.03)
    end
end)

-- ═══════════════════════════════════════════════════
-- ─── CALAVERAS FLOTANTES (fondo del hub) ───────────
-- ═══════════════════════════════════════════════════
for i = 1, 5 do
    local skLbl = Instance.new("TextLabel", Main)
    skLbl.Size                   = UDim2.new(0, 20, 0, 20)
    skLbl.Position               = UDim2.new(math.random(5,88)/100, 0, math.random(10,85)/100, 0)
    skLbl.BackgroundTransparency = 1
    skLbl.Text                   = "💀"
    skLbl.TextSize               = math.random(9,13)
    skLbl.Font                   = Enum.Font.GothamBold
    skLbl.TextTransparency       = 0.88
    skLbl.ZIndex                 = 1
    task.spawn(function()
        task.wait(math.random(0,25)/10)
        while ScreenGui.Parent do
            TweenService:Create(skLbl, TweenInfo.new(2.5+math.random(0,12)/10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                TextTransparency = 0.65,
                Position = UDim2.new(skLbl.Position.X.Scale, 0, skLbl.Position.Y.Scale - 0.05, 0)
            }):Play()
            task.wait(6)
        end
    end)
end

-- ═══════════════════════════════════════════════════
-- ─── LLUVIA DE CALAVERAS EN SAVE BUTTON ────────────
-- ═══════════════════════════════════════════════════
for i = 1, 10 do
    local drop = Instance.new("TextLabel", SaveOuter)
    drop.Size                   = UDim2.new(0, 14, 0, 14)
    drop.BackgroundTransparency = 1
    drop.Text                   = "💀"
    drop.TextSize               = 10
    drop.Font                   = Enum.Font.GothamBold
    drop.TextTransparency       = 1
    drop.ZIndex                 = 5
    task.spawn(function()
        task.wait(math.random(0,30)/10)
        while ScreenGui.Parent do
            local xp = math.random(5,90)/100
            drop.Position = UDim2.new(xp, 0, 0, -14)
            drop.TextTransparency = 0.05
            TweenService:Create(drop, TweenInfo.new(0.85+math.random(0,5)/10, Enum.EasingStyle.Linear), {
                Position          = UDim2.new(xp, 0, 1, 4),
                TextTransparency  = 0.92,
            }):Play()
            task.wait(1.1 + math.random(0,18)/10)
        end
    end)
end
