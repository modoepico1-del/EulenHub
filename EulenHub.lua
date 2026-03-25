-- KMONEY HUB - 500x300

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

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
    galaxyBloom.Intensity = 1.5; galaxyBloom.Size = 40
    galaxyBloom.Threshold = 0.8; galaxyBloom.Parent = Lighting

    galaxyGalaxyCC = Instance.new("ColorCorrectionEffect")
    galaxyGalaxyCC.Saturation = 0.8; galaxyGalaxyCC.Contrast = 0.3
    galaxyGalaxyCC.TintColor = Color3.fromRGB(200,150,255)
    galaxyGalaxyCC.Parent = Lighting

    Lighting.Ambient = Color3.fromRGB(120,60,180)
    Lighting.Brightness = 3
    Lighting.ClockTime = 0

    for i = 1, 2 do
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800+i*200, 800+i*200, 800+i*200)
        p.Anchored = true; p.CanCollide = false; p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(140+i*20, 60+i*10, 200+i*15)
        p.Transparency = 0.3
        p.Position = Vector3.new(
            math.cos(i*2) * (3000+i*500),
            1500+i*300,
            math.sin(i*2) * (3000+i*500)
        )
        p.Parent = workspace
        table.insert(galaxyPlanets, p)
    end

    galaxySkyBrightConn = RunService.Heartbeat:Connect(function()
        if not config.GalaxySkyBright then return end
        local t = tick() * 0.5
        Lighting.Ambient = Color3.fromRGB(
            120 + math.floor(math.sin(t)*60),
            50  + math.floor(math.sin(t*0.8)*40),
            180 + math.floor(math.sin(t*1.2)*50)
        )
        if galaxyBloom then galaxyBloom.Intensity = 1.2 + math.sin(t*2)*0.4 end
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
    Lighting.Ambient = Color3.fromRGB(127,127,127)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
end

-- ══════════════════════════════════════════
-- SAVE CONFIG
-- ══════════════════════════════════════════
local darkOn   = false
local galaxyOn = false

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            DarkMode = darkOn,
            Galaxy   = galaxyOn,
        }))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.DarkMode ~= nil then darkOn   = data.DarkMode end
            if data.Galaxy   ~= nil then galaxyOn = data.Galaxy   end
        end
    end)
end

loadConfig()

-- ══════════════════════════════════════════
-- COLORES (#DF6589 → #3C1053)
-- ══════════════════════════════════════════
local HotPink  = Color3.fromRGB(223, 101, 137)
local DeepPlum = Color3.fromRGB(60,  16,  83)
local White    = Color3.fromRGB(255, 255, 255)
local KnobOff  = Color3.fromRGB(180, 120, 160)
local KnobOn   = Color3.fromRGB(223, 101, 137)

if PlayerGui:FindFirstChild("KmoneyHub") then
    PlayerGui:FindFirstChild("KmoneyHub"):Destroy()
end

-- ══════════════════════════════════════════
-- GUI  (500 x 360 para los dos toggles)
-- ══════════════════════════════════════════
local GUI_W, GUI_H = 500, 360

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KmoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, GUI_W, 0, GUI_H)
Main.Position         = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
Main.BackgroundColor3 = DeepPlum
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, HotPink),
    ColorSequenceKeypoint.new(1.0, DeepPlum),
})
BgGrad.Rotation = 135
BgGrad.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size                   = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3       = DeepPlum
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel        = 0
Header.ZIndex                 = 3
Header.Parent                 = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size                   = UDim2.new(1, 0, 0, 1.5)
HeaderLine.Position               = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3       = HotPink
HeaderLine.BackgroundTransparency = 0.3
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
TitleStroke.Color = HotPink; TitleStroke.Thickness = 1.5; TitleStroke.Transparency = 0.4
TitleStroke.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                   = UDim2.new(0, 30, 0, 30)
CloseBtn.Position               = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3       = HotPink
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
    Row.BackgroundColor3       = DeepPlum
    Row.BackgroundTransparency = 0.4
    Row.BorderSizePixel        = 0
    Row.ZIndex                 = 4
    Row.Parent                 = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = HotPink; Stroke.Transparency = 0.5; Stroke.Thickness = 1; Stroke.Parent = Row

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
    BtnTrack.BackgroundColor3       = DeepPlum
    BtnTrack.BackgroundTransparency = 0.2
    BtnTrack.Text                   = ""
    BtnTrack.BorderSizePixel        = 0
    BtnTrack.ZIndex                 = 5
    BtnTrack.Parent                 = Row
    Instance.new("UICorner", BtnTrack).CornerRadius = UDim.new(1, 0)
    local BtnStroke = Instance.new("UIStroke")
    BtnStroke.Color = HotPink; BtnStroke.Transparency = 0.4; BtnStroke.Thickness = 1
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
MiscLabel.TextColor3             = HotPink
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
-- TOGGLE: GALAXY  (yPos 80, debajo de Dark Mode)
-- ══════════════════════════════════════════
local B2, K2 = makeToggle("Galaxy", 80)

local GalaxyKnobOn = Color3.fromRGB(170, 100, 255)  -- morado galaxia cuando ON

local function applyGalaxyState()
    if galaxyOn then
        config.GalaxySkyBright = true
        enableGalaxySkyBright()
        K2.Position = UDim2.new(1,-21,0.5,-9); K2.BackgroundColor3 = GalaxyKnobOn
    else
        config.GalaxySkyBright = false
        disableGalaxySkyBright()
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
-- SAVE CONFIG BUTTON (fijo abajo)
-- ══════════════════════════════════════════
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                   = UDim2.new(1, -24, 0, 36)
SaveBtn.Position               = UDim2.new(0, 12, 1, -48)
SaveBtn.BackgroundColor3       = HotPink
SaveBtn.BackgroundTransparency = 0.2
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
