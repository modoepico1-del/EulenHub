-- ╔══════════════════════════════════════╗
-- ║           DEMONTIME HUB              ║
-- ╚══════════════════════════════════════╝

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local me          = Players.LocalPlayer
local player      = me
local LocalPlayer = me
local RS          = RunService
local Camera      = workspace.CurrentCamera

-- ══════════════════════════════════════
--  VARIABLES DE ESTADO (declaradas antes de saveConfig)
-- ══════════════════════════════════════

local unwalkOn           = false
local unwalkConn         = nil
local xrayOn             = false
local espOn              = false
local darkOn             = false
local antiRagdollEnabled = false
local fovValue           = 70  -- valor por defecto

-- ══════════════════════════════════════
--  SAVE / LOAD CONFIG
-- ══════════════════════════════════════

local CONFIG_FILE = "DEMONTIME_config.json"

-- saveConfig declarada AQUI, despues de las variables, para que lea valores reales
local function saveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            Unwalk      = unwalkOn,
            Xray        = xrayOn,
            ESP         = espOn,
            Darkmode    = darkOn,
            AntiRagdoll = antiRagdollEnabled,
            FOV         = fovValue,
        }))
    end)
end

local savedCfg = {}
pcall(function() savedCfg = HttpService:JSONDecode(readfile(CONFIG_FILE)) end)

-- ══════════════════════════════════════
--  GUI SETUP
-- ══════════════════════════════════════

if CoreGui:FindFirstChild("DEMONTIME_GUI") then
    CoreGui:FindFirstChild("DEMONTIME_GUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "DEMONTIME_GUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text             = "DEMONTIME"
ToggleBtn.Size             = UDim2.new(0, 110, 0, 28)
ToggleBtn.Position         = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.TextColor3       = Color3.fromRGB(255, 0, 0)
ToggleBtn.TextSize         = 12
ToggleBtn.Font             = Enum.Font.GothamBlack
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.ZIndex           = 10
ToggleBtn.Parent           = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent       = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color        = Color3.fromRGB(255, 0, 0)
ToggleStroke.Thickness    = 1.5
ToggleStroke.Transparency = 0.0
ToggleStroke.Parent       = ToggleBtn

local MainFrame = Instance.new("Frame")
MainFrame.Size               = UDim2.new(0, 300, 0, 680)
MainFrame.Position           = UDim2.new(0, 16, 0.5, -340)
MainFrame.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0
MainFrame.BorderSizePixel    = 0
MainFrame.Active             = true
MainFrame.Draggable          = true
MainFrame.ClipsDescendants   = true
MainFrame.Visible            = true
MainFrame.Parent             = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent       = MainFrame

local function addNeonBorder(parent, thickness, color)
    local glow = Instance.new("Frame")
    glow.Size                   = UDim2.new(1, thickness*6, 1, thickness*6)
    glow.Position               = UDim2.new(0, -thickness*3, 0, -thickness*3)
    glow.BackgroundColor3       = color
    glow.BackgroundTransparency = 0.72
    glow.BorderSizePixel        = 0
    glow.ZIndex                 = parent.ZIndex - 1
    glow.Parent                 = parent
    local gc = Instance.new("UICorner")
    gc.CornerRadius = UDim.new(0, 14)
    gc.Parent       = glow
    local mid = Instance.new("Frame")
    mid.Size                   = UDim2.new(1, thickness*3, 1, thickness*3)
    mid.Position               = UDim2.new(0, -thickness*1.5, 0, -thickness*1.5)
    mid.BackgroundColor3       = color
    mid.BackgroundTransparency = 0.50
    mid.BorderSizePixel        = 0
    mid.ZIndex                 = parent.ZIndex - 1
    mid.Parent                 = parent
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 12)
    mc.Parent       = mid
    local stroke = Instance.new("UIStroke")
    stroke.Color           = color
    stroke.Thickness       = thickness
    stroke.Transparency    = 0.0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent          = parent
end

addNeonBorder(MainFrame, 2, Color3.fromRGB(255, 0, 0))

local TitleBar = Instance.new("Frame")
TitleBar.Size              = UDim2.new(1, 0, 0, 42)
TitleBar.Position          = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
TitleBar.BorderSizePixel   = 0
TitleBar.ZIndex            = 3
TitleBar.Parent            = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent       = TitleBar

