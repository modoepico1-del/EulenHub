-- DEMONTIMEDuelsGUI Lua Script
-- Compatible with Roblox LocalScript

local Players = game:GetService('Players')
local _LocalPlayer23 = Players.LocalPlayer

local _call104 = Color3.fromRGB(15, 10, 25)
local accentColor = Color3.fromRGB(180, 0, 255)
local accentRed = Color3.fromRGB(200, 30, 60)
local textColor = Color3.fromRGB(230, 210, 255)
local borderColor = Color3.fromRGB(90, 0, 160)
local headerBg = Color3.fromRGB(25, 10, 45)

-- ScreenGui
local _call138 = Instance.new('ScreenGui')
_call138.Name = 'DEMONTIMEDuelsGUI'
_call138.ResetOnSpawn = false
_call138.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_call138.Parent = _LocalPlayer23:WaitForChild('PlayerGui')

-- Main Frame
local _call142 = Instance.new('Frame')
_call142.Name = 'Main'
_call142.Size = UDim2.new(0, 300, 0, 680)
_call142.Position = UDim2.new(0, 16, 0.5, -340)
_call142.BackgroundColor3 = _call104
_call142.BackgroundTransparency = 0
_call142.BorderSizePixel = 0
_call142.Active = true
_call142.Draggable = true
_call142.ClipsDescendants = true
_call142.Parent = _call138

local mainCorner = Instance.new('UICorner')
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = _call142

local mainStroke = Instance.new('UIStroke')
mainStroke.Color = accentColor
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = _call142

-- Header
local header = Instance.new('Frame')
header.Name = 'Header'
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = headerBg
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = _call142

local headerCorner = Instance.new('UICorner')
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerFix = Instance.new('Frame')
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = headerBg
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 2
headerFix.Parent = header

local headerLine = Instance.new('Frame')
headerLine.Name = 'AccentLine'
headerLine.Size = UDim2.new(1, 0, 0, 2)
headerLine.Position = UDim2.new(0, 0, 1, 0)
headerLine.BackgroundColor3 = accentColor
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 3
headerLine.Parent = header

local titleLabel = Instance.new('TextLabel')
titleLabel.Name = 'Title'
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = '☠ DEMONTIME DUELS'
titleLabel.TextColor3 = textColor
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = header

local closeBtn = Instance.new('TextButton')
closeBtn.Name = 'CloseButton'
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0.5, -15)
closeBtn.BackgroundColor3 = accentRed
closeBtn.BorderSizePixel = 0
closeBtn.Text = '✕'
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 4
closeBtn.Parent = header

local closeCorner = Instance.new('UICorner')
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    _call138:Destroy()
end)
