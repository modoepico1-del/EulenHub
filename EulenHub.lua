local Lighting     = game:GetService("Lighting")
local Players      = game:GetService("Players")

-- limpiar todo
for _, v in ipairs(Lighting:GetChildren()) do
    v:Destroy()
end

-- iluminacion base noche
Lighting.Ambient              = Color3.fromRGB(60, 80, 140)
Lighting.OutdoorAmbient       = Color3.fromRGB(65, 85, 145)
Lighting.Brightness           = 0.0
Lighting.ClockTime            = 0.0
Lighting.GlobalShadows        = false
Lighting.ShadowSoftness       = 0.0
Lighting.FogEnd               = 9999
Lighting.FogStart             = 9998
Lighting.ExposureCompensation = 0.0

-- color correction sin brillo
local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness = -0.10          -- ligeramente mas oscuro
CC.Contrast   =  0.15
CC.Saturation =  1.00
CC.TintColor  = Color3.fromRGB(170, 185, 255)
CC.Parent     = Lighting

-- cielo oscuro
local Sky = Instance.new("Sky")
Sky.StarCount            = 4000
Sky.CelestialBodiesShown = false
Sky.Parent               = Lighting

-- FILTRO AZUL OSCURO ENCIMA DE LA PANTALLA
local lp = Players.LocalPlayer
local sg = Instance.new("ScreenGui")
sg.Name          = "DemontimeFilter"
sg.ResetOnSpawn  = false
sg.DisplayOrder  = -999          -- detras de todo el resto de GUI
sg.Parent        = lp.PlayerGui

local filtro = Instance.new("Frame")
filtro.Size                 = UDim2.new(1, 0, 1, 0)
filtro.Position             = UDim2.new(0, 0, 0, 0)
filtro.BackgroundColor3     = Color3.fromRGB(5, 10, 40)   -- azul muy oscuro
filtro.BackgroundTransparency = 0.45                       -- 45% opaco = apagado pero visible
filtro.BorderSizePixel      = 0
filtro.ZIndex               = 1
filtro.Parent               = sg
