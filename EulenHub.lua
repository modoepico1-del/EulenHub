-- KMONEY HUB - 300x340

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local me                = LocalPlayer
local RS                = RunService

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
local antiRagdollOn      = false
local antiRagdollMode    = nil
local ragdollConnections = {}
local cachedCharData     = {}

local function cacheCharacterData()
    local char = me.Character; if not char then return false end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = {
        character = char, humanoid = hum, root = root,
        originalWalkSpeed = hum.WalkSpeed, originalJumpPower = hum.JumpPower, isFrozen = false,
    }
    return true
end

local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do
        if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
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
        if isRagdolled() then removeRagdollConstraints(); forceExitRagdoll() end
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
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
            task.wait(0.5); if antiRagdollMode then cacheCharacterData() end
        end)
        table.insert(ragdollConnections, charConn)
        task.spawn(antiRagdollLoop)
    else
        antiRagdollMode = nil; disconnectAllRagdoll(); cachedCharData = {}
    end
end

-- ══════════════════════════════════════════
-- ESTADOS
-- ══════════════════════════════════════════
local infJumpOn              = false
local autoStealActive        = false
local unwalkOn               = false
local espOn                  = false
local unwalkConn             = nil
local AUTO_STEAL_PROX_RADIUS = 7
local STEAL_DURATION         = 0.2   -- ← nuevo: duración del steal en segundos

-- ══════════════════════════════════════════
-- SAVE / LOAD CONFIG
-- ══════════════════════════════════════════
local darkOn           = false
local galaxyOn         = false
local antiRagdollSaved = false
local infJumpSaved     = false
local autoStealSaved   = false
local unwalkSaved      = false
local espSaved         = false

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            DarkMode      = darkOn,
            Galaxy        = galaxyOn,
            AntiRagdoll   = antiRagdollOn,
            InfJump       = infJumpOn,
            AutoSteal     = autoStealActive,
            StealRadius   = AUTO_STEAL_PROX_RADIUS,
            StealDuration = STEAL_DURATION,
            Unwalk        = unwalkOn,
            ESP           = espOn,
        }))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.DarkMode      ~= nil then darkOn                 = data.DarkMode      end
            if data.Galaxy        ~= nil then galaxyOn               = data.Galaxy        end
            if data.AntiRagdoll   ~= nil then antiRagdollSaved       = data.AntiRagdoll   end
            if data.InfJump       ~= nil then infJumpSaved           = data.InfJump       end
            if data.AutoSteal     ~= nil then autoStealSaved         = data.AutoSteal     end
            if data.StealRadius   ~= nil then AUTO_STEAL_PROX_RADIUS = data.StealRadius   end
            if data.StealDuration ~= nil then STEAL_DURATION         = data.StealDuration end
            if data.Unwalk        ~= nil then unwalkSaved            = data.Unwalk        end
            if data.ESP           ~= nil then espSaved               = data.ESP           end
        end
    end)
end

loadConfig()

-- ══════════════════════════════════════════
-- COLORES
-- ══════════════════════════════════════════
local NavyDark     = Color3.fromRGB(30,  35,  65)
local IndigoDark   = Color3.fromRGB(45,  48,  90)
local IndigoMid    = Color3.fromRGB(75,  75, 130)
local White        = Color3.fromRGB(255, 255, 255)
local KnobOff      = Color3.fromRGB(80,  85, 120)
local KnobOn       = Color3.fromRGB(120, 130, 200)
local ESP_HUB_BLUE = Color3.fromRGB(130, 180, 255)  -- azul claro estilo hub

if PlayerGui:FindFirstChild("KmoneyHub") then
    PlayerGui:FindFirstChild("KmoneyHub"):Destroy()
end

-- ══════════════════════════════════════════
-- LAYOUT
-- ══════════════════════════════════════════
local GUI_W    = 300
local GUI_H    = 492
local ROW_H    = 30
local ROW_GAP  = 3
local SEC_H    = 14
local HEADER_H = 40
local PAD_BOT  = 4
local SAVE_H   = 26

local CONTENT_Y = HEADER_H + 1 + 3  -- 44

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
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, IndigoDark),
    ColorSequenceKeypoint.new(1.0, NavyDark),
})
BgGrad.Rotation = 135
BgGrad.Parent = Main

-- ── Header ──
local Header = Instance.new("Frame")
Header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
Header.BackgroundColor3       = IndigoDark
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel        = 0
Header.ZIndex                 = 3
Header.Parent                 = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size                   = UDim2.new(1, 0, 0, 1)
HeaderLine.Position               = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3       = IndigoMid
HeaderLine.BackgroundTransparency = 0.2
HeaderLine.BorderSizePixel        = 0
HeaderLine.ZIndex                 = 4
HeaderLine.Parent                 = Header

local Title = Instance.new("TextLabel")
Title.Size                   = UDim2.new(1, -50, 1, 0)
Title.Position               = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text                   = "Kmoney"
Title.TextColor3             = White
Title.Font                   = Enum.Font.GothamBlack
Title.TextSize               = 16
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.ZIndex                 = 5
Title.Parent                 = Header
local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = IndigoMid; TitleStroke.Thickness = 1.2; TitleStroke.Transparency = 0.4
TitleStroke.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                   = UDim2.new(0, 24, 0, 24)
CloseBtn.Position               = UDim2.new(1, -32, 0.5, -12)
CloseBtn.BackgroundColor3       = IndigoMid
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text                   = "x"
CloseBtn.TextColor3             = White
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 12
CloseBtn.BorderSizePixel        = 0
CloseBtn.ZIndex                 = 6
CloseBtn.Parent                 = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- ── Content frame ──
local Content = Instance.new("Frame")
Content.Size                   = UDim2.new(1, -16, 1, -(CONTENT_Y + SAVE_H + PAD_BOT + 12))
Content.Position               = UDim2.new(0, 8, 0, CONTENT_Y)
Content.BackgroundTransparency = 1
Content.ZIndex                 = 3
Content.Parent                 = Main

