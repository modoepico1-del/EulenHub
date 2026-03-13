-- ╔══════════════════════════════════════╗
-- ║   DEMONTIME - ILUMINACION LIMPIA     ║
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

Lighting.Ambient              = Color3.fromRGB(130, 120, 160)
Lighting.OutdoorAmbient       = Color3.fromRGB(140, 125, 170)
Lighting.Brightness           = 1.3                            -- brillo reducido
Lighting.ClockTime            = 14.0
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = false
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999
Lighting.FogStart             = 9998
Lighting.FogColor             = Color3.fromRGB(180, 160, 220)
Lighting.ExposureCompensation = -0.2                           -- un poco menos expuesto

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.0
CC.Contrast     =  0.20
CC.Saturation   =  1.40
CC.TintColor    = Color3.fromRGB(210, 185, 255)  -- violeta suave como la foto
CC.Parent       = Lighting

local Sky = Instance.new("Sky")
Sky.StarCount            = 0
Sky.CelestialBodiesShown = true
Sky.Parent               = Lighting

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

print("DEMONTIME | Iluminacion violeta cargada")
