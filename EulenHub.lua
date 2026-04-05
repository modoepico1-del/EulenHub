local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local me                = LocalPlayer
local RS                = RunService

local CONFIG_FILE = "kmoney_config.json"

-- ══════════════════════════════════════════
--   SPEED CONFIG (Dragon Hub style)
-- ══════════════════════════════════════════
local SpeedConfig = {
    NormalSpeed  = 59.5,
    CarrySpeed   = 30,
    Mode         = "Carry",   -- "Carry" | "Normal"
    ModeKey      = Enum.KeyCode.Q,
    SpeedEnabled = true,
}

local speedBV = nil
local function removeSpeedBV()
    if speedBV and speedBV.Parent then speedBV:Destroy() end
    speedBV = nil
end
local function getSpeedBV()
    local char = me.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local existing = root:FindFirstChild("KmoneySpeedBV")
    if existing then return existing end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "KmoneySpeedBV"; bv.MaxForce = Vector3.new(1e5,0,1e5)
    bv.Velocity = Vector3.zero; bv.P = 1e4; bv.Parent = root
    speedBV = bv; return bv
end

RunService.Heartbeat:Connect(function()
    if not SpeedConfig.SpeedEnabled then removeSpeedBV(); return end
    local char = me.Character; if not char then removeSpeedBV(); return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then removeSpeedBV(); return end
    if hum.Health <= 0 then removeSpeedBV(); return end
    local moveDir = hum.MoveDirection
    local spd = (SpeedConfig.Mode == "Carry") and SpeedConfig.CarrySpeed or SpeedConfig.NormalSpeed
    local bv = getSpeedBV(); if not bv then return end
    if moveDir.Magnitude > 0.1 then bv.Velocity = moveDir * spd
    else bv.Velocity = Vector3.zero end
end)

me.CharacterAdded:Connect(function()
    speedBV = nil
end)

-- Speed Billboard
local speedBB = nil
local function makeSpeedBB()
    local c = me.Character; if not c then return end
    local head = c:FindFirstChild("Head"); if not head then return end
    if speedBB then pcall(function() speedBB:Destroy() end) end
    speedBB = Instance.new("BillboardGui"); speedBB.Name = "KmoneySpeedBB"
    speedBB.Adornee = head; speedBB.Size = UDim2.new(0,160,0,36)
    speedBB.StudsOffset = Vector3.new(0,3.2,0); speedBB.AlwaysOnTop = true; speedBB.Parent = head
    local lbl = Instance.new("TextLabel"); lbl.Name = "SpeedLbl"
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255); lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.TextStrokeTransparency = 0.3; lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true; lbl.Text = "Speed: 0"; lbl.Parent = speedBB
end
makeSpeedBB()
me.CharacterAdded:Connect(function(c)
    task.wait(0.15); makeSpeedBB()
end)
RunService.RenderStepped:Connect(function()
    if not speedBB or not speedBB.Parent then return end
    local c = me.Character; if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local lbl = speedBB:FindFirstChild("SpeedLbl"); if not lbl then return end
    local v = hrp.AssemblyLinearVelocity
    lbl.Text = "Speed: "..math.floor(Vector3.new(v.X,0,v.Z).Magnitude)
end)

-- Mode key toggle
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == SpeedConfig.ModeKey then
        SpeedConfig.Mode = (SpeedConfig.Mode == "Carry") and "Normal" or "Carry"
    end
end)

-- ══════════════════════════════════════════
--   OPTIMIZER + DARK + GALAXY
-- ══════════════════════════════════════════
local xrayEnabled = false; local originalTransparency = {}
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
    darkCC = Instance.new("ColorCorrectionEffect"); darkCC.Name = "NebulaDarkMode"
    darkCC.Brightness = -0.25; darkCC.Contrast = 0.1; darkCC.Saturation = -0.1
    darkCC.Enabled = true; darkCC.Parent = Lighting
end
local function disableDarkMode() if darkCC then darkCC:Destroy(); darkCC = nil end end

local originalSkybox, galaxySkyBright, galaxySkyBrightConn
local galaxyPlanets = {}; local galaxyBloom, galaxyGalaxyCC
local galaxyCfg = { on = false }
local function enableGalaxySkyBright()
    if galaxySkyBright then return end
    originalSkybox = Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent = nil end
    galaxySkyBright = Instance.new("Sky")
    for _, f in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
        galaxySkyBright[f] = "rbxassetid://1534951537"
    end
    galaxySkyBright.StarCount = 10000; galaxySkyBright.CelestialBodiesShown = false; galaxySkyBright.Parent = Lighting
    galaxyBloom = Instance.new("BloomEffect"); galaxyBloom.Intensity = 1.5; galaxyBloom.Size = 40; galaxyBloom.Threshold = 0.8; galaxyBloom.Parent = Lighting
    galaxyGalaxyCC = Instance.new("ColorCorrectionEffect"); galaxyGalaxyCC.Saturation = 0.8; galaxyGalaxyCC.Contrast = 0.3
    galaxyGalaxyCC.TintColor = Color3.fromRGB(200,150,255); galaxyGalaxyCC.Parent = Lighting
    Lighting.Ambient = Color3.fromRGB(120,60,180); Lighting.Brightness = 3; Lighting.ClockTime = 0
    for i = 1, 2 do
        local p = Instance.new("Part"); p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(800+i*200,800+i*200,800+i*200); p.Anchored = true; p.CanCollide = false
        p.CastShadow = false; p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(140+i*20,60+i*10,200+i*15); p.Transparency = 0.3
        p.Position = Vector3.new(math.cos(i*2)*(3000+i*500), 1500+i*300, math.sin(i*2)*(3000+i*500))
        p.Parent = workspace; table.insert(galaxyPlanets, p)
    end
    galaxySkyBrightConn = RunService.Heartbeat:Connect(function()
        if not galaxyCfg.on then return end
        local t = tick()*0.5
        Lighting.Ambient = Color3.fromRGB(120+math.floor(math.sin(t)*60),50+math.floor(math.sin(t*0.8)*40),180+math.floor(math.sin(t*1.2)*50))
        if galaxyBloom then galaxyBloom.Intensity = 1.2+math.sin(t*2)*0.4 end
    end)