local TitleLine = Instance.new("Frame")
TitleLine.Size             = UDim2.new(1, 0, 0, 2)
TitleLine.Position         = UDim2.new(0, 0, 1, -2)
TitleLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
TitleLine.BorderSizePixel  = 0
TitleLine.ZIndex           = 4
TitleLine.Parent           = TitleBar

local lineGlow = Instance.new("Frame")
lineGlow.Size                   = UDim2.new(1, 0, 0, 8)
lineGlow.Position               = UDim2.new(0, 0, 1, -5)
lineGlow.BackgroundColor3       = Color3.fromRGB(255, 0, 0)
lineGlow.BackgroundTransparency = 0.6
lineGlow.BorderSizePixel        = 0
lineGlow.ZIndex                 = 3
lineGlow.Parent                 = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text                   = "DEMONTIME"
TitleLabel.Size                   = UDim2.new(1, -50, 1, 0)
TitleLabel.Position               = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3             = Color3.fromRGB(255, 0, 0)
TitleLabel.TextSize               = 17
TitleLabel.Font                   = Enum.Font.GothamBlack
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
TitleLabel.ZIndex                 = 5
TitleLabel.Parent                 = TitleBar

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color        = Color3.fromRGB(0, 0, 0)
TitleStroke.Thickness    = 2.5
TitleStroke.Transparency = 0.0
TitleStroke.Parent       = TitleLabel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "X"
CloseBtn.Size              = UDim2.new(0, 28, 0, 28)
CloseBtn.Position          = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
CloseBtn.TextColor3        = Color3.fromRGB(255, 0, 0)
CloseBtn.TextSize          = 13
CloseBtn.Font              = Enum.Font.GothamBlack
CloseBtn.BorderSizePixel   = 0
CloseBtn.ZIndex            = 6
CloseBtn.Parent            = TitleBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent       = CloseBtn

local CloseBtnStroke = Instance.new("UIStroke")
CloseBtnStroke.Color        = Color3.fromRGB(255, 0, 0)
CloseBtnStroke.Thickness    = 1.2
CloseBtnStroke.Transparency = 0.1
CloseBtnStroke.Parent       = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180,0,0), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0,0,0), TextColor3 = Color3.fromRGB(255,0,0)}):Play()
end)
CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,300,0,0)}):Play()
    task.delay(0.27, function()
        MainFrame.Visible = false
        MainFrame.Size    = UDim2.new(0,300,0,680)
    end)
end)

-- ContentArea deja 60px abajo para el botón Save
local ContentArea = Instance.new("Frame")
ContentArea.Size             = UDim2.new(1, 0, 1, -102)
ContentArea.Position         = UDim2.new(0, 0, 0, 42)
ContentArea.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ContentArea.BorderSizePixel  = 0
ContentArea.ZIndex           = 3
ContentArea.Parent           = MainFrame

-- ══════════════════════════════════════
--  HELPER FILA
-- ══════════════════════════════════════

local function makeOptionRow(parent, labelText, yPos)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -20, 0, 44)
    row.Position         = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    row.BorderSizePixel  = 0
    row.ZIndex           = 4
    row.Parent           = parent
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 7)
    rc.Parent       = row
    local rs2 = Instance.new("UIStroke")
    rs2.Color        = Color3.fromRGB(255, 0, 0)
    rs2.Thickness    = 0.8
    rs2.Transparency = 0.5
    rs2.Parent       = row
    local lbl = Instance.new("TextLabel")
    lbl.Text                  = labelText
    lbl.Size                  = UDim2.new(1, -70, 1, 0)
    lbl.Position              = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency= 1
    lbl.TextColor3            = Color3.fromRGB(220, 220, 220)
    lbl.TextSize              = 14
    lbl.Font                  = Enum.Font.GothamBlack
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 5
    lbl.Parent                = row
    local track = Instance.new("TextButton")
    track.Text             = ""
    track.Size             = UDim2.new(0, 44, 0, 24)
    track.Position         = UDim2.new(1, -54, 0.5, -12)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel  = 0
    track.ZIndex           = 5
    track.Parent           = row
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent       = track
    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 18, 0, 18)
    thumb.Position         = UDim2.new(0, 3, 0.5, -9)
    thumb.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 6
    thumb.Parent           = track
    local thc = Instance.new("UICorner")
    thc.CornerRadius = UDim.new(1, 0)
    thc.Parent       = thumb
    return lbl, track, thumb
