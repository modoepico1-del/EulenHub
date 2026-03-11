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

-- ─── COLORES GRIM REAPER ───────────────────────────────────────
local BLACK      = Color3.fromRGB(4, 4, 4)
local DARKGRAY   = Color3.fromRGB(12, 12, 14)
local CARD       = Color3.fromRGB(10, 10, 12)
local CARD2      = Color3.fromRGB(16, 16, 18)
local GHOST      = Color3.fromRGB(220, 220, 230)
local GHOSTDIM   = Color3.fromRGB(140, 140, 155)
local RED        = Color3.fromRGB(180, 20, 20)
local REDDIM     = Color3.fromRGB(100, 10, 10)
local FULL_HEIGHT = 315

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
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 270, 0, FULL_HEIGHT)
Main.Position         = UDim2.new(0.5, -135, 0.5, -157)
Main.BackgroundColor3 = BLACK
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Outer stroke - blood red
local grimStroke = Instance.new("UIStroke", Main)
grimStroke.Color     = RED
grimStroke.Thickness = 1.5

-- Skull decorations (floating in background)
local SKULLS = {"💀", "💀", "💀", "💀", "💀"}
for i, sk in ipairs(SKULLS) do
    local skLbl = Instance.new("TextLabel", Main)
    skLbl.Size                   = UDim2.new(0, 20, 0, 20)
    skLbl.Position               = UDim2.new(math.random(5,88)/100, 0, math.random(5,88)/100, 0)
    skLbl.BackgroundTransparency = 1
    skLbl.Text                   = sk
    skLbl.TextSize               = math.random(10,14)
    skLbl.Font                   = Enum.Font.GothamBold
    skLbl.TextTransparency       = 0.75
    skLbl.ZIndex                 = 1
    -- Float animation
    task.spawn(function()
        task.wait(math.random(0,20)/10)
        while ScreenGui.Parent do
            TweenService:Create(skLbl, TweenInfo.new(2+math.random(0,10)/5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                TextTransparency = 0.4,
                Position = UDim2.new(skLbl.Position.X.Scale, 0, skLbl.Position.Y.Scale - 0.04, 0)
            }):Play()
            task.wait(4)
        end
    end)
end

-- Top blood line
local TopLine = Instance.new("Frame", Main)
TopLine.Size             = UDim2.new(1, 0, 0, 2)
TopLine.BackgroundColor3 = RED
TopLine.BorderSizePixel  = 0
Instance.new("UIGradient", TopLine).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,20,20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40,0,0)),
})

-- Title bar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size             = UDim2.new(1, 0, 0, 48)
TitleBar.Position         = UDim2.new(0, 0, 0, 2)
TitleBar.BackgroundColor3 = DARKGRAY
TitleBar.BorderSizePixel  = 0
Instance.new("UIGradient", TitleBar).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(16,14,14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(6,6,6)),
})

-- Skull icon left
local SkullIcon = Instance.new("TextLabel", TitleBar)
SkullIcon.Size                   = UDim2.new(0, 28, 1, 0)
SkullIcon.Position               = UDim2.new(0, 8, 0, 0)
SkullIcon.BackgroundTransparency = 1
SkullIcon.Text                   = "💀"
SkullIcon.TextSize               = 16
SkullIcon.Font                   = Enum.Font.GothamBold

-- Title label
local TitleLbl = Instance.new("TextLabel", TitleBar)
TitleLbl.Size                   = UDim2.new(1, -80, 1, 0)
TitleLbl.Position               = UDim2.new(0, 40, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "KMONEY HUB"
TitleLbl.TextColor3             = GHOST
TitleLbl.TextStrokeColor3       = RED
TitleLbl.TextStrokeTransparency = 0.2
TitleLbl.Font                   = Enum.Font.GothamBlack
TitleLbl.TextSize               = 16
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Minimize button
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size                   = UDim2.new(0, 26, 0, 26)
MinBtn.Position               = UDim2.new(1, -36, 0.5, -13)
MinBtn.BackgroundColor3       = CARD
MinBtn.Text                   = "—"
MinBtn.TextColor3             = GHOSTDIM
MinBtn.Font                   = Enum.Font.GothamBold
MinBtn.TextSize               = 13
MinBtn.BorderSizePixel        = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local minStroke = Instance.new("UIStroke", MinBtn)
minStroke.Color = REDDIM; minStroke.Thickness = 1; minStroke.Transparency = 0.4

-- Content
local Content = Instance.new("Frame", Main)
Content.Size                   = UDim2.new(1, 0, 1, -52)
Content.Position               = UDim2.new(0, 0, 0, 52)
Content.BackgroundTransparency = 1

local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad)

