-- ╔══════════════════════════════════════════════╗
-- ║              EULEN HUB                       ║
-- ║     Compatible con todos los executors       ║
-- ╚══════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local LocalPlayer      = Players.LocalPlayer

-- ══════════════════════════════════════════
-- COMPATIBILIDAD: intenta CoreGui, si falla usa PlayerGui
-- ══════════════════════════════════════════
local guiParent
local ok = pcall(function()
    guiParent = game:GetService("CoreGui")
    local t = Instance.new("ScreenGui")
    t.Parent = guiParent
    t:Destroy()
end)
if not ok then
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════
--                 COLORES
-- ══════════════════════════════════════════
local C = {
    bg        = Color3.fromRGB(0,   0,   0),
    bgRow     = Color3.fromRGB(6,   6,   6),
    bgRowHov  = Color3.fromRGB(14,  14,  14),
    header    = Color3.fromRGB(0,   0,   0),
    border    = Color3.fromRGB(255,255,255),
    neon      = Color3.fromRGB(255,255,255),
    neonDim   = Color3.fromRGB(170,170,170),
    text      = Color3.fromRGB(255,255,255),
    subtext   = Color3.fromRGB(130,130,130),
    trackOn   = Color3.fromRGB(255,255,255),
    trackOff  = Color3.fromRGB(30,  30,  30),
    sliderBg  = Color3.fromRGB(28,  28,  28),
    sliderFg  = Color3.fromRGB(255,255,255),
    sep       = Color3.fromRGB(22,  22,  22),
    rowH      = 34,
    width     = 310,
}

-- ══════════════════════════════════════════
--              UTILIDADES
-- ══════════════════════════════════════════
local function New(class, props, children)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do
        pcall(function() o[k]=v end)
    end
    for _,c in pairs(children or {}) do c.Parent=o end
    return o
end
local function Tw(o,t,p)
    pcall(function()
        TweenService:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart),p):Play()
    end)
end

-- ══════════════════════════════════════════
--               DRAG SYSTEM
-- ══════════════════════════════════════════
local function Drag(frame, handle)
    local drag,inp,st,sp = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; st=i.Position; sp=frame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then inp=i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i==inp and drag then
            local d = i.Position - st
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- ══════════════════════════════════════════
--              DESTRUIR HUB ANTERIOR
-- ══════════════════════════════════════════
for _,v in pairs(guiParent:GetChildren()) do
    if v.Name == "EulenHub" then v:Destroy() end
end

-- ══════════════════════════════════════════
--              CONSTRUIR GUI
-- ══════════════════════════════════════════
local Screen = New("ScreenGui",{
    Name            = "EulenHub",
    Parent          = guiParent,
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
})

pcall(function() Screen.IgnoreGuiInset = true end)

local Win = New("Frame",{
    Name             = "Win",
    Parent           = Screen,
    BackgroundColor3 = C.bg,
    BorderSizePixel  = 0,
    Size             = UDim2.new(0, C.width, 0, 52),
    Position         = UDim2.new(0, 50, 0, 100),
    ClipsDescendants = false,
},{
    New("UICorner",{CornerRadius=UDim.new(0,7)}),
    New("UIStroke",{Color=C.border, Thickness=1.5, Transparency=0}),
})

-- ══════════════════════════════════════════
--                 HEADER
-- ══════════════════════════════════════════
local Header = New("Frame",{
    Parent           = Win,
    Name             = "Header",
    BackgroundColor3 = C.header,
    BorderSizePixel  = 0,
    Size             = UDim2.new(1,0,0,52),
},{
    New("UICorner",{CornerRadius=UDim.new(0,7)}),
    New("Frame",{
        BackgroundColor3=C.header, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,1,-10)
    }),
    New("Frame",{
        BackgroundColor3=C.border, BackgroundTransparency=0.2, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1)
    }),
})

New("TextLabel",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,10,0,6),
    Text="⬡", Font=Enum.Font.GothamBold,
    TextColor3=C.neon, TextSize=18,
})
New("TextLabel",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(1,-80,0,24), Position=UDim2.new(0,36,0,5),
    Text="EULEN HUB", Font=Enum.Font.GothamBold,
    TextColor3=C.neon, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local FpsLbl = New("TextLabel",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(0,70,0,13), Position=UDim2.new(0,36,0,32),
    Text="FPS: --", Font=Enum.Font.Gotham,
    TextColor3=C.neon, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})