end
local function disableGalaxySkyBright()
    if galaxySkyBrightConn then galaxySkyBrightConn:Disconnect(); galaxySkyBrightConn = nil end
    if galaxySkyBright then galaxySkyBright:Destroy(); galaxySkyBright = nil end
    if originalSkybox then originalSkybox.Parent = Lighting end
    if galaxyBloom then galaxyBloom:Destroy(); galaxyBloom = nil end
    if galaxyGalaxyCC then galaxyGalaxyCC:Destroy(); galaxyGalaxyCC = nil end
    for _, obj in ipairs(galaxyPlanets) do if obj then obj:Destroy() end end
    galaxyPlanets = {}
    Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.Brightness = 2; Lighting.ClockTime = 14
end

-- ══════════════════════════════════════════
--   ANTI RAGDOLL
-- ══════════════════════════════════════════
local antiRagdollOn = false; local antiRagdollMode = nil
local ragdollConnections = {}; local cachedCharData = {}
local function cacheCharacterData()
    local char = me.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return false end
    cachedCharData = { character=char, humanoid=hum, root=root, isFrozen=false }; return true
end
local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do pcall(function() conn:Disconnect() end) end
    ragdollConnections = {}
end
local function isRagdolled()
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    if state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then return true end
    local endTime = me:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then return true end; return false
end
local function removeRagdollConstraints()
    if not cachedCharData.character then return end
    for _, d in ipairs(cachedCharData.character:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end
local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function() me:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    if cachedCharData.humanoid.Health > 0 then cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running) end
    cachedCharData.root.Anchored = false
    cachedCharData.root.AssemblyLinearVelocity = Vector3.zero
    cachedCharData.root.AssemblyAngularVelocity = Vector3.zero
end
local function antiRagdollLoop()
    while antiRagdollMode do
        task.wait()
        if isRagdolled() then removeRagdollConstraints(); forceExitRagdoll() end
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid and cam.CameraSubject ~= cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end
end
local function toggleAntiRagdoll(enable)
    if enable then
        disconnectAllRagdoll(); if not cacheCharacterData() then return end
        antiRagdollMode = "v1"
        table.insert(ragdollConnections, me.CharacterAdded:Connect(function()
            task.wait(0.5); if antiRagdollMode then cacheCharacterData() end
        end))
        task.spawn(antiRagdollLoop)
    else antiRagdollMode = nil; disconnectAllRagdoll(); cachedCharData = {} end
end

-- ══════════════════════════════════════════
--   STATE VARIABLES
-- ══════════════════════════════════════════
local infJumpOn              = false
local autoStealActive        = false
local unwalkOn               = false
local espOn                  = false
local unwalkConn             = nil
local AUTO_STEAL_PROX_RADIUS = 20
local STEAL_DURATION         = 0.35
local darkOn      = false; local galaxyOn = false
local antiRagdollSaved=false; local infJumpSaved=false
local autoStealSaved=false; local unwalkSaved=false; local espSaved=false

-- ══════════════════════════════════════════
--   SAVE / LOAD
-- ══════════════════════════════════════════
local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            DarkMode=darkOn, Galaxy=galaxyOn, AntiRagdoll=antiRagdollOn,
            InfJump=infJumpOn, AutoSteal=autoStealActive,
            StealRadius=AUTO_STEAL_PROX_RADIUS, StealDuration=STEAL_DURATION,
            Unwalk=unwalkOn, ESP=espOn,
            NormalSpeed=SpeedConfig.NormalSpeed, CarrySpeed=SpeedConfig.CarrySpeed,
        }))
    end)
end
local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if data.DarkMode      ~= nil then darkOn                 = data.DarkMode      end
            if data.Galaxy        ~= nil then galaxyOn               = data.Galaxy        end
            if data.AntiRagdoll   ~= nil then antiRagdollSaved       = data.AntiRagdoll   end
            if data.InfJump       ~= nil then infJumpSaved           = data.InfJump       end
            if data.AutoSteal     ~= nil then autoStealSaved         = data.AutoSteal     end
            if data.StealRadius   ~= nil then AUTO_STEAL_PROX_RADIUS = data.StealRadius   end
            if data.StealDuration ~= nil then STEAL_DURATION         = data.StealDuration end
            if data.Unwalk        ~= nil then unwalkSaved            = data.Unwalk        end
            if data.ESP           ~= nil then espSaved               = data.ESP           end
            if data.NormalSpeed   ~= nil then SpeedConfig.NormalSpeed= data.NormalSpeed   end
            if data.CarrySpeed    ~= nil then SpeedConfig.CarrySpeed = data.CarrySpeed    end
        end
    end)
end
loadConfig()

-- ══════════════════════════════════════════
--   COLORES DRAGON HUB STYLE
-- ══════════════════════════════════════════
local BG_MAIN    = Color3.fromRGB(18, 18, 18)
local BG_TOPBAR  = Color3.fromRGB(22, 22, 22)
local BG_LEFT    = Color3.fromRGB(25, 25, 25)
local BG_ROW     = Color3.fromRGB(28, 28, 28)
local BG_KNOB    = Color3.fromRGB(40, 40, 40)
local CLR_ON     = Color3.fromRGB(240, 240, 240)
local CLR_OFF    = Color3.fromRGB(55, 55, 55)
local CLR_WHITE  = Color3.fromRGB(220, 220, 220)
local CLR_GRAY   = Color3.fromRGB(100, 100, 100)
local CLR_DIM    = Color3.fromRGB(180, 180, 180)
local CLR_STROKE = Color3.fromRGB(50, 50, 50)
local ESP_COLOR  = Color3.fromRGB(130, 180, 255)