end

local function toggleOn(lbl, track, thumb)
    TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200,0,0)}):Play()
    TweenService:Create(thumb, TweenInfo.new(0.2), {Position = UDim2.new(0,23,0.5,-9), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
    TweenService:Create(lbl,   TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255,80,80)}):Play()
end
local function toggleOff(lbl, track, thumb)
    TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    TweenService:Create(thumb, TweenInfo.new(0.2), {Position = UDim2.new(0,3,0.5,-9), BackgroundColor3 = Color3.fromRGB(180,180,180)}):Play()
    TweenService:Create(lbl,   TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(220,220,220)}):Play()
end

-- ══════════════════════════════════════
--  UNWALK
-- ══════════════════════════════════════

local unwalkLabel, unwalkTrack, unwalkThumb = makeOptionRow(ContentArea, "UNWALK", 10)

local function enableUnwalk()
    local char = me.Character if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid") if not hum then return end
    local anim = hum:FindFirstChildOfClass("Animator") if not anim then return end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do t:Stop(0) end
    if unwalkConn then unwalkConn:Disconnect() end
    unwalkConn = RS.Heartbeat:Connect(function()
        if not unwalkOn then unwalkConn:Disconnect() unwalkConn = nil return end
        local c  = me.Character if not c then return end
        local h  = c:FindFirstChildOfClass("Humanoid") if not h then return end
        local an = h:FindFirstChildOfClass("Animator") if not an then return end
        for _, t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0) end
    end)
end
local function disableUnwalk()
    if unwalkConn then unwalkConn:Disconnect() unwalkConn = nil end
end
unwalkTrack.MouseButton1Click:Connect(function()
    unwalkOn = not unwalkOn
    if unwalkOn then toggleOn(unwalkLabel, unwalkTrack, unwalkThumb); enableUnwalk()
    else toggleOff(unwalkLabel, unwalkTrack, unwalkThumb); disableUnwalk() end
end)

-- ══════════════════════════════════════
--  XRAY
-- ══════════════════════════════════════

local xrayLabel, xrayTrack, xrayThumb = makeOptionRow(ContentArea, "XRAY", 64)
local originalTransparency = {}
local xrayDescConn         = nil
local xrayCharConn         = nil

local function startXray()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.Brightness    = 3
        Lighting.FogEnd        = 9e9
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material   = Enum.Material.Plastic
                end
            end)
        end
    end)
    local function cleanCharacter(char)
        if char == player.Character then return end
        pcall(function()
            for _, a in ipairs(char:GetChildren()) do
                if a:IsA("Accessory") then a:Destroy() end
            end
            char.ChildAdded:Connect(function(c)
                if xrayOn and c:IsA("Accessory") then c:Destroy() end
            end)
        end)
    end
    pcall(function()
        for _, h in ipairs(workspace:GetDescendants()) do
            if h:IsA("Humanoid") then cleanCharacter(h.Parent) end
        end
    end)
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Anchored and
               (obj.Name:lower():find("base") or obj.Name:lower():find("claim") or
               (obj.Parent and (obj.Parent.Name:lower():find("base") or obj.Parent.Name:lower():find("claim")))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end)
    xrayDescConn = workspace.DescendantAdded:Connect(function(obj)
        if not xrayOn then return end
        pcall(function()
            if obj:IsA("BasePart") and obj.Anchored and
               (obj.Name:lower():find("base") or obj.Name:lower():find("claim") or
               (obj.Parent and (obj.Parent.Name:lower():find("base") or obj.Parent.Name:lower():find("claim")))) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end)
    end)
    xrayCharConn = player.CharacterAdded:Connect(function()
        task.wait(0.5) if xrayOn then startXray() end
    end)
end
local function stopXray()
    if xrayDescConn then xrayDescConn:Disconnect() xrayDescConn = nil end
    if xrayCharConn then xrayCharConn:Disconnect() xrayCharConn = nil end
    for obj, val in pairs(originalTransparency) do
        pcall(function() obj.LocalTransparencyModifier = val end)
    end
    originalTransparency = {}
end
xrayTrack.MouseButton1Click:Connect(function()
    xrayOn = not xrayOn
    if xrayOn then toggleOn(xrayLabel, xrayTrack, xrayThumb); startXray()
    else toggleOff(xrayLabel, xrayTrack, xrayThumb); stopXray() end
end)

