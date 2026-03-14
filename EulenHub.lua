-- DEMONTIMEDuelsGUI Lua Script
-- Compatible with Roblox LocalScript

local Players = game:GetService('Players')
local _LocalPlayer23 = Players.LocalPlayer

-- Color palette
local _call104 = Color3.fromRGB(15, 10, 25)         -- Dark background (deep dark purple/black)
local accentColor = Color3.fromRGB(180, 0, 255)      -- Demon purple accent
local accentRed = Color3.fromRGB(200, 30, 60)        -- Demon red
local textColor = Color3.fromRGB(230, 210, 255)      -- Soft lavender text
local dimText = Color3.fromRGB(130, 100, 160)        -- Dimmed text
local borderColor = Color3.fromRGB(90, 0, 160)       -- Border glow color
local headerBg = Color3.fromRGB(25, 10, 45)          -- Header background
local buttonBg = Color3.fromRGB(35, 12, 60)          -- Button background
local buttonHover = Color3.fromRGB(55, 20, 100)      -- Button hover

---------------------------------------------------------------
-- ScreenGui
---------------------------------------------------------------
local _call138 = Instance.new('ScreenGui')
_call138.Name = 'DEMONTIMEDuelsGUI'
_call138.ResetOnSpawn = false
_call138.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_call138.Parent = _LocalPlayer23:WaitForChild('PlayerGui')

---------------------------------------------------------------
-- Main Frame
---------------------------------------------------------------
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

-- Corner rounding
local mainCorner = Instance.new('UICorner')
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = _call142

-- Outer glow stroke
local mainStroke = Instance.new('UIStroke')
mainStroke.Color = accentColor
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = _call142

---------------------------------------------------------------
-- Header bar
---------------------------------------------------------------
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

-- Cover bottom corners of header
local headerFix = Instance.new('Frame')
headerFix.Size = UDim2.new(1, 0, 0, 10)
headerFix.Position = UDim2.new(0, 0, 1, -10)
headerFix.BackgroundColor3 = headerBg
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 2
headerFix.Parent = header

-- Accent line under header
local headerLine = Instance.new('Frame')
headerLine.Name = 'AccentLine'
headerLine.Size = UDim2.new(1, 0, 0, 2)
headerLine.Position = UDim2.new(0, 0, 1, 0)
headerLine.BackgroundColor3 = accentColor
headerLine.BorderSizePixel = 0
headerLine.ZIndex = 3
headerLine.Parent = header

-- Title label
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

-- Close button
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

---------------------------------------------------------------
-- Scroll / Content area
---------------------------------------------------------------
local contentFrame = Instance.new('ScrollingFrame')
contentFrame.Name = 'Content'
contentFrame.Size = UDim2.new(1, 0, 1, -52)
contentFrame.Position = UDim2.new(0, 0, 0, 52)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 3
contentFrame.ScrollBarImageColor3 = accentColor
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- auto-set later
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = _call142

local listLayout = Instance.new('UIListLayout')
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = contentFrame

local contentPad = Instance.new('UIPadding')
contentPad.PaddingTop = UDim.new(0, 12)
contentPad.PaddingBottom = UDim.new(0, 12)
contentPad.PaddingLeft = UDim.new(0, 12)
contentPad.PaddingRight = UDim.new(0, 12)
contentPad.Parent = contentFrame

---------------------------------------------------------------
-- Helper: Section label
---------------------------------------------------------------
local function createSection(parent, text, order)
    local lbl = Instance.new('TextLabel')
    lbl.LayoutOrder = order
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text:upper()
    lbl.TextColor3 = accentColor
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

---------------------------------------------------------------
-- Helper: Flat button
---------------------------------------------------------------
local function createButton(parent, text, order, callback)
    local btn = Instance.new('TextButton')
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = buttonBg
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = textColor
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    btn.Parent = parent

    local btnCorner = Instance.new('UICorner')
    btnCorner.CornerRadius = UDim.new(0, 7)
    btnCorner.Parent = btn

    local btnStroke = Instance.new('UIStroke')
    btnStroke.Color = borderColor
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5
    btnStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = buttonHover
        btnStroke.Transparency = 0
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = buttonBg
        btnStroke.Transparency = 0.5
    end)
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end

    return btn
end

---------------------------------------------------------------
-- Helper: Toggle button (on/off)
---------------------------------------------------------------
local function createToggle(parent, text, order, default, callback)
    local state = default or false

    local row = Instance.new('Frame')
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = buttonBg
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new('UICorner')
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new('UIStroke')
    rowStroke.Color = borderColor
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.5
    rowStroke.Parent = row

    local lbl = Instance.new('TextLabel')
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = textColor
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local toggleBg = Instance.new('Frame')
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
    toggleBg.BackgroundColor3 = state and accentColor or Color3.fromRGB(50, 30, 70)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = row

    local tbCorner = Instance.new('UICorner')
    tbCorner.CornerRadius = UDim.new(1, 0)
    tbCorner.Parent = toggleBg

    local knob = Instance.new('Frame')
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg

    local knobCorner = Instance.new('UICorner')
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local clickArea = Instance.new('TextButton')
    clickArea.Size = UDim2.new(1, 0, 1, 0)
    clickArea.BackgroundTransparency = 1
    clickArea.Text = ''
    clickArea.Parent = row

    clickArea.MouseButton1Click:Connect(function()
        state = not state
        toggleBg.BackgroundColor3 = state and accentColor or Color3.fromRGB(50, 30, 70)
        knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        if callback then callback(state) end
    end)

    return row