-- ── Helpers ──
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeSectionLabel(text, yPos)
    local Lbl = Instance.new("TextLabel")
    Lbl.Size                   = UDim2.new(1, 0, 0, SEC_H)
    Lbl.Position               = UDim2.new(0, 0, 0, yPos)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = text
    Lbl.TextColor3             = IndigoMid
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 10
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left
    Lbl.ZIndex                 = 4
    Lbl.Parent                 = Content
end

local function makeToggle(labelText, yPos)
    local Row = Instance.new("Frame")
    Row.Size                   = UDim2.new(1, 0, 0, ROW_H)
    Row.Position               = UDim2.new(0, 0, 0, yPos)
    Row.BackgroundColor3       = IndigoDark
    Row.BackgroundTransparency = 0.3
    Row.BorderSizePixel        = 0
    Row.ZIndex                 = 4
    Row.Parent                 = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = IndigoMid; Stroke.Transparency = 0.5; Stroke.Thickness = 1; Stroke.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                   = UDim2.new(1, -62, 1, 0)
    Lbl.Position               = UDim2.new(0, 10, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = labelText
    Lbl.TextColor3             = White
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 12
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left
    Lbl.ZIndex                 = 5
    Lbl.Parent                 = Row

    local BtnTrack = Instance.new("TextButton")
    BtnTrack.Size                   = UDim2.new(0, 38, 0, 20)
    BtnTrack.Position               = UDim2.new(1, -44, 0.5, -10)
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
    Knob.Size             = UDim2.new(0, 14, 0, 14)
    Knob.Position         = UDim2.new(0, 3, 0.5, -7)
    Knob.BackgroundColor3 = KnobOff
    Knob.BorderSizePixel  = 0
    Knob.ZIndex           = 6
    Knob.Parent           = BtnTrack
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    return BtnTrack, Knob, Row
end

-- ══════════════════════════════════════════
-- POSICIONES
-- VISUAL : 2 filas (Dark Mode, Galaxy)
-- MISC   : 4 filas (Anti Ragdoll, Inf Jump, Unwalk, ESP)
-- AUTO   : 5 filas (Auto Steal, Auto Left, Auto Right, Auto Left Play, Auto Right Play)
-- ══════════════════════════════════════════
local GAP_SEC = 6

local function visRowY(i)  return SEC_H + (i-1)*(ROW_H + ROW_GAP) end
local MISC_BASE = SEC_H + 2*(ROW_H + ROW_GAP) + GAP_SEC
local function miscRowY(i) return MISC_BASE + SEC_H + (i-1)*(ROW_H + ROW_GAP) end
local AUTO_BASE = MISC_BASE + SEC_H + 4*(ROW_H + ROW_GAP) + GAP_SEC
local function autoRowY(i) return AUTO_BASE + SEC_H + (i-1)*(ROW_H + ROW_GAP) end

-- ── Sección VISUAL ──
makeSectionLabel("— VISUAL —", 0)
local B1, K1 = makeToggle("Dark Mode", visRowY(1))
local B2, K2 = makeToggle("Galaxy",    visRowY(2))

-- ── Sección MISC ──
makeSectionLabel("— MISC —", MISC_BASE)
local B3, K3 = makeToggle("Anti Ragdoll", miscRowY(1))
local B4, K4 = makeToggle("Inf Jump",     miscRowY(2))
local B6, K6 = makeToggle("Unwalk",       miscRowY(3))
local B7, K7 = makeToggle("ESP",          miscRowY(4))

-- ── Sección AUTO ──
makeSectionLabel("— AUTO —", AUTO_BASE)
local B5,  K5,  AutoStealRow    = makeToggle("Auto Steal  ⚙️",   autoRowY(1))
local B8,  K8                   = makeToggle("Auto Left",         autoRowY(2))
local B9,  K9                   = makeToggle("Auto Right",        autoRowY(3))
local B10, K10                  = makeToggle("Auto Left Play",    autoRowY(4))
local B11, K11                  = makeToggle("Auto Right Play",   autoRowY(5))

-- ══════════════════════════════════════════
-- MINI PANEL AUTO STEAL (right-click)
-- ══════════════════════════════════════════
local miniPanelOpen = false
-- El mini panel se coloca fuera del hub, a la izquierda, alineado verticalmente
-- con la fila de Auto Steal. Se pone como hijo de ScreenGui para salir del clip del Main.
local MiniPanel = Instance.new("Frame")
MiniPanel.Name                 = "MiniPanel"
MiniPanel.Size                 = UDim2.new(0, 170, 0, 58)
-- X: borde izquierdo del hub menos el ancho del panel menos 8px de margen
-- Y: misma posición vertical que la fila Auto Steal dentro del hub
MiniPanel.Position             = UDim2.new(0.5, (GUI_W/2) + 8, 0.5, -(GUI_H/2) + autoRowY(1) + CONTENT_Y)
MiniPanel.BackgroundColor3     = IndigoDark
MiniPanel.BackgroundTransparency = 0.08
MiniPanel.BorderSizePixel      = 0
MiniPanel.Visible              = false
MiniPanel.ZIndex               = 20
MiniPanel.Parent               = ScreenGui   -- ← hijo de ScreenGui, no de Main
Instance.new("UICorner", MiniPanel).CornerRadius = UDim.new(0, 8)
local MiniStroke = Instance.new("UIStroke", MiniPanel)
MiniStroke.Color = ESP_HUB_BLUE; MiniStroke.Thickness = 1; MiniStroke.Transparency = 0.4

-- Título mini panel
local MiniTitle = Instance.new("TextLabel")
MiniTitle.Size                   = UDim2.new(1, -8, 0, 18)
MiniTitle.Position               = UDim2.new(0, 8, 0, 4)
MiniTitle.BackgroundTransparency = 1
MiniTitle.Text                   = "Steal Duration (s)"
MiniTitle.TextColor3             = ESP_HUB_BLUE
MiniTitle.Font                   = Enum.Font.GothamBold
MiniTitle.TextSize               = 10
MiniTitle.TextXAlignment         = Enum.TextXAlignment.Left
MiniTitle.ZIndex                 = 21
MiniTitle.Parent                 = MiniPanel

-- Botón menos
local MinusBtn = Instance.new("TextButton")
MinusBtn.Size                   = UDim2.new(0, 22, 0, 22)
MinusBtn.Position               = UDim2.new(0, 8, 0, 28)
MinusBtn.BackgroundColor3       = IndigoMid
MinusBtn.BackgroundTransparency = 0.2
MinusBtn.Text                   = "−"
MinusBtn.TextColor3             = White
MinusBtn.Font                   = Enum.Font.GothamBold
MinusBtn.TextSize               = 14
MinusBtn.BorderSizePixel        = 0
MinusBtn.ZIndex                 = 22
MinusBtn.Parent                 = MiniPanel
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

-- Label valor
local DurLabel = Instance.new("TextLabel")
DurLabel.Size                   = UDim2.new(0, 70, 0, 22)
DurLabel.Position               = UDim2.new(0, 34, 0, 28)
DurLabel.BackgroundTransparency = 1
DurLabel.Text                   = tostring(STEAL_DURATION)
DurLabel.TextColor3             = White
DurLabel.Font                   = Enum.Font.GothamBold
DurLabel.TextSize               = 12
DurLabel.TextXAlignment         = Enum.TextXAlignment.Center
DurLabel.ZIndex                 = 22
DurLabel.Parent                 = MiniPanel

-- Botón más
local PlusBtn = Instance.new("TextButton")
PlusBtn.Size                   = UDim2.new(0, 22, 0, 22)
PlusBtn.Position               = UDim2.new(0, 108, 0, 28)
PlusBtn.BackgroundColor3       = IndigoMid
PlusBtn.BackgroundTransparency = 0.2
PlusBtn.Text                   = "+"
PlusBtn.TextColor3             = White
PlusBtn.Font                   = Enum.Font.GothamBold
PlusBtn.TextSize               = 14
PlusBtn.BorderSizePixel        = 0
PlusBtn.ZIndex                 = 22
PlusBtn.Parent                 = MiniPanel
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

local function updateDurLabel()
    DurLabel.Text = string.format("%.2f", STEAL_DURATION)
end

MinusBtn.MouseButton1Click:Connect(function()
    STEAL_DURATION = math.max(0.01, math.floor((STEAL_DURATION - 0.01)*100 + 0.5)/100)
    updateDurLabel()
end)

PlusBtn.MouseButton1Click:Connect(function()
    STEAL_DURATION = math.floor((STEAL_DURATION + 0.01)*100 + 0.5)/100
    updateDurLabel()
end)

-- Toggle mini panel con clic derecho en el row
AutoStealRow.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        miniPanelOpen = not miniPanelOpen
        MiniPanel.Visible = miniPanelOpen
    end
end)
B5.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        miniPanelOpen = not miniPanelOpen
        MiniPanel.Visible = miniPanelOpen
    end