-- ══════════════════════════════════════
--  ESP
-- ══════════════════════════════════════

local espLabel, espTrack, espThumb = makeOptionRow(ContentArea, "ESP", 118)
local espObjects     = {}
local espConnections = {}

local function createESP(plr)
    if plr == LocalPlayer then return end
    if not plr.Character then return end
    if plr.Character:FindFirstChild("NightESP") then return end
    local c       = plr.Character
    local charHrp = c:FindFirstChild("HumanoidRootPart")
    if not charHrp then return end
    local humanoid = c:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
    local hitbox = Instance.new("BoxHandleAdornment")
    hitbox.Name        = "NightESP"
    hitbox.Adornee     = charHrp
    hitbox.Size        = Vector3.new(4, 6, 2)
    hitbox.Color3      = Color3.fromRGB(255, 0, 50)
    hitbox.Transparency= 0.3
    hitbox.ZIndex      = 10
    hitbox.AlwaysOnTop = true
    hitbox.Parent      = c
    espObjects[plr]    = {box = hitbox, character = c}
end
local function removeESP(plr)
    pcall(function()
        if plr.Character then
            local hitbox = plr.Character:FindFirstChild("NightESP")
            if hitbox then hitbox:Destroy() end
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Automatic end
        end
        if espObjects[plr] then espObjects[plr] = nil end
    end)
end
local function enableESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character then pcall(function() createESP(plr) end) end
            local conn = plr.CharacterAdded:Connect(function()
                task.wait(0.1)
                if espOn then pcall(function() createESP(plr) end) end
            end)
            table.insert(espConnections, conn)
        end
    end
    local playerAddedConn = Players.PlayerAdded:Connect(function(plr)
        if plr == LocalPlayer then return end
        local charAddedConn = plr.CharacterAdded:Connect(function()
            task.wait(0.1)
            if espOn then pcall(function() createESP(plr) end) end
        end)
        table.insert(espConnections, charAddedConn)
    end)
    table.insert(espConnections, playerAddedConn)
