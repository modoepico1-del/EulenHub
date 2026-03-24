-- ╔══════════════════════════════════════════════════╗
-- ║           NEON HUB - Script Roblox               ║
-- ║         500x500 | Sin funciones | Sin opciones   ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════
--  COLORES (basados en la imagen)
-- ══════════════════════════════════════
local Colors = {
    HotPink    = Color3.fromRGB(255, 0, 170),   -- Franja 1: Rosa fuerte
    Violet     = Color3.fromRGB(160, 0, 220),   -- Franja 2: Violeta
    DeepBlue   = Color3.fromRGB(60,  0, 200),   -- Franja 3: Azul profundo
    Cyan       = Color3.fromRGB(0,  180, 255),   -- Franja 4: Cian
    LightCyan  = Color3.fromRGB(0,  240, 255),   -- Franja 5: Cian claro
    White      = Color3.fromRGB(255, 255, 255),
    Dark       = Color3.fromRGB(10,   5,  30),
    Transparent = Color3.fromRGB(20,  10,  50),
}

-- ══════════════════════════════════════
--  CREAR SCREENGUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeonHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- ══════════════════════════════════════
--  MARCO PRINCIPAL (500x500)
-- ══════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 500)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -250)
MainFrame.BackgroundColor3 = Colors.Dark
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Esquinas redondeadas
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

-- Sombra exterior simulada
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Colors.HotPink
Shadow.ImageTransparency = 0.6
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.ZIndex = 0
Shadow.Parent = MainFrame

-- ══════════════════════════════════════
--  FONDO GRADIENTE (5 franjas verticales)
-- ══════════════════════════════════════
local BgGradient = Instance.new("Frame")
BgGradient.Name = "BgGradient"
BgGradient.Size = UDim2.new(1, 0, 1, 0)
BgGradient.Position = UDim2.new(0, 0, 0, 0)
BgGradient.BackgroundColor3 = Colors.Dark
BgGradient.BorderSizePixel = 0
BgGradient.ZIndex = 1
BgGradient.Parent = MainFrame

local BgUIGradient = Instance.new("UIGradient")
BgUIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Colors.HotPink),
    ColorSequenceKeypoint.new(0.25, Colors.Violet),
    ColorSequenceKeypoint.new(0.50, Colors.DeepBlue),
    ColorSequenceKeypoint.new(0.75, Colors.Cyan),
    ColorSequenceKeypoint.new(1.00, Colors.LightCyan),
})
BgUIGradient.Rotation = 180
BgUIGradient.Parent = BgGradient

-- Overlay oscuro para que el texto sea legible
local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Colors.Dark
Overlay.BackgroundTransparency = 0.45
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 2
Overlay.Parent = MainFrame

-- ══════════════════════════════════════
--  BARRA SUPERIOR (Header)
-- ══════════════════════════════════════
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 56)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Colors.Dark
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0
Header.ZIndex = 3
Header.Parent = MainFrame

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.5, Colors.Violet),
    ColorSequenceKeypoint.new(1.0, Colors.DeepBlue),
})
HeaderGradient.Rotation = 90
HeaderGradient.Parent = Header

-- Línea decorativa bajo el header
local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 2)
HeaderLine.Position = UDim2.new(0, 0, 1, -2)
HeaderLine.BackgroundColor3 = Colors.LightCyan
HeaderLine.BackgroundTransparency = 0.2
HeaderLine.BorderSizePixel = 0
HeaderLine.ZIndex = 4
HeaderLine.Parent = Header

local HeaderLineGrad = Instance.new("UIGradient")
HeaderLineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.5, Colors.Cyan),
    ColorSequenceKeypoint.new(1.0, Colors.LightCyan),
})
HeaderLineGrad.Parent = HeaderLine

-- ══════════════════════════════════════
--  TÍTULO DEL HUB
-- ══════════════════════════════════════
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 18, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✦ NEON HUB ✦"
TitleLabel.TextColor3 = Colors.White
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5
TitleLabel.Parent = Header

-- Gradiente en el texto del título
local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.5, Colors.Cyan),
    ColorSequenceKeypoint.new(1.0, Colors.LightCyan),
})
TitleGradient.Parent = TitleLabel

-- ══════════════════════════════════════
--  BOTÓN CERRAR (X)
-- ══════════════════════════════════════
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseButton"
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -46, 0, 10)
CloseBtn.BackgroundColor3 = Colors.HotPink
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.White
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 6
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- ══════════════════════════════════════
--  SECCIÓN: DECORACIÓN / LOGO CENTRAL
-- ══════════════════════════════════════
local LogoFrame = Instance.new("Frame")
LogoFrame.Name = "LogoFrame"
LogoFrame.Size = UDim2.new(0, 110, 0, 110)
LogoFrame.Position = UDim2.new(0.5, -55, 0, 72)
LogoFrame.BackgroundColor3 = Colors.Transparent
LogoFrame.BackgroundTransparency = 0.1
LogoFrame.BorderSizePixel = 0
LogoFrame.ZIndex = 4
LogoFrame.Parent = MainFrame

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = LogoFrame

