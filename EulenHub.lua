-- KMONEY HUB - 500x300

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG_FILE = "kmoney_config.json"

-- ══════════════════════════════════════════
-- VARIABLES STEAL
-- ══════════════════════════════════════════
local StealData      = {}
local isStealing     = false
local stealStartTime = 0
local phantomLetterLabels = {}
local SBPct, SBFill, SBStatus = nil, nil, nil

local Values = {
    STEAL_DURATION = 0.7,
}
local Connections = {}
local Enabled     = { AutoSteal = false }

local function findNearestPrompt()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil end
    local nearest, minDist, nearName = nil, math.huge, nil
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil, nil end
    for _, desc in ipairs(plots:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Steal" then
            local part = desc.Parent
            if part and part:IsA("BasePart") then
                local d = (hrp.Position - part.Position).Magnitude
                if d < minDist then
                    minDist = d; nearest = desc
                    nearName = part.Name
                end
            end
        end
    end
    return nearest, minDist, nearName
end

-- ══════════════════════════════════════════
-- OPTIMIZER / DARK MODE
-- ══════════════════════════════════════════
local xrayEnabled          = false
local originalTransparency = {}

local function enableOptimizer()
    if getgenv and getgenv().NEBULA_OPT_ACTIVE then return end
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = true end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false; Lighting.Brightness = 2; Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9
        for _, fx in ipairs(Lighting:GetChildren()) do if fx:IsA("PostEffect") then fx.Enabled = false end end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false; obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false; obj.Material = Enum.Material.Plastic
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then child:Destroy() end
                    end
                elseif obj:IsA("Sky") then obj:Destroy() end
            end)
        end
    end)
    xrayEnabled = true
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and (obj.Name:lower():find("base") or (obj.Parent and obj.Parent.Name:lower():find("base"))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.88
            end
        end
    end)
end

local function disableOptimizer()
    if getgenv then getgenv().NEBULA_OPT_ACTIVE = false end
    if xrayEnabled then
        for part, value in pairs(originalTransparency) do if part then part.LocalTransparencyModifier = value end end
        originalTransparency = {}; xrayEnabled = false
    end
end

local darkCC = nil

local function enableDarkMode()
    if darkCC and darkCC.Parent then return end
    darkCC = Instance.new("ColorCorrectionEffect")
    darkCC.Name = "NebulaDarkMode"; darkCC.Brightness = -0.25; darkCC.Contrast = 0.1
    darkCC.Saturation = -0.1; darkCC.Enabled = true; darkCC.Parent = Lighting
end

local function disableDarkMode()
    if darkCC then darkCC:Destroy(); darkCC = nil end
end

-- ══════════════════════════════════════════
-- SAVE CONFIG
-- ══════════════════════════════════════════
local darkOn      = false
local autoStealOn = false

local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            DarkMode  = darkOn,
            AutoSteal = autoStealOn,
        }))
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.DarkMode  ~= nil then darkOn      = data.DarkMode  end
            if data.AutoSteal ~= nil then autoStealOn = data.AutoSteal end
        end
    end)
end

loadConfig()

-- ══════════════════════════════════════════
-- COLORES PASTEL
-- ══════════════════════════════════════════
local Pink     = Color3.fromRGB(255, 182, 193)
local Lavender = Color3.fromRGB(200, 195, 240)
local SkyBlue  = Color3.fromRGB(110, 195, 220)
local White    = Color3.fromRGB(255, 255, 255)
local GreenOk  = Color3.fromRGB(150, 240, 180)

-- Limpiar hub anterior
if PlayerGui:FindFirstChild("KmoneyHub") then
    PlayerGui:FindFirstChild("KmoneyHub"):Destroy()
end