end

---------------------------------------------------------------
-- Helper: Separator
---------------------------------------------------------------
local function createSep(parent, order)
    local sep = Instance.new('Frame')
    sep.LayoutOrder = order
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = borderColor
    sep.BackgroundTransparency = 0.6
    sep.BorderSizePixel = 0
    sep.Parent = parent
    return sep
end

---------------------------------------------------------------
-- Helper: Info label
---------------------------------------------------------------
local function createInfoLabel(parent, text, order)
    local lbl = Instance.new('TextLabel')
    lbl.LayoutOrder = order
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = dimText
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = parent
    return lbl
end

---------------------------------------------------------------
-- Populate content
---------------------------------------------------------------
local o = 1 -- layout order counter

-- Stats display
createSection(contentFrame, '⚔ Duel Stats', o) o += 1

local statsFrame = Instance.new('Frame')
statsFrame.LayoutOrder = o; o += 1
statsFrame.Size = UDim2.new(1, 0, 0, 68)
statsFrame.BackgroundColor3 = headerBg
statsFrame.BorderSizePixel = 0
statsFrame.Parent = contentFrame

local sfCorner = Instance.new('UICorner')
sfCorner.CornerRadius = UDim.new(0, 7)
sfCorner.Parent = statsFrame

local sfStroke = Instance.new('UIStroke')
sfStroke.Color = borderColor
sfStroke.Thickness = 1
sfStroke.Transparency = 0.4
sfStroke.Parent = statsFrame

local function makeStat(parent, labelTxt, valueTxt, xOffset)
    local c = Instance.new('Frame')
    c.Size = UDim2.new(0.5, -10, 1, 0)
    c.Position = UDim2.new(0, xOffset, 0, 0)
    c.BackgroundTransparency = 1
    c.Parent = parent

    local vl = Instance.new('TextLabel')
    vl.Size = UDim2.new(1, 0, 0.55, 0)
    vl.Position = UDim2.new(0, 0, 0, 8)
    vl.BackgroundTransparency = 1
    vl.Text = valueTxt
    vl.TextColor3 = textColor
    vl.TextSize = 22
    vl.Font = Enum.Font.GothamBold
    vl.TextXAlignment = Enum.TextXAlignment.Center
    vl.Parent = c

    local ll = Instance.new('TextLabel')
    ll.Size = UDim2.new(1, 0, 0.4, 0)
    ll.Position = UDim2.new(0, 0, 0.6, 0)
    ll.BackgroundTransparency = 1
    ll.Text = labelTxt
    ll.TextColor3 = dimText
    ll.TextSize = 10
    ll.Font = Enum.Font.Gotham
    ll.TextXAlignment = Enum.TextXAlignment.Center
    ll.Parent = c
end

makeStat(statsFrame, 'WINS', '0', 8)
makeStat(statsFrame, 'LOSSES', '0', 150)

-- divider inside stats
local statDiv = Instance.new('Frame')
statDiv.Size = UDim2.new(0, 1, 0.7, 0)
statDiv.Position = UDim2.new(0.5, 0, 0.15, 0)
statDiv.BackgroundColor3 = borderColor
statDiv.BackgroundTransparency = 0.4
statDiv.BorderSizePixel = 0
statDiv.Parent = statsFrame

createSep(contentFrame, o) o += 1

-- Duel actions
createSection(contentFrame, '⚡ Actions', o) o += 1
createButton(contentFrame, '🗡  Challenge Player', o, function() print('Challenge Player clicked') end) o += 1
createButton(contentFrame, '🛡  Accept Duel', o, function() print('Accept Duel clicked') end) o += 1
createButton(contentFrame, '💀  Forfeit Duel', o, function() print('Forfeit Duel clicked') end) o += 1

createSep(contentFrame, o) o += 1

-- Settings toggles
createSection(contentFrame, '⚙ Settings', o) o += 1
createToggle(contentFrame, 'Auto-Accept Duels', o, false, function(v) print('Auto-Accept:', v) end) o += 1
createToggle(contentFrame, 'Show Notifications', o, true, function(v) print('Notifications:', v) end) o += 1
createToggle(contentFrame, 'Sound FX', o, true, function(v) print('Sound FX:', v) end) o += 1
createToggle(contentFrame, 'Spectate Mode', o, false, function(v) print('Spectate:', v) end) o += 1

createSep(contentFrame, o) o += 1

-- Info
createSection(contentFrame, 'ℹ Info', o) o += 1
createInfoLabel(contentFrame, 'Challenge any player to a 1v1 duel.\nWins are tracked on the leaderboard.\nUse forfeit to cancel an active duel.', o) o += 1

createSep(contentFrame, o) o += 1

-- Reset / misc
createButton(contentFrame, '🔄  Reset Stats', o, function() print('Stats reset') end) o += 1
createButton(contentFrame, '🏆  Leaderboard', o, function() print('Leaderboard opened') end) o += 1