local LogoGradient = Instance.new("UIGradient")
LogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.5, Colors.Violet),
    ColorSequenceKeypoint.new(1.0, Colors.Cyan),
})
LogoGradient.Rotation = 135
LogoGradient.Parent = LogoFrame

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⬡"
LogoText.TextColor3 = Colors.White
LogoText.Font = Enum.Font.GothamBold
LogoText.TextSize = 52
LogoText.ZIndex = 5
LogoText.Parent = LogoFrame

-- ══════════════════════════════════════
--  ETIQUETA DE BIENVENIDA
-- ══════════════════════════════════════
local WelcomeLabel = Instance.new("TextLabel")
WelcomeLabel.Name = "Welcome"
WelcomeLabel.Size = UDim2.new(1, -40, 0, 30)
WelcomeLabel.Position = UDim2.new(0, 20, 0, 195)
WelcomeLabel.BackgroundTransparency = 1
WelcomeLabel.Text = "Bienvenido, " .. LocalPlayer.DisplayName
WelcomeLabel.TextColor3 = Colors.White
WelcomeLabel.Font = Enum.Font.GothamSemibold
WelcomeLabel.TextSize = 18
WelcomeLabel.TextXAlignment = Enum.TextXAlignment.Center
WelcomeLabel.ZIndex = 5
WelcomeLabel.Parent = MainFrame

-- ══════════════════════════════════════
--  SEPARADOR DECORATIVO
-- ══════════════════════════════════════
local function CreateDivider(yPos)
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(0, 360, 0, 2)
    Div.Position = UDim2.new(0.5, -180, 0, yPos)
    Div.BackgroundColor3 = Colors.Cyan
    Div.BackgroundTransparency = 0.4
    Div.BorderSizePixel = 0
    Div.ZIndex = 4
    Div.Parent = MainFrame

    local DivGrad = Instance.new("UIGradient")
    DivGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.2, Colors.HotPink),
        ColorSequenceKeypoint.new(0.5, Colors.Cyan),
        ColorSequenceKeypoint.new(0.8, Colors.Violet),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0,0,0)),
    })
    DivGrad.Parent = Div
    return Div
end

CreateDivider(235)
CreateDivider(430)

-- ══════════════════════════════════════
--  TARJETAS DE INFO (sin botones funcionales)
-- ══════════════════════════════════════
local InfoData = {
    { icon = "🎮", label = "Modo",    value = "Exploración" },
    { icon = "⚡", label = "Estado",  value = "Activo"      },
    { icon = "🌐", label = "Versión", value = "v1.0.0"      },
    { icon = "✦",  label = "Tier",    value = "Neon"        },
}

local CardStartX = 20
local CardY      = 250
local CardW      = 104
local CardH      = 80
local CardGap    = 8

for i, data in ipairs(InfoData) do
    local xPos = CardStartX + (i - 1) * (CardW + CardGap)

    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(0, CardW, 0, CardH)
    Card.Position = UDim2.new(0, xPos, 0, CardY)
    Card.BackgroundColor3 = Colors.Dark
    Card.BackgroundTransparency = 0.3
    Card.BorderSizePixel = 0
    Card.ZIndex = 5
    Card.Parent = MainFrame

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card

    local CardGradient = Instance.new("UIGradient")
    CardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Colors.Violet),
        ColorSequenceKeypoint.new(1.0, Colors.DeepBlue),
    })
    CardGradient.Rotation = 135
    CardGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0.7),
    })
    CardGradient.Parent = Card

    -- Borde brillante
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Colors.Cyan
    CardStroke.Transparency = 0.5
    CardStroke.Thickness = 1.2
    CardStroke.Parent = Card

    local IconLbl = Instance.new("TextLabel")
    IconLbl.Size = UDim2.new(1, 0, 0, 30)
    IconLbl.Position = UDim2.new(0, 0, 0, 8)
    IconLbl.BackgroundTransparency = 1
    IconLbl.Text = data.icon
    IconLbl.TextColor3 = Colors.LightCyan
    IconLbl.Font = Enum.Font.GothamBold
    IconLbl.TextSize = 22
    IconLbl.ZIndex = 6
    IconLbl.Parent = Card

    local KeyLbl = Instance.new("TextLabel")
    KeyLbl.Size = UDim2.new(1, -8, 0, 18)
    KeyLbl.Position = UDim2.new(0, 4, 0, 38)
    KeyLbl.BackgroundTransparency = 1
    KeyLbl.Text = data.label
    KeyLbl.TextColor3 = Colors.Cyan
    KeyLbl.Font = Enum.Font.Gotham
    KeyLbl.TextSize = 11
    KeyLbl.ZIndex = 6
    KeyLbl.Parent = Card

    local ValLbl = Instance.new("TextLabel")
    ValLbl.Size = UDim2.new(1, -8, 0, 20)
    ValLbl.Position = UDim2.new(0, 4, 0, 55)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text = data.value
    ValLbl.TextColor3 = Colors.White
    ValLbl.Font = Enum.Font.GothamBold
    ValLbl.TextSize = 13
    ValLbl.ZIndex = 6
    ValLbl.Parent = Card