local PingLbl = New("TextLabel",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(0,90,0,13), Position=UDim2.new(0,100,0,32),
    Text="PING: --ms", Font=Enum.Font.Gotham,
    TextColor3=C.subtext, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,
})
New("TextLabel",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(0,50,0,13), Position=UDim2.new(0,196,0,32),
    Text="FREE", Font=Enum.Font.GothamBold,
    TextColor3=C.neonDim, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left,
})

local XBtn = New("TextButton",{
    Parent=Header, BackgroundTransparency=1,
    Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-32,0,8),
    Text="✕", Font=Enum.Font.GothamBold,
    TextColor3=C.neon, TextSize=14,
})
XBtn.MouseButton1Click:Connect(function()
    Tw(Win,0.25,{Size=UDim2.new(0,C.width,0,0), BackgroundTransparency=1})
    task.wait(0.3)
    Screen:Destroy()
end)
XBtn.MouseEnter:Connect(function() Tw(XBtn,0.1,{TextColor3=Color3.fromRGB(255,70,70)}) end)
XBtn.MouseLeave:Connect(function() Tw(XBtn,0.1,{TextColor3=C.neon}) end)

Drag(Win, Header)

-- ══════════════════════════════════════════
--          SCROLL CONTENT
-- ══════════════════════════════════════════
local Scroll = New("ScrollingFrame",{
    Parent=Win, Name="Scroll",
    BackgroundTransparency=1, BorderSizePixel=0,
    Size=UDim2.new(1,0,1,-52),
    Position=UDim2.new(0,0,0,52),
    ScrollBarThickness=2,
    ScrollBarImageColor3=C.border,
    CanvasSize=UDim2.new(0,0,0,0),
    ClipsDescendants=true,
})

local Layout = New("UIListLayout",{
    Parent=Scroll,
    SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,0),
})

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local h = Layout.AbsoluteContentSize.Y
    Scroll.CanvasSize = UDim2.new(0,0,0,h)
    Win.Size = UDim2.new(0,C.width,0, 52 + math.min(h,420))
end)

-- ══════════════════════════════════════════
--         COMPONENTES REUTILIZABLES
-- ══════════════════════════════════════════
local Hub = {}

function Hub:Section(txt)
    New("Frame",{Parent=Scroll, BackgroundColor3=Color3.fromRGB(10,10,10),
        BorderSizePixel=0, Size=UDim2.new(1,0,0,22)},{
        New("TextLabel",{BackgroundTransparency=1,
            Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,10,0,0),
            Text=txt, Font=Enum.Font.GothamSemibold,
            TextColor3=C.neonDim, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left}),
        New("Frame",{BackgroundColor3=C.border, BackgroundTransparency=0.72,
            BorderSizePixel=0, Size=UDim2.new(1,0,0,1),
            Position=UDim2.new(0,0,1,-1)}),
    })
end

function Hub:Toggle(txt, default, cb)
    local state = default or false
    local row = New("Frame",{Parent=Scroll, BackgroundColor3=C.bgRow,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,C.rowH)})
    local bar = New("Frame",{Parent=row, BackgroundColor3=C.neon,
        BackgroundTransparency=1, BorderSizePixel=0,
        Size=UDim2.new(0,2,0.55,0), Position=UDim2.new(0,0,0.225,0)})
    New("TextLabel",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(1,-56,1,0), Position=UDim2.new(0,12,0,0),
        Text=txt, Font=Enum.Font.GothamSemibold,
        TextColor3=C.text, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left})
    local track = New("Frame",{Parent=row,
        BackgroundColor3=state and C.trackOn or C.trackOff,
        BorderSizePixel=0, Size=UDim2.new(0,36,0,19),
        Position=UDim2.new(1,-46,0.5,-9)},{
        New("UICorner",{CornerRadius=UDim.new(0,10)})})
    local knob = New("Frame",{Parent=track,
        BackgroundColor3=state and Color3.fromRGB(0,0,0) or Color3.fromRGB(80,80,80),
        BorderSizePixel=0, Size=UDim2.new(0,15,0,15),
        Position=state and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7)},{
        New("UICorner",{CornerRadius=UDim.new(0,8)})})
    New("Frame",{Parent=row, BackgroundColor3=C.sep,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1)})
    local hit = New("TextButton",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0), Text=""})
    hit.MouseButton1Click:Connect(function()
        state = not state
        Tw(track,0.18,{BackgroundColor3=state and C.trackOn or C.trackOff})
        Tw(knob,0.18,{
            Position=state and UDim2.new(1,-18,0.5,-7) or UDim2.new(0,3,0.5,-7),
            BackgroundColor3=state and Color3.fromRGB(0,0,0) or Color3.fromRGB(80,80,80),
        })
        if cb then pcall(cb,state) end
    end)
    hit.MouseEnter:Connect(function()
        Tw(bar,0.12,{BackgroundTransparency=0})
        Tw(row,0.12,{BackgroundColor3=C.bgRowHov})
    end)
    hit.MouseLeave:Connect(function()
        Tw(bar,0.12,{BackgroundTransparency=1})
        Tw(row,0.12,{BackgroundColor3=C.bgRow})
    end)
