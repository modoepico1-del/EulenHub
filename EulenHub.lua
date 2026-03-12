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

-- ─── DARK MODE ─────────────────────────────────────────────────
local darkModeEnabled  = false
local darkModeObjects  = {}
local originalLighting = {}

local function saveLightingState()
    originalLighting = {
        ClockTime                = Lighting.ClockTime,
        Ambient                  = Lighting.Ambient,
        Brightness               = Lighting.Brightness,
        EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        GlobalShadows            = Lighting.GlobalShadows,
        OutdoorAmbient           = Lighting.OutdoorAmbient,
        FogColor                 = Lighting.FogColor,
        FogEnd                   = Lighting.FogEnd,
        FogStart                 = Lighting.FogStart,
    }
end

local function startDarkMode()
    saveLightingState()
    darkModeObjects = {}

    -- Eliminar skies existentes
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            table.insert(darkModeObjects, {removed = true, instance = child, parent = Lighting})
            child.Parent = nil
        end
    end

    -- Solo sky negro, sin tocar nada mas del Lighting
    local sky = Instance.new("Sky")
    sky.Name                 = "BlackSky"
    sky.SkyboxBk             = "rbxassetid://2013298"
    sky.SkyboxDn             = "rbxassetid://2013298"
    sky.SkyboxFt             = "rbxassetid://2013298"
    sky.SkyboxLf             = "rbxassetid://2013298"
    sky.SkyboxRt             = "rbxassetid://2013298"
    sky.SkyboxUp             = "rbxassetid://2013298"
    sky.StarCount            = 0
    sky.CelestialBodiesShown = false
    sky.Parent               = Lighting
    table.insert(darkModeObjects, sky)

    -- Quitar niebla para que el juego se vea mas brilloso
    Lighting.FogStart = 10000
end

local function stopDarkMode()
    for _, obj in ipairs(darkModeObjects) do
        pcall(function()
            if obj.removed then
                obj.instance.Parent = obj.parent
            else
                obj:Destroy()
            end
        end)
    end
    darkModeObjects = {}
    pcall(function()
        Lighting.FogStart = originalLighting.FogStart or 0
    end)
end

-- ─── SAVE / LOAD ───────────────────────────────────────────────
local CONFIG_FILE = "KMoneyHub_config.json"

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            AutoSteal   = stealEnabled,
            AntiRagdoll = antiRagdollEnabled,
            XRAY        = unwalkEnabled,
            DarkMode    = darkModeEnabled,
        }))
    end)
end

local savedCfg = {}
pcall(function() savedCfg = HttpService:JSONDecode(readfile(CONFIG_FILE)) end)

-- ─── PALETA ────────────────────────────────────────────────────
local WHITE       = Color3.fromRGB(255, 255, 255)
local BLACK       = Color3.fromRGB(0, 0, 0)
local FULL_HEIGHT = 371

