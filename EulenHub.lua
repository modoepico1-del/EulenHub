-- KMONEY HUB - 500x420

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")
local me               = LocalPlayer

local CONFIG_FILE = "kmoney_config.json"

-- ══════════════════════════════════════════
-- OPTIMIZER / DARK MODE
-- ══════════════════════════════════════════
local xrayEnabled          = false
local originalTransparency = {}

local function enableOptimizer()
    if getgenv and getgenv().NEBULA_OPT_ACTIVE then return end
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        for _, fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled = false end end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false; obj.Material = Enum.Material.Plastic
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then child:Destroy() end
                    end
                elseif obj:IsA("Sky") then obj:Destroy() end
            end)
        end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.88
            end
        end
    end)
end

local function disableOptimizer()
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = false end
    if xrayEnabled then
        for part, value in pairs(originalTransparency) do if part then part.LocalTransparencyModifier = value end end
        originalTransparency = {}; xrayEnabled = false
    end
end

local darkCC = nil
local function enableDarkMode()
    if darkCC and darkCC.Parent then return end
    darkCC = Instance.new("ColorCorrectionEffect")
    darkCC.Name = "NebulaDarkMode"; darkCC.Brightness = -0.25; darkCC.Contrast = 0.1
    darkCC.Saturation = -0.1; darkCC.Enabled = true; darkCC.Parent = Lighting
end
local function disableDarkMode()
    if darkCC then darkCC:Destroy(); darkCC = nil end
end

-- ══════════════════════════════════════════
-- GALAXY SKY
-- ══════════════════════════════════════════
local originalSkybox, galaxySkyBright, galaxySkyBrightConn
local galaxyPlanets = {}
local galaxyBloom, galaxyGalaxyCC
local config = { GalaxySkyBright = false }

local function enableGalaxySkyBright()
    if galaxySkyBright then return end
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    galaxySkyBright = Instance.new("Sky")
    galaxySkyBright.SkyboxBk = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxDn = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxFt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxLf = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxRt = "rbxassetid://1534951537"
    galaxySkyBright.SkyboxUp = "rbxassetid://1534951537"
    galaxySkyBright.StarCount = 10000
    galaxySkyBright.CelestialBodiesShown = false
    galaxySkyBright.Parent = Lighting
    galaxyBloom = Instance.new("BloomEffect")
    galaxyBloom.Intensity = 1.5; galaxyBloom.Size = 40; galaxyBloom.Threshold = 0.8; galaxyBloom.Parent = Lighting
    galaxyGalaxyCC = Instance.new("ColorCorrectionEffect")
    galaxyGalaxyCC.Saturation = 0.8; galaxyGalaxyCC.Contrast = 0.3
    galaxyGalaxyCC.TintColor = Color3.fromRGB(200,150,255); galaxyGalaxyCC.Parent = Lighting
    Lighting.Ambient = Color3.fromRGB(120,60,180); Lighting.Brightness = 3; Lighting.ClockTime = 0
    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800+i*200,800+i*200,800+i*200)
        p.Anchored = true; p.CanCollide = false; p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(140+i*20,60+i*10,200+i*15)
        p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i*2)*(3000+i*500), 1500+i*300, math.sin(i*2)*(3000+i*500))
        p.Parent = workspace
        table.insert(galaxyPlanets, p)
    end
    galaxySkyBrightConn = RunService.Heartbeat:Connect(function()
        if not config.GalaxySkyBright then return end
        local t = tick()*0.5
        Lighting.Ambient = Color3.fromRGB(
            120+math.floor(math.sin(t)*60),
            50+math.floor(math.sin(t*0.8)*40),
            180+math.floor(math.sin(t*1.2)*50)
        )
        if galaxyBloom then galaxyBloom.Intensity = 1.2+math.sin(t*2)*0.4 end
    end)
end

local function disableGalaxySkyBright()
    if galaxySkyBrightConn then galaxySkyBrightConn:Disconnect(); galaxySkyBrightConn = nil end
    if galaxySkyBright then galaxySkyBright:Destroy(); galaxySkyBright = nil end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if galaxyBloom then galaxyBloom:Destroy(); galaxyBloom = nil end
    if galaxyGalaxyCC then galaxyGalaxyCC:Destroy(); galaxyGalaxyCC = nil end
    for _, obj in ipairs(galaxyPlanets) do if obj then obj:Destroy() end end
    galaxyPlanets = {}
    Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.Brightness = 2; Lighting.ClockTime = 14
end

-- ══════════════════════════════════════════
-- ANTI RAGDOLL
-- ══════════════════════════════════════════
local antiRagdollOn   = false
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData  = {}