end

function Hub:Slider(txt, min, max, def, suffix, cb)
    suffix=suffix or ""; def=math.clamp(def or min,min,max)
    local val=def
    local row=New("Frame",{Parent=Scroll, BackgroundColor3=C.bgRow,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,46)})
    New("TextLabel",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(0.65,0,0,18), Position=UDim2.new(0,12,0,6),
        Text=txt, Font=Enum.Font.GothamSemibold, TextColor3=C.text, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left})
    local vl=New("TextLabel",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(0.35,-10,0,18), Position=UDim2.new(0.65,0,0,6),
        Text=tostring(def)..suffix, Font=Enum.Font.GothamBold,
        TextColor3=C.neon, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right})
    local bg=New("Frame",{Parent=row, BackgroundColor3=C.sliderBg,
        BorderSizePixel=0, Size=UDim2.new(1,-22,0,3),
        Position=UDim2.new(0,11,0,32)},{
        New("UICorner",{CornerRadius=UDim.new(0,2)})})
    local pct=(def-min)/(max-min)
    local fill=New("Frame",{Parent=bg, BackgroundColor3=C.sliderFg,
        BorderSizePixel=0, Size=UDim2.new(pct,0,1,0)},{
        New("UICorner",{CornerRadius=UDim.new(0,2)})})
    local thumb=New("Frame",{Parent=bg, BackgroundColor3=C.neon,
        BorderSizePixel=0, Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(pct,-5,0.5,-5)},{
        New("UICorner",{CornerRadius=UDim.new(0,5)})})
    New("Frame",{Parent=row, BackgroundColor3=C.sep,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1)})
    local sliding=false
    local function upd(x)
        local p=math.clamp((x-bg.AbsolutePosition.X)/bg.AbsoluteSize.X,0,1)
        val=math.floor(min+p*(max-min))
        vl.Text=tostring(val)..suffix
        Tw(fill,0.04,{Size=UDim2.new(p,0,1,0)})
        Tw(thumb,0.04,{Position=UDim2.new(p,-5,0.5,-5)})
        if cb then pcall(cb,val) end
    end
    bg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
end

function Hub:Button(txt, sub, cb)
    local h = sub and 46 or C.rowH
    local row=New("Frame",{Parent=Scroll, BackgroundColor3=C.bgRow,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,h)})
    local bar=New("Frame",{Parent=row, BackgroundColor3=C.neon,
        BackgroundTransparency=1, BorderSizePixel=0,
        Size=UDim2.new(0,2,0.55,0), Position=UDim2.new(0,0,0.225,0)})
    New("TextLabel",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(1,-38,0,18), Position=UDim2.new(0,12,0,sub and 7 or 8),
        Text=txt, Font=Enum.Font.GothamSemibold, TextColor3=C.text, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left})
    if sub then
        New("TextLabel",{Parent=row, BackgroundTransparency=1,
            Size=UDim2.new(1,-38,0,14), Position=UDim2.new(0,12,0,25),
            Text=sub, Font=Enum.Font.Gotham, TextColor3=C.subtext, TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left})
    end
    New("TextLabel",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(0,24,1,0), Position=UDim2.new(1,-28,0,0),
        Text="›", Font=Enum.Font.GothamBold, TextColor3=C.neonDim, TextSize=20})
    New("Frame",{Parent=row, BackgroundColor3=C.sep,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1)})
    local hit=New("TextButton",{Parent=row, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0), Text=""})
    hit.MouseButton1Click:Connect(function()
        Tw(row,0.05,{BackgroundColor3=Color3.fromRGB(30,30,30)})
        Tw(row,0.25,{BackgroundColor3=C.bgRow})
        if cb then pcall(cb) end
    end)
    hit.MouseEnter:Connect(function()
        Tw(bar,0.12,{BackgroundTransparency=0})
        Tw(row,0.12,{BackgroundColor3=C.bgRowHov})
    end)
    hit.MouseLeave:Connect(function()
        Tw(bar,0.12,{BackgroundTransparency=1})
        Tw(row,0.12,{BackgroundColor3=C.bgRow})
    end)
