-- ╔══════════════════════════════════════╗
-- ║   DEMONTIME - NOCHE CLARA EXACTA     ║
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
--  ILUMINACION: NOCHE PERO SE VE TODO
-- ══════════════════════════════════════

Lighting.Ambient              = Color3.fromRGB(80, 100, 160)   -- azul claro fuerte
Lighting.OutdoorAmbient       = Color3.fromRGB(90, 110, 170)   -- exterior igual
Lighting.Brightness           = 0.0                             -- SIN brillo de sol
Lighting.ClockTime            = 0.0                             -- medianoche
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = false                           -- sin sombras
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999                            -- sin niebla
Lighting.FogStart             = 9998
Lighting.FogColor              = Color3.fromRGB(10, 15, 50)
Lighting.ExposureCompensation = 0.0

-- ══════════════════════════════════════
--  COLOR CORRECTION
-- ══════════════════════════════════════

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.0
CC.Contrast     =  0.25
CC.Saturation   =  1.20
CC.TintColor    = Color3.fromRGB(175, 190, 255)   -- tinte azul marino suave
CC.Parent       = Lighting

-- ══════════════════════════════════════
--  SIN BLOOM -- apagado total
-- ══════════════════════════════════════

-- No se agrega BloomEffect
-- No se agrega SunRaysEffect
-- No se agrega Atmosphere

-- ══════════════════════════════════════
--  CIELO NOCHE CON ESTRELLAS
-- ══════════════════════════════════════

local Sky = Instance.new("Sky")
Sky.StarCount            = 5000
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
lbl.Text             = "DEMONTIME | Noche clara activada"
lbl.Size             = UDim2.new(0, 290, 0, 32)
lbl.Position         = UDim2.new(0.5, -145, 0, 14)
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

print("DEMONTIME | Noche clara cargada")
