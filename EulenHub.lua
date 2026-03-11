local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local HRP       = character:WaitForChild("HumanoidRootPart", 5)
local Camera    = workspace.CurrentCamera

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    HRP       = newChar:WaitForChild("HumanoidRootPart", 5)
end)

-- ─── SAVE / LOAD ───────────────────────────────────────────────
local HttpService  = game:GetService("HttpService")
local CONFIG_FILE  = "KMoneyHub_config.json"

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
pcall(function()
    savedCfg = HttpService:JSONDecode(readfile(CONFIG_FILE))
end)

-- ─── AUTO STEAL LOGIC ──────────────────────────────────────────
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

-- ─── ANTI RAGDOLL LOGIC ────────────────────────────────────────
local antiRagdollEnabled      = false
local RAGDOLL_SPEED           = 16
local currentCharacter        = nil
local ragdollRemoteConnection = nil
local moveConnection          = nil
local playerModule            = nil
local controls                = nil

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
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end
end

local function disconnectRemote()
    if ragdollRemoteConnection then
        ragdollRemoteConnection:Disconnect()
        ragdollRemoteConnection = nil
    end
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

    if not ragdollRemote or not ragdollRemote:IsA("RemoteEvent") then
        warn("[Anti-Ragdoll] Could not find Ragdoll remote")
        return
    end

    ragdollRemoteConnection = ragdollRemote.OnClientEvent:Connect(function(arg1, arg2)
        if not antiRagdollEnabled then return end

        if arg1 == "Make" or arg2 == "manualM" then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            Camera.CameraSubject = head
            root.CanCollide = false

            if controls then pcall(controls.Enable, controls) end
            cleanupRagdoll()

            local anchor = Instance.new("BodyPosition")
            anchor.Name          = "RagdollAnchor"
            anchor.MaxForce      = Vector3.new(1e5, 1e5, 1e5)
            anchor.Position      = root.Position
            anchor.D             = 200
            anchor.P             = 5000
            anchor.Parent        = root

            moveConnection = RunService.Heartbeat:Connect(function()
                if not antiRagdollEnabled then
                    cleanupRagdoll()
                    return
                end
                local moveDir = Vector3.zero
                if controls then
                    pcall(function() moveDir = controls:GetMoveVector() end)
                end
                if moveDir.Magnitude > 0.1 then
                    local camCF   = Camera.CFrame
                    local flatFwd = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
                    local flatRgt = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit
                    local worldDir = (flatFwd * -moveDir.Z + flatRgt * moveDir.X).Unit
                    anchor.Position = root.Position + worldDir * RAGDOLL_SPEED * 0.1
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

-- Hook character spawns for Anti Ragdoll
player.CharacterAdded:Connect(function(newChar)
    if antiRagdollEnabled then
        task.wait(1)
        setupAntiRagdoll(newChar)
    end
end)

-- ─── UNWALK LOGIC ──────────────────────────────────────────────
local unwalkEnabled       = false
local originalTransparency = {}
local unwalkDescConn      = nil
local unwalkCharConn      = nil

local function isPlayerBase(obj)
    if not (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
        return false
    end
    local n = obj.Name:lower()
    local p = obj.Parent and obj.Parent.Name:lower() or ""
    return n:find("base") or n:find("claim") or p:find("base") or p:find("claim")
end

local function applyUnwalk()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPlayerBase(obj) then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.8
        end
    end
end

local function revertUnwalk()
    for obj, val in pairs(originalTransparency) do
        pcall(function() obj.LocalTransparencyModifier = val end)
    end
    originalTransparency = {}
end

local function startUnwalk()
    applyUnwalk()
    unwalkDescConn = workspace.DescendantAdded:Connect(function(obj)
        if unwalkEnabled and isPlayerBase(obj) then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.8
        end
    end)
    unwalkCharConn = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if unwalkEnabled then applyUnwalk() end
    end)
end

local function stopUnwalk()
    if unwalkDescConn then unwalkDescConn:Disconnect(); unwalkDescConn = nil end
    if unwalkCharConn then unwalkCharConn:Disconnect(); unwalkCharConn = nil end
    revertUnwalk()
end

-- ─── GUI ───────────────────────────────────────────────────────
if CoreGui:FindFirstChild("KMoneyHub") then
    CoreGui:FindFirstChild("KMoneyHub"):Destroy()
end

local CYAN     = Color3.fromRGB(0, 230, 255)
local CYAN_DIM = Color3.fromRGB(0, 160, 200)
local BG       = Color3.fromRGB(2, 2, 4)
local CARD     = Color3.fromRGB(4, 7, 12)

-- Height: 120 base + 56 per extra row (3 rows = 232)
local FULL_HEIGHT = 232

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KMoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function() ScreenGui.Parent = CoreGui end)

local Main = Instance.new("Frame", ScreenGui)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 262, 0, FULL_HEIGHT)
Main.Position         = UDim2.new(0.5, -131, 0.5, -88)
Main.BackgroundColor3 = BG
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local neonStroke = Instance.new("UIStroke", Main)
neonStroke.Color     = CYAN
neonStroke.Thickness = 2

