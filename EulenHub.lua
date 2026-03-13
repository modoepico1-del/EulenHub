local Lighting = game:GetService("Lighting")

for _, v in ipairs(Lighting:GetChildren()) do
    v:Destroy()
end

Lighting.Ambient              = Color3.fromRGB(70, 90, 155)
Lighting.OutdoorAmbient       = Color3.fromRGB(75, 95, 160)
Lighting.Brightness           = 0.0
Lighting.ClockTime            = 0.0
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = false
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999
Lighting.FogStart             = 9998
Lighting.FogColor             = Color3.fromRGB(0, 0, 0)
Lighting.ExposureCompensation = 0.0

local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness   =  0.0
CC.Contrast     =  0.20
CC.Saturation   =  1.10
CC.TintColor    = Color3.fromRGB(180, 195, 255)
CC.Parent       = Lighting

local Sky = Instance.new("Sky")
Sky.StarCount            = 5000
Sky.CelestialBodiesShown = false
Sky.Parent               = Lighting