local function Make(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    return obj
end
local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15), props):Play()
end

-- ══════════════════════════════════════════
--   SCREENGUI
-- ══════════════════════════════════════════
if PlayerGui:FindFirstChild("KmoneyHub") then PlayerGui:FindFirstChild("KmoneyHub"):Destroy() end

local ScreenGui = Make("ScreenGui", {
    Name="KmoneyHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PlayerGui,
})

-- ══════════════════════════════════════════
--   MAIN FRAME
-- ══════════════════════════════════════════
local MainFrame = Make("Frame", {
    Name="MainFrame", Size=UDim2.new(0,310,0,460),
    Position=UDim2.new(0.5,-155,0.5,-230),
    BackgroundColor3=BG_MAIN, BorderSizePixel=0, Parent=ScreenGui,
})
Make("UICorner", { CornerRadius=UDim.new(0,10), Parent=MainFrame })
Make("UIStroke", { Color=CLR_STROKE, Thickness=1, Parent=MainFrame })

do
    local dragging, dragStart, startPos = false, nil, nil
    MainFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=inp.Position; startPos=MainFrame.Position
        end
    end)
    MainFrame.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- ══════════════════════════════════════════
--   TOP BAR
-- ══════════════════════════════════════════
local TopBar = Make("Frame", {
    Size=UDim2.new(1,0,0,38), BackgroundColor3=BG_TOPBAR,
    BorderSizePixel=0, Parent=MainFrame,
})
Make("UICorner", { CornerRadius=UDim.new(0,10), Parent=TopBar })

Make("TextLabel", {
    Text="KMONEY HUB", Size=UDim2.new(0,120,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamBlack,
    TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=TopBar,
})

-- Mode display in topbar (like Dragon Hub)
local topModeFrame = Make("Frame", {
    Size=UDim2.new(0,80,0,24), Position=UDim2.new(0,136,0.5,-12),
    BackgroundColor3=BG_KNOB, BorderSizePixel=0, Parent=TopBar,
})
Make("UICorner", { CornerRadius=UDim.new(0,6), Parent=topModeFrame })
local topModeLabel = Make("TextLabel", {
    Text=SpeedConfig.Mode, Size=UDim2.new(0.72,0,1,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamSemibold, TextSize=11, Parent=topModeFrame,
})
local topKeyLabel = Make("TextLabel", {
    Text="Q", Size=UDim2.new(0,20,0,20),
    Position=UDim2.new(1,-22,0.5,-10),
    BackgroundColor3=Color3.fromRGB(60,60,60),
    TextColor3=CLR_WHITE, Font=Enum.Font.GothamBold, TextSize=10,
    Parent=topModeFrame,
})
Make("UICorner", { CornerRadius=UDim.new(0,4), Parent=topKeyLabel })

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == SpeedConfig.ModeKey then
        SpeedConfig.Mode = (SpeedConfig.Mode=="Carry") and "Normal" or "Carry"
        topModeLabel.Text = SpeedConfig.Mode
    end
end)

local CloseBtn = Make("TextButton", {
    Text="−", Size=UDim2.new(0,28,0,20), Position=UDim2.new(1,-32,0.5,-10),
    BackgroundColor3=Color3.fromRGB(50,50,50), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=18, BorderSizePixel=0, Parent=TopBar,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=CloseBtn })

-- ══════════════════════════════════════════
--   LEFT PANEL
-- ══════════════════════════════════════════
local LeftPanel = Make("Frame", {
    Size=UDim2.new(0,100,1,-40), Position=UDim2.new(0,0,0,40),
    BackgroundColor3=BG_LEFT, BorderSizePixel=0, Parent=MainFrame,
})
Make("UICorner", { CornerRadius=UDim.new(0,8), Parent=LeftPanel })

local RightPanel = Make("Frame", {
    Size=UDim2.new(1,-108,1,-48), Position=UDim2.new(0,106,0,44),
    BackgroundColor3=BG_MAIN, BorderSizePixel=0, Parent=MainFrame,
})

-- ══════════════════════════════════════════
--   TAB SYSTEM
-- ══════════════════════════════════════════
local Tabs = {}; local TabBtns = {}

local function CreateTab(name, index)
    local btn = Make("TextButton", {
        Name=name.."Tab", Text=name,
        Size=UDim2.new(1,-10,0,36), Position=UDim2.new(0,5,0,8+(index-1)*42),
        BackgroundColor3=Color3.fromRGB(35,35,35), TextColor3=CLR_DIM,
        Font=Enum.Font.GothamSemibold, TextSize=12, BorderSizePixel=0, Parent=LeftPanel,
    })
    Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=btn })
    local content = Make("Frame", {
        Name=name.."Content", Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, Visible=false, Parent=RightPanel,
    })
    Tabs[name]=content; TabBtns[name]=btn
    return btn, content
end

local function SelectTab(name)
    for n, c in pairs(Tabs) do
        c.Visible = (n==name)
        local btn = TabBtns[n]
        if n==name then
            Tween(btn, { BackgroundColor3=CLR_WHITE, TextColor3=Color3.fromRGB(10,10,10) })
            btn.Font = Enum.Font.GothamBlack
        else
            Tween(btn, { BackgroundColor3=Color3.fromRGB(35,35,35), TextColor3=CLR_DIM })
            btn.Font = Enum.Font.GothamSemibold
        end
    end
end

-- Tabs en orden: Speed primero (como Dragon Hub)
local tabNames = {"Speed", "Mechanics", "Visual", "Auto", "Settings"}
for i, name in ipairs(tabNames) do
    local btn, _ = CreateTab(name, i)
    btn.MouseButton1Click:Connect(function() SelectTab(name) end)
end