end
local function disableESP()
    for _, plr in ipairs(Players:GetPlayers()) do pcall(function() removeESP(plr) end) end
    for _, conn in ipairs(espConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    espConnections = {}
    espObjects     = {}
end
espTrack.MouseButton1Click:Connect(function()
    espOn = not espOn
    if espOn then toggleOn(espLabel, espTrack, espThumb); enableESP()
    else toggleOff(espLabel, espTrack, espThumb); disableESP() end
end)

-- ══════════════════════════════════════
--  DARKMODE
-- ══════════════════════════════════════

local darkLabel, darkTrack, darkThumb = makeOptionRow(ContentArea, "DARKMODE", 172)
local darkModeObjects  = {}
local originalLighting = {}

local function saveLightingState()
    originalLighting = { FogStart = Lighting.FogStart }
end
local function startDarkMode()
    saveLightingState()
    darkModeObjects = {}
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            table.insert(darkModeObjects, {removed = true, instance = child, parent = Lighting})
            child.Parent = nil
        end
    end
    local sky = Instance.new("Sky")
    sky.Name                 = "BlackSky"
    sky.SkyboxBk             = "rbxassetid://2013298"
    sky.SkyboxDn             = "rbxassetid://2013298"
    sky.SkyboxFt             = "rbxassetid://2013298"
    sky.SkyboxLf             = "rbxassetid://2013298"
    sky.SkyboxRt             = "rbxassetid://2013298"
    sky.SkyboxUp             = "rbxassetid://2013298"
    sky.StarCount            = 0
    sky.CelestialBodiesShown = false
    sky.Parent               = Lighting
    table.insert(darkModeObjects, sky)
    Lighting.FogStart = 10000
end
local function stopDarkMode()
    for _, obj in ipairs(darkModeObjects) do
        pcall(function()
            if obj.removed then obj.instance.Parent = obj.parent
            else obj:Destroy() end
        end)
    end
    darkModeObjects = {}
    pcall(function() Lighting.FogStart = originalLighting.FogStart or 0 end)
end
darkTrack.MouseButton1Click:Connect(function()
    darkOn = not darkOn
    if darkOn then toggleOn(darkLabel, darkTrack, darkThumb); startDarkMode()
    else toggleOff(darkLabel, darkTrack, darkThumb); stopDarkMode() end
end)

-- ══════════════════════════════════════
--  ANTI RAGDOLL
-- ══════════════════════════════════════

local ragdollLabel, ragdollTrack, ragdollThumb = makeOptionRow(ContentArea, "ANTI RAGDOLL", 226)
local RAGDOLL_SPEED           = 16
local currentCharacter        = nil
local ragdollRemoteConnection = nil
local moveConnection          = nil
local playerModule, controls  = nil, nil

pcall(function()
    playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    controls     = playerModule:GetControls()
end)

local function cleanupRagdoll()
    if currentCharacter then
        local root = currentCharacter:FindFirstChild("HumanoidRootPart")
        if root then
            local anchor = root:FindFirstChild("RagdollAnchor")
            if anchor then anchor:Destroy() end
        end
    end
    if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
end
local function disconnectRemote()
    if ragdollRemoteConnection then ragdollRemoteConnection:Disconnect(); ragdollRemoteConnection = nil end
end
local function setupAntiRagdoll(char)
    currentCharacter = char
    cleanupRagdoll()
    disconnectRemote()
    local humanoid = char:WaitForChild("Humanoid", 5)
    local root     = char:WaitForChild("HumanoidRootPart", 5)
    local head     = char:WaitForChild("Head", 5)
    if not (humanoid and root and head) then return end
    local ragdollRemote
    pcall(function()
        ragdollRemote = ReplicatedStorage:WaitForChild("Packages", 8)
                            :WaitForChild("Ragdoll", 5)
                            :WaitForChild("Ragdoll", 5)
    end)
    if not ragdollRemote or not ragdollRemote:IsA("RemoteEvent") then return end
    ragdollRemoteConnection = ragdollRemote.OnClientEvent:Connect(function(arg1, arg2)
        if not antiRagdollEnabled then return end
        if arg1 == "Make" or arg2 == "manualM" then
            humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
            Camera.CameraSubject = head
            root.CanCollide      = false
            if controls then pcall(controls.Enable, controls) end
            cleanupRagdoll()
            local anchor = Instance.new("BodyPosition")
            anchor.Name     = "RagdollAnchor"
            anchor.MaxForce = Vector3.new(1e5,1e5,1e5)
            anchor.Position = root.Position
            anchor.D        = 200
            anchor.P        = 5000
            anchor.Parent   = root
            moveConnection = RunService.Heartbeat:Connect(function()
                if not antiRagdollEnabled then cleanupRagdoll(); return end
                local moveDir = Vector3.zero
                if controls then pcall(function() moveDir = controls:GetMoveVector() end) end
                if moveDir.Magnitude > 0.1 then
                    local cf  = Camera.CFrame
                    local fwd = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
                    local rgt = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                    anchor.Position = root.Position + (fwd*-moveDir.Z+rgt*moveDir.X).Unit*RAGDOLL_SPEED*0.1
                else
                    anchor.Position = root.Position
                end
            end)
        elseif arg1 == "Destroy" or arg2 == "manualD" then
            cleanupRagdoll()
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            root.CanCollide      = true
            Camera.CameraSubject = humanoid
            if controls then pcall(controls.Enable, controls) end
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    if antiRagdollEnabled then task.wait(1); setupAntiRagdoll(newChar) end
end)

ragdollTrack.MouseButton1Click:Connect(function()
    antiRagdollEnabled = not antiRagdollEnabled
    if antiRagdollEnabled then
        toggleOn(ragdollLabel, ragdollTrack, ragdollThumb)
        if player.Character then setupAntiRagdoll(player.Character) end
    else
        toggleOff(ragdollLabel, ragdollTrack, ragdollThumb)
        cleanupRagdoll()
        disconnectRemote()
    end
end)

-- ══════════════════════════════════════
--  FOV SLIDER
-- ══════════════════════════════════════

local fovRow = Instance.new("Frame")
fovRow.Size             = UDim2.new(1, -20, 0, 56)
fovRow.Position         = UDim2.new(0, 10, 0, 280)
fovRow.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
fovRow.BorderSizePixel  = 0
fovRow.ZIndex           = 4
fovRow.Parent           = ContentArea
local frc = Instance.new("UICorner")
frc.CornerRadius = UDim.new(0, 7)
frc.Parent       = fovRow
local frs = Instance.new("UIStroke")
frs.Color        = Color3.fromRGB(255, 0, 0)
frs.Thickness    = 0.8
frs.Transparency = 0.5
frs.Parent       = fovRow

-- Label + valor actual
local fovLabel = Instance.new("TextLabel")
fovLabel.Text                  = "FOV"
fovLabel.Size                  = UDim2.new(0, 120, 0, 22)
fovLabel.Position              = UDim2.new(0, 14, 0, 4)
fovLabel.BackgroundTransparency= 1
fovLabel.TextColor3            = Color3.fromRGB(220, 220, 220)
fovLabel.TextSize              = 14
fovLabel.Font                  = Enum.Font.GothamBlack
fovLabel.TextXAlignment        = Enum.TextXAlignment.Left
fovLabel.ZIndex                = 5
fovLabel.Parent                = fovRow

local fovValLabel = Instance.new("TextLabel")
fovValLabel.Text                  = tostring(fovValue)
fovValLabel.Size                  = UDim2.new(0, 50, 0, 22)
fovValLabel.Position              = UDim2.new(1, -62, 0, 4)
fovValLabel.BackgroundTransparency= 1
fovValLabel.TextColor3            = Color3.fromRGB(255, 80, 80)
fovValLabel.TextSize              = 13
fovValLabel.Font                  = Enum.Font.GothamBlack
fovValLabel.TextXAlignment        = Enum.TextXAlignment.Right
fovValLabel.ZIndex                = 5
fovValLabel.Parent                = fovRow

-- Track del slider
local sliderTrack = Instance.new("Frame")
sliderTrack.Size             = UDim2.new(1, -28, 0, 8)
sliderTrack.Position         = UDim2.new(0, 14, 0, 34)
sliderTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
sliderTrack.BorderSizePixel  = 0
sliderTrack.ZIndex           = 5
sliderTrack.Parent           = fovRow
local stc = Instance.new("UICorner")
stc.CornerRadius = UDim.new(1, 0)
stc.Parent       = sliderTrack

-- Fill del slider
local sliderFill = Instance.new("Frame")
sliderFill.Size             = UDim2.new(0, 0, 1, 0)  -- se actualiza abajo
sliderFill.Position         = UDim2.new(0, 0, 0, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
sliderFill.BorderSizePixel  = 0
sliderFill.ZIndex           = 6
sliderFill.Parent           = sliderTrack
local sfc = Instance.new("UICorner")
sfc.CornerRadius = UDim.new(1, 0)
sfc.Parent       = sliderFill

-- Thumb del slider
local sliderThumb = Instance.new("Frame")
sliderThumb.Size             = UDim2.new(0, 16, 0, 16)
sliderThumb.Position         = UDim2.new(0, -8, 0.5, -8)
sliderThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderThumb.BorderSizePixel  = 0
sliderThumb.ZIndex           = 7
sliderThumb.Parent           = sliderTrack
local sthc = Instance.new("UICorner")
sthc.CornerRadius = UDim.new(1, 0)
sthc.Parent       = sliderThumb

local FOV_MIN  = 70
local FOV_MAX  = 120

local function updateFOVVisual(pct)
    sliderFill.Size          = UDim2.new(pct, 0, 1, 0)
    sliderThumb.Position     = UDim2.new(pct, -8, 0.5, -8)
    fovValLabel.Text         = tostring(fovValue)
end

-- Inicializar posición según fovValue
local initPct = (fovValue - FOV_MIN) / (FOV_MAX - FOV_MIN)
updateFOVVisual(initPct)

-- Lógica de arrastre del slider
local draggingFOV = false

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = true
    end
end)
sliderTrack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingFOV and (input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch) then
        local trackPos   = sliderTrack.AbsolutePosition.X
        local trackWidth = sliderTrack.AbsoluteSize.X
        local mouseX     = input.Position.X
        local pct        = math.clamp((mouseX - trackPos) / trackWidth, 0, 1)
        fovValue         = math.floor(FOV_MIN + pct * (FOV_MAX - FOV_MIN))
        Camera.FieldOfView = fovValue
        updateFOVVisual(pct)
    end
end)

