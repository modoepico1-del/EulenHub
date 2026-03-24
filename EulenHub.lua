-- KMONEY HUB - 500x300

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- Colores pastel de la foto
local Pink    = Color3.fromRGB(255, 182, 193)  -- Rosa pastel
local Lavender= Color3.fromRGB(200, 195, 240)  -- Lavanda pastel
local SkyBlue = Color3.fromRGB(110, 195, 220)  -- Azul cielo pastel
local White   = Color3.fromRGB(255, 255, 255)
local Dark    = Color3.fromRGB(60,  50,  80)
local TextCol = Color3.fromRGB(80,  60,  100)

-- Limpiar hub anterior
if PlayerGui:FindFirstChild("KmoneyHub") then
    PlayerGui:FindFirstChild("KmoneyHub"):Destroy()
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "KmoneyHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent       = PlayerGui

-- Marco principal 500x300
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 500, 0, 300)
Main.Position         = UDim2.new(0.5, -250, 0.5, -150)
Main.BackgroundColor3 = White
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

-- Gradiente de fondo (rosa -> lavanda -> azul)
local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0,  Pink),
    ColorSequenceKeypoint.new(0.5,  Lavender),
    ColorSequenceKeypoint.new(1.0,  SkyBlue),
})
BgGrad.Rotation = 90
BgGrad.Parent = Main

-- Sombra
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, 8)
Shadow.BackgroundColor3 = Color3.fromRGB(180, 160, 200)
Shadow.BackgroundTransparency = 0.6
Shadow.BorderSizePixel = 0
Shadow.ZIndex = 0
Shadow.Parent = Main
local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 18)
ShadowCorner.Parent = Shadow

-- Header bar
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 52)
Header.Position         = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = White
Header.BackgroundTransparency = 0.55
Header.BorderSizePixel  = 0
Header.ZIndex           = 3
Header.Parent           = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

-- Línea bajo el header
local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1.5)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3 = White
HeaderLine.BackgroundTransparency = 0.3
HeaderLine.BorderSizePixel = 0
HeaderLine.ZIndex = 4
HeaderLine.Parent = Header

-- Título
local Title = Instance.new("TextLabel")
Title.Size                   = UDim2.new(1, -60, 1, 0)
Title.Position               = UDim2.new(0, 18, 0, 0)
Title.BackgroundTransparency = 1
Title.Text                   = "Kmoney"
Title.TextColor3             = White
Title.Font                   = Enum.Font.GothamBlack
Title.TextSize               = 20
Title.TextXAlignment         = Enum.TextXAlignment.Left
Title.ZIndex                 = 5
Title.Parent                 = Header

-- Stroke en título para legibilidad
local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(160, 130, 180)
TitleStroke.Thickness = 1.5
TitleStroke.Transparency = 0.3
TitleStroke.Parent = Title

-- Botón cerrar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 30, 0, 30)
CloseBtn.Position         = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3 = White
CloseBtn.BackgroundTransparency = 0.4
CloseBtn.Text             = "x"
CloseBtn.TextColor3       = Color3.fromRGB(180, 100, 140)
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 15
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 6
CloseBtn.Parent           = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Área de contenido
local Content = Instance.new("Frame")
Content.Size                 = UDim2.new(1, -24, 1, -68)
Content.Position             = UDim2.new(0, 12, 0, 60)
Content.BackgroundTransparency = 1
Content.ZIndex               = 3
Content.Parent               = Main

-- Helper: crear toggle
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeToggle(labelText, yPos)
    local Row = Instance.new("Frame")
    Row.Size             = UDim2.new(1, 0, 0, 48)
    Row.Position         = UDim2.new(0, 0, 0, yPos)
    Row.BackgroundColor3 = White
    Row.BackgroundTransparency = 0.45
    Row.BorderSizePixel  = 0
    Row.ZIndex           = 4
    Row.Parent           = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = White
    Stroke.Transparency = 0.5
    Stroke.Thickness = 1
    Stroke.Parent = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                   = UDim2.new(1, -80, 1, 0)
    Lbl.Position               = UDim2.new(0, 14, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = labelText
    Lbl.TextColor3             = White
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 14
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left
    Lbl.ZIndex                 = 5
    Lbl.Parent                 = Row

    local BtnTrack = Instance.new("TextButton")
    BtnTrack.Size             = UDim2.new(0, 46, 0, 24)
    BtnTrack.Position         = UDim2.new(1, -58, 0.5, -12)
    BtnTrack.BackgroundColor3 = White
    BtnTrack.BackgroundTransparency = 0.5
    BtnTrack.Text             = ""
    BtnTrack.BorderSizePixel  = 0
    BtnTrack.ZIndex           = 5
    BtnTrack.Parent           = Row
    Instance.new("UICorner", BtnTrack).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size             = UDim2.new(0, 18, 0, 18)
    Knob.Position         = UDim2.new(0, 3, 0.5, -9)
    Knob.BackgroundColor3 = Color3.fromRGB(200, 170, 210)
    Knob.BorderSizePixel  = 0
    Knob.ZIndex           = 6
    Knob.Parent           = BtnTrack
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    return BtnTrack, Knob
end

-- Toggle 1: Auto Steal
local stealOn = false
local B1, K1 = makeToggle("Auto Steal", 0)
B1.MouseButton1Click:Connect(function()
    stealOn = not stealOn
    if stealOn then
        TweenService:Create(K1, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(110,195,220)}):Play()
    else
        TweenService:Create(K1, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- Toggle 2: Anti Ragdoll
local ragOn = false
local B2, K2 = makeToggle("Anti Ragdoll", 56)
B2.MouseButton1Click:Connect(function()
    ragOn = not ragOn
    if ragOn then
        TweenService:Create(K2, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(110,195,220)}):Play()
    else
        TweenService:Create(K2, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- Toggle 3: XRAY
local xrayOn = false
local B3, K3 = makeToggle("XRAY", 112)
B3.MouseButton1Click:Connect(function()
    xrayOn = not xrayOn
    if xrayOn then
        TweenService:Create(K3, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(110,195,220)}):Play()
    else
        TweenService:Create(K3, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- Toggle 4: Dark Mode
local darkOn = false
local B4, K4 = makeToggle("Dark Mode", 168)
B4.MouseButton1Click:Connect(function()
    darkOn = not darkOn
    if darkOn then
        TweenService:Create(K4, ti, {Position = UDim2.new(1,-21,0.5,-9), BackgroundColor3 = Color3.fromRGB(110,195,220)}):Play()
    else
        TweenService:Create(K4, ti, {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- Cerrar
CloseBtn.MouseButton1Click:Connect(function()
    local t = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    t:Play()
    t.Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- Drag
local dragging, dragStart, startPos = false, nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; startPos = Main.Position
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Animación de entrada
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 500, 0, 300),
    Position = UDim2.new(0.5, -250, 0.5, -150),
}):Play()