local TopLine = Instance.new("Frame", Main)
TopLine.Size             = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = CYAN
TopLine.BorderSizePixel  = 0

-- Title bar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.Position         = UDim2.new(0, 0, 0, 2)
TitleBar.BackgroundColor3 = CARD
TitleBar.BorderSizePixel  = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size                   = UDim2.new(1, -46, 1, 0)
TitleLbl.Position               = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "KMONEY HUB"
TitleLbl.TextColor3             = CYAN
TitleLbl.TextStrokeColor3       = CYAN
TitleLbl.TextStrokeTransparency = 0.4
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.TextSize               = 17
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left

local DollarBtn = Instance.new("TextButton", TitleBar)
DollarBtn.Size                   = UDim2.new(0, 28, 0, 28)
DollarBtn.Position               = UDim2.new(1, -36, 0.5, -14)
DollarBtn.BackgroundTransparency = 1
DollarBtn.Text                   = "$"
DollarBtn.TextColor3             = CYAN
DollarBtn.TextStrokeColor3       = CYAN
DollarBtn.TextStrokeTransparency = 0.3
DollarBtn.Font                   = Enum.Font.GothamBold
DollarBtn.TextSize               = 16
DollarBtn.BorderSizePixel        = 0
Instance.new("UIStroke", DollarBtn).Thickness = 0

-- Content
local Content = Instance.new("Frame", Main)
Content.Size                   = UDim2.new(1, 0, 1, -47)
Content.Position               = UDim2.new(0, 0, 0, 47)
Content.BackgroundTransparency = 1

-- ─── HELPER: build a toggle row ────────────────────────────────
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeToggleRow(labelText, yOffset)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, -28, 0, 44)
    Row.Position         = UDim2.new(0, 14, 0, yOffset)
    Row.BackgroundColor3 = CARD
    Row.BorderSizePixel  = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local rStroke = Instance.new("UIStroke", Row)
    rStroke.Color        = CYAN_DIM
    rStroke.Thickness    = 0
    rStroke.Transparency = 1

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size                   = UDim2.new(1, -60, 1, 0)
    Lbl.Position               = UDim2.new(0, 12, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = labelText
    Lbl.TextColor3             = Color3.fromRGB(180, 235, 255)
    Lbl.TextStrokeColor3       = CYAN
    Lbl.TextStrokeTransparency = 0.7
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 14
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Row)
    Btn.Size             = UDim2.new(0, 46, 0, 24)
    Btn.Position         = UDim2.new(1, -54, 0.5, -12)
    Btn.BackgroundColor3 = Color3.fromRGB(10, 20, 32)
    Btn.Text             = ""
    Btn.BorderSizePixel  = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)

    local bStroke = Instance.new("UIStroke", Btn)
    bStroke.Color        = CYAN_DIM
    bStroke.Thickness    = 1
    bStroke.Transparency = 0.5

    local Knob = Instance.new("Frame", Btn)
    Knob.Size             = UDim2.new(0, 18, 0, 18)
    Knob.Position         = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(50, 80, 100)
    Knob.BorderSizePixel  = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    return Btn, Knob, bStroke
end

-- ─── ROW 1: Auto Steal ─────────────────────────────────────────
local Toggle1, Knob1, tStroke1 = makeToggleRow("Auto Steal", 12)