-- ══════════════════════════════════════════
--   HELPERS GUI
-- ══════════════════════════════════════════
local function makeSectionLabel(parent, text, yPos)
    Make("TextLabel", {
        Text=text, Size=UDim2.new(1,-10,0,18), Position=UDim2.new(0,5,0,yPos),
        BackgroundTransparency=1, TextColor3=CLR_GRAY, Font=Enum.Font.GothamBold,
        TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=parent,
    })
end

local function makeToggleRow(parent, label, yPos, callback, initState)
    local row = Make("Frame", {
        Size=UDim2.new(1,-6,0,38), Position=UDim2.new(0,3,0,yPos),
        BackgroundColor3=BG_ROW, BorderSizePixel=0, Parent=parent,
    })
    Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=row })
    Make("TextLabel", {
        Text=label, Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamSemibold,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local dSz = 16
    local state = initState or false
    local togBG = Make("Frame", {
        Size=UDim2.new(0,42,0,22), Position=UDim2.new(1,-48,0.5,-11),
        BackgroundColor3=state and CLR_ON or CLR_OFF, BorderSizePixel=0, Parent=row,
    })
    Make("UICorner", { CornerRadius=UDim.new(1,0), Parent=togBG })
    local knob = Make("Frame", {
        Size=UDim2.new(0,dSz,0,dSz),
        Position=state and UDim2.new(1,-dSz-3,0.5,-dSz/2) or UDim2.new(0,3,0.5,-dSz/2),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, Parent=togBG,
    })
    Make("UICorner", { CornerRadius=UDim.new(1,0), Parent=knob })
    local btn = Make("TextButton", {
        Text="", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=row,
    })
    btn.MouseButton1Click:Connect(function()
        state = not state
        Tween(togBG, { BackgroundColor3=state and CLR_ON or CLR_OFF })
        Tween(knob, { Position=state and UDim2.new(1,-dSz-3,0.5,-dSz/2) or UDim2.new(0,3,0.5,-dSz/2) })
        if callback then callback(state) end
        task.defer(saveConfig)
    end)
    return togBG, knob
end

local function setToggleState(togBG, knob, newState)
    local dSz = 16
    togBG.BackgroundColor3 = newState and CLR_ON or CLR_OFF
    knob.Position = newState and UDim2.new(1,-dSz-3,0.5,-dSz/2) or UDim2.new(0,3,0.5,-dSz/2)
end

-- Slider row (igual al Dragon Hub)
local function makeSliderRow(parent, label, desc, value, yPos, callback)
    local row = Make("Frame", {
        Size=UDim2.new(1,-6,0,48), Position=UDim2.new(0,3,0,yPos),
        BackgroundColor3=BG_ROW, BorderSizePixel=0, Parent=parent,
    })
    Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=row })
    Make("TextLabel", {
        Text=label, Size=UDim2.new(0.65,0,0,20), Position=UDim2.new(0,10,0,5),
        BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamSemibold,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    Make("TextLabel", {
        Text=desc, Size=UDim2.new(0.65,0,0,14), Position=UDim2.new(0,10,0,22),
        BackgroundTransparency=1, TextColor3=Color3.fromRGB(90,90,90),
        Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Left, Parent=row,
    })
    local valBox = Make("Frame", {
        Size=UDim2.new(0,54,0,26), Position=UDim2.new(1,-58,0.5,-13),
        BackgroundColor3=BG_KNOB, BorderSizePixel=0, Parent=row,
    })
    Make("UICorner", { CornerRadius=UDim.new(0,6), Parent=valBox })
    local valLabel = Instance.new("TextBox")
    valLabel.Size=UDim2.new(1,0,1,0); valLabel.BackgroundTransparency=1
    valLabel.Text=tostring(value); valLabel.TextColor3=CLR_WHITE
    valLabel.Font=Enum.Font.GothamBold; valLabel.TextSize=12
    valLabel.ClearTextOnFocus=false; valLabel.BorderSizePixel=0; valLabel.Parent=valBox
    valLabel.FocusLost:Connect(function()
        local v = tonumber(valLabel.Text)
        if v then
            v = math.clamp(math.floor(v*10+0.5)/10, 0, 500)
            valLabel.Text = tostring(v)
            if callback then callback(v) end
        else valLabel.Text = tostring(value) end
    end)
    local sliderBG = Make("Frame", {
        Size=UDim2.new(1,-20,0,4), Position=UDim2.new(0,10,1,-8),
        BackgroundColor3=Color3.fromRGB(50,50,50), BorderSizePixel=0, Parent=row,
    })
    Make("UICorner", { CornerRadius=UDim.new(1,0), Parent=sliderBG })
    local sliderFill = Make("Frame", {
        Size=UDim2.new(math.clamp(value/200,0,1),0,1,0),
        BackgroundColor3=CLR_WHITE, BorderSizePixel=0, Parent=sliderBG,
    })
    Make("UICorner", { CornerRadius=UDim.new(1,0), Parent=sliderFill })
    local dragging = false
    sliderBG.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local rel = math.clamp((inp.Position.X-sliderBG.AbsolutePosition.X)/sliderBG.AbsoluteSize.X,0,1)
            local newVal = math.round(rel*200*10)/10
            sliderFill.Size = UDim2.new(rel,0,1,0)
            valLabel.Text = tostring(newVal)
            if callback then callback(newVal) end
        end
    end)
    return valLabel
end

-- ══════════════════════════════════════════
--   SPEED TAB (primer tab, igual Dragon Hub)
-- ══════════════════════════════════════════
local SpeedContent = Tabs["Speed"]
makeSectionLabel(SpeedContent, "SPEED CONFIGURATION", 4)

makeSliderRow(SpeedContent, "Normal Speed", "Walking / Running speed",
    SpeedConfig.NormalSpeed, 26, function(v) SpeedConfig.NormalSpeed = v; saveConfig() end)

makeSliderRow(SpeedContent, "Carry Speed", "Speed while holding an item",
    SpeedConfig.CarrySpeed, 82, function(v) SpeedConfig.CarrySpeed = v; saveConfig() end)

-- Mode row
local modeRow = Make("Frame", {
    Size=UDim2.new(1,-6,0,40), Position=UDim2.new(0,3,0,138),
    BackgroundColor3=BG_ROW, BorderSizePixel=0, Parent=SpeedContent,
})
Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=modeRow })
Make("TextLabel", {
    Text="Mode", Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamSemibold,
    TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=modeRow,
})
local modeDisplay = Make("Frame", {
    Size=UDim2.new(0,80,0,26), Position=UDim2.new(1,-86,0.5,-13),
    BackgroundColor3=BG_KNOB, BorderSizePixel=0, Parent=modeRow,
})
Make("UICorner", { CornerRadius=UDim.new(0,6), Parent=modeDisplay })
local modeLabel = Make("TextLabel", {
    Text=SpeedConfig.Mode, Size=UDim2.new(0.72,0,1,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamSemibold, TextSize=11, Parent=modeDisplay,
})
local keyBadge = Make("TextLabel", {
    Text="Q", Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-22,0.5,-10),
    BackgroundColor3=Color3.fromRGB(60,60,60), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=10, Parent=modeDisplay,
})
Make("UICorner", { CornerRadius=UDim.new(0,4), Parent=keyBadge })

