local Lighting = game:GetService("Lighting")
local Players  = game:GetService("Players")

for _, v in ipairs(Lighting:GetChildren()) do
    v:Destroy()
end

Lighting.Ambient              = Color3.fromRGB(35, 45, 90)
Lighting.OutdoorAmbient       = Color3.fromRGB(35, 45, 90)
Lighting.Brightness           = 0.0
Lighting.ClockTime            = 0.0
Lighting.GlobalShadows        = false
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999
Lighting.FogStart             = 9998
Lighting.ExposureCompensation = 0.0

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness = -0.15
CC.Contrast   =  0.10
CC.Saturation =  0.85
CC.TintColor  = Color3.fromRGB(140, 155, 230)
CC.Parent     = Lighting

local Sky = Instance.new("Sky")
Sky.StarCount            = 3000
Sky.CelestialBodiesShown = false
Sky.Parent               = Lighting

-- filtro azul oscuro encima de pantalla
local lp = Players.LocalPlayer
if lp.PlayerGui:FindFirstChild("DemontimeFilter") then
    lp.PlayerGui:FindFirstChild("DemontimeFilter"):Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name         = "DemontimeFilter"
sg.ResetOnSpawn = false
sg.DisplayOrder = -999
sg.Parent       = lp.PlayerGui

local filtro = Instance.new("Frame")
filtro.Size                   = UDim2.new(1, 0, 1, 0)
filtro.Position               = UDim2.new(0, 0, 0, 0)
filtro.BackgroundColor3       = Color3.fromRGB(3, 8, 35)
filtro.BackgroundTransparency = 0.40
filtro.BorderSizePixel        = 0
filtro.Parent                 = sg