Toggle1.MouseButton1Click:Connect(function()
    stealEnabled = not stealEnabled
    if stealEnabled then
        startAutoSteal()
        TweenService:Create(Toggle1, ti, {BackgroundColor3 = CYAN}):Play()
        TweenService:Create(Knob1, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
        tStroke1.Color = CYAN; tStroke1.Transparency = 0
    else
        stopAutoSteal()
        TweenService:Create(Toggle1, ti, {BackgroundColor3 = Color3.fromRGB(10,20,32)}):Play()
        TweenService:Create(Knob1, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(50,80,100)}):Play()
        tStroke1.Color = CYAN_DIM; tStroke1.Transparency = 0.5
    end
    saveConfig()
end)

-- restore Auto Steal
if savedCfg.AutoSteal then
    stealEnabled = true
    startAutoSteal()
    Toggle1.BackgroundColor3 = CYAN
    Knob1.Position           = UDim2.new(1,-21,0.5,-9)
    Knob1.BackgroundColor3   = Color3.fromRGB(255,255,255)
    tStroke1.Color           = CYAN
    tStroke1.Transparency    = 0
end

-- ─── ROW 2: Anti Ragdoll ───────────────────────────────────────
local Toggle2, Knob2, tStroke2 = makeToggleRow("Anti Ragdoll", 68)

Toggle2.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        task.wait(0.5)
        setupAntiRagdoll(character)
        TweenService:Create(Toggle2, ti, {BackgroundColor3 = CYAN}):Play()
        TweenService:Create(Knob2, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
        tStroke2.Color = CYAN; tStroke2.Transparency = 0
    else
        cleanupRagdoll()
        disconnectRemote()
        TweenService:Create(Toggle2, ti, {BackgroundColor3 = Color3.fromRGB(10,20,32)}):Play()
        TweenService:Create(Knob2, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(50,80,100)}):Play()
        tStroke2.Color = CYAN_DIM; tStroke2.Transparency = 0.5
    end
    saveConfig()
end)

-- restore Anti Ragdoll
if savedCfg.AntiRagdoll then
    antiRagdollEnabled = true
    task.delay(1, function() setupAntiRagdoll(character) end)
    Toggle2.BackgroundColor3 = CYAN
    Knob2.Position           = UDim2.new(1,-21,0.5,-9)
    Knob2.BackgroundColor3   = Color3.fromRGB(255,255,255)
    tStroke2.Color           = CYAN
    tStroke2.Transparency    = 0
end

-- ─── ROW 3: XRAY ──────────────────────────────────────────────
local Toggle3, Knob3, tStroke3 = makeToggleRow("XRAY", 124)

Toggle3.MouseButton1Click:Connect(function()
    unwalkEnabled = not unwalkEnabled
    if unwalkEnabled then
        startUnwalk()
        TweenService:Create(Toggle3, ti, {BackgroundColor3 = CYAN}):Play()
        TweenService:Create(Knob3, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
        tStroke3.Color = CYAN; tStroke3.Transparency = 0
    else
        stopUnwalk()
        TweenService:Create(Toggle3, ti, {BackgroundColor3 = Color3.fromRGB(10,20,32)}):Play()
        TweenService:Create(Knob3, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(50,80,100)}):Play()
        tStroke3.Color = CYAN_DIM; tStroke3.Transparency = 0.5
    end
    saveConfig()
end)

-- restore XRAY
if savedCfg.XRAY then
    unwalkEnabled = true
    startUnwalk()
    Toggle3.BackgroundColor3 = CYAN
    Knob3.Position           = UDim2.new(1,-21,0.5,-9)
    Knob3.BackgroundColor3   = Color3.fromRGB(255,255,255)
    tStroke3.Color           = CYAN
    tStroke3.Transparency    = 0
end

-- ─── DRAGGABLE ─────────────────────────────────────────────────
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
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ─── $ = MINIMIZAR / RESTAURAR ─────────────────────────────────
local minimized = false
DollarBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0, 262, 0, 48) or UDim2.new(0, 262, 0, FULL_HEIGHT)
    }):Play()
end)

-- ─── NEON PULSE ────────────────────────────────────────────────
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.045
        local pulse = (math.sin(t) + 1) / 2
        neonStroke.Transparency = 0.05 + pulse * 0.5
        task.wait(0.03)
    end
end)

-- ─── OPEN ANIMATION ────────────────────────────────────────────
Main.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(Main,
    TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size = UDim2.new(0, 262, 0, FULL_HEIGHT)}
):Play()