-- ─── GUI ───────────────────────────────────────────────────────
if CoreGui:FindFirstChild("KMoneyHub") then
    CoreGui:FindFirstChild("KMoneyHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KMoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function() ScreenGui.Parent = CoreGui end)

local Main = Instance.new("Frame", ScreenGui)
Main.Name                   = "Main"
Main.Size                   = UDim2.new(0, 270, 0, FULL_HEIGHT)
Main.Position               = UDim2.new(0.5, -135, 0.5, -185)
Main.BackgroundTransparency = 1
Main.BorderSizePixel        = 0
Main.ClipsDescendants       = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local grimStroke = Instance.new("UIStroke", Main)
grimStroke.Color        = BLACK
grimStroke.Thickness    = 2
grimStroke.Transparency = 0

local TopLine = Instance.new("Frame", Main)
TopLine.Size             = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = BLACK
TopLine.BorderSizePixel  = 0

local TitleBar = Instance.new("Frame", Main)
TitleBar.Size               = UDim2.new(1, 0, 0, 48)
TitleBar.Position           = UDim2.new(0, 0, 0, 2)
TitleBar.BackgroundTransparency = 1
TitleBar.BorderSizePixel    = 0

local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size                   = UDim2.new(1, -46, 1, 0)
TitleLbl.Position               = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "KMONEY HUB"
TitleLbl.TextColor3             = WHITE
TitleLbl.TextStrokeColor3       = BLACK
TitleLbl.TextStrokeTransparency = 0
TitleLbl.Font                   = Enum.Font.GothamBlack
TitleLbl.TextSize               = 16
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size               = UDim2.new(0, 26, 0, 26)
MinBtn.Position           = UDim2.new(1, -36, 0.5, -13)
MinBtn.BackgroundTransparency = 1
MinBtn.Text               = "—"
MinBtn.TextColor3         = WHITE
MinBtn.Font               = Enum.Font.GothamBold
MinBtn.TextSize           = 13
MinBtn.BorderSizePixel    = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local minStroke = Instance.new("UIStroke", MinBtn)
minStroke.Color = BLACK; minStroke.Thickness = 1.5; minStroke.Transparency = 0

local Content = Instance.new("Frame", Main)
Content.Size                 = UDim2.new(1, 0, 1, -52)
Content.Position             = UDim2.new(0, 0, 0, 52)
Content.BackgroundTransparency = 1

local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

-- ─── TOGGLE ROW HELPER ─────────────────────────────────────────
local function makeToggleRow(labelText, yOffset)
    local Row = Instance.new("Frame", Content)
    Row.Size                 = UDim2.new(1, -24, 0, 46)
    Row.Position             = UDim2.new(0, 12, 0, yOffset)
    Row.BackgroundTransparency = 1
    Row.BorderSizePixel      = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local rowStroke = Instance.new("UIStroke", Row)
    rowStroke.Color = BLACK; rowStroke.Thickness = 1.5; rowStroke.Transparency = 0

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1,-70,1,0); Lbl.Position = UDim2.new(0,14,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = labelText
    Lbl.TextColor3 = WHITE
    Lbl.TextStrokeColor3 = BLACK; Lbl.TextStrokeTransparency = 0
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Row)
    Btn.Size = UDim2.new(0,46,0,24); Btn.Position = UDim2.new(1,-56,0.5,-12)
    Btn.BackgroundTransparency = 1; Btn.Text = ""; Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1,0)
    local bStroke = Instance.new("UIStroke", Btn)
    bStroke.Color = BLACK; bStroke.Thickness = 1.5; bStroke.Transparency = 0

    local Knob = Instance.new("Frame", Btn)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,3,0.5,-9)
    Knob.BackgroundColor3 = WHITE; Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    local kStroke = Instance.new("UIStroke", Knob)
    kStroke.Color = BLACK; kStroke.Thickness = 1; kStroke.Transparency = 0

    return Btn, Knob, bStroke, rowStroke
end

local function applyOn(b,k,s,rs)
    k.Position         = UDim2.new(1,-21,0.5,-9)
    k.BackgroundColor3 = BLACK
end

local function applyOff(b,k,s,rs)
    k.Position         = UDim2.new(0,3,0.5,-9)
    k.BackgroundColor3 = WHITE
end

-- ROW 1: Auto Steal
local T1,K1,S1,RS1 = makeToggleRow("Auto Steal", 10)
if savedCfg.AutoSteal then stealEnabled=true; startAutoSteal(); applyOn(T1,K1,S1,RS1) end
T1.MouseButton1Click:Connect(function()
    stealEnabled = not stealEnabled
    if stealEnabled then
        startAutoSteal()
        TweenService:Create(K1,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=BLACK}):Play()
    else
        stopAutoSteal()
        TweenService:Create(K1,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=WHITE}):Play()
    end
end)