-- Update mode labels when key pressed
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == SpeedConfig.ModeKey then
        modeLabel.Text = SpeedConfig.Mode
        topModeLabel.Text = SpeedConfig.Mode
    end
end)

-- ══════════════════════════════════════════
--   MECHANICS TAB (antes Misc)
-- ══════════════════════════════════════════
local MechContent = Tabs["Mechanics"]
makeSectionLabel(MechContent, "MECHANICS", 4)

local B3bg, K3 = makeToggleRow(MechContent, "Anti Ragdoll", 26, function(v)
    antiRagdollOn = v; toggleAntiRagdoll(v)
end, antiRagdollSaved)
antiRagdollOn = antiRagdollSaved
if antiRagdollOn then setToggleState(B3bg,K3,true); toggleAntiRagdoll(true) end

local B4bg, K4 = makeToggleRow(MechContent, "Inf Jump", 72, function(v)
    infJumpOn = v
end, infJumpSaved)
infJumpOn = infJumpSaved
if infJumpOn then setToggleState(B4bg,K4,true) end

local B6bg, K6 = makeToggleRow(MechContent, "Unwalk", 118, function(v)
    unwalkOn = v
    if v then
        local char=me.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
        for _,t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
        if unwalkConn then unwalkConn:Disconnect() end
        unwalkConn = RS.Heartbeat:Connect(function()
            if not unwalkOn then unwalkConn:Disconnect(); unwalkConn=nil; return end
            local c=me.Character; if not c then return end
            local h=c:FindFirstChildOfClass("Humanoid"); if not h then return end
            local an=h:FindFirstChildOfClass("Animator"); if not an then return end
            for _,t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
        end)
    else
        if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end
    end
end, unwalkSaved)
unwalkOn = unwalkSaved
if unwalkOn then setToggleState(B6bg,K6,true) end

local B7bg, K7 = makeToggleRow(MechContent, "ESP", 164, function(v)
    espOn = v
    if v then enableESP() else disableESP() end
end, espSaved)
espOn = espSaved

-- ══════════════════════════════════════════
--   VISUAL TAB
-- ══════════════════════════════════════════
local VisContent = Tabs["Visual"]
makeSectionLabel(VisContent, "VISUAL", 4)

local B1bg, K1 = makeToggleRow(VisContent, "Dark Mode", 26, function(v)
    darkOn = v
    if v then enableOptimizer(); enableDarkMode()
    else disableOptimizer(); disableDarkMode() end
end, darkOn)
if darkOn then enableOptimizer(); enableDarkMode() end

local B2bg, K2 = makeToggleRow(VisContent, "Galaxy Sky", 72, function(v)
    galaxyOn = v; galaxyCfg.on = v
    if v then enableGalaxySkyBright() else disableGalaxySkyBright() end
end, galaxyOn)
if galaxyOn then galaxyCfg.on = true; enableGalaxySkyBright() end

-- ══════════════════════════════════════════
--   AUTO TAB
-- ══════════════════════════════════════════
local AutoContent = Tabs["Auto"]
makeSectionLabel(AutoContent, "AUTO STEAL", 4)

local B5bg, K5 = makeToggleRow(AutoContent, "Auto Steal", 26, function(v)
    autoStealActive = v
    if v then enableAutoSteal() else disableAutoSteal() end
end, autoStealSaved)
autoStealActive = autoStealSaved

-- Steal Duration
local durRow = Make("Frame", {
    Size=UDim2.new(1,-6,0,38), Position=UDim2.new(0,3,0,72),
    BackgroundColor3=BG_ROW, BorderSizePixel=0, Parent=AutoContent,
})
Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=durRow })
Make("TextLabel", {
    Text="Steal Duration", Size=UDim2.new(0.55,0,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamSemibold,
    TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=durRow,
})
local durValBox = Make("Frame", {
    Size=UDim2.new(0,70,0,26), Position=UDim2.new(1,-74,0.5,-13),
    BackgroundColor3=BG_KNOB, BorderSizePixel=0, Parent=durRow,
})
Make("UICorner", { CornerRadius=UDim.new(0,6), Parent=durValBox })
local durMinus = Make("TextButton", {
    Text="−", Size=UDim2.new(0,22,0,22), Position=UDim2.new(0,2,0.5,-11),
    BackgroundColor3=Color3.fromRGB(55,55,55), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0, Parent=durValBox,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=durMinus })
local durLbl = Make("TextLabel", {
    Text=string.format("%.2f",STEAL_DURATION), Size=UDim2.new(0,22,1,0),
    Position=UDim2.new(0,24,0,0), BackgroundTransparency=1, TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=11, Parent=durValBox,
})
local durPlus = Make("TextButton", {
    Text="+", Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-24,0.5,-11),
    BackgroundColor3=Color3.fromRGB(55,55,55), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0, Parent=durValBox,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=durPlus })