-- ══════════════════════════════════════
--  SAVE CONFIG (anclado al fondo, hijo de MainFrame)
-- ══════════════════════════════════════

local SaveFrame = Instance.new("Frame")
SaveFrame.Size                   = UDim2.new(1, -24, 0, 40)
SaveFrame.Position               = UDim2.new(0, 12, 1, -52)
SaveFrame.BackgroundTransparency = 1
SaveFrame.BorderSizePixel        = 0
SaveFrame.ZIndex                 = 6
SaveFrame.Parent                 = MainFrame  -- hijo de MainFrame → siempre al fondo

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size                   = UDim2.new(1, 0, 1, 0)
SaveBtn.BackgroundTransparency = 1
SaveBtn.Text                   = "SAVE CONFIG"
SaveBtn.Font                   = Enum.Font.GothamBlack
SaveBtn.TextSize               = 13
SaveBtn.TextColor3             = Color3.fromRGB(255, 80, 80)
SaveBtn.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
SaveBtn.TextStrokeTransparency = 0
SaveBtn.BorderSizePixel        = 0
SaveBtn.ZIndex                 = 7
SaveBtn.Parent                 = SaveFrame

Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)

local saveStroke = Instance.new("UIStroke", SaveBtn)
saveStroke.Color        = Color3.fromRGB(255, 0, 0)
saveStroke.Thickness    = 1.5
saveStroke.Transparency = 0