-- ─── TOGGLE ROW HELPER ─────────────────────────────────────────
local function makeToggleRow(labelText, yOffset)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, -24, 0, 46)
    Row.Position         = UDim2.new(0, 12, 0, yOffset)
    Row.BackgroundColor3 = CARD
    Row.BorderSizePixel  = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    Instance.new("UIGradient", Row).Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(16,14,14)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,8)),
    })

    local rowStroke = Instance.new("UIStroke", Row)
    rowStroke.Color = REDDIM; rowStroke.Thickness = 1; rowStroke.Transparency = 0.6

    -- Skull left of label
    local SkLbl = Instance.new("TextLabel", Row)
    SkLbl.Size = UDim2.new(0,22,1,0); SkLbl.Position = UDim2.new(0,10,0,0)
    SkLbl.BackgroundTransparency = 1; SkLbl.Text = "💀"
    SkLbl.TextSize = 12; SkLbl.Font = Enum.Font.GothamBold
    SkLbl.TextTransparency = 0.3

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1,-70,1,0); Lbl.Position = UDim2.new(0,36,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = labelText
    Lbl.TextColor3 = GHOST; Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 13; Lbl.TextXAlignment = Enum.TextXAlignment.Left

    local Btn = Instance.new("TextButton", Row)
    Btn.Size = UDim2.new(0,46,0,24); Btn.Position = UDim2.new(1,-56,0.5,-12)
    Btn.BackgroundColor3 = Color3.fromRGB(8,8,10); Btn.Text = ""; Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1,0)
    local bStroke = Instance.new("UIStroke", Btn)
    bStroke.Color = REDDIM; bStroke.Thickness = 1; bStroke.Transparency = 0.5

    local Knob = Instance.new("Frame", Btn)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,3,0.5,-9)
    Knob.BackgroundColor3 = Color3.fromRGB(50,50,55); Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    return Btn, Knob, bStroke, rowStroke
end

local function applyOn(b,k,s,rs)
    b.BackgroundColor3 = RED
    k.Position         = UDim2.new(1,-21,0.5,-9)
    k.BackgroundColor3 = GHOST
    s.Color = RED; s.Transparency = 0
    rs.Color = RED; rs.Transparency = 0.2
end

local function applyOff(b,k,s,rs)
    b.BackgroundColor3 = Color3.fromRGB(8,8,10)
    k.Position         = UDim2.new(0,3,0.5,-9)
    k.BackgroundColor3 = Color3.fromRGB(50,50,55)
    s.Color = REDDIM; s.Transparency = 0.5
    rs.Color = REDDIM; rs.Transparency = 0.6
end

-- ROW 1: Auto Steal
local T1,K1,S1,RS1 = makeToggleRow("Auto Steal", 10)
if savedCfg.AutoSteal then stealEnabled=true; startAutoSteal(); applyOn(T1,K1,S1,RS1) end
T1.MouseButton1Click:Connect(function()
    stealEnabled = not stealEnabled
    if stealEnabled then
        startAutoSteal()
        TweenService:Create(T1,ti,{BackgroundColor3=RED}):Play()
        TweenService:Create(K1,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=GHOST}):Play()
        S1.Color=RED; S1.Transparency=0; RS1.Color=RED; RS1.Transparency=0.2
    else
        stopAutoSteal()
        TweenService:Create(T1,ti,{BackgroundColor3=Color3.fromRGB(8,8,10)}):Play()
        TweenService:Create(K1,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,50,55)}):Play()
        S1.Color=REDDIM; S1.Transparency=0.5; RS1.Color=REDDIM; RS1.Transparency=0.6
    end
end)

-- ROW 2: Anti Ragdoll
local T2,K2,S2,RS2 = makeToggleRow("Anti Ragdoll", 66)
if savedCfg.AntiRagdoll then antiRagdollEnabled=true; task.delay(1,function() setupAntiRagdoll(character) end); applyOn(T2,K2,S2,RS2) end
T2.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        task.wait(0.5); setupAntiRagdoll(character)
        TweenService:Create(T2,ti,{BackgroundColor3=RED}):Play()
        TweenService:Create(K2,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=GHOST}):Play()
        S2.Color=RED; S2.Transparency=0; RS2.Color=RED; RS2.Transparency=0.2
    else
        cleanupRagdoll(); disconnectRemote()
        TweenService:Create(T2,ti,{BackgroundColor3=Color3.fromRGB(8,8,10)}):Play()
        TweenService:Create(K2,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,50,55)}):Play()
        S2.Color=REDDIM; S2.Transparency=0.5; RS2.Color=REDDIM; RS2.Transparency=0.6
    end
end)