durMinus.MouseButton1Click:Connect(function()
    STEAL_DURATION=math.max(0.01,math.floor((STEAL_DURATION-0.01)*100+0.5)/100)
    durLbl.Text=string.format("%.2f",STEAL_DURATION)
end)
durPlus.MouseButton1Click:Connect(function()
    STEAL_DURATION=math.floor((STEAL_DURATION+0.01)*100+0.5)/100
    durLbl.Text=string.format("%.2f",STEAL_DURATION)
end)

-- Steal Radius
local radRow = Make("Frame", {
    Size=UDim2.new(1,-6,0,38), Position=UDim2.new(0,3,0,118),
    BackgroundColor3=BG_ROW, BorderSizePixel=0, Parent=AutoContent,
})
Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=radRow })
Make("TextLabel", {
    Text="Steal Radius", Size=UDim2.new(0.55,0,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, TextColor3=CLR_WHITE, Font=Enum.Font.GothamSemibold,
    TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=radRow,
})
local radValBox = Make("Frame", {
    Size=UDim2.new(0,70,0,26), Position=UDim2.new(1,-74,0.5,-13),
    BackgroundColor3=BG_KNOB, BorderSizePixel=0, Parent=radRow,
})
Make("UICorner", { CornerRadius=UDim.new(0,6), Parent=radValBox })
local radMinus = Make("TextButton", {
    Text="−", Size=UDim2.new(0,22,0,22), Position=UDim2.new(0,2,0.5,-11),
    BackgroundColor3=Color3.fromRGB(55,55,55), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0, Parent=radValBox,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=radMinus })
local radLbl = Make("TextLabel", {
    Text=tostring(AUTO_STEAL_PROX_RADIUS), Size=UDim2.new(0,22,1,0),
    Position=UDim2.new(0,24,0,0), BackgroundTransparency=1, TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=11, Parent=radValBox,
})
local radPlus = Make("TextButton", {
    Text="+", Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-24,0.5,-11),
    BackgroundColor3=Color3.fromRGB(55,55,55), TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0, Parent=radValBox,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=radPlus })
radMinus.MouseButton1Click:Connect(function()
    AUTO_STEAL_PROX_RADIUS=math.max(1,AUTO_STEAL_PROX_RADIUS-1)
    radLbl.Text=tostring(AUTO_STEAL_PROX_RADIUS)
end)
radPlus.MouseButton1Click:Connect(function()
    AUTO_STEAL_PROX_RADIUS=AUTO_STEAL_PROX_RADIUS+1
    radLbl.Text=tostring(AUTO_STEAL_PROX_RADIUS)
end)

-- ══════════════════════════════════════════
--   SETTINGS TAB
-- ══════════════════════════════════════════
local SetContent = Tabs["Settings"]
makeSectionLabel(SetContent, "CONFIG", 4)

local saveBtn = Make("TextButton", {
    Text="SAVE CONFIG", Size=UDim2.new(1,-6,0,38), Position=UDim2.new(0,3,0,26),
    BackgroundColor3=BG_ROW, TextColor3=CLR_WHITE, Font=Enum.Font.GothamBold,
    TextSize=12, BorderSizePixel=0, Parent=SetContent,
})
Make("UICorner", { CornerRadius=UDim.new(0,7), Parent=saveBtn })
saveBtn.MouseButton1Click:Connect(function()
    saveConfig(); saveBtn.Text="SAVED!"
    task.delay(1.2, function() saveBtn.Text="SAVE CONFIG" end)
end)

Make("TextLabel", {
    Text="kmoney hub", Size=UDim2.new(1,-10,0,20), Position=UDim2.new(0,5,1,-30),
    BackgroundTransparency=1, TextColor3=Color3.fromRGB(70,70,70),
    Font=Enum.Font.Gotham, TextSize=9, TextXAlignment=Enum.TextXAlignment.Center, Parent=SetContent,
})

-- ══════════════════════════════════════════
--   PROGRESS BAR HUD
-- ══════════════════════════════════════════
local BottomBar = Make("Frame", {
    Name="BottomBar", Size=UDim2.new(0,320,0,36), Position=UDim2.new(0.5,-160,1,-70),
    BackgroundColor3=BG_MAIN, BackgroundTransparency=0.1, BorderSizePixel=0,
    Visible=false, ZIndex=30, Parent=ScreenGui,
})
Make("UICorner", { CornerRadius=UDim.new(0,8), Parent=BottomBar })
Make("UIStroke", { Color=CLR_STROKE, Thickness=1, Parent=BottomBar })

local BottomFill = Make("Frame", {
    Size=UDim2.new(0,0,1,0), BackgroundColor3=CLR_WHITE,
    BorderSizePixel=0, ZIndex=31, Parent=BottomBar,
})
Make("UICorner", { CornerRadius=UDim.new(0,8), Parent=BottomFill })

local PctLabel = Make("TextLabel", {
    Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, Text="0%", TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=32, Parent=BottomBar,
})

local RadiusLabel = Make("TextLabel", {
    Size=UDim2.new(0,80,1,0), Position=UDim2.new(1,-140,0,0),
    BackgroundTransparency=1, Text="Radius: "..AUTO_STEAL_PROX_RADIUS,
    TextColor3=CLR_WHITE, Font=Enum.Font.GothamBold, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Right, ZIndex=32, Parent=BottomBar,
})

local function updateRadiusLabel()
    RadiusLabel.Text = "Radius: "..AUTO_STEAL_PROX_RADIUS
end

local RadMinusBtn = Make("TextButton", {
    Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-56,0.5,-10),
    BackgroundColor3=Color3.fromRGB(50,50,50), Text="−", TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0, ZIndex=33, Parent=BottomBar,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=RadMinusBtn })
