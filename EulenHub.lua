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

-- ─── XRAY (Optimizer + XRay) ───────────────────────────────────
local unwalkEnabled        = false
local originalTransparency = {}
local unwalkDescConn       = nil
local unwalkCharConn       = nil

local function startUnwalk()
    -- Optimizer
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
    -- Character Clean
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
    -- XRay: bases semitransparentes
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

-- ─── NOCLIP (Semi-Invisible) LOGIC ────────────────────────────
local noclipConnections = {}
local isInvisible       = false
local noclipClone, oldRoot, hip, animTrack, noclipConn, noclipCharConn

local function removeFolders()
    local playerName = player.Name
    local playerFolder = workspace:FindFirstChild(playerName)
    if not playerFolder then return end
    local doubleRig = playerFolder:FindFirstChild("DoubleRig")
    if doubleRig then doubleRig:Destroy() end
    local constraints = playerFolder:FindFirstChild("Constraints")
    if constraints then constraints:Destroy() end
    local c = playerFolder.ChildAdded:Connect(function(child)
        if child.Name == "DoubleRig" or child.Name == "Constraints" then child:Destroy() end
    end)
    table.insert(noclipConnections, c)
end

local function doClone()
    if not (character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0) then return false end
    hip     = character.Humanoid.HipHeight
    oldRoot = character:FindFirstChild("HumanoidRootPart")
    if not oldRoot or not oldRoot.Parent then return false end
    local tmp = Instance.new("Model"); tmp.Parent = game
    character.Parent = tmp
    noclipClone = oldRoot:Clone()
    noclipClone.Parent = character
    oldRoot.Parent = workspace.CurrentCamera
    noclipClone.CFrame = oldRoot.CFrame
    character.PrimaryPart = noclipClone
    character.Parent = workspace
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("Weld") or v:IsA("Motor6D") then
            if v.Part0 == oldRoot then v.Part0 = noclipClone end
            if v.Part1 == oldRoot then v.Part1 = noclipClone end
        end
    end
    tmp:Destroy()
    return true
end

local function revertClone()
    if not oldRoot or not oldRoot:IsDescendantOf(workspace) or not character or character.Humanoid.Health <= 0 then return end
    local tmp = Instance.new("Model"); tmp.Parent = game
    character.Parent = tmp
    oldRoot.Parent = character
    character.PrimaryPart = oldRoot
    character.Parent = workspace
    oldRoot.CanCollide = true
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("Weld") or v:IsA("Motor6D") then
            if v.Part0 == noclipClone then v.Part0 = oldRoot end
            if v.Part1 == noclipClone then v.Part1 = oldRoot end
        end
    end
    if noclipClone then
        local pos = noclipClone.CFrame
        noclipClone:Destroy(); noclipClone = nil
        oldRoot.CFrame = pos
    end
    oldRoot = nil
    if character and character.Humanoid then character.Humanoid.HipHeight = hip end
    tmp:Destroy()
end

local function animationTrickery()
    if not (character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0) then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
    local hum      = character.Humanoid
    local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)
    animTrack = animator:LoadAnimation(anim)
    animTrack.Priority = Enum.AnimationPriority.Action4
    animTrack:Play(0, 1, 0)
    anim:Destroy()
    local c = animTrack.Stopped:Connect(function()
        if isInvisible then animationTrickery() end
    end)
    table.insert(noclipConnections, c)
    task.delay(0, function()
        animTrack.TimePosition = 0.7
        task.delay(1, function() animTrack:AdjustSpeed(math.huge) end)
    end)
end

local function enableNoclip()
    if not character or character.Humanoid.Health <= 0 then return false end
    removeFolders()
    if not doClone() then return false end
    task.wait(0.1)
    animationTrickery()
    noclipConn = RunService.PreSimulation:Connect(function()
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 and oldRoot then
            local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
            if root then
                local cf = root.CFrame - Vector3.new(0, character.Humanoid.HipHeight + (root.Size.Y/2) - 1 + 0.09, 0)
                oldRoot.CFrame    = cf * CFrame.Angles(math.rad(180), 0, 0)
                oldRoot.Velocity  = root.Velocity
                oldRoot.CanCollide = false
            end
        end
    end)
    table.insert(noclipConnections, noclipConn)
    noclipCharConn = player.CharacterAdded:Connect(function()
        if isInvisible then
            if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
            if noclipConn then noclipConn:Disconnect() end
            revertClone(); removeFolders()
            isInvisible = false
            for _, c in ipairs(noclipConnections) do if c then c:Disconnect() end end
            noclipConnections = {}
        end
    end)
    table.insert(noclipConnections, noclipCharConn)
    return true