-- ROW 3: XRAY
local T3,K3,S3,RS3 = makeToggleRow("XRAY", 122)
if savedCfg.XRAY then unwalkEnabled=true; startUnwalk(); applyOn(T3,K3,S3,RS3) end
T3.MouseButton1Click:Connect(function()
    unwalkEnabled = not unwalkEnabled
    if unwalkEnabled then
        startUnwalk()
        TweenService:Create(T3,ti,{BackgroundColor3=RED}):Play()
        TweenService:Create(K3,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=GHOST}):Play()
        S3.Color=RED; S3.Transparency=0; RS3.Color=RED; RS3.Transparency=0.2
    else
        stopUnwalk()
        TweenService:Create(T3,ti,{BackgroundColor3=Color3.fromRGB(8,8,10)}):Play()
        TweenService:Create(K3,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,50,55)}):Play()
        S3.Color=REDDIM; S3.Transparency=0.5; RS3.Color=REDDIM; RS3.Transparency=0.6
    end
end)

-- ─── SEPARATOR ─────────────────────────────────────────────────
local Sep = Instance.new("Frame", Content)
Sep.Size             = UDim2.new(1, -24, 0, 1)
Sep.Position         = UDim2.new(0, 12, 0, 188)
Sep.BackgroundColor3 = RED
Sep.BorderSizePixel  = 0
Sep.BackgroundTransparency = 0.5
Instance.new("UIGradient", Sep).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180,20,20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
})

-- ─── SAVE BUTTON ───────────────────────────────────────────────
local SaveFrame = Instance.new("Frame", Content)
SaveFrame.Size                   = UDim2.new(1, -24, 0, 40)
SaveFrame.Position               = UDim2.new(0, 12, 0, 200)
SaveFrame.BackgroundTransparency = 1

local SaveBtn = Instance.new("TextButton", SaveFrame)
SaveBtn.Size             = UDim2.new(1, 0, 1, 0)
SaveBtn.BackgroundColor3 = REDDIM
SaveBtn.Text             = "💀  SAVE CONFIG  💀"
SaveBtn.Font             = Enum.Font.GothamBlack
SaveBtn.TextSize         = 13
SaveBtn.TextColor3       = GHOST
SaveBtn.BorderSizePixel  = 0
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIGradient", SaveBtn).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80,8,8)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160,16,16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80,8,8)),
})

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    SaveBtn.Text = "💀  SAVED!  💀"
    task.wait(1)
    SaveBtn.Text = "💀  SAVE CONFIG  💀"
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

-- ─── GRIM PULSE (rojo sangriento pulsando) ─────────────────────
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.04
        local pulse = (math.sin(t) + 1) / 2
        grimStroke.Transparency = 0.05 + pulse * 0.65
        grimStroke.Color = Color3.fromRGB(
            120 + math.floor(pulse * 80),
            10 + math.floor(pulse * 10),
            10
        )
        -- Title flicker
        TitleLbl.TextStrokeTransparency = 0.1 + pulse * 0.5
        TitleLbl.TextColor3 = Color3.fromRGB(
            200 + math.floor(pulse * 20),
            200 + math.floor(pulse * 20),
            210 + math.floor(pulse * 20)
        )
        task.wait(0.03)
    end
end)


-- ─── GUADAÑA (fuera del hub, a la izquierda) ──────────────────
local ScytheFrame = Instance.new("Frame", ScreenGui)
ScytheFrame.Name             = "Scythe"
ScytheFrame.Size             = UDim2.new(0, 80, 0, 320)
ScytheFrame.BackgroundTransparency = 1
ScytheFrame.BorderSizePixel  = 0
ScytheFrame.ZIndex           = 5

-- Mango (palo largo)
local Handle = Instance.new("Frame", ScytheFrame)
Handle.Size             = UDim2.new(0, 8, 0, 260)
Handle.Position         = UDim2.new(0, 38, 0, 55)
Handle.BackgroundColor3 = Color3.fromRGB(60, 35, 15)
Handle.BorderSizePixel  = 0
Instance.new("UICorner", Handle).CornerRadius = UDim.new(0, 4)
Instance.new("UIGradient", Handle).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(55, 32, 12)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 20, 8)),
})

-- Vendas del mango
for i, yp in ipairs({0.2, 0.35, 0.55, 0.72, 0.88}) do
    local wr = Instance.new("Frame", Handle)
    wr.Size             = UDim2.new(1, 4, 0, 5)
    wr.Position         = UDim2.new(-0.25, 0, yp, 0)
    wr.BackgroundColor3 = Color3.fromRGB(120, 90, 20)
    wr.BorderSizePixel  = 0
    Instance.new("UICorner", wr).CornerRadius = UDim.new(0, 2)