local RadPlusBtn = Make("TextButton", {
    Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-32,0.5,-10),
    BackgroundColor3=Color3.fromRGB(50,50,50), Text="+", TextColor3=CLR_WHITE,
    Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0, ZIndex=33, Parent=BottomBar,
})
Make("UICorner", { CornerRadius=UDim.new(0,5), Parent=RadPlusBtn })
RadMinusBtn.MouseButton1Click:Connect(function()
    AUTO_STEAL_PROX_RADIUS=math.max(1,AUTO_STEAL_PROX_RADIUS-1)
    updateRadiusLabel(); radLbl.Text=tostring(AUTO_STEAL_PROX_RADIUS)
end)
RadPlusBtn.MouseButton1Click:Connect(function()
    AUTO_STEAL_PROX_RADIUS=AUTO_STEAL_PROX_RADIUS+1
    updateRadiusLabel(); radLbl.Text=tostring(AUTO_STEAL_PROX_RADIUS)
end)

-- ══════════════════════════════════════════
--   CLOSE BUTTON
-- ══════════════════════════════════════════
CloseBtn.MouseButton1Click:Connect(function()
    disableGalaxySkyBright(); toggleAntiRagdoll(false)
    if unwalkConn then unwalkConn:Disconnect(); unwalkConn=nil end
    Tween(MainFrame, { Size=UDim2.new(0,310,0,0) }, 0.2)
    task.delay(0.22, function() MainFrame.Visible=false end)
end)

-- ══════════════════════════════════════════
--   INF JUMP
-- ══════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not infJumpOn then return end
    local char=me.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if hrp.AssemblyLinearVelocity.Y < -80 then
        hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,-80,hrp.AssemblyLinearVelocity.Z)
    end
end)
UserInputService.JumpRequest:Connect(function()
    if not infJumpOn then return end
    local char=me.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,54,hrp.AssemblyLinearVelocity.Z)
end)