-- ══════════════════════════════════════════
-- GUI  (500 x 400 para dar espacio)
-- ══════════════════════════════════════════
local GUI_W, GUI_H = 500, 400

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "KmoneyHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, GUI_W, 0, GUI_H)
Main.Position         = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
Main.BackgroundColor3 = White
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.Parent           = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Pink),
    ColorSequenceKeypoint.new(0.5, Lavender),
    ColorSequenceKeypoint.new(1.0, SkyBlue),
})
BgGrad.Rotation = 90
BgGrad.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size                   = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3       = White
Header.BackgroundTransparency = 0.55
Header.BorderSizePixel        = 0
Header.ZIndex                 = 3
Header.Parent                 = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size                   = UDim2.new(1, 0, 0, 1.5)
HeaderLine.Position               = UDim2.new(0, 0, 1, -1)
HeaderLine.BackgroundColor3       = White
HeaderLine.BackgroundTransparency = 0.3
HeaderLine.BorderSizePixel        = 0
HeaderLine.ZIndex                 = 4
HeaderLine.Parent                 = Header

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
local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(160, 130, 180)
TitleStroke.Thickness = 1.5; TitleStroke.Transparency = 0.3
TitleStroke.Parent = Title

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size                   = UDim2.new(0, 30, 0, 30)
CloseBtn.Position               = UDim2.new(1, -42, 0.5, -15)
CloseBtn.BackgroundColor3       = White
CloseBtn.BackgroundTransparency = 0.4
CloseBtn.Text                   = "x"
CloseBtn.TextColor3             = Color3.fromRGB(180, 100, 140)
CloseBtn.Font                   = Enum.Font.GothamBold
CloseBtn.TextSize               = 15
CloseBtn.BorderSizePixel        = 0
CloseBtn.ZIndex                 = 6
CloseBtn.Parent                 = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Content
local Content = Instance.new("Frame")
Content.Size                 = UDim2.new(1, -24, 1, -118)
Content.Position             = UDim2.new(0, 12, 0, 60)
Content.BackgroundTransparency = 1
Content.ZIndex               = 3
Content.Parent               = Main

-- ══════════════════════════════════════════
-- TOGGLE HELPER
-- ══════════════════════════════════════════
local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

local function makeSectionLabel(text, yPos)
    local Lbl = Instance.new("TextLabel")
    Lbl.Size                   = UDim2.new(1, 0, 0, 20)
    Lbl.Position               = UDim2.new(0, 0, 0, yPos)
    Lbl.BackgroundTransparency = 1
    Lbl.Text                   = text
    Lbl.TextColor3             = White
    Lbl.Font                   = Enum.Font.GothamBold
    Lbl.TextSize               = 11
    Lbl.TextXAlignment         = Enum.TextXAlignment.Left
    Lbl.ZIndex                 = 4
    Lbl.Parent                 = Content
    local S = Instance.new("UIStroke")
    S.Color = Color3.fromRGB(160,130,180); S.Thickness = 1; S.Transparency = 0.5; S.Parent = Lbl
    return Lbl
end

local function makeToggle(labelText, yPos)
    local Row = Instance.new("Frame")
    Row.Size                   = UDim2.new(1, 0, 0, 48)
    Row.Position               = UDim2.new(0, 0, 0, yPos)
    Row.BackgroundColor3       = White
    Row.BackgroundTransparency = 0.45
    Row.BorderSizePixel        = 0
    Row.ZIndex                 = 4
    Row.Parent                 = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = White; Stroke.Transparency = 0.5; Stroke.Thickness = 1; Stroke.Parent = Row

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
    BtnTrack.Size                   = UDim2.new(0, 46, 0, 24)
    BtnTrack.Position               = UDim2.new(1, -58, 0.5, -12)
    BtnTrack.BackgroundColor3       = White
    BtnTrack.BackgroundTransparency = 0.5
    BtnTrack.Text                   = ""
    BtnTrack.BorderSizePixel        = 0
    BtnTrack.ZIndex                 = 5
    BtnTrack.Parent                 = Row
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

-- ══════════════════════════════════════════
-- SECCION: STEAL
-- ══════════════════════════════════════════
makeSectionLabel("— STEAL —", 0)

-- Toggle Auto Steal
local B_steal, K_steal = makeToggle("Auto Steal", 24)

-- Barra de progreso del steal
local SBRow = Instance.new("Frame")
SBRow.Size                   = UDim2.new(1, 0, 0, 44)
SBRow.Position               = UDim2.new(0, 0, 0, 80)
SBRow.BackgroundColor3       = White
SBRow.BackgroundTransparency = 0.55
SBRow.BorderSizePixel        = 0
SBRow.ZIndex                 = 4
SBRow.Parent                 = Content
Instance.new("UICorner", SBRow).CornerRadius = UDim.new(0, 10)
local SBStroke = Instance.new("UIStroke")
SBStroke.Color = White; SBStroke.Transparency = 0.5; SBStroke.Thickness = 1; SBStroke.Parent = SBRow

