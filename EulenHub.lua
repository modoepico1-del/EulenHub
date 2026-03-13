-- ╔══════════════════════════════════════╗
-- ║   DEMONTIME - ILUMINACION EXACTA     ║
-- ╚══════════════════════════════════════╝

local Lighting     = game:GetService("Lighting")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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
--  ILUMINACION BASE
-- ══════════════════════════════════════

Lighting.Ambient              = Color3.fromRGB(20, 30, 70)    -- azul oscuro como la foto
Lighting.OutdoorAmbient       = Color3.fromRGB(25, 35, 80)    -- exterior azul marino
Lighting.Brightness           = 1.0                            -- brillo moderado oscuro
Lighting.ClockTime            = 20.0                           -- noche temprana
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = true
Lighting.ShadowSoftness       = 0.5
Lighting.FogEnd               = 800
Lighting.FogStart             = 400
Lighting.FogColor             = Color3.fromRGB(10, 15, 50)    -- niebla azul oscura
Lighting.ExposureCompensation = -0.1

-- ══════════════════════════════════════
--  COLOR CORRECTION
-- ══════════════════════════════════════

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.0
CC.Contrast     =  0.30               -- contraste que hace los colores nítidos
CC.Saturation   =  1.30               -- colores vividos sin exagerar
CC.TintColor    = Color3.fromRGB(160, 180, 255)  -- tinte azul marino de la foto
CC.Parent       = Lighting

-- ══════════════════════════════════════
--  BLOOM MUY SUAVE
-- ══════════════════════════════════════

local Bloom = Instance.new("BloomEffect")
Bloom.Intensity = 0.25
Bloom.Size      = 12
Bloom.Threshold = 0.92
Bloom.Parent    = Lighting

-- ══════════════════════════════════════
--  ATMOSFERA OSCURA AZULADA
-- ══════════════════════════════════════

local Atmo = Instance.new("Atmosphere")
Atmo.Density = 0.30
Atmo.Offset  = 0.10
Atmo.Color   = Color3.fromRGB(20, 40, 120)    -- azul marino profundo
Atmo.Decay   = Color3.fromRGB(8, 15, 50)
Atmo.Glare   = 0.0
Atmo.Haze    = 0.8
Atmo.Parent  = Lighting

-- ══════════════════════════════════════
--  CIELO AZUL OSCURO CON ESTRELLAS
-- ══════════════════════════════════════

local Sky = Instance.new("Sky")
Sky.StarCount            = 4000
Sky.CelestialBodiesShown = true
Sky.Parent               = Lighting

-- ══════════════════════════════════════
--  MENSAJE
-- ══════════════════════════════════════

local lp  = Players.LocalPlayer
local sg  = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent       = lp.PlayerGui

local lbl = Instance.new("TextLabel")
lbl.Text             = "DEMONTIME | Iluminacion lista"
lbl.Size             = UDim2.new(0, 270, 0, 32)
lbl.Position         = UDim2.new(0.5, -135, 0, 14)
lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
lbl.TextColor3       = Color3.fromRGB(255, 0, 0)
lbl.TextSize         = 13
lbl.Font             = Enum.Font.GothamBlack
lbl.BorderSizePixel  = 0
lbl.Parent           = sg

local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 6)
lc.Parent = lbl

local ls = Instance.new("UIStroke")
ls.Color     = Color3.fromRGB(255, 0, 0)
ls.Thickness = 1.2
ls.Parent    = lbl

TweenService:Create(lbl,
    TweenInfo.new(0.5, Enum.EasingStyle.Quad,
    Enum.EasingDirection.In, 0, false, 2.5),
    { TextTransparency = 1, BackgroundTransparency = 1 }
):Play()

task.delay(3.2, function() sg:Destroy() end)

print("DEMONTIME | Iluminacion oscura colorida cargada")