end

-- ══════════════════════════════════════════
--   ✦ OPCIONES — EJEMPLO COMPLETO ✦
-- ══════════════════════════════════════════

Hub:Section("  ⚙ MOVIMIENTO")

Hub:Toggle("Speed Hack", false, function(v)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = v and 50 or 16
        end
    end
end)

Hub:Toggle("Infinite Jump", false, function(v)
    LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    _G.InfJump = v
    if v then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").StateChanged:Connect(function(_, new)
            if _G.InfJump and new == Enum.HumanoidStateType.Jumping then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Freefall)
            end
        end)
    end
end)

Hub:Slider("Walk Speed", 16, 200, 16, " sp", function(v)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

Hub:Slider("Jump Power", 50, 300, 50, " jp", function(v)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

Hub:Section("  👁 VISUAL")

Hub:Toggle("No Clip", false, function(v)
    _G.NoClip = v
    if v then
        RunService.Stepped:Connect(function()
            if _G.NoClip and LocalPlayer.Character then
                for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end
end)

Hub:Toggle("Full Bright", false, function(v)
    local lighting = game:GetService("Lighting")
    lighting.Brightness = v and 10 or 1
    lighting.ClockTime  = v and 14 or 14
    lighting.FogEnd     = v and 1e6 or 100000
    lighting.GlobalShadows = not v
end)

Hub:Toggle("ESP Jugadores", false, function(v)
    _G.ESP = v
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local existing = p.Character:FindFirstChild("ESP_BOX")
            if v and not existing then
                local bb = Instance.new("BillboardGui")
                bb.Name = "ESP_BOX"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 60, 0, 80)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                local lbl = Instance.new("TextLabel", bb)
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Text = p.Name
                lbl.TextColor3 = Color3.fromRGB(255,255,255)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 12
                bb.Parent = p.Character:FindFirstChild("HumanoidRootPart") or p.Character
            elseif not v and existing then
                existing:Destroy()
            end
        end
    end
end)

Hub:Section("  🎮 MISCELÁNEOS")

Hub:Button("Rejuvenecer personaje", "Resetea tu personaje en el juego", function()
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
end)

Hub:Button("Copiar posición", "Imprime tu posición en output", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        print("[EulenHub] Posición: " .. tostring(root.Position))
    end
end)

Hub:Button("Ir al spawn", "Teletransporta al punto de inicio", function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if root and spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
    end
end)

Hub:Slider("Campo de visión", 70, 120, 70, "°", function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

-- ══════════════════════════════════════════
--       FPS / PING EN TIEMPO REAL
-- ══════════════════════════════════════════
local fbuf, lt = {}, tick()
RunService.Heartbeat:Connect(function(dt)
    table.insert(fbuf, 1/dt)
    if #fbuf > 30 then table.remove(fbuf,1) end
    if tick()-lt >= 0.5 then
        lt = tick()
        local s=0
        for _,v in ipairs(fbuf) do s=s+v end
        local fps = math.floor(s/#fbuf)
        FpsLbl.Text = "FPS: "..fps
        FpsLbl.TextColor3 = fps>=55 and C.neon or (fps>=30 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,70,70))
        local ok,p = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then
            PingLbl.Text = "PING: "..p.."ms"
            PingLbl.TextColor3 = p<=80 and Color3.fromRGB(120,255,120) or (p<=150 and Color3.fromRGB(255,200,0) or Color3.fromRGB(255,70,70))
        else
            PingLbl.Text = "PING: --ms"
        end
    end
end)

-- ══════════════════════════════════════════
--          ANIMACIÓN ENTRADA
-- ══════════════════════════════════════════
Win.BackgroundTransparency = 1
task.wait(0.05)
Tw(Win, 0.35, {BackgroundTransparency = 0})

warn("[EulenHub] ✓ Cargado correctamente — "..LocalPlayer.Name)
