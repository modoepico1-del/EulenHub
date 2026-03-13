-- ╔══════════════════════════════════════╗
-- ║   DEMONTIME - APAGADO EXACTO         ║
-- ╚══════════════════════════════════════╝

local Lighting     = game:GetService("Lighting")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ══════════════════════════════════════
--  LIMPIAR ABSOLUTAMENTE TODO
-- ══════════════════════════════════════

for _, v in ipairs(Lighting:GetChildren()) do
    v:Destroy()
end

-- ══════════════════════════════════════
--  SOLO CONFIGURACION BASE
-- ══════════════════════════════════════

Lighting.Ambient              = Color3.fromRGB(70, 90, 155)   -- azul marino que ilumina todo
Lighting.OutdoorAmbient       = Color3.fromRGB(75, 95, 160)
Lighting.Brightness           = 0.0                            -- sol APAGADO
Lighting.ClockTime            = 0.0                            -- medianoche
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = false                          -- sin sombras
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999
Lighting.FogStart             = 9998
Lighting.FogColor             = Color3.fromRGB(0, 0, 0)
Lighting.ExposureCompensation = 0.0                            -- sin exposicion extra

-- ══════════════════════════════════════
--  UN SOLO EFECTO: COLOR CORRECTION
-- ══════════════════════════════════════

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.0
CC.Contrast     =  0.20
CC.Saturation   =  1.10                                        -- colores normales
CC.TintColor    = Color3.fromRGB(180, 195, 255)                -- tinte azul suave
CC.Parent       = Lighting

-- ══════════════════════════════════════
--  CIELO OSCURO
-- ══════════════════════════════════════

local Sky = Instance.new("Sky")
Sky.StarCount            = 5000
Sky.CelestialBodiesShown = false                               -- sin luna ni sol
Sky.Parent               = Lighting

-- ══════════════════════════════════════
--  MENSAJE
-- ══════════════════════════════════════

local lp  = Players.LocalPlayer
local sg  = Instance.new("ScreenGui")
sg.ResetOnSpawn = false
sg.Parent       = lp.PlayerGui

local lbl = Instance.new("TextLabel")
lbl.Text             = "DEMONTIME | Apagado activado"
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

print("DEMONTIME | Apagado exacto cargado")
