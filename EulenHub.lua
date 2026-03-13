local Lighting = game:GetService("Lighting")
local Players  = game:GetService("Players")

-- quitar filtro de pantalla si existe
if Players.LocalPlayer.PlayerGui:FindFirstChild("DemontimeFilter") then
    Players.LocalPlayer.PlayerGui:FindFirstChild("DemontimeFilter"):Destroy()
end

-- borrar todos los efectos
for _, v in ipairs(Lighting:GetChildren()) do
    v:Destroy()
end

-- valores exactos default de Roblox
Lighting.Ambient              = Color3.fromRGB(70, 70, 70)
Lighting.OutdoorAmbient       = Color3.fromRGB(140, 140, 140)
Lighting.Brightness           = 2.0
Lighting.ClockTime            = 14.0
Lighting.GeographicLatitude   = 41.7
Lighting.GlobalShadows        = true
Lighting.ShadowSoftness       = 0.2
Lighting.FogEnd               = 100000
Lighting.FogStart             = 0
Lighting.ExposureCompensation = 0.0