-- ══════════════════════════════════════════
--   ESP
-- ══════════════════════════════════════════
local espObjects={}; local espConnections={}
local function createESP(plr)
    if plr==me or not plr.Character then return end
    if plr.Character:FindFirstChild("NightESP") then return end
    local c=plr.Character; local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local head=c:FindFirstChild("Head")
    local hum=c:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
    local hitbox=Instance.new("BoxHandleAdornment")
    hitbox.Name="NightESP"; hitbox.Adornee=hrp; hitbox.Size=Vector3.new(4,6,2)
    hitbox.Color3=ESP_COLOR; hitbox.Transparency=0.3; hitbox.ZIndex=10; hitbox.AlwaysOnTop=true; hitbox.Parent=c
    espObjects[plr]=hitbox
    if head then
        local bb=Instance.new("BillboardGui"); bb.Name="ESP_Name"; bb.Adornee=head
        bb.Size=UDim2.new(0,200,0,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=c
        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text=plr.DisplayName or plr.Name; lbl.TextColor3=ESP_COLOR; lbl.Font=Enum.Font.GothamBold
        lbl.TextScaled=true; lbl.TextStrokeTransparency=0.4; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.Parent=bb
    end
end
local function removeESP(plr)
    pcall(function()
        if plr.Character then
            local h=plr.Character:FindFirstChild("NightESP"); if h then h:Destroy() end
            local n=plr.Character:FindFirstChild("ESP_Name"); if n then n:Destroy() end
            local hum=plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Automatic end
        end
        espObjects[plr]=nil
    end)
end
function enableESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=me then
            if plr.Character then pcall(function() createESP(plr) end) end
            table.insert(espConnections,plr.CharacterAdded:Connect(function()
                task.wait(0.1); if espOn then pcall(function() createESP(plr) end) end
            end))
        end
    end
    table.insert(espConnections,Players.PlayerAdded:Connect(function(plr)
        if plr==me then return end
        table.insert(espConnections,plr.CharacterAdded:Connect(function()
            task.wait(0.1); if espOn then pcall(function() createESP(plr) end) end
        end))
    end))
end
function disableESP()
    for _,plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end
    for _,conn in ipairs(espConnections) do if conn and conn.Connected then conn:Disconnect() end end
    espConnections={}; espObjects={}
end
if espSaved then setToggleState(B7bg,K7,true); enableESP() end

-- ══════════════════════════════════════════
--   AUTO STEAL ENGINE
-- ══════════════════════════════════════════
local autoStealStealConnection=nil; local autoStealAnimalsCache={}
local autoStealPromptCache={}; local autoStealLastFire={}; local autoStealScannerStarted=false
local animalsDataAS={}
pcall(function() animalsDataAS=require(ReplicatedStorage:WaitForChild("Datas",5):WaitForChild("Animals",5)) end)

local stealCirclePart, stealCircleConn = nil, nil
local function hideStealCircle()
    if stealCirclePart then stealCirclePart:Destroy(); stealCirclePart=nil end
    if stealCircleConn then stealCircleConn:Disconnect(); stealCircleConn=nil end
end
local function showStealCircle(radius)
    if stealCirclePart then stealCirclePart.Size=Vector3.new(0.15,radius*2,radius*2); return end
    stealCirclePart=Instance.new("Part"); stealCirclePart.Name="KmoneyStealCircle"
    stealCirclePart.Shape=Enum.PartType.Cylinder; stealCirclePart.Size=Vector3.new(0.15,radius*2,radius*2)
    stealCirclePart.Anchored=true; stealCirclePart.CanCollide=false; stealCirclePart.CastShadow=false
    stealCirclePart.Material=Enum.Material.Neon; stealCirclePart.Color=Color3.fromRGB(255,255,255)
    stealCirclePart.Transparency=0.55; stealCirclePart.Parent=workspace
    stealCircleConn=RunService.Heartbeat:Connect(function()
        if not autoStealActive then hideStealCircle(); return end
        local char=me.Character; if char and stealCirclePart then
            local root=char:FindFirstChild("HumanoidRootPart")
            if root then stealCirclePart.CFrame=CFrame.new(root.Position+Vector3.new(0,-2.8,0))*CFrame.Angles(0,0,math.rad(90)) end
        end
    end)
end

local function animateProgressBar()
    task.spawn(function()
        BottomFill.Size=UDim2.new(0,0,1,0); PctLabel.Text="0%"
        local steps=20; local stepWait=STEAL_DURATION/steps
        for i=1,steps do
            BottomFill.Size=UDim2.new(i/steps,0,1,0); PctLabel.Text=math.floor(i/steps*100).."%"
            task.wait(stepWait)
        end
        task.wait(0.2); BottomFill.Size=UDim2.new(0,0,1,0); PctLabel.Text="0%"
    end)
end

local function autoSteal_isMyBase(plotName)
    local plots=workspace:FindFirstChild("Plots"); local plot=plots and plots:FindFirstChild(plotName); if not plot then return false end
    local sign=plot:FindFirstChild("PlotSign"); if not sign then return false end
    local yb=sign:FindFirstChild("YourBase"); if yb and yb:IsA("BillboardGui") then return yb.Enabled==true end; return false
end
local function autoSteal_scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if autoSteal_isMyBase(plot.Name) then return end
    local podiums=plot:FindFirstChild("AnimalPodiums"); if not podiums then return end
    for _,podium in ipairs(podiums:GetChildren()) do
        if podium:IsA("Model") and podium:FindFirstChild("Base") then
            table.insert(autoStealAnimalsCache,{
                plot=plot.Name, slot=podium.Name,
                worldPosition=podium:GetPivot().Position, uid=plot.Name.."_"..podium.Name,
            })
        end
    end
end
local function autoSteal_initScanner()
    if autoStealScannerStarted then return end; autoStealScannerStarted=true
    task.spawn(function()
        task.wait(2); local plots=workspace:WaitForChild("Plots",10); if not plots then return end
        for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then autoSteal_scanPlot(plot) end end
        plots.ChildAdded:Connect(function(plot) if plot:IsA("Model") then task.wait(0.5); autoSteal_scanPlot(plot) end end)
        task.spawn(function()
            while task.wait(4) do
                autoStealAnimalsCache={}; autoStealPromptCache={}
                for _,plot in ipairs(plots:GetChildren()) do if plot:IsA("Model") then autoSteal_scanPlot(plot) end end
            end
        end)
    end)
end
local function autoSteal_findPrompt(animalData)
    if not animalData then return nil end
    local cached=autoStealPromptCache[animalData.uid]; if cached and cached.Parent then return cached end
    local plots=workspace:FindFirstChild("Plots"); if not plots then return nil end
    local plot=plots:FindFirstChild(animalData.plot); if not plot then return nil end
    local podiums=plot:FindFirstChild("AnimalPodiums"); if not podiums then return nil end
    local podium=podiums:FindFirstChild(animalData.slot); if not podium then return nil end
    local base=podium:FindFirstChild("Base"); if not base then return nil end
    local spawn=base:FindFirstChild("Spawn"); if not spawn then return nil end
    for _,desc in ipairs(spawn:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then autoStealPromptCache[animalData.uid]=desc; return desc end
    end; return nil
end
local function autoSteal_fire(prompt, uid)
    local now=tick(); local last=autoStealLastFire[uid] or 0
    if (now-last)<STEAL_DURATION then return false end
    autoStealLastFire[uid]=now; pcall(function() fireproximityprompt(prompt) end); return true
end
local function autoSteal_getNearest()
    local char=me.Character; if not char then return nil,nil end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil,nil end
    local nearest,nearestPrompt,minDist=nil,nil,math.huge
    for _,animalData in ipairs(autoStealAnimalsCache) do
        if autoSteal_isMyBase(animalData.plot) then continue end
        if not animalData.worldPosition then continue end
        local dist=(hrp.Position-animalData.worldPosition).Magnitude
        if dist<AUTO_STEAL_PROX_RADIUS and dist<minDist then
            local prompt=autoStealPromptCache[animalData.uid]
            if not prompt or not prompt.Parent then prompt=autoSteal_findPrompt(animalData) end
            if prompt and prompt.Parent then minDist=dist; nearest=animalData; nearestPrompt=prompt end
        end
    end
    return nearest,nearestPrompt
end
local function startAutoStealLoop()
    if autoStealStealConnection then autoStealStealConnection:Disconnect() end
    autoStealStealConnection=RunService.Heartbeat:Connect(function()
        if not autoStealActive then return end
        local target,prompt=autoSteal_getNearest(); if not target or not prompt then return end
        if autoSteal_fire(prompt,target.uid) then task.spawn(animateProgressBar) end
    end)
end
local function stopAutoStealLoop()
    if autoStealStealConnection then autoStealStealConnection:Disconnect(); autoStealStealConnection=nil end
end
function enableAutoSteal()
    autoStealActive=true; autoSteal_initScanner(); startAutoStealLoop()
    showStealCircle(AUTO_STEAL_PROX_RADIUS); BottomBar.Visible=true; updateRadiusLabel()
end
function disableAutoSteal()
    autoStealActive=false; stopAutoStealLoop(); hideStealCircle()
    BottomBar.Visible=false; BottomFill.Size=UDim2.new(0,0,1,0); PctLabel.Text="0%"
end
if autoStealSaved then setToggleState(B5bg,K5,true); enableAutoSteal() end

-- ══════════════════════════════════════════
--   OPEN ANIMATION
-- ══════════════════════════════════════════
SelectTab("Speed")
MainFrame.Size = UDim2.new(0,310,0,0)
Tween(MainFrame, { Size=UDim2.new(0,310,0,460) }, 0.25)

print("[KMONEY HUB] Loaded!")