-- Status label
SBStatus = Instance.new("TextLabel")
SBStatus.Size                   = UDim2.new(0.5, 0, 0, 18)
SBStatus.Position               = UDim2.new(0, 14, 0, 4)
SBStatus.BackgroundTransparency = 1
SBStatus.Text                   = "READY"
SBStatus.TextColor3             = White
SBStatus.Font                   = Enum.Font.GothamBold
SBStatus.TextSize               = 11
SBStatus.TextXAlignment         = Enum.TextXAlignment.Left
SBStatus.ZIndex                 = 5
SBStatus.Parent                 = SBRow

-- Porcentaje
SBPct = Instance.new("TextLabel")
SBPct.Size                   = UDim2.new(0.5, -14, 0, 18)
SBPct.Position               = UDim2.new(0.5, 0, 0, 4)
SBPct.BackgroundTransparency = 1
SBPct.Text                   = "0%"
SBPct.TextColor3             = White
SBPct.Font                   = Enum.Font.GothamBold
SBPct.TextSize               = 11
SBPct.TextXAlignment         = Enum.TextXAlignment.Right
SBPct.Visible                = false
SBPct.ZIndex                 = 5
SBPct.Parent                 = SBRow

-- Track de la barra
local SBTrack = Instance.new("Frame")
SBTrack.Size                   = UDim2.new(1, -28, 0, 12)
SBTrack.Position               = UDim2.new(0, 14, 0, 26)
SBTrack.BackgroundColor3       = White
SBTrack.BackgroundTransparency = 0.7
SBTrack.BorderSizePixel        = 0
SBTrack.ZIndex                 = 5
SBTrack.Parent                 = SBRow
Instance.new("UICorner", SBTrack).CornerRadius = UDim.new(1, 0)

-- Fill de la barra
SBFill = Instance.new("Frame")
SBFill.Size             = UDim2.new(0, 0, 1, 0)
SBFill.BackgroundColor3 = SkyBlue
SBFill.BorderSizePixel  = 0
SBFill.ZIndex           = 6
SBFill.Parent           = SBTrack
Instance.new("UICorner", SBFill).CornerRadius = UDim.new(1, 0)
local FillGrad = Instance.new("UIGradient")
FillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Pink),
    ColorSequenceKeypoint.new(1, SkyBlue),
})
FillGrad.Parent = SBFill

-- Phantom letters (7 bloques que se revelan)
local phantomFrame = Instance.new("Frame")
phantomFrame.Size                   = UDim2.new(0, 140, 0, 18)
phantomFrame.Position               = UDim2.new(0.5, -70, 0, 4)
phantomFrame.BackgroundTransparency = 1
phantomFrame.ZIndex                 = 6
phantomFrame.Parent                 = SBRow

for i = 1, 7 do
    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(0, 18, 1, 0)
    lbl.Position               = UDim2.new(0, (i-1)*20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "█"
    lbl.TextColor3             = White
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 12
    lbl.TextTransparency       = 1
    lbl.ZIndex                 = 7
    lbl.Parent                 = phantomFrame
    table.insert(phantomLetterLabels, lbl)
end

-- ══════════════════════════════════════════
-- STEAL LOGIC
-- ══════════════════════════════════════════
local progressConnection = nil

local function ResetProgressBar()
    for _, lbl in ipairs(phantomLetterLabels) do lbl.TextTransparency = 1 end
    if SBPct    then SBPct.Visible = false end
    if SBFill   then
        TweenService:Create(SBFill, TweenInfo.new(0.15), {Size = UDim2.new(0,0,1,0)}):Play()
    end
    if SBStatus then SBStatus.Text = "READY" end
end

local function UpdatePhantomLetters(prog)
    local numLetters = 7
    local lettersToShow = math.clamp(math.floor(prog * numLetters + 0.999), 0, numLetters)
    for i, lbl in ipairs(phantomLetterLabels) do
        lbl.TextTransparency = i <= lettersToShow and 0 or 1
    end
    if SBPct then
        SBPct.Visible = true
        SBPct.Text = math.floor(prog * 100) .. "%"
    end
    if SBFill then
        SBFill.Size = UDim2.new(prog, 0, 1, 0)
    end
    if SBStatus then
        SBStatus.Text = isStealing and "STEALING..." or "READY"
    end
end

local function cachePromptData(prompt)
    if StealData[prompt] then return StealData[prompt] end
    local data = {hold={}, trigger={}, ready=true}
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                if c.Function then table.insert(data.hold, c.Function) end
            end
            for _, c in ipairs(getconnections(prompt.Triggered)) do
                if c.Function then table.insert(data.trigger, c.Function) end
            end
        end
    end)
    StealData[prompt] = data
    return data
