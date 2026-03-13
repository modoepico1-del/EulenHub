-- ╔══════════════════════════════════════╗
-- ║    DEMONTIME - ILUMINACION EXACTA    ║
-- ╚══════════════════════════════════════╝

local Lighting    = game:GetService("Lighting")
local Players     = game:GetService("Players")
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
--  ILUMINACION BASE (luz plana y pareja)
-- ══════════════════════════════════════

Lighting.Ambient              = Color3.fromRGB(200, 200, 200)  -- ambiente MUY claro
Lighting.OutdoorAmbient       = Color3.fromRGB(210, 210, 210)  -- exterior blanquecino
Lighting.Brightness           = 4.0                            -- maximo brillo
Lighting.ClockTime            = 12.0                           -- mediodia exacto
Lighting.GeographicLatitude   = 0                              -- ecuador = sol directo
Lighting.GlobalShadows        = false                          -- sin sombras = look cartoon
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999                           -- sin niebla
Lighting.FogStart             = 9998
Lighting.ExposureCompensation = 1.0                            -- maxima exposicion

-- ══════════════════════════════════════
--  COLOR CORRECTION
-- ══════════════════════════════════════

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.10     -- mas claro todavia
CC.Contrast     =  0.50     -- contraste que hace los colores nítidos
CC.Saturation   =  1.8      -- saturacion muy alta = colores cartoon puros
CC.TintColor    = Color3.fromRGB(255, 255, 255)  -- sin tinte, colores puros
CC.Parent       = Lighting

-- ══════════════════════════════════════
--  BLOOM SUAVE
-- ══════════════════════════════════════

local Bloom = Instance.new("BloomEffect")
Bloom.Intensity = 0.3
Bloom.Size      = 10
Bloom.Threshold = 0.98       -- solo en lo muy brillante
Bloom.Parent    = Lighting

-- ══════════════════════════════════════
--  ATMOSFERA MINIMA (cielo azul vivo)
-- ══════════════════════════════════════

local Atmo = Instance.new("Atmosphere")
Atmo.Density = 0.05           -- aire completamente limpio
Atmo.Offset  = 0.0
Atmo.Color   = Color3.fromRGB(100, 170, 255)   -- azul cielo vivo
Atmo.Decay   = Color3.fromRGB(60, 120, 220)
Atmo.Glare   = 0.1
Atmo.Haze    = 0.0            -- cero neblina
Atmo.Parent  = Lighting

-- ══════════════════════════════════════
--  CIELO
-- ══════════════════════════════════════

local Sky = Instance.new("Sky")
Sky.StarCount            = 0
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
lbl.Text             = "DEMONTIME | Iluminacion cargada"
lbl.Size             = UDim2.new(0, 300, 0, 32)
lbl.Position         = UDim2.new(0.5, -150, 0, 14)
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

print("DEMONTIME | Iluminacion exacta cargada")