end

local function disableNoclip()
    if animTrack then animTrack:Stop(); animTrack:Destroy(); animTrack = nil end
    if noclipConn then noclipConn:Disconnect() end
    if noclipCharConn then noclipCharConn:Disconnect() end
    revertClone(); removeFolders()
    for _, c in ipairs(noclipConnections) do if c then c:Disconnect() end end
    noclipConnections = {}
end
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

-- ─── GUI ───────────────────────────────────────────────────────
if CoreGui:FindFirstChild("KMoneyHub") then
    CoreGui:FindFirstChild("KMoneyHub"):Destroy()
end

local CYAN     = Color3.fromRGB(0, 230, 255)
local CYAN_DIM = Color3.fromRGB(0, 160, 200)
local BG       = Color3.fromRGB(2, 2, 4)
local CARD     = Color3.fromRGB(4, 7, 12)
local FULL_HEIGHT = 356

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KMoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
pcall(function() ScreenGui.Parent = CoreGui end)

local Main = Instance.new("Frame", ScreenGui)
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 262, 0, FULL_HEIGHT)
Main.Position         = UDim2.new(0.5, -131, 0.5, -150)
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

local Content = Instance.new("Frame", Main)
Content.Size                   = UDim2.new(1, 0, 1, -47)
Content.Position               = UDim2.new(0, 0, 0, 47)
Content.BackgroundTransparency = 1

local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeToggleRow(labelText, yOffset)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, -28, 0, 44)
    Row.Position         = UDim2.new(0, 14, 0, yOffset)
    Row.BackgroundColor3 = CARD
    Row.BorderSizePixel  = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Size = UDim2.new(1,-60,1,0); Lbl.Position = UDim2.new(0,12,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = labelText
    Lbl.TextColor3 = Color3.fromRGB(180,235,255); Lbl.TextStrokeColor3 = CYAN
    Lbl.TextStrokeTransparency = 0.7; Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 14; Lbl.TextXAlignment = Enum.TextXAlignment.Left
    local Btn = Instance.new("TextButton", Row)
    Btn.Size = UDim2.new(0,46,0,24); Btn.Position = UDim2.new(1,-54,0.5,-12)
    Btn.BackgroundColor3 = Color3.fromRGB(10,20,32); Btn.Text = ""; Btn.BorderSizePixel = 0
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1,0)
    local bStroke = Instance.new("UIStroke", Btn)
    bStroke.Color = CYAN_DIM; bStroke.Thickness = 1; bStroke.Transparency = 0.5
    local Knob = Instance.new("Frame", Btn)
    Knob.Size = UDim2.new(0,18,0,18); Knob.Position = UDim2.new(0,3,0.5,-9)
    Knob.BackgroundColor3 = Color3.fromRGB(50,80,100); Knob.BorderSizePixel = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    return Btn, Knob, bStroke
end

local function applyOn(b,k,s)
    b.BackgroundColor3=CYAN; k.Position=UDim2.new(1,-21,0.5,-9)
    k.BackgroundColor3=Color3.fromRGB(255,255,255); s.Color=CYAN; s.Transparency=0
end

local function applyOff(b,k,s)
    b.BackgroundColor3=Color3.fromRGB(10,20,32); k.Position=UDim2.new(0,3,0.5,-9)
    k.BackgroundColor3=Color3.fromRGB(50,80,100); s.Color=CYAN_DIM; s.Transparency=0.5
end

-- ROW 1: Auto Steal
local T1,K1,S1 = makeToggleRow("Auto Steal", 12)
if savedCfg.AutoSteal then stealEnabled=true; startAutoSteal(); applyOn(T1,K1,S1) end
T1.MouseButton1Click:Connect(function()
    stealEnabled = not stealEnabled
    if stealEnabled then startAutoSteal(); TweenService:Create(T1,ti,{BackgroundColor3=CYAN}):Play(); TweenService:Create(K1,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play(); S1.Color=CYAN; S1.Transparency=0
    else stopAutoSteal(); TweenService:Create(T1,ti,{BackgroundColor3=Color3.fromRGB(10,20,32)}):Play(); TweenService:Create(K1,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,80,100)}):Play(); S1.Color=CYAN_DIM; S1.Transparency=0.5 end