end

local function executeSteal(prompt, name)
    if isStealing then return end
    local data = cachePromptData(prompt)
    if not data.ready then return end
    data.ready = false; isStealing = true; stealStartTime = tick()
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then
            if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
            return
        end
        local prog = math.clamp((tick() - stealStartTime) / Values.STEAL_DURATION, 0, 1)
        UpdatePhantomLetters(prog)
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(pcall, f) end
        task.wait(Values.STEAL_DURATION)
        for _, f in ipairs(data.trigger) do task.spawn(pcall, f) end
        if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
        ResetProgressBar()
        data.ready = true; isStealing = false
    end)
end

local lastStealScan = 0

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local now = tick()
        if now - lastStealScan < 0.05 then return end
        lastStealScan = now
        local p, _, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect(); Connections.autoSteal = nil end
    isStealing = false
    if progressConnection then progressConnection:Disconnect(); progressConnection = nil end
    ResetProgressBar()
end

-- Conectar toggle Auto Steal
if autoStealOn then
    Enabled.AutoSteal = true
    K_steal.Position = UDim2.new(1,-21,0.5,-9)
    K_steal.BackgroundColor3 = SkyBlue
    startAutoSteal()
end

B_steal.MouseButton1Click:Connect(function()
    autoStealOn = not autoStealOn
    Enabled.AutoSteal = autoStealOn
    if autoStealOn then
        startAutoSteal()
        TweenService:Create(K_steal, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=SkyBlue}):Play()
    else
        stopAutoSteal()
        TweenService:Create(K_steal, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- ══════════════════════════════════════════
-- SECCION: MISC
-- ══════════════════════════════════════════
makeSectionLabel("— MISC —", 136)

local B1, K1 = makeToggle("Dark Mode", 160)

local function applyDarkState()
    if darkOn then
        enableOptimizer(); enableDarkMode()
        K1.Position         = UDim2.new(1, -21, 0.5, -9)
        K1.BackgroundColor3 = SkyBlue
    else
        disableOptimizer(); disableDarkMode()
        K1.Position         = UDim2.new(0, 3, 0.5, -9)
        K1.BackgroundColor3 = Color3.fromRGB(200, 170, 210)
    end
end

applyDarkState()

B1.MouseButton1Click:Connect(function()
    darkOn = not darkOn
    if darkOn then
        enableOptimizer(); enableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(1,-21,0.5,-9), BackgroundColor3=SkyBlue}):Play()
    else
        disableOptimizer(); disableDarkMode()
        TweenService:Create(K1, ti, {Position=UDim2.new(0,3,0.5,-9), BackgroundColor3=Color3.fromRGB(200,170,210)}):Play()
    end
end)

-- ══════════════════════════════════════════
-- SAVE CONFIG BUTTON (fijo abajo)
-- ══════════════════════════════════════════
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                   = UDim2.new(1, -24, 0, 36)
SaveBtn.Position               = UDim2.new(0, 12, 1, -48)
SaveBtn.BackgroundColor3       = White
SaveBtn.BackgroundTransparency = 0.35
SaveBtn.Text                   = "💾  Save Config"
SaveBtn.TextColor3             = White
SaveBtn.Font                   = Enum.Font.GothamBold
SaveBtn.TextSize               = 14
SaveBtn.BorderSizePixel        = 0
SaveBtn.ZIndex                 = 6
SaveBtn.Parent                 = Main
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 10)
local SaveStroke = Instance.new("UIStroke")
SaveStroke.Color = White; SaveStroke.Transparency = 0.45; SaveStroke.Thickness = 1
SaveStroke.Parent = SaveBtn

SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    local orig = SaveBtn.Text
    SaveBtn.Text = "✔  Saved!"
    SaveBtn.TextColor3 = GreenOk
    task.delay(1.2, function()
        SaveBtn.Text = orig
        SaveBtn.TextColor3 = White
    end)
end)

-- ══════════════════════════════════════════
-- CERRAR
-- ══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    stopAutoSteal()
    local t = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    t:Play()
    t.Completed:Connect(function() ScreenGui:Destroy() end)
end)

-- ══════════════════════════════════════════
-- DRAG
-- ══════════════════════════════════════════
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

-- ══════════════════════════════════════════
-- ANIMACION ENTRADA
-- ══════════════════════════════════════════
Main.Size = UDim2.new(0, 0, 0, 0)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size     = UDim2.new(0, GUI_W, 0, GUI_H),
    Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2),
}):Play()