-- ROW 2: Anti Ragdoll
local T2,K2,S2,RS2 = makeToggleRow("Anti Ragdoll", 66)
if savedCfg.AntiRagdoll then antiRagdollEnabled=true; task.delay(1,function() setupAntiRagdoll(character) end); applyOn(T2,K2,S2,RS2) end
T2.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        task.wait(0.5); setupAntiRagdoll(character)
        TweenService:Create(K2,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=BLACK}):Play()
    else
        cleanupRagdoll(); disconnectRemote()
        TweenService:Create(K2,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=WHITE}):Play()
    end
end)

-- ROW 3: XRAY
local T3,K3,S3,RS3 = makeToggleRow("XRAY", 122)
if savedCfg.XRAY then unwalkEnabled=true; startUnwalk(); applyOn(T3,K3,S3,RS3) end
T3.MouseButton1Click:Connect(function()
    unwalkEnabled = not unwalkEnabled
    if unwalkEnabled then
        startUnwalk()
        TweenService:Create(K3,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=BLACK}):Play()
    else
        stopUnwalk()
        TweenService:Create(K3,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=WHITE}):Play()
    end
end)

-- ROW 4: Dark Mode
local T4,K4,S4,RS4 = makeToggleRow("Dark Mode", 178)
if savedCfg.DarkMode then darkModeEnabled=true; startDarkMode(); applyOn(T4,K4,S4,RS4) end
T4.MouseButton1Click:Connect(function()
    darkModeEnabled = not darkModeEnabled
    if darkModeEnabled then
        startDarkMode()
        TweenService:Create(K4,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=BLACK}):Play()
    else
        stopDarkMode()
        TweenService:Create(K4,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=WHITE}):Play()
    end
end)

-- ─── SEPARATOR ─────────────────────────────────────────────────
local Sep = Instance.new("Frame", Content)
Sep.Size             = UDim2.new(1, -24, 0, 1)
Sep.Position         = UDim2.new(0, 12, 0, 244)
Sep.BackgroundColor3 = WHITE
Sep.BorderSizePixel  = 0

-- ─── SAVE BUTTON ───────────────────────────────────────────────
local SaveFrame = Instance.new("Frame", Content)
SaveFrame.Size               = UDim2.new(1, -24, 0, 40)
SaveFrame.Position           = UDim2.new(0, 12, 0, 256)
SaveFrame.BackgroundTransparency = 1

local SaveBtn = Instance.new("TextButton", SaveFrame)
SaveBtn.Size               = UDim2.new(1, 0, 1, 0)
SaveBtn.BackgroundTransparency = 1
SaveBtn.Text               = "SAVE CONFIG"
SaveBtn.Font               = Enum.Font.GothamBlack
SaveBtn.TextSize           = 13
SaveBtn.TextColor3         = WHITE
SaveBtn.TextStrokeColor3   = BLACK
SaveBtn.TextStrokeTransparency = 0
SaveBtn.BorderSizePixel    = 0
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)
local saveStroke = Instance.new("UIStroke", SaveBtn)
saveStroke.Color = BLACK; saveStroke.Thickness = 1.5; saveStroke.Transparency = 0

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    SaveBtn.Text = "SAVED!"
    task.wait(1)
    SaveBtn.Text = "SAVE CONFIG"
end)

-- ─── DRAGGABLE ─────────────────────────────────────────────────
do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=inp.Position; startPos=Main.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
end

-- ─── MINIMIZAR ─────────────────────────────────────────────────
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinBtn.Text = minimized and "+" or "—"
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0,270,0,52) or UDim2.new(0,270,0,FULL_HEIGHT)
    }):Play()
end)

-- ─── NEON PULSE ────────────────────────────────────────────────
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.04
        local pulse = (math.sin(t) + 1) / 2
        grimStroke.Transparency = 0.05 + pulse * 0.5
        task.wait(0.03)
    end
end)

-- ─── OPEN ANIMATION ────────────────────────────────────────────
Main.Size = UDim2.new(0,0,0,0)
TweenService:Create(Main, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,270,0,FULL_HEIGHT)}):Play()