end)

-- ROW 2: Anti Ragdoll
local T2,K2,S2 = makeToggleRow("Anti Ragdoll", 68)
if savedCfg.AntiRagdoll then antiRagdollEnabled=true; task.delay(1,function() setupAntiRagdoll(character) end); applyOn(T2,K2,S2) end
T2.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then task.wait(0.5); setupAntiRagdoll(character); TweenService:Create(T2,ti,{BackgroundColor3=CYAN}):Play(); TweenService:Create(K2,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play(); S2.Color=CYAN; S2.Transparency=0
    else cleanupRagdoll(); disconnectRemote(); TweenService:Create(T2,ti,{BackgroundColor3=Color3.fromRGB(10,20,32)}):Play(); TweenService:Create(K2,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,80,100)}):Play(); S2.Color=CYAN_DIM; S2.Transparency=0.5 end
end)

-- ROW 3: XRAY
local T3,K3,S3 = makeToggleRow("XRAY", 124)
if savedCfg.XRAY then unwalkEnabled=true; startUnwalk(); applyOn(T3,K3,S3) end
T3.MouseButton1Click:Connect(function()
    unwalkEnabled = not unwalkEnabled
    if unwalkEnabled then startUnwalk(); TweenService:Create(T3,ti,{BackgroundColor3=CYAN}):Play(); TweenService:Create(K3,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play(); S3.Color=CYAN; S3.Transparency=0
    else stopUnwalk(); TweenService:Create(T3,ti,{BackgroundColor3=Color3.fromRGB(10,20,32)}):Play(); TweenService:Create(K3,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,80,100)}):Play(); S3.Color=CYAN_DIM; S3.Transparency=0.5 end
end)

-- ROW 4: Noclip
local T4,K4,S4 = makeToggleRow("Noclip", 180)
T4.MouseButton1Click:Connect(function()
    isInvisible = not isInvisible
    if isInvisible then
        removeFolders()
        if enableNoclip() then
            TweenService:Create(T4,ti,{BackgroundColor3=CYAN}):Play(); TweenService:Create(K4,ti,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play(); S4.Color=CYAN; S4.Transparency=0
        else
            isInvisible = false
        end
    else
        disableNoclip()
        TweenService:Create(T4,ti,{BackgroundColor3=Color3.fromRGB(10,20,32)}):Play(); TweenService:Create(K4,ti,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=Color3.fromRGB(50,80,100)}):Play(); S4.Color=CYAN_DIM; S4.Transparency=0.5
    end
end)

-- ─── SAVE BUTTON ───────────────────────────────────────────────
local SaveFrame = Instance.new("Frame", Content)
SaveFrame.Size                   = UDim2.new(1, -28, 0, 40)
SaveFrame.Position               = UDim2.new(0, 14, 0, 248)
SaveFrame.BackgroundTransparency = 1
SaveFrame.BorderSizePixel        = 0

local SaveBtn = Instance.new("TextButton", SaveFrame)
SaveBtn.Size             = UDim2.new(1, 0, 1, 0)
SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
SaveBtn.Text             = "SAVE CONFIG"
SaveBtn.Font             = Enum.Font.GothamBlack
SaveBtn.TextSize         = 14
SaveBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
SaveBtn.BorderSizePixel  = 0
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 10)

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    SaveBtn.Text = "✅ SAVED!"
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

-- ─── $ MINIMIZAR / RESTAURAR ───────────────────────────────────
local minimized = false
DollarBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = minimized and UDim2.new(0,262,0,48) or UDim2.new(0,262,0,FULL_HEIGHT)
    }):Play()
end)

-- ─── NEON PULSE ────────────────────────────────────────────────
task.spawn(function()
    local t = 0
    while ScreenGui.Parent do
        t = t + 0.045
        neonStroke.Transparency = 0.05 + ((math.sin(t)+1)/2)*0.5
        task.wait(0.03)
    end
end)

-- ─── OPEN ANIMATION ────────────────────────────────────────────
Main.Size = UDim2.new(0,0,0,0)
TweenService:Create(Main, TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(0,262,0,FULL_HEIGHT)}):Play()