end)

-- ══════════════════════════════════════════
-- DARK MODE
-- ══════════════════════════════════════════
local function applyDarkState()
    if darkOn then
        enableOptimizer(); enableDarkMode()
        K1.Position = UDim2.new(1,-17,0.5,-7); K1.BackgroundColor3 = KnobOn
    else
        disableOptimizer(); disableDarkMode()
        K1.Position = UDim2.new(0,3,0.5,-7);   K1.BackgroundColor3 = KnobOff
    end
end
applyDarkState()
B1.MouseButton1Click:Connect(function()
    darkOn = not darkOn
    if darkOn then
        enableOptimizer(); enableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        disableOptimizer(); disableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- GALAXY
-- ══════════════════════════════════════════
local function applyGalaxyState()
    if galaxyOn then
        config.GalaxySkyBright = true; enableGalaxySkyBright()
        K2.Position = UDim2.new(1,-17,0.5,-7); K2.BackgroundColor3 = KnobOn
    else
        config.GalaxySkyBright = false; disableGalaxySkyBright()
        K2.Position = UDim2.new(0,3,0.5,-7);   K2.BackgroundColor3 = KnobOff
    end
end
applyGalaxyState()
B2.MouseButton1Click:Connect(function()
    galaxyOn = not galaxyOn
    config.GalaxySkyBright = galaxyOn
    if galaxyOn then
        enableGalaxySkyBright()
        TweenService:Create(K2, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        disableGalaxySkyBright()
        TweenService:Create(K2, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- ANTI RAGDOLL
-- ══════════════════════════════════════════
local function applyAntiRagdollState()
    if antiRagdollOn then
        toggleAntiRagdoll(true)
        K3.Position = UDim2.new(1,-17,0.5,-7); K3.BackgroundColor3 = KnobOn
    else
        toggleAntiRagdoll(false)
        K3.Position = UDim2.new(0,3,0.5,-7);   K3.BackgroundColor3 = KnobOff
    end
end
antiRagdollOn = antiRagdollSaved
applyAntiRagdollState()
B3.MouseButton1Click:Connect(function()
    antiRagdollOn = not antiRagdollOn
    if antiRagdollOn then
        toggleAntiRagdoll(true)
        TweenService:Create(K3, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        toggleAntiRagdoll(false)
        TweenService:Create(K3, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- INF JUMP
-- ══════════════════════════════════════════
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
        K4.Position = UDim2.new(1,-17,0.5,-7); K4.BackgroundColor3 = KnobOn
    else
        K4.Position = UDim2.new(0,3,0.5,-7);   K4.BackgroundColor3 = KnobOff
    end
end
infJumpOn = infJumpSaved
applyInfJumpState()
B4.MouseButton1Click:Connect(function()
    infJumpOn = not infJumpOn
    if infJumpOn then
        TweenService:Create(K4, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        TweenService:Create(K4, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- UNWALK
-- ══════════════════════════════════════════
local function enableUnwalk()
    local char=me.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RS.Heartbeat:Connect(function()
        if not unwalkOn then unwalkConn:Disconnect(); unwalkConn=nil; return end
        local c=me.Character; if not c then return end
        local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
        local an=h:FindFirstChildOfClass("Animator"); if not an then return end
        for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end
local function disableUnwalk()
    if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end
end
local function applyUnwalkState()
    if unwalkOn then
        enableUnwalk(); K6.Position=UDim2.new(1,-17,0.5,-7); K6.BackgroundColor3=KnobOn
    else
        disableUnwalk(); K6.Position=UDim2.new(0,3,0.5,-7); K6.BackgroundColor3=KnobOff
    end
end
unwalkOn = unwalkSaved
applyUnwalkState()
B6.MouseButton1Click:Connect(function()
    unwalkOn = not unwalkOn
    if unwalkOn then
        enableUnwalk()
        TweenService:Create(K6, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        disableUnwalk()
        TweenService:Create(K6, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- ESP  — hitbox AZUL CLARO HUB, nombre AZUL CLARO HUB (mismo color)
-- ══════════════════════════════════════════
local espObjects     = {}
local espConnections = {}

local function createESP(plr)
    if plr == me then return end
    if not plr.Character then return end
    if plr.Character:FindFirstChild("NightESP") then return end
    local c    = plr.Character
    local hrp  = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local head = c:FindFirstChild("Head")
    local hum  = c:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end

    -- ► Box ahora usa ESP_HUB_BLUE igual que el nombre
    local hitbox = Instance.new("BoxHandleAdornment")
    hitbox.Name         = "NightESP"
    hitbox.Adornee      = hrp
    hitbox.Size         = Vector3.new(4, 6, 2)
    hitbox.Color3       = ESP_HUB_BLUE   -- ← CAMBIO: azul claro igual que el nombre
    hitbox.Transparency = 0.3
    hitbox.ZIndex       = 10
    hitbox.AlwaysOnTop  = true
    hitbox.Parent       = c
    espObjects[plr]     = hitbox

    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name        = "ESP_Name"
        billboard.Adornee     = head
        billboard.Size        = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent      = c
        local label = Instance.new("TextLabel")
        label.Size                   = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text                   = plr.DisplayName or plr.Name
        label.TextColor3             = ESP_HUB_BLUE
        label.Font                   = Enum.Font.GothamBold
        label.TextScaled             = true
        label.TextStrokeTransparency = 0.4
        label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
        label.Parent                 = billboard
    end
end

local function removeESP(plr)
    pcall(function()
        if plr.Character then
            local h = plr.Character:FindFirstChild("NightESP"); if h then h:Destroy() end
            local n = plr.Character:FindFirstChild("ESP_Name"); if n then n:Destroy() end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Automatic end
        end
        espObjects[plr] = nil
    end)
end

local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= me then
            if plr.Character then pcall(function() createESP(plr) end) end
            local c = plr.CharacterAdded:Connect(function()
                task.wait(0.1); if espOn then pcall(function() createESP(plr) end) end
            end)
            table.insert(espConnections, c)
        end
    end
    local c2 = Players.PlayerAdded:Connect(function(plr)
        if plr == me then return end
        local c3 = plr.CharacterAdded:Connect(function()
            task.wait(0.1); if espOn then pcall(function() createESP(plr) end) end
        end)
        table.insert(espConnections, c3)
    end)
    table.insert(espConnections, c2)
end

local function disableESP()
    for _, plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end
    for _, conn in ipairs(espConnections) do if conn and conn.Connected then conn:Disconnect() end end
    espConnections = {}; espObjects = {}
end

local function applyEspState()
    if espOn then
        enableESP(); K7.Position=UDim2.new(1,-17,0.5,-7); K7.BackgroundColor3=KnobOn
    else
        disableESP(); K7.Position=UDim2.new(0,3,0.5,-7);  K7.BackgroundColor3=KnobOff
    end
end
espOn = espSaved
applyEspState()
B7.MouseButton1Click:Connect(function()
    espOn = not espOn
    if espOn then
        enableESP()
        TweenService:Create(K7, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        disableESP()
        TweenService:Create(K7, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- BARRA DE PROGRESO
-- ══════════════════════════════════════════
local progressBarBg = Instance.new("Frame")
progressBarBg.Size                   = UDim2.new(1, -16, 0, 5)
progressBarBg.Position               = UDim2.new(0, 8, 1, -(SAVE_H + PAD_BOT + 8))
progressBarBg.BackgroundColor3       = NavyDark
progressBarBg.BackgroundTransparency = 0.15
progressBarBg.Visible                = false
progressBarBg.ZIndex                 = 10
progressBarBg.Parent                 = Main
Instance.new("UICorner", progressBarBg).CornerRadius = UDim.new(0, 4)
local pbStroke = Instance.new("UIStroke", progressBarBg)
pbStroke.Color = IndigoMid; pbStroke.Thickness = 1; pbStroke.Transparency = 0.4

local progressFill = Instance.new("Frame")
progressFill.Size             = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = KnobOn
progressFill.BorderSizePixel  = 0
progressFill.ZIndex           = 11
progressFill.Parent           = progressBarBg
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 4)

local percentLabel = Instance.new("TextLabel")
percentLabel.Size                   = UDim2.new(1, 0, 1, 0)
percentLabel.BackgroundTransparency = 1
percentLabel.Font                   = Enum.Font.GothamBold
percentLabel.TextSize               = 6
percentLabel.TextColor3             = White
percentLabel.Text                   = "0%"
percentLabel.ZIndex                 = 12
percentLabel.Parent                 = progressBarBg

local function animateProgressBar()
    task.spawn(function()
        progressFill.Size = UDim2.new(0, 0, 1, 0); percentLabel.Text = "0%"
        local steps = 10
        local stepWait = STEAL_DURATION / steps
        for i = 1, steps do
            local pct = i/steps
            progressFill.Size = UDim2.new(pct, 0, 1, 0)
            percentLabel.Text = math.floor(pct*100).."%"
            task.wait(stepWait)
        end
        task.wait(0.2)
        progressFill.Size = UDim2.new(0,0,1,0); percentLabel.Text = "0%"
    end)
end

-- ══════════════════════════════════════════
-- CIRCULO DE RADIO
-- ══════════════════════════════════════════
local stealCirclePart, stealCircleConn = nil, nil

local function hideStealCircle()
    if stealCirclePart then stealCirclePart:Destroy(); stealCirclePart = nil end
    if stealCircleConn then stealCircleConn:Disconnect(); stealCircleConn = nil end
end

local function showStealCircle(radius)
    if stealCirclePart then
        stealCirclePart.Size = Vector3.new(0.15, radius*2, radius*2)
        return
    end
    stealCirclePart = Instance.new("Part")
    stealCirclePart.Name         = "KmoneyStealCircle"
    stealCirclePart.Shape        = Enum.PartType.Cylinder
    stealCirclePart.Size         = Vector3.new(0.15, radius*2, radius*2)
    stealCirclePart.Anchored     = true
    stealCirclePart.CanCollide   = false
    stealCirclePart.CastShadow   = false
    stealCirclePart.Material     = Enum.Material.Neon
    stealCirclePart.Color        = Color3.fromRGB(255, 255, 255)
    stealCirclePart.Transparency = 0.55
    stealCirclePart.Parent       = workspace

    stealCircleConn = RunService.Heartbeat:Connect(function()
        if not autoStealActive then hideStealCircle(); return end
        local char = me.Character
        if char and stealCirclePart then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                stealCirclePart.CFrame = CFrame.new(root.Position + Vector3.new(0,-2.8,0))
                    * CFrame.Angles(0, 0, math.rad(90))
            end
        end
    end)
end

-- ══════════════════════════════════════════
-- AUTO STEAL  (usa STEAL_DURATION como cooldown)
-- ══════════════════════════════════════════
local autoStealStealConnection = nil
local autoStealAnimalsCache    = {}
local autoStealPromptCache     = {}
local autoStealLastFire        = {}
local autoStealScannerStarted  = false

local animalsDataAS = {}
pcall(function()
    animalsDataAS = require(ReplicatedStorage:WaitForChild("Datas",5):WaitForChild("Animals",5))
end)

local function autoSteal_getHRP()
    local char = me.Character; if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end

local function autoSteal_isMyBase(plotName)
    local plots = workspace:FindFirstChild("Plots")
    local plot  = plots and plots:FindFirstChild(plotName); if not plot then return false end
    local sign  = plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb    = sign:FindFirstChild("YourBase")
    if yb and yb:IsA("BillboardGui") then return yb.Enabled == true end
    return false
end

local function autoSteal_scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if autoSteal_isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _, podium in ipairs(podiums:GetChildren()) do
        if podium:IsA("Model") and podium:FindFirstChild("Base") then
            local animalName = "Unknown"
            local spawn = podium.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        animalName = child.Name
                        local info = animalsDataAS[animalName]
                        if info and info.DisplayName then animalName = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(autoStealAnimalsCache, {
                name          = animalName,
                plot          = plot.Name,
                slot          = podium.Name,
                worldPosition = podium:GetPivot().Position,
                uid           = plot.Name.."_"..podium.Name,
            })
        end
    end
end

local function autoSteal_initScanner()
    if autoStealScannerStarted then return end
    autoStealScannerStarted = true
    task.spawn(function()
        task.wait(2)
        local plots = workspace:WaitForChild("Plots", 10); if not plots then return end
        for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then autoSteal_scanPlot(plot) end end
        plots.ChildAdded:Connect(function(plot)
            if plot:IsA("Model") then task.wait(0.5); autoSteal_scanPlot(plot) end
        end)
        task.spawn(function()
            while task.wait(4) do
                autoStealAnimalsCache = {}
                autoStealPromptCache  = {}
                for _, plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then autoSteal_scanPlot(plot) end end
            end
        end)
    end)
end

local function autoSteal_findPrompt(animalData)
    if not animalData then return nil end
    local cached = autoStealPromptCache[animalData.uid]
    if cached and cached.Parent then return cached end
    local plots   = workspace:FindFirstChild("Plots");                     if not plots   then return nil end
    local plot    = plots:FindFirstChild(animalData.plot);                 if not plot    then return nil end
    local podiums = plot:FindFirstChild("AnimalPodiums");                  if not podiums then return nil end
    local podium  = podiums:FindFirstChild(animalData.slot);               if not podium  then return nil end
    local base    = podium:FindFirstChild("Base");                         if not base    then return nil end
    local spawn   = base:FindFirstChild("Spawn");                          if not spawn   then return nil end
    for _, desc in ipairs(spawn:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            autoStealPromptCache[animalData.uid] = desc
            return desc
        end
    end
    return nil
end

local function autoSteal_fire(prompt, uid)
    local now  = tick()
    local last = autoStealLastFire[uid] or 0
    -- ← usa STEAL_DURATION como cooldown entre disparos
    if (now - last) < STEAL_DURATION then return false end
    autoStealLastFire[uid] = now
    pcall(function() fireproximityprompt(prompt) end)
    return true
end

local function autoSteal_getNearest()
    local hrp = autoSteal_getHRP(); if not hrp then return nil, nil end
    local nearest, nearestPrompt, minDist = nil, nil, math.huge
    for _, animalData in ipairs(autoStealAnimalsCache) do
        if autoSteal_isMyBase(animalData.plot) then continue end
        if not animalData.worldPosition then continue end
        local dist = (hrp.Position - animalData.worldPosition).Magnitude
        if dist < AUTO_STEAL_PROX_RADIUS and dist < minDist then
            local prompt = autoStealPromptCache[animalData.uid]
            if not prompt or not prompt.Parent then prompt = autoSteal_findPrompt(animalData) end
            if prompt and prompt.Parent then
                minDist = dist; nearest = animalData; nearestPrompt = prompt
            end
        end
    end
    return nearest, nearestPrompt
end

local function startAutoStealLoop()
    if autoStealStealConnection then autoStealStealConnection:Disconnect() end
    autoStealStealConnection = RunService.Heartbeat:Connect(function()
        if not autoStealActive then return end
        local target, prompt = autoSteal_getNearest()
        if not target or not prompt then return end
        if autoSteal_fire(prompt, target.uid) then
            task.spawn(animateProgressBar)
        end
    end)
end

local function stopAutoStealLoop()
    if autoStealStealConnection then autoStealStealConnection:Disconnect(); autoStealStealConnection = nil end
end

local function enableAutoSteal()
    autoStealActive = true
    autoSteal_initScanner()
    startAutoStealLoop()
    showStealCircle(AUTO_STEAL_PROX_RADIUS)
    progressBarBg.Visible = true
end
local function disableAutoSteal()
    autoStealActive = false
    stopAutoStealLoop()
    hideStealCircle()
    progressBarBg.Visible = false
    progressFill.Size = UDim2.new(0,0,1,0)
    percentLabel.Text = "0%"
end

local function applyAutoStealState()
    if autoStealActive then
        enableAutoSteal(); K5.Position=UDim2.new(1,-17,0.5,-7); K5.BackgroundColor3=KnobOn
    else
        K5.Position=UDim2.new(0,3,0.5,-7); K5.BackgroundColor3=KnobOff
    end
end
autoStealActive = autoStealSaved
applyAutoStealState()
B5.MouseButton1Click:Connect(function()
    autoStealActive = not autoStealActive
    if autoStealActive then
        enableAutoSteal()
        TweenService:Create(K5, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        disableAutoSteal()
        TweenService:Create(K5, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)


-- ══════════════════════════════════════════
-- AUTO LEFT / RIGHT / LEFT PLAY / RIGHT PLAY
-- ══════════════════════════════════════════
local NORMAL_SPEED   = 16
local CARRY_SPEED    = 12

-- Coordenadas — cámbialas a las tuyas
local POSITION_L1  = Vector3.new(0,  0,  0)
local POSITION_L2  = Vector3.new(0,  0,  0)
local POSITION_R1  = Vector3.new(0,  0,  0)
local POSITION_R2  = Vector3.new(0,  0,  0)
local ALP_P1       = Vector3.new(0,  0,  0)
local ALP_P2       = Vector3.new(0,  0,  0)
local ALP_P3       = Vector3.new(0,  0,  0)
local ARP_P1       = Vector3.new(0,  0,  0)
local ARP_P2       = Vector3.new(0,  0,  0)
local ARP_P3       = Vector3.new(0,  0,  0)

local AutoLeftEnabled      = false
local AutoRightEnabled     = false
local AutoLeftPlayEnabled  = false
local AutoRightPlayEnabled = false

local autoLeftConnection      = nil
local autoRightConnection     = nil
local autoLeftPlayConnection  = nil
local autoRightPlayConnection = nil

local autoLeftPhase      = 1
local autoRightPhase     = 1
local autoLeftPlayPhase  = 1
local autoRightPlayPhase = 1

local function startAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() end
    autoLeftPhase = 1
    autoLeftConnection = RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if autoLeftPhase == 1 then
            local dist = (Vector3.new(POSITION_L1.X,h.Position.Y,POSITION_L1.Z)-h.Position).Magnitude
            if dist < 1 then autoLeftPhase = 2 return end
            local dir = Vector3.new((POSITION_L1-h.Position).X,0,(POSITION_L1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity = Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoLeftPhase == 2 then
            local dist = (Vector3.new(POSITION_L2.X,h.Position.Y,POSITION_L2.Z)-h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity = Vector3.new(0,0,0)
                AutoLeftEnabled = false
                if autoLeftConnection then autoLeftConnection:Disconnect(); autoLeftConnection = nil end
                autoLeftPhase = 1
                TweenService:Create(K8, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
                return
            end
            local dir = Vector3.new((POSITION_L2-h.Position).X,0,(POSITION_L2-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity = Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        end
    end)
end

local function stopAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect(); autoLeftConnection = nil end
    autoLeftPhase = 1
    local c = me.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero,false) end end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase = 1
    local arLastPos, arStuckTimer = nil, 0
    autoRightConnection = RunService.Heartbeat:Connect(function(dt)
        if not AutoRightEnabled then return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        local currentPos = h.Position
        if arLastPos then
            if (currentPos-arLastPos).Magnitude < 0.05 then arStuckTimer=arStuckTimer+dt else arStuckTimer=0 end
        end
        arLastPos = currentPos
        if autoRightPhase == 1 then
            local dist = (Vector3.new(POSITION_R1.X,h.Position.Y,POSITION_R1.Z)-h.Position).Magnitude
            if dist < 1 then autoRightPhase=2; arStuckTimer=0 return end
            if arStuckTimer > 0.4 then
                arStuckTimer=0
                local sd=(POSITION_R1-h.Position)
                local ss=Vector3.new(sd.X,0,sd.Z).Unit*math.min(4,sd.Magnitude)
                h.CFrame=CFrame.new(h.Position+ss); h.AssemblyLinearVelocity=Vector3.zero return
            end
            local dir=Vector3.new((POSITION_R1-h.Position).X,0,(POSITION_R1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoRightPhase == 2 then
            local dist=(Vector3.new(POSITION_R2.X,h.Position.Y,POSITION_R2.Z)-h.Position).Magnitude
            if dist < 1 then
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightEnabled = false
                if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection = nil end
                autoRightPhase = 1
                TweenService:Create(K9, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
                return
            end
            if arStuckTimer > 0.4 then
                arStuckTimer=0
                local sd=(POSITION_R2-h.Position)
                local ss=Vector3.new(sd.X,0,sd.Z).Unit*math.min(4,sd.Magnitude)
                h.CFrame=CFrame.new(h.Position+ss); h.AssemblyLinearVelocity=Vector3.zero return
            end
            local dir=Vector3.new((POSITION_R2-h.Position).X,0,(POSITION_R2-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        end
    end)
end

local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect(); autoRightConnection = nil end
    autoRightPhase = 1
    local c = me.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero,false) end end
end

local function startAutoLeftPlay()
    if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect() end
    autoLeftPlayPhase = 1
    autoLeftPlayConnection = RunService.Heartbeat:Connect(function()
        if not AutoLeftPlayEnabled then return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if autoLeftPlayPhase == 1 then
            local dist=(Vector3.new(ALP_P1.X,h.Position.Y,ALP_P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoLeftPlayPhase=2 return end
            local dir=Vector3.new((ALP_P1-h.Position).X,0,(ALP_P1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoLeftPlayPhase == 2 then
            local dist=(Vector3.new(ALP_P2.X,h.Position.Y,ALP_P2.Z)-h.Position).Magnitude
            if dist<1.5 then autoLeftPlayPhase=3 return end
            local dir=Vector3.new((ALP_P2-h.Position).X,0,(ALP_P2-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoLeftPlayPhase == 3 then
            local dist=(Vector3.new(ALP_P1.X,h.Position.Y,ALP_P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoLeftPlayPhase=4 return end
            local dir=Vector3.new((ALP_P1-h.Position).X,0,(ALP_P1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoLeftPlayPhase == 4 then
            local dist=(Vector3.new(ALP_P3.X,h.Position.Y,ALP_P3.Z)-h.Position).Magnitude
            if dist<1.5 then
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoLeftPlayEnabled = false
                if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect(); autoLeftPlayConnection = nil end
                autoLeftPlayPhase = 1
                TweenService:Create(K10, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
                return
            end
            local dir=Vector3.new((ALP_P3-h.Position).X,0,(ALP_P3-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        end
    end)
end

local function stopAutoLeftPlay()
    if autoLeftPlayConnection then autoLeftPlayConnection:Disconnect(); autoLeftPlayConnection = nil end
    autoLeftPlayPhase = 1
    local c = me.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero,false) end end
end

local function startAutoRightPlay()
    if autoRightPlayConnection then autoRightPlayConnection:Disconnect() end
    autoRightPlayPhase = 1
    autoRightPlayConnection = RunService.Heartbeat:Connect(function()
        if not AutoRightPlayEnabled then return end
        local c = me.Character; if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not h or not hum then return end
        if autoRightPlayPhase == 1 then
            local dist=(Vector3.new(ARP_P1.X,h.Position.Y,ARP_P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoRightPlayPhase=2 return end
            local dir=Vector3.new((ARP_P1-h.Position).X,0,(ARP_P1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*NORMAL_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*NORMAL_SPEED)
        elseif autoRightPlayPhase == 2 then
            local dist=(Vector3.new(ARP_P2.X,h.Position.Y,ARP_P2.Z)-h.Position).Magnitude
            if dist<1.5 then autoRightPlayPhase=3 return end
            local dir=Vector3.new((ARP_P2-h.Position).X,0,(ARP_P2-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoRightPlayPhase == 3 then
            local dist=(Vector3.new(ARP_P1.X,h.Position.Y,ARP_P1.Z)-h.Position).Magnitude
            if dist<1.5 then autoRightPlayPhase=4 return end
            local dir=Vector3.new((ARP_P1-h.Position).X,0,(ARP_P1-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        elseif autoRightPlayPhase == 4 then
            local dist=(Vector3.new(ARP_P3.X,h.Position.Y,ARP_P3.Z)-h.Position).Magnitude
            if dist<1.5 then
                hum:Move(Vector3.zero,false); h.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightPlayEnabled = false
                if autoRightPlayConnection then autoRightPlayConnection:Disconnect(); autoRightPlayConnection = nil end
                autoRightPlayPhase = 1
                TweenService:Create(K11, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
                return
            end
            local dir=Vector3.new((ARP_P3-h.Position).X,0,(ARP_P3-h.Position).Z).Unit
            hum:Move(dir,false); h.AssemblyLinearVelocity=Vector3.new(dir.X*CARRY_SPEED,h.AssemblyLinearVelocity.Y,dir.Z*CARRY_SPEED)
        end
    end)
end

local function stopAutoRightPlay()
    if autoRightPlayConnection then autoRightPlayConnection:Disconnect(); autoRightPlayConnection = nil end
    autoRightPlayPhase = 1
    local c = me.Character
    if c then local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum:Move(Vector3.zero,false) end end
end

-- ── Toggle Auto Left ──
K8.Position = UDim2.new(0,3,0.5,-7); K8.BackgroundColor3 = KnobOff
B8.MouseButton1Click:Connect(function()
    AutoLeftEnabled = not AutoLeftEnabled
    if AutoLeftEnabled then
        startAutoLeft()
        TweenService:Create(K8, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        stopAutoLeft()
        TweenService:Create(K8, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ── Toggle Auto Right ──
K9.Position = UDim2.new(0,3,0.5,-7); K9.BackgroundColor3 = KnobOff
B9.MouseButton1Click:Connect(function()
    AutoRightEnabled = not AutoRightEnabled
    if AutoRightEnabled then
        startAutoRight()
        TweenService:Create(K9, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        stopAutoRight()
        TweenService:Create(K9, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ── Toggle Auto Left Play ──
K10.Position = UDim2.new(0,3,0.5,-7); K10.BackgroundColor3 = KnobOff
B10.MouseButton1Click:Connect(function()
    AutoLeftPlayEnabled = not AutoLeftPlayEnabled
    if AutoLeftPlayEnabled then
        startAutoLeftPlay()
        TweenService:Create(K10, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        stopAutoLeftPlay()
        TweenService:Create(K10, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ── Toggle Auto Right Play ──
K11.Position = UDim2.new(0,3,0.5,-7); K11.BackgroundColor3 = KnobOff
B11.MouseButton1Click:Connect(function()
    AutoRightPlayEnabled = not AutoRightPlayEnabled
    if AutoRightPlayEnabled then
        startAutoRightPlay()
        TweenService:Create(K11, ti, {Position=UDim2.new(1,-17,0.5,-7), BackgroundColor3=KnobOn}):Play()
    else
        stopAutoRightPlay()
        TweenService:Create(K11, ti, {Position=UDim2.new(0,3,0.5,-7), BackgroundColor3=KnobOff}):Play()
    end
end)

-- ══════════════════════════════════════════
-- SAVE CONFIG
-- ══════════════════════════════════════════
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                   = UDim2.new(1, -16, 0, SAVE_H)
SaveBtn.Position               = UDim2.new(0, 8, 1, -(SAVE_H + PAD_BOT))
SaveBtn.BackgroundColor3       = IndigoMid
SaveBtn.BackgroundTransparency = 0.1
SaveBtn.Text                   = "Save Config"
SaveBtn.TextColor3             = White
SaveBtn.Font                   = Enum.Font.GothamBold
SaveBtn.TextSize               = 12
SaveBtn.BorderSizePixel        = 0
SaveBtn.ZIndex                 = 6
SaveBtn.Parent                 = Main
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)
local SaveStroke = Instance.new("UIStroke")
SaveStroke.Color = White; SaveStroke.Transparency = 0.6; SaveStroke.Thickness = 1
SaveStroke.Parent = SaveBtn

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    local orig = SaveBtn.Text
    SaveBtn.Text = "Saved!"; SaveBtn.TextColor3 = Color3.fromRGB(150,240,180)
    task.delay(1.2, function() SaveBtn.Text=orig; SaveBtn.TextColor3=White end)
end)

-- ══════════════════════════════════════════
-- CERRAR
-- ══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    disableGalaxySkyBright(); toggleAntiRagdoll(false); disableAutoSteal(); disableUnwalk(); disableESP()
    stopAutoLeft(); stopAutoRight(); stopAutoLeftPlay(); stopAutoRightPlay()
    local t = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0),
    })
    t:Play(); t.Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- ══════════════════════════════════════════
-- DRAG
-- ══════════════════════════════════════════
local dragging, dragStart, startPos, miniStartPos = false, nil, nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging      = true
        dragStart     = inp.Position
        startPos      = Main.Position
        miniStartPos  = MiniPanel.Position
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        MiniPanel.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + d.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + d.Y)
    end
end)

-- ══════════════════════════════════════════
-- ANIMACION ENTRADA
-- ══════════════════════════════════════════
Main.Size = UDim2.new(0,0,0,0)
Main.Position = UDim2.new(0.5,0,0.5,0)
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size=UDim2.new(0,GUI_W,0,GUI_H), Position=UDim2.new(0.5,-GUI_W/2,0.5,-GUI_H/2),
}):Play()