local function cacheCharacterData()
    local char = me.Character; if not char then return false end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = {
        character        = char,
        humanoid         = hum,
        root             = root,
        originalWalkSpeed = hum.WalkSpeed,
        originalJumpPower = hum.JumpPower,
        isFrozen         = false,
    }
    return true
end

local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    if state == Enum.HumanoidStateType.Physics
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.FallingDown then return true end
    local endTime = me:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint")
        or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            pcall(function() descendant:Destroy() end)
        end
    end
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    local hum  = cachedCharData.humanoid
    local root = cachedCharData.root
    pcall(function() me:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.Running) end
    root.Anchored = false
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function antiRagdollLoop()
    while antiRagdollMode do
        task.wait()
        if isRagdolled() then
            removeRagdollConstraints()
            forceExitRagdoll()
        end
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid
        and cam.CameraSubject ~= cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end
end

local function toggleAntiRagdoll(enable)
    if enable then
        disconnectAllRagdoll()
        if not cacheCharacterData() then return end
        antiRagdollMode = "v1"
        local charConn = me.CharacterAdded:Connect(function()
            task.wait(0.5)
            if antiRagdollMode then cacheCharacterData() end
        end)
        table.insert(ragdollConnections, charConn)
        task.spawn(antiRagdollLoop)
    else
        antiRagdollMode = nil
        disconnectAllRagdoll()
        cachedCharData  = {}
    end
end

-- ══════════════════════════════════════════
-- INF JUMP STATE
-- ══════════════════════════════════════════
local infJumpOn = false

-- ══════════════════════════════════════════
-- SAVE CONFIG
-- ══════════════════════════════════════════
local darkOn           = false
local galaxyOn         = false
local antiRagdollSaved = false
local infJumpSaved     = false

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            DarkMode    = darkOn,
            Galaxy      = galaxyOn,
            AntiRagdoll = antiRagdollOn,
            InfJump     = infJumpOn,
        }))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.DarkMode    ~= nil then darkOn           = data.DarkMode    end
            if data.Galaxy      ~= nil then galaxyOn         = data.Galaxy      end
            if data.AntiRagdoll ~= nil then antiRagdollSaved = data.AntiRagdoll end
            if data.InfJump     ~= nil then infJumpSaved     = data.InfJump     end
        end
    end)
end

loadConfig()

-- ══════════════════════════════════════════
-- COLORES — paleta azul índigo de la imagen
-- ══════════════════════════════════════════
local NavyDark    = Color3.fromRGB(30,  35,  65)   -- fondo más oscuro
local IndigoDark  = Color3.fromRGB(45,  48,  90)   -- fondo medio
local IndigoMid   = Color3.fromRGB(75,  75, 130)   -- acento / header line
local SlatBlue    = Color3.fromRGB(95,  95, 115)   -- botón acento
local White       = Color3.fromRGB(255, 255, 255)
local KnobOff     = Color3.fromRGB(80,  85, 120)
local KnobOn      = Color3.fromRGB(120, 130, 200)  -- toggle encendido azul
local GalaxyKnobOn = Color3.fromRGB(130, 110, 210) -- galaxy on morado-azul
local RagKnobOn   = Color3.fromRGB(100, 200, 180)  -- anti ragdoll on
local JumpKnobOn  = Color3.fromRGB(100, 180, 240)  -- inf jump on

if PlayerGui:FindFirstChild("KmoneyHub") then
    PlayerGui:FindFirstChild("KmoneyHub"):Destroy()
end

-- ══════════════════════════════════════════
-- GUI  (500 x 420)
-- ══════════════════════════════════════════
local GUI_W, GUI_H = 500, 420

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KmoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, GUI_W, 0, GUI_H)
Main.Position         = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
Main.BackgroundColor3 = NavyDark
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, IndigoDark),
    ColorSequenceKeypoint.new(1.0, NavyDark),
})
BgGrad.Rotation = 135
BgGrad.Parent = Main

local Header = Instance.new("Frame")
Header.Size                   = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3       = IndigoDark
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel        = 0
Header.ZIndex                 = 3
Header.Parent                 = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size                   = UDim2.new(1, 0, 0, 1.5)
HeaderLine.Position               = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3       = IndigoMid
HeaderLine.BackgroundTransparency = 0.2
HeaderLine.BorderSizePixel        = 0
HeaderLine.ZIndex                 = 4
HeaderLine.Parent                 = Header