end

-- ══════════════════════════════════════
--  BARRA DE PROGRESO DECORATIVA
-- ══════════════════════════════════════
local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(0, 460, 0, 14)
BarBg.Position = UDim2.new(0, 20, 0, 350)
BarBg.BackgroundColor3 = Colors.Dark
BarBg.BackgroundTransparency = 0.4
BarBg.BorderSizePixel = 0
BarBg.ZIndex = 5
BarBg.Parent = MainFrame

local BarBgCorner = Instance.new("UICorner")
BarBgCorner.CornerRadius = UDim.new(1, 0)
BarBgCorner.Parent = BarBg

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0.72, 0, 1, 0)
BarFill.BackgroundColor3 = Colors.HotPink
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 6
BarFill.Parent = BarBg

local BarFillCorner = Instance.new("UICorner")
BarFillCorner.CornerRadius = UDim.new(1, 0)
BarFillCorner.Parent = BarFill

local BarFillGrad = Instance.new("UIGradient")
BarFillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.4, Colors.Violet),
    ColorSequenceKeypoint.new(0.7, Colors.Cyan),
    ColorSequenceKeypoint.new(1.0, Colors.LightCyan),
})
BarFillGrad.Parent = BarFill

local BarLabel = Instance.new("TextLabel")
BarLabel.Size = UDim2.new(1, 0, 0, 18)
BarLabel.Position = UDim2.new(0, 0, 0, -20)
BarLabel.BackgroundTransparency = 1
BarLabel.Text = "NIVEL  ▸  72 / 100"
BarLabel.TextColor3 = Colors.LightCyan
BarLabel.Font = Enum.Font.GothamSemibold
BarLabel.TextSize = 12
BarLabel.TextXAlignment = Enum.TextXAlignment.Left
BarLabel.ZIndex = 6
BarLabel.Parent = BarBg

-- ══════════════════════════════════════
--  FOOTER
-- ══════════════════════════════════════
local Footer = Instance.new("Frame")
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 44)
Footer.Position = UDim2.new(0, 0, 1, -44)
Footer.BackgroundColor3 = Colors.Dark
Footer.BackgroundTransparency = 0.3
Footer.BorderSizePixel = 0
Footer.ZIndex = 3
Footer.Parent = MainFrame

local FooterGradient = Instance.new("UIGradient")
FooterGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.DeepBlue),
    ColorSequenceKeypoint.new(0.5, Colors.Cyan),
    ColorSequenceKeypoint.new(1.0, Colors.LightCyan),
})
FooterGradient.Rotation = 90
FooterGradient.Parent = Footer

local FooterLine = Instance.new("Frame")
FooterLine.Size = UDim2.new(1, 0, 0, 2)
FooterLine.Position = UDim2.new(0, 0, 0, 0)
FooterLine.BackgroundColor3 = Colors.Cyan
FooterLine.BackgroundTransparency = 0.3
FooterLine.BorderSizePixel = 0
FooterLine.ZIndex = 4
FooterLine.Parent = Footer

local FooterLineGrad = Instance.new("UIGradient")
FooterLineGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Colors.HotPink),
    ColorSequenceKeypoint.new(0.5, Colors.Cyan),
    ColorSequenceKeypoint.new(1.0, Colors.LightCyan),
})
FooterLineGrad.Parent = FooterLine

local FooterText = Instance.new("TextLabel")
FooterText.Size = UDim2.new(1, 0, 1, 0)
FooterText.BackgroundTransparency = 1
FooterText.Text = "✦  NEON HUB  •  2025  ✦"
FooterText.TextColor3 = Colors.White
FooterText.Font = Enum.Font.Gotham
FooterText.TextSize = 13
FooterText.ZIndex = 5
FooterText.Parent = Footer

-- ══════════════════════════════════════
--  ANIMACIÓN: Logo giratoria
-- ══════════════════════════════════════
local angle = 0
RunService.RenderStepped:Connect(function(dt)
    angle = angle + dt * 45
    LogoFrame.Rotation = angle % 360

    -- Pulso de color en el borde del header line
    local t = math.sin(tick() * 2) * 0.5 + 0.5
    HeaderLine.BackgroundTransparency = 0.1 + t * 0.6
end)

-- ══════════════════════════════════════
--  ANIMACIÓN: Entrada del Hub
-- ══════════════════════════════════════
MainFrame.Position = UDim2.new(0.5, -250, 1.5, 0)
MainFrame.BackgroundTransparency = 1

local tweenIn = TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -250, 0.5, -250),
    BackgroundTransparency = 0,
})
tweenIn:Play()

-- ══════════════════════════════════════
--  BOTÓN CERRAR: Acción
-- ══════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    local tweenOut = TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -250, 1.5, 0),
        BackgroundTransparency = 1,
    })
    tweenOut:Play()
    tweenOut.Completed:Connect(function()
        ScreenGui:Destroy()
    end)
end)

-- ══════════════════════════════════════
--  ARRASTRAR HUB (Drag)
-- ══════════════════════════════════════
local dragging, dragInput, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = MainFrame.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