SaveBtn.MouseEnter:Connect(function()
    TweenService:Create(SaveBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end)
SaveBtn.MouseLeave:Connect(function()
    TweenService:Create(SaveBtn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,80,80)}):Play()
end)
SaveBtn.MouseButton1Click:Connect(function()
    saveConfig()
    SaveBtn.Text = "SAVED!"
    task.wait(1)
    SaveBtn.Text = "SAVE CONFIG"
end)

-- ══════════════════════════════════════
--  TOGGLE VENTANA
-- ══════════════════════════════════════

ToggleBtn.MouseButton1Click:Connect(function()
    if MainFrame.Visible then
        TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,300,0,0)}):Play()
        task.delay(0.27, function()
            MainFrame.Visible = false
            MainFrame.Size    = UDim2.new(0,300,0,680)
        end)
    else
        MainFrame.Size    = UDim2.new(0,300,0,0)
        MainFrame.Visible = true
        TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,300,0,680)}):Play()
    end
end)

-- ══════════════════════════════════════
--  ANIMACIONES NEON
-- ══════════════════════════════════════

task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(TitleStroke,  TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.6}):Play()
        task.wait(1.2)
        TweenService:Create(TitleStroke,  TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.0}):Play()
        task.wait(1.2)
    end
end)
task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(TitleLine,    TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.55}):Play()
        task.wait(1.0)
        TweenService:Create(TitleLine,    TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency=0.0}):Play()
        task.wait(1.0)
    end
end)
task.spawn(function()
    while ScreenGui.Parent do
        TweenService:Create(ToggleStroke, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.6}):Play()
        task.wait(1.0)
        TweenService:Create(ToggleStroke, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency=0.0}):Play()
        task.wait(1.0)
    end
end)

-- ══════════════════════════════════════
--  APERTURA Y ARRASTRE
-- ══════════════════════════════════════

MainFrame.Size = UDim2.new(0, 300, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,300,0,680)}):Play()

local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

-- ══════════════════════════════════════
--  AUTO-LOAD CONFIG AL INICIAR
-- ══════════════════════════════════════

task.defer(function()
    if savedCfg.Unwalk then
        unwalkOn = true
        toggleOn(unwalkLabel, unwalkTrack, unwalkThumb)
        enableUnwalk()
    end
    if savedCfg.Xray then
        xrayOn = true
        toggleOn(xrayLabel, xrayTrack, xrayThumb)
        startXray()
    end
    if savedCfg.ESP then
        espOn = true
        toggleOn(espLabel, espTrack, espThumb)
        enableESP()
    end
    if savedCfg.Darkmode then
        darkOn = true
        toggleOn(darkLabel, darkTrack, darkThumb)
        startDarkMode()
    end
    if savedCfg.AntiRagdoll then
        antiRagdollEnabled = true
        toggleOn(ragdollLabel, ragdollTrack, ragdollThumb)
        if player.Character then setupAntiRagdoll(player.Character) end
    end
    if savedCfg.FOV then
        fovValue = math.clamp(savedCfg.FOV, 70, 120)
        Camera.FieldOfView = fovValue
        local pct = (fovValue - FOV_MIN) / (FOV_MAX - FOV_MIN)
        updateFOVVisual(pct)
    end
end)