end

-- Punta inferior
local BottomCap = Instance.new("Frame", ScytheFrame)
BottomCap.Size             = UDim2.new(0, 12, 0, 10)
BottomCap.Position         = UDim2.new(0, 36, 0, 308)
BottomCap.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
BottomCap.BorderSizePixel  = 0
Instance.new("UICorner", BottomCap).CornerRadius = UDim.new(0, 4)

-- Hoja de la guadana
local BladeBack = Instance.new("Frame", ScytheFrame)
BladeBack.Size             = UDim2.new(0, 70, 0, 75)
BladeBack.Position         = UDim2.new(0, 0, 0, 0)
BladeBack.BackgroundColor3 = Color3.fromRGB(190, 190, 205)
BladeBack.BorderSizePixel  = 0
BladeBack.Rotation         = 15
Instance.new("UICorner", BladeBack).CornerRadius = UDim.new(0.5, 0)
Instance.new("UIGradient", BladeBack).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 235)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 250, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 90, 100)),
})

local BladeSharp = Instance.new("Frame", ScytheFrame)
BladeSharp.Size             = UDim2.new(0, 55, 0, 55)
BladeSharp.Position         = UDim2.new(0, 5, 0, 10)
BladeSharp.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
BladeSharp.BorderSizePixel  = 0
BladeSharp.Rotation         = 15
Instance.new("UICorner", BladeSharp).CornerRadius = UDim.new(0.6, 0)

-- Brillo hoja
local BladeShine = Instance.new("Frame", ScytheFrame)
BladeShine.Size             = UDim2.new(0, 5, 0, 40)
BladeShine.Position         = UDim2.new(0, 10, 0, 8)
BladeShine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BladeShine.BorderSizePixel  = 0
BladeShine.Rotation         = 30
BladeShine.BackgroundTransparency = 0.4
Instance.new("UICorner", BladeShine).CornerRadius = UDim.new(1, 0)

-- Skull encima del mango
local SkullTop = Instance.new("TextLabel", ScytheFrame)
SkullTop.Size                   = UDim2.new(0, 28, 0, 28)
SkullTop.Position               = UDim2.new(0, 27, 0, 43)
SkullTop.BackgroundTransparency = 1
SkullTop.Text                   = "💀"
SkullTop.TextSize               = 20
SkullTop.Font                   = Enum.Font.GothamBold
SkullTop.ZIndex                 = 6

-- Gotas de sangre
for i, pos in ipairs({{8,38},{18,28},{28,18}}) do
    local drop = Instance.new("Frame", ScytheFrame)
    drop.Size             = UDim2.new(0, 5, 0, 8)
    drop.Position         = UDim2.new(0, pos[1], 0, pos[2])
    drop.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    drop.BorderSizePixel  = 0
    Instance.new("UICorner", drop).CornerRadius = UDim.new(1, 0)
end

-- Posicionar guadana relativa al Main y animar flotacion
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.035
        local wave = math.sin(t) * 8
        ScytheFrame.Position = UDim2.new(
            Main.Position.X.Scale,
            Main.Position.X.Offset - 90,
            Main.Position.Y.Scale,
            Main.Position.Y.Offset - 30 + wave
        )
        BladeBack.BackgroundTransparency = 0.05 + math.abs(math.sin(t)) * 0.15
        task.wait(0.03)
    end
end)

-- ─── LLUVIA DE CALAVERAS EN SAVE BUTTON ────────────────────────
for i = 1, 12 do
    local drop = Instance.new("TextLabel", SaveFrame)
    drop.Size                   = UDim2.new(0, 16, 0, 16)
    drop.BackgroundTransparency = 1
    drop.Text                   = "💀"
    drop.TextSize               = 11
    drop.Font                   = Enum.Font.GothamBold
    drop.TextTransparency       = 1
    drop.ZIndex                 = 5
    task.spawn(function()
        task.wait(math.random(0,30)/10)
        while ScreenGui.Parent do
            local xp = math.random(5,90)/100
            drop.Position = UDim2.new(xp, 0, 0, -16)
            drop.TextTransparency = 0.1
            TweenService:Create(drop, TweenInfo.new(0.9+math.random(0,5)/10, Enum.EasingStyle.Linear), {
                Position = UDim2.new(xp, 0, 1, 4),
                TextTransparency = 0.9
            }):Play()
            task.wait(1.2 + math.random(0,15)/10)
        end
    end)
end

-- ─── OPEN ANIMATION ────────────────────────────────────────────
Main.Size = UDim2.new(0,0,0,0)
TweenService:Create(Main, TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,270,0,FULL_HEIGHT)}):Play()