local Title = Instance.new("TextLabel")
Title.Size                   = UDim2.new(1, -60, 1, 0)
Title.Position               = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text                   = "Kmoney"
Title.TextColor3             = White
Title.Font                   = Enum.Font.GothamBlack
Title.TextSize               = 20
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.ZIndex                 = 5
Title.Parent                 = Header
local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = IndigoMid; TitleStroke.Thickness = 1.5; TitleStroke.Transparency = 0.4
TitleStroke.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                   = UDim2.new(0, 30, 0, 30)
CloseBtn.Position               = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3       = IndigoMid
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text                   = "x"
CloseBtn.TextColor3             = White
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 15
CloseBtn.BorderSizePixel        = 0
CloseBtn.ZIndex                 = 6
CloseBtn.Parent                 = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local Content = Instance.new("Frame")
Content.Size                 = UDim2.new(1, -24, 1, -118)
Content.Position             = UDim2.new(0, 12, 0, 60)
Content.BackgroundTransparency = 1
Content.ZIndex               = 3
Content.Parent               = Main

-- ══════════════════════════════════════════
-- TOGGLE HELPER
-- ══════════════════════════════════════════
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeToggle(labelText, yPos)
    local Row = Instance.new("Frame")
    Row.Size                   = UDim2.new(1, 0, 0, 48)
    Row.Position               = UDim2.new(0, 0, 0, yPos)
    Row.BackgroundColor3       = IndigoDark
    Row.BackgroundTransparency = 0.3
    Row.BorderSizePixel        = 0
    Row.ZIndex                 = 4
    Row.Parent                 = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = IndigoMid; Stroke.Transparency = 0.4; Stroke.Thickness = 1; Stroke.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                   = UDim2.new(1, -80, 1, 0)
    Lbl.Position               = UDim2.new(0, 14, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = labelText
    Lbl.TextColor3             = White
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 14
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left
    Lbl.ZIndex                 = 5
    Lbl.Parent                 = Row

    local BtnTrack = Instance.new("TextButton")
    BtnTrack.Size                   = UDim2.new(0, 46, 0, 24)
    BtnTrack.Position               = UDim2.new(1, -58, 0.5, -12)
    BtnTrack.BackgroundColor3       = NavyDark
    BtnTrack.BackgroundTransparency = 0.1
    BtnTrack.Text                   = ""
    BtnTrack.BorderSizePixel        = 0
    BtnTrack.ZIndex                 = 5
    BtnTrack.Parent                 = Row
    Instance.new("UICorner", BtnTrack).CornerRadius = UDim.new(1, 0)
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = IndigoMid; BtnStroke.Transparency = 0.3; BtnStroke.Thickness = 1
    BtnStroke.Parent = BtnTrack

    local Knob = Instance.new("Frame")
    Knob.Size             = UDim2.new(0, 18, 0, 18)
    Knob.Position         = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = KnobOff
    Knob.BorderSizePixel  = 0
    Knob.ZIndex           = 6
    Knob.Parent           = BtnTrack
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    return BtnTrack, Knob
end

-- ══════════════════════════════════════════
-- SECCION MISC
-- ══════════════════════════════════════════
local MiscLabel = Instance.new("TextLabel")
MiscLabel.Size                   = UDim2.new(1, 0, 0, 20)
MiscLabel.Position               = UDim2.new(0, 0, 0, 0)
MiscLabel.BackgroundTransparency = 1
MiscLabel.Text                   = "— MISC —"
MiscLabel.TextColor3             = IndigoMid
MiscLabel.Font                   = Enum.Font.GothamBold
MiscLabel.TextSize               = 11
MiscLabel.TextXAlignment         = Enum.TextXAlignment.Left
MiscLabel.ZIndex                 = 4
MiscLabel.Parent                 = Content

-- ══════════════════════════════════════════
-- TOGGLE: DARK MODE  (yPos 24)
-- ══════════════════════════════════════════
local B1, K1 = makeToggle("Dark Mode", 24)

local function applyDarkState()
    if darkOn then
        enableOptimizer(); enableDarkMode()
        K1.Position = UDim2.new(1,-21,0.5,-9); K1.BackgroundColor3 = KnobOn
    else
        disableOptimizer(); disableDarkMode()
        K1.Position = UDim2.new(0,3,0.5,-9);   K1.BackgroundColor3 = KnobOff
    end
end
applyDarkState()

B1.MouseButton1Click:Connect(function()
    darkOn = not darkOn
    if darkOn then
        enableOptimizer(); enableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=KnobOn}):Play()
    else
        disableOptimizer(); disableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- TOGGLE: GALAXY  (yPos 80)
-- ══════════════════════════════════════════
local B2, K2 = makeToggle("Galaxy", 80)

