-- ╔══════════════════════════════════════╗
-- ║   DEMONTIME - ILUMINACION GALAXY     ║
-- ╚══════════════════════════════════════╝

local Lighting     = game:GetService("Lighting")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ══════════════════════════════════════
--  LIMPIAR TODO
-- ══════════════════════════════════════

for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("ColorCorrectionEffect")
    or v:IsA("BloomEffect")
    or v:IsA("BlurEffect")
    or v:IsA("SunRaysEffect")
    or v:IsA("DepthOfFieldEffect")
    or v:IsA("Atmosphere")
    or v:IsA("Sky") then
        v:Destroy()
    end
end

-- ══════════════════════════════════════
--  ILUMINACION BASE GALAXY
-- ══════════════════════════════════════

Lighting.Ambient              = Color3.fromRGB(40, 20, 80)    -- morado galaxia oscuro
Lighting.OutdoorAmbient       = Color3.fromRGB(50, 25, 100)   -- exterior violeta profundo
Lighting.Brightness           = 1.4                            -- brillo moderado, no cega
Lighting.ClockTime            = 0.0                            -- medianoche
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = true
Lighting.ShadowSoftness       = 0.8
Lighting.FogEnd               = 600
Lighting.FogStart             = 200
Lighting.FogColor             = Color3.fromRGB(20, 5, 50)     -- niebla morada espacial
Lighting.ExposureCompensation = 0.2                            -- exposicion suave

-- ══════════════════════════════════════
--  COLOR CORRECTION (look galaxia)
-- ══════════════════════════════════════

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.02
CC.Contrast     =  0.40     -- contraste medio para ver bien
CC.Saturation   =  0.90     -- saturado pero no exagerado
CC.TintColor    = Color3.fromRGB(170, 140, 255)  -- tinte purpura galaxia
CC.Parent       = Lighting

-- ══════════════════════════════════════
--  BLOOM (brillo neon suave)
-- ══════════════════════════════════════

local Bloom = Instance.new("BloomEffect")
Bloom.Intensity = 0.5        -- bloom suave, no excesivo
Bloom.Size      = 20
Bloom.Threshold = 0.80
Bloom.Parent    = Lighting

-- ══════════════════════════════════════
--  ATMOSFERA ESPACIAL
-- ══════════════════════════════════════

local Atmo = Instance.new("Atmosphere")
Atmo.Density = 0.35
Atmo.Offset  = 0.20
Atmo.Color   = Color3.fromRGB(60, 20, 120)    -- purpura espacial
Atmo.Decay   = Color3.fromRGB(15, 5, 40)      -- decay muy oscuro
Atmo.Glare   = 0.0
Atmo.Haze    = 1.2
Atmo.Parent  = Lighting

-- ══════════════════════════════════════
--  CIELO ESTRELLADO GALAXY
-- ══════════════════════════════════════

local oldSky = Lighting:FindFirstChildOfClass("Sky")
if oldSky then oldSky:Destroy() end

local Sky = Instance.new("Sky")
Sky.StarCount            = 8000   -- muchas estrellas
Sky.CelestialBodiesShown = true
Sky.Parent               = Lighting

-- ══════════════════════════════════════
--  PUNTO DE LUZ GALAXY (PointLight en el sol)
-- ══════════════════════════════════════

-- Luz ambiental extra con color galaxia
local sunPart = Instance.new("Part")
sunPart.Anchored        = true
sunPart.CanCollide      = false
sunPart.Transparency    = 1
sunPart.Size            = Vector3.new(1, 1, 1)
sunPart.Position        = Vector3.new(0, 500, 0)
sunPart.Parent          = workspace

local galaxyLight = Instance.new("PointLight")
galaxyLight.Color       = Color3.fromRGB(130, 60, 255)  -- purpura galaxia
galaxyLight.Brightness  = 2.0
galaxyLight.Range       = 999
galaxyLight.Shadows     = false
galaxyLight.Parent      = sunPart

-- ══════════════════════════════════════
--  MENSAJE
-- ══════════════════════════════════════

local lp  = Players.LocalPlayer
local sg  = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent       = lp.PlayerGui

local lbl = Instance.new("TextLabel")
lbl.Text             = "DEMONTIME | Galaxy activado"
lbl.Size             = UDim2.new(0, 280, 0, 32)
lbl.Position         = UDim2.new(0.5, -140, 0, 14)
lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lbl.TextColor3       = Color3.fromRGB(180, 80, 255)
lbl.TextSize         = 13
lbl.Font             = Enum.Font.GothamBlack
lbl.BorderSizePixel  = 0
lbl.Parent           = sg

local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 6)
lc.Parent = lbl

local ls = Instance.new("UIStroke")
ls.Color     = Color3.fromRGB(180, 80, 255)
ls.Thickness = 1.2
ls.Parent    = lbl

TweenService:Create(lbl,
    TweenInfo.new(0.5, Enum.EasingStyle.Quad,
    Enum.EasingDirection.In, 0, false, 2.5),
    { TextTransparency = 1, BackgroundTransparency = 1 }
):Play()

task.delay(3.2, function() sg:Destroy() end)

print("DEMONTIME | Galaxy iluminacion cargada")