local function applyGalaxyState()
    if galaxyOn then
        config.GalaxySkyBright = true; enableGalaxySkyBright()
        K2.Position = UDim2.new(1,-21,0.5,-9); K2.BackgroundColor3 = GalaxyKnobOn
    else
        config.GalaxySkyBright = false; disableGalaxySkyBright()
        K2.Position = UDim2.new(0,3,0.5,-9);   K2.BackgroundColor3 = KnobOff
    end
end
applyGalaxyState()

B2.MouseButton1Click:Connect(function()
    galaxyOn = not galaxyOn
    config.GalaxySkyBright = galaxyOn
    if galaxyOn then
        enableGalaxySkyBright()
        TweenService:Create(K2, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=GalaxyKnobOn}):Play()
    else
        disableGalaxySkyBright()
        TweenService:Create(K2, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- TOGGLE: ANTI RAGDOLL  (yPos 136)
-- ══════════════════════════════════════════
local B3, K3 = makeToggle("Anti Ragdoll", 136)

local function applyAntiRagdollState()
    if antiRagdollOn then
        toggleAntiRagdoll(true)
        K3.Position = UDim2.new(1,-21,0.5,-9); K3.BackgroundColor3 = RagKnobOn
    else
        toggleAntiRagdoll(false)
        K3.Position = UDim2.new(0,3,0.5,-9);   K3.BackgroundColor3 = KnobOff
    end
end

antiRagdollOn = antiRagdollSaved
applyAntiRagdollState()

B3.MouseButton1Click:Connect(function()
    antiRagdollOn = not antiRagdollOn
    if antiRagdollOn then
        toggleAntiRagdoll(true)
        TweenService:Create(K3, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=RagKnobOn}):Play()
    else
        toggleAntiRagdoll(false)
        TweenService:Create(K3, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- TOGGLE: INF JUMP  (yPos 192)
-- ══════════════════════════════════════════
local B4, K4 = makeToggle("Inf Jump", 192)

local jumpForce      = 50
local clampFallSpeed = 80

RunService.Heartbeat:Connect(function()
    if not infJumpOn then return end
    local char = me.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Velocity.Y < -clampFallSpeed then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, -clampFallSpeed, hrp.Velocity.Z)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not infJumpOn then return end
    local char = me.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, jumpForce, hrp.Velocity.Z) end
end)

local function applyInfJumpState()
    if infJumpOn then
        K4.Position = UDim2.new(1,-21,0.5,-9); K4.BackgroundColor3 = JumpKnobOn
    else
        K4.Position = UDim2.new(0,3,0.5,-9);   K4.BackgroundColor3 = KnobOff
    end
end

infJumpOn = infJumpSaved
applyInfJumpState()

B4.MouseButton1Click:Connect(function()
    infJumpOn = not infJumpOn
    if infJumpOn then
        TweenService:Create(K4, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=JumpKnobOn}):Play()
    else
        TweenService:Create(K4, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- SAVE CONFIG BUTTON (fijo abajo)
-- ══════════════════════════════════════════
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                   = UDim2.new(1, -24, 0, 36)
SaveBtn.Position               = UDim2.new(0, 12, 1, -48)
SaveBtn.BackgroundColor3       = IndigoMid
SaveBtn.BackgroundTransparency = 0.1
SaveBtn.Text                   = "💾  Save Config"
SaveBtn.TextColor3             = White
SaveBtn.Font                   = Enum.Font.GothamBold
SaveBtn.TextSize               = 14
SaveBtn.BorderSizePixel        = 0
SaveBtn.ZIndex                 = 6
SaveBtn.Parent                 = Main
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 10)
local SaveStroke = Instance.new("UIStroke")
SaveStroke.Color = White; SaveStroke.Transparency = 0.6; SaveStroke.Thickness = 1
SaveStroke.Parent = SaveBtn

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    local orig = SaveBtn.Text
    SaveBtn.Text = "✔  Saved!"
    SaveBtn.TextColor3 = Color3.fromRGB(150, 240, 180)
    task.delay(1.2, function()
        SaveBtn.Text = orig
        SaveBtn.TextColor3 = White
    end)
end)

-- ══════════════════════════════════════════
-- CERRAR
-- ══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    disableGalaxySkyBright()
    toggleAntiRagdoll(false)
    local t = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    t:Play()
    t.Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- ══════════════════════════════════════════
-- DRAG
-- ══════════════════════════════════════════
local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(inp)
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

-- ══════════════════════════════════════════
-- ANIMACION ENTRADA
-- ══════════════════════════════════════════
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = UDim2.new(0, GUI_W, 0, GUI_H),
    Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
}):Play()
