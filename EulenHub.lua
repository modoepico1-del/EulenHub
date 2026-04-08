- ============================================================
-- K7 HUB v4 - WITH VYSE AIMBOT (FPS UNCAPPED) + ULTRA FAST STEAL + FLOAT (FIXED)
-- ============================================================

repeat task.wait() until game:IsLoaded()

pcall(function() setfpscap(999) end)

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local SoundService   = game:GetService("SoundService")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")
local LocalPlayer    = Players.LocalPlayer

local NORMAL_SPEED   = 60
local CARRY_SPEED    = 30
local FOV_VALUE      = 70
local UI_SCALE       = 1.0
local speedToggled   = false
local autoBatToggled = false
local hittingCooldown = false

local Keybinds = {
    AutoBat = Enum.KeyCode.E,
    SpeedToggle = Enum.KeyCode.Q,
    AutoLeft = Enum.KeyCode.Z,
    AutoRight = Enum.KeyCode.C,
    InfiniteJump = Enum.KeyCode.M,
    UIToggle = Enum.KeyCode.U,
    Float = Enum.KeyCode.F
}

local AutoLeftEnabled  = false
local AutoRightEnabled = false
local autoLeftConnection  = nil
local autoRightConnection = nil
local autoLeftPhase  = 1
local autoRightPhase = 1

local POSITION_L1 = Vector3.new(-476.48, -6.28,  92.73)
local POSITION_L2 = Vector3.new(-483.12, -4.95,  94.80)
local POSITION_R1 = Vector3.new(-476.16, -6.52,  25.62)
local POSITION_R2 = Vector3.new(-483.04, -5.09,  23.14)

local isStealing   = false
local stealStartTime = nil
local Values = {
    STEAL_RADIUS       = 20,
    STEAL_DURATION     = 0.2,
    DEFAULT_GRAVITY    = 196.2,
    GalaxyGravityPercent = 70,
    HOP_POWER          = 35,
    HOP_COOLDOWN       = 0.08,
}

local Enabled = {
    AntiRagdoll    = false,
    AutoSteal      = false,
    InfiniteJump   = false,
    ShinyGraphics  = false,
    Optimizer      = false,
    Unwalk         = false,
    AutoLeftEnabled  = false,
    AutoRightEnabled = false,
}

local Connections          = {}
local StealData            = {}
local galaxyVectorForce    = nil
local galaxyAttachment     = nil
local galaxyEnabled        = false
local hopsEnabled          = false
local lastHopTime          = 0
local spaceHeld            = false
local originalJumpPower    = 50
local originalTransparency = {}
local xrayEnabled          = false
local savedAnimations      = {}
local originalSkybox       = nil
local shinyGraphicsSky     = nil
local shinyGraphicsConn    = nil
local shinyPlanets         = {}
local shinyBloom           = nil
local shinyCC              = nil
local h, hrp, speedLbl
local progressConnection   = nil

local gui = nil
local main = nil
local speedSwBg, speedSwCircle = nil, nil
local batSwBg, batSwCircle = nil, nil
local waitingForKey = nil

-- ===== FLOAT VARIABLES (OPTIMIZED) =====
local floatEnabled    = false
local floatHeight     = 10
local floatConn       = nil
local floatAttachment = nil
local floatForce      = nil
local floatVisualSetter = nil
local cachedMass      = 0
local lastMassUpdate  = 0

local function getHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function isMyPlotByName(pn)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(pn)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled end
    end
    return false
end

local function findNearestPrompt()
    local myHrp = getHRP()
    if not myHrp then return nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local np, nd, nn = nil, math.huge, nil
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then continue end
        for _, pod in ipairs(podiums:GetChildren()) do
            pcall(function()
                local base  = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - myHrp.Position).Magnitude
                    if dist < nd and dist <= Values.STEAL_RADIUS then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, ch in ipairs(att:GetChildren()) do
                                if ch:IsA("ProximityPrompt") then
                                    np, nd, nn = ch, dist, pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    return np, nd, nn
end

local ProgressLabel, ProgressPercentLabel, ProgressBarFill, RadiusInput, DurationInput

local function ResetProgressBar()
    if ProgressLabel        then ProgressLabel.Text = "READY" end
    if ProgressPercentLabel then ProgressPercentLabel.Text = "" end
    if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(0,0,1,0) end
end

local function executeSteal(prompt, name)
    if isStealing then return end
    if not StealData[prompt] then
        StealData[prompt] = {hold={}, trigger={}, ready=true}
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(StealData[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(StealData[prompt].trigger, c.Function) end
                end
            end
        end)
    end
    local data = StealData[prompt]
    if not data.ready then return end
    data.ready   = false
    isStealing   = true
    stealStartTime = tick()
    if ProgressLabel then ProgressLabel.Text = name or "STEALING..." end
    if progressConnection then progressConnection:Disconnect() end
    progressConnection = RunService.Heartbeat:Connect(function()
        if not isStealing then progressConnection:Disconnect() return end
        local prog = math.clamp((tick()-stealStartTime)/Values.STEAL_DURATION, 0, 1)
        if ProgressBarFill      then ProgressBarFill.Size = UDim2.new(prog,0,1,0) end
        if ProgressPercentLabel then ProgressPercentLabel.Text = math.floor(prog*100).."%" end
    end)
    task.spawn(function()
        for _, f in ipairs(data.hold)    do task.spawn(f) end
        local elapsed = 0
        while elapsed < Values.STEAL_DURATION do elapsed = elapsed + task.wait() end
        for _, f in ipairs(data.trigger) do task.spawn(f) end
        if progressConnection then progressConnection:Disconnect() end
        ResetProgressBar()
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if Connections.autoSteal then return end
    Connections.autoSteal = RunService.Heartbeat:Connect(function()
        if not Enabled.AutoSteal or isStealing then return end
        local p,_,n = findNearestPrompt()
        if p then executeSteal(p,n) end
    end)
end
local function stopAutoSteal()
    if Connections.autoSteal then Connections.autoSteal:Disconnect() Connections.autoSteal=nil end
    isStealing = false
    ResetProgressBar()
end

local function startAntiRagdoll()
    if Connections.antiRagdoll then return end
    Connections.antiRagdoll = RunService.Heartbeat:Connect(function()
        if not Enabled.AntiRagdoll then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local st = hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.Running)
                workspace.CurrentCamera.CameraSubject = hum
                pcall(function()
                    local pm = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
                    if pm then require(pm:FindFirstChild("ControlModule")):Enable() end
                end)
                if root then root.Velocity=Vector3.new(0,0,0) root.RotVelocity=Vector3.new(0,0,0) end
            end
        end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end
        end
    end)
end
local function stopAntiRagdoll()
    if Connections.antiRagdoll then Connections.antiRagdoll:Disconnect() Connections.antiRagdoll=nil end
end

local function captureJumpPower()
    local c = LocalPlayer.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower>0 then originalJumpPower=hum.JumpPower end
    end
end
task.spawn(function() task.wait(1) captureJumpPower() end)
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) captureJumpPower() end)

local function setupGalaxyForce()
    pcall(function()
        local c  = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
        if galaxyVectorForce then galaxyVectorForce:Destroy() end
        if galaxyAttachment  then galaxyAttachment:Destroy()  end
        galaxyAttachment = Instance.new("Attachment"); galaxyAttachment.Parent = rp
        galaxyVectorForce = Instance.new("VectorForce")
        galaxyVectorForce.Attachment0         = galaxyAttachment
        galaxyVectorForce.ApplyAtCenterOfMass = true
        galaxyVectorForce.RelativeTo          = Enum.ActuatorRelativeTo.World
        galaxyVectorForce.Force               = Vector3.new(0,0,0)
        galaxyVectorForce.Parent              = rp
    end)
end
local function updateGalaxyForce()
    if not galaxyEnabled or not galaxyVectorForce then return end
    local c = LocalPlayer.Character; if not c then return end
    local mass = 0
    for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then mass=mass+p:GetMass() end end
    local tg = Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100)
    galaxyVectorForce.Force = Vector3.new(0, mass*(Values.DEFAULT_GRAVITY-tg)*0.95, 0)
end
local function adjustGalaxyJump()
    pcall(function()
        local c   = LocalPlayer.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if not galaxyEnabled then hum.JumpPower=originalJumpPower return end
        local ratio = math.sqrt((Values.DEFAULT_GRAVITY*(Values.GalaxyGravityPercent/100))/Values.DEFAULT_GRAVITY)
        hum.JumpPower = originalJumpPower*ratio
    end)
end
local function doMiniHop()
    if not hopsEnabled then return end
    pcall(function()
        local c   = LocalPlayer.Character; if not c then return end
        local rp  = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        if tick()-lastHopTime < Values.HOP_COOLDOWN then return end
        lastHopTime = tick()
        if hum.FloorMaterial==Enum.Material.Air then
            rp.AssemblyLinearVelocity = Vector3.new(rp.AssemblyLinearVelocity.X, Values.HOP_POWER, rp.AssemblyLinearVelocity.Z)
        end
    end)
end
local function startInfiniteJump()
    galaxyEnabled=true hopsEnabled=true setupGalaxyForce() adjustGalaxyJump()
end
local function stopInfiniteJump()
    galaxyEnabled=false hopsEnabled=false
    if galaxyVectorForce then galaxyVectorForce:Destroy() galaxyVectorForce=nil end
    if galaxyAttachment  then galaxyAttachment:Destroy()  galaxyAttachment=nil  end
    adjustGalaxyJump()
end
RunService.Heartbeat:Connect(function()
    if hopsEnabled and spaceHeld then doMiniHop() end
    if galaxyEnabled then updateGalaxyForce() end
end)

local function startUnwalk()
    local c = LocalPlayer.Character; if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
    local anim = c:FindFirstChild("Animate")
    if anim then savedAnimations.Animate=anim:Clone() anim:Destroy() end
end
local function stopUnwalk()
    local c = LocalPlayer.Character
    if c and savedAnimations.Animate then savedAnimations.Animate:Clone().Parent=c savedAnimations.Animate=nil end
end

-- ===== FLOAT (OPTIMIZED & FIXED) =====
local function setupFloatForce()
    pcall(function()
        local c  = LocalPlayer.Character; if not c then return end
        local rp = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
        if floatForce      then floatForce:Destroy()      floatForce = nil      end
        if floatAttachment then floatAttachment:Destroy() floatAttachment = nil end
        floatAttachment = Instance.new("Attachment")
        floatAttachment.Parent = rp
        floatForce = Instance.new("VectorForce")
        floatForce.Attachment0         = floatAttachment
        floatForce.ApplyAtCenterOfMass = true
        floatForce.RelativeTo          = Enum.ActuatorRelativeTo.World
        floatForce.Force               = Vector3.new(0, 0, 0)
        floatForce.Parent              = rp
    end)
end

local function startFloat()
    floatEnabled = true
    setupFloatForce()
    cachedMass = 0
    lastMassUpdate = 0
    
    if floatConn then floatConn:Disconnect() end
    floatConn = RunService.Heartbeat:Connect(function(dt)
        if not floatEnabled then return end
        pcall(function()
            local c   = LocalPlayer.Character; if not c then return end
            local rp  = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            
            -- Update mass only every 2 seconds instead of every frame
            local now = tick()
            if now - lastMassUpdate > 2 or cachedMass == 0 then
                cachedMass = 0
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then cachedMass = cachedMass + p:GetMass() end
                end
                lastMassUpdate = now
            end
            
            -- Optimized raycast
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {c}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            local result  = workspace:Raycast(rp.Position, Vector3.new(0, -500, 0), rayParams)
            local groundY = result and result.Position.Y or (rp.Position.Y - floatHeight)
            local targetY = groundY + floatHeight
            local diff    = targetY - rp.Position.Y
            
            -- Improved PID values for smoother float
            local kP  = 500  -- Increased proportional gain
            local kD  = 80   -- Increased damping
            local velY = rp.AssemblyLinearVelocity.Y
            
            -- Add a deadzone to reduce jitter
            if math.abs(diff) < 0.1 and math.abs(velY) < 0.5 then
                diff = 0
                velY = 0
            end
            
            if floatForce then
                floatForce.Force = Vector3.new(0, cachedMass * (kP * diff - kD * velY + workspace.Gravity), 0)
            end
            hum.JumpPower = 0
        end)
    end)
end

local function stopFloat()
    floatEnabled = false
    cachedMass = 0
    if floatConn      then floatConn:Disconnect()     floatConn = nil      end
    if floatForce     then floatForce:Destroy()       floatForce = nil     end
    if floatAttachment then floatAttachment:Destroy() floatAttachment = nil end
    pcall(function()
        local c   = LocalPlayer.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local rp  = c:FindFirstChild("HumanoidRootPart"); if not rp then return end
        hum.JumpPower = originalJumpPower
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {c}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(rp.Position, Vector3.new(0, -500, 0), rayParams)
        if result then
            rp.CFrame = CFrame.new(rp.Position.X, result.Position.Y + rp.Size.Y/2 + 0.1, rp.Position.Z)
            rp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- ===== XRAY =====
local xrayDescendantConn = nil
local function isXrayTarget(obj)
    if not obj:IsA("BasePart") then return false end
    if not obj.Anchored then return false end
    local nameLower = obj.Name:lower()
    local parentNameLower = (obj.Parent and obj.Parent.Name:lower()) or ""
    return nameLower:find("base") ~= nil or parentNameLower:find("base") ~= nil
end
local function applyXrayToPart(obj)
    pcall(function()
        if isXrayTarget(obj) and originalTransparency[obj] == nil then
            originalTransparency[obj] = obj.LocalTransparencyModifier
            obj.LocalTransparencyModifier = 0.85
        end
    end)
end
local function applyXrayToAll()
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do applyXrayToPart(obj) end
    end)
end
local function startXrayWatcher()
    if xrayDescendantConn then return end
    xrayDescendantConn = workspace.DescendantAdded:Connect(function(obj)
        if not xrayEnabled then return end
        task.defer(function() if xrayEnabled then applyXrayToPart(obj) end end)
    end)
end
local function stopXrayWatcher()
    if xrayDescendantConn then xrayDescendantConn:Disconnect() xrayDescendantConn = nil end
end

local function enableOptimizer()
    if getgenv and getgenv().OPTIMIZER_ACTIVE then return end
    if getgenv then getgenv().OPTIMIZER_ACTIVE=true end
    pcall(function() setfpscap(999) end)
    pcall(function()
        Lighting.GlobalShadows=false Lighting.Brightness=3 Lighting.FogEnd=9e9
    end)
    pcall(function()
        for _,obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj:Destroy()
                elseif obj:IsA("BasePart") then obj.CastShadow=false obj.Material=Enum.Material.Plastic end
            end)
        end
    end)
    xrayEnabled = true
    applyXrayToAll()
    startXrayWatcher()
end
local function disableOptimizer()
    if getgenv then getgenv().OPTIMIZER_ACTIVE=false end
    stopXrayWatcher()
    if xrayEnabled then
        for part, val in pairs(originalTransparency) do
            if part and part.Parent then part.LocalTransparencyModifier = val end
        end
        originalTransparency = {}
        xrayEnabled = false
    end
end

local function enableShinyGraphics()
    if shinyGraphicsSky then return end
    originalSkybox=Lighting:FindFirstChildOfClass("Sky")
    if originalSkybox then originalSkybox.Parent=nil end
    shinyGraphicsSky=Instance.new("Sky")
    for _,prop in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
        shinyGraphicsSky[prop]="rbxassetid://1534951537"
    end
    shinyGraphicsSky.StarCount=10000 shinyGraphicsSky.CelestialBodiesShown=false
    shinyGraphicsSky.Parent=Lighting
    shinyBloom=Instance.new("BloomEffect") shinyBloom.Intensity=1.5 shinyBloom.Size=40 shinyBloom.Threshold=0.8 shinyBloom.Parent=Lighting
    shinyCC=Instance.new("ColorCorrectionEffect") shinyCC.Saturation=0.8 shinyCC.Contrast=0.3 shinyCC.TintColor=Color3.fromRGB(200,200,200) shinyCC.Parent=Lighting
    Lighting.Ambient=Color3.fromRGB(100,100,110) Lighting.Brightness=3 Lighting.ClockTime=0
    for i=1,2 do
        local p=Instance.new("Part") p.Shape=Enum.PartType.Ball
        p.Size=Vector3.new(800+i*200,800+i*200,800+i*200) p.Anchored=true p.CanCollide=false p.CastShadow=false
        p.Material=Enum.Material.Neon p.Color=Color3.fromRGB(160+i*15,160+i*15,165+i*15) p.Transparency=0.3
        p.Position=Vector3.new(math.cos(i*2)(3000+i*500),1500+i*300,math.sin(i*2)(3000+i*500)) p.Parent=workspace
        table.insert(shinyPlanets,p)
    end
    shinyGraphicsConn=RunService.Heartbeat:Connect(function()
        if not Enabled.ShinyGraphics then return end
        local t=tick()*0.5
        Lighting.Ambient=Color3.fromRGB(100+math.sin(t)30,100+math.sin(t.8)*30,110+math.sin(t*1.2)*30)
        if shinyBloom then shinyBloom.Intensity=1.2+math.sin(t*2)*0.4 end
    end)
end
local function disableShinyGraphics()
    if shinyGraphicsConn then shinyGraphicsConn:Disconnect() shinyGraphicsConn=nil end
    if shinyGraphicsSky  then shinyGraphicsSky:Destroy()     shinyGraphicsSky=nil  end
    if originalSkybox    then originalSkybox.Parent=Lighting  end
    if shinyBloom        then shinyBloom:Destroy() shinyBloom=nil end
    if shinyCC           then shinyCC:Destroy()    shinyCC=nil    end
    for _,obj in ipairs(shinyPlanets) do if obj then obj:Destroy() end end
    shinyPlanets={}
    Lighting.Ambient=Color3.fromRGB(127,127,127) Lighting.Brightness=2 Lighting.ClockTime=14
end

local function faceSouth()
    local c=LocalPlayer.Character; if not c then return end
    local rp=c:FindFirstChild("HumanoidRootPart"); if not rp then return end
    rp.CFrame=CFrame.new(rp.Position)*CFrame.Angles(0,0,0)
    local cam=workspace.CurrentCamera
    if cam then local cp=rp.Position cam.CFrame=CFrame.new(cp.X,cp.Y+5,cp.Z-12)*CFrame.Angles(math.rad(-15),0,0) end
end
local function faceNorth()
    local c=LocalPlayer.Character; if not c then return end
    local rp=c:FindFirstChild("HumanoidRootPart"); if not rp then return end
    rp.CFrame=CFrame.new(rp.Position)*CFrame.Angles(0,math.rad(180),0)
    local cam=workspace.CurrentCamera
    if cam then local cp=rp.Position cam.CFrame=CFrame.new(cp.X,cp.Y+2,cp.Z+12)*CFrame.Angles(0,math.rad(180),0) end
end

local _G_AL_swBg, _G_AL_swCircle = nil, nil
local _G_AR_swBg, _G_AR_swCircle = nil, nil

local function startAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() end
    autoLeftPhase=1
    autoLeftConnection=RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end
        local c=LocalPlayer.Character; if not c then return end
        local rp=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local spd=NORMAL_SPEED
        if autoLeftPhase==1 then
            local tgt=Vector3.new(POSITION_L1.X,rp.Position.Y,POSITION_L1.Z)
            if (tgt-rp.Position).Magnitude<1 then
                autoLeftPhase=2
                local d=(POSITION_L2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd) return
            end
            local d=(POSITION_L1-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif autoLeftPhase==2 then
            local tgt=Vector3.new(POSITION_L2.X,rp.Position.Y,POSITION_L2.Z)
            if (tgt-rp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false) rp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoLeftEnabled=false Enabled.AutoLeftEnabled=false
                if autoLeftConnection then autoLeftConnection:Disconnect() autoLeftConnection=nil end
                autoLeftPhase=1
                if _G_AL_swBg and _G_AL_swCircle then
                    _G_AL_swBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
                    _G_AL_swCircle.Position = UDim2.new(0,3,0.5,-8)
                end
                faceSouth() return
            end
            local d=(POSITION_L2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoLeft()
    if autoLeftConnection then autoLeftConnection:Disconnect() autoLeftConnection=nil end
    autoLeftPhase=1
    local c=LocalPlayer.Character
    if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end

local function startAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() end
    autoRightPhase=1
    autoRightConnection=RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local c=LocalPlayer.Character; if not c then return end
        local rp=c:FindFirstChild("HumanoidRootPart")
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not rp or not hum then return end
        local spd=NORMAL_SPEED
        if autoRightPhase==1 then
            local tgt=Vector3.new(POSITION_R1.X,rp.Position.Y,POSITION_R1.Z)
            if (tgt-rp.Position).Magnitude<1 then
                autoRightPhase=2
                local d=(POSITION_R2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
                hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd) return
            end
            local d=(POSITION_R1-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        elseif autoRightPhase==2 then
            local tgt=Vector3.new(POSITION_R2.X,rp.Position.Y,POSITION_R2.Z)
            if (tgt-rp.Position).Magnitude<1 then
                hum:Move(Vector3.zero,false) rp.AssemblyLinearVelocity=Vector3.new(0,0,0)
                AutoRightEnabled=false Enabled.AutoRightEnabled=false
                if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection=nil end
                autoRightPhase=1
                if _G_AR_swBg and _G_AR_swCircle then
                    _G_AR_swBg.BackgroundColor3 = Color3.fromRGB(28,28,28)
                    _G_AR_swCircle.Position = UDim2.new(0,3,0.5,-8)
                end
                faceNorth() return
            end
            local d=(POSITION_R2-rp.Position); local mv=Vector3.new(d.X,0,d.Z).Unit
            hum:Move(mv,false) rp.AssemblyLinearVelocity=Vector3.new(mv.X*spd,rp.AssemblyLinearVelocity.Y,mv.Z*spd)
        end
    end)
end
local function stopAutoRight()
    if autoRightConnection then autoRightConnection:Disconnect() autoRightConnection=nil end
    autoRightPhase=1
    local c=LocalPlayer.Character
    if c then local hum=c:FindFirstChildOfClass("Humanoid") if hum then hum:Move(Vector3.zero,false) end end
end

local SAFE_DELAY = 0.08
local function getBat()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        tool = backpack:FindFirstChild("Bat")
        if tool then tool.Parent = char return tool end
    end
    return nil
end
local function tryHitBat()
    if hittingCooldown then return end
    hittingCooldown = true
    local bat = getBat()
    if bat then
        pcall(function()
            bat:Activate()
            local evt = bat:FindFirstChildWhichIsA("RemoteEvent")
            if evt then evt:FireServer() end
        end)
    end
    task.delay(SAFE_DELAY, function() hittingCooldown = false end)
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDist = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - targetHRP.Position).Magnitude
            if dist < closestDist then closestDist = dist closestPlayer = plr end
        end
    end
    return closestPlayer, closestDist
end
local function flyToFrontOfTarget(targetHRP)
    if not hrp then return end
    local forward = targetHRP.CFrame.LookVector
    local frontPos = targetHRP.Position + forward * 1.5
    local direction = (frontPos - hrp.Position).Unit
    hrp.Velocity = Vector3.new(direction.X * 56.5, direction.Y * 56.5, direction.Z * 56.5)
end

local function applyFOV(value)
    FOV_VALUE = value
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = FOV_VALUE end
end

local uiScaleInstance = nil
local lastScaleUpdate = 0
local scaleTween = nil
local targetScale = 1.0
local function applyUIScale(value)
    targetScale = value
    local now = tick()
    if now - lastScaleUpdate < 0.08 then return end
    lastScaleUpdate = now
    UI_SCALE = value
    if main and not uiScaleInstance then
        uiScaleInstance = Instance.new("UIScale")
        uiScaleInstance.Parent = main
    end
    if uiScaleInstance then
        if scaleTween then scaleTween:Cancel() end
        scaleTween = TweenService:Create(uiScaleInstance, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Scale = UI_SCALE})
        scaleTween:Play()
    end
end

local saveConfigBtn
local function saveConfig()
    local cfg={
        normalSpeed=NORMAL_SPEED, carrySpeed=CARRY_SPEED,
        fovValue=FOV_VALUE, uiScale=UI_SCALE,
        autoBatKey=Keybinds.AutoBat.Name, speedToggleKey=Keybinds.SpeedToggle.Name,
        autoLeftKey=Keybinds.AutoLeft.Name, autoRightKey=Keybinds.AutoRight.Name,
        infiniteJumpKey=Keybinds.InfiniteJump.Name,
        floatKey=Keybinds.Float.Name,
        autoStealEnabled=Enabled.AutoSteal, grabRadius=Values.STEAL_RADIUS,
        stealDuration=Values.STEAL_DURATION,
        antiRagdoll=Enabled.AntiRagdoll, infiniteJump=Enabled.InfiniteJump,
        galaxyGravity=Values.GalaxyGravityPercent, hopPower=Values.HOP_POWER,
        optimizer=Enabled.Optimizer, unwalk=Enabled.Unwalk,
        shinyGraphics=Enabled.ShinyGraphics,
        autoLeftEnabled=Enabled.AutoLeftEnabled, autoRightEnabled=Enabled.AutoRightEnabled,
        floatEnabled=floatEnabled,
        floatHeight=floatHeight,
    }
    local ok=false
    if writefile then pcall(function() writefile("K7HubConfig.json",HttpService:JSONEncode(cfg)) ok=true end) end
    if saveConfigBtn then
        local prev=saveConfigBtn.Text
        saveConfigBtn.Text = ok and "Saved!" or "Failed!"
        task.wait(1.5)
        saveConfigBtn.Text = prev
    end
    return ok
end
local function loadConfig()
    if not (isfile and isfile("K7HubConfig.json")) then return end
    local ok,cfg=pcall(function() return HttpService:JSONDecode(readfile("K7HubConfig.json")) end)
    if not ok or not cfg then return end
    if cfg.normalSpeed  then NORMAL_SPEED=cfg.normalSpeed end
    if cfg.carrySpeed   then CARRY_SPEED=cfg.carrySpeed   end
    if cfg.fovValue     then FOV_VALUE=cfg.fovValue       end
    if cfg.uiScale      then UI_SCALE=cfg.uiScale         end
    if cfg.autoBatKey   and Enum.KeyCode[cfg.autoBatKey]    then Keybinds.AutoBat=Enum.KeyCode[cfg.autoBatKey]       end
    if cfg.speedToggleKey and Enum.KeyCode[cfg.speedToggleKey] then Keybinds.SpeedToggle=Enum.KeyCode[cfg.speedToggleKey] end
    if cfg.autoLeftKey  and Enum.KeyCode[cfg.autoLeftKey]   then Keybinds.AutoLeft=Enum.KeyCode[cfg.autoLeftKey]     end
    if cfg.autoRightKey and Enum.KeyCode[cfg.autoRightKey]  then Keybinds.AutoRight=Enum.KeyCode[cfg.autoRightKey]   end
    if cfg.infiniteJumpKey and Enum.KeyCode[cfg.infiniteJumpKey] then Keybinds.InfiniteJump=Enum.KeyCode[cfg.infiniteJumpKey] end
    if cfg.floatKey and Enum.KeyCode[cfg.floatKey] then Keybinds.Float=Enum.KeyCode[cfg.floatKey] end
    if cfg.grabRadius   then Values.STEAL_RADIUS=cfg.grabRadius end
    if cfg.stealDuration then Values.STEAL_DURATION=cfg.stealDuration end
    if cfg.antiRagdoll  ~=nil then Enabled.AntiRagdoll=cfg.antiRagdoll   end
    if cfg.autoStealEnabled~=nil then Enabled.AutoSteal=cfg.autoStealEnabled end
    if cfg.infiniteJump ~=nil then Enabled.InfiniteJump=cfg.infiniteJump  end
    if cfg.optimizer    ~=nil then Enabled.Optimizer=cfg.optimizer        end
    if cfg.unwalk       ~=nil then Enabled.Unwalk=cfg.unwalk              end
    if cfg.shinyGraphics~=nil then Enabled.ShinyGraphics=cfg.shinyGraphics end
    if cfg.galaxyGravity then Values.GalaxyGravityPercent=cfg.galaxyGravity end
    if cfg.hopPower      then Values.HOP_POWER=cfg.hopPower                end
    if cfg.autoLeftEnabled  ~=nil then Enabled.AutoLeftEnabled=cfg.autoLeftEnabled   end
    if cfg.autoRightEnabled ~=nil then Enabled.AutoRightEnabled=cfg.autoRightEnabled end
    if cfg.floatEnabled ~=nil then floatEnabled=cfg.floatEnabled end
    if cfg.floatHeight then floatHeight=cfg.floatHeight end
end
loadConfig()

-- =============================================================
--  GUI (REMAINING CODE CONTINUES AS-IS)
-- =============================================================

local C_BG     = Color3.fromRGB(0,   0,   0)
local C_PURPLE = Color3.fromRGB(178,  0, 255)
local C_PURPLE2= Color3.fromRGB(215, 90, 255)
local C_DIM    = Color3.fromRGB(100,  0, 145)
local C_SW_OFF = Color3.fromRGB(28,  28,  28)
local C_WHITE  = Color3.fromRGB(255, 255, 255)
local C_ROW_BG = Color3.fromRGB(10,   0,  16)

local lastTickTime = 0
local tickSound = Instance.new("Sound")
tickSound.SoundId  = "rbxassetid://9119734881"
tickSound.Volume   = 0.22
tickSound.RollOffMaxDistance = 0
tickSound.Parent   = SoundService
local function playTick()
    local now = tick()
    if now - lastTickTime < 0.08 then return end
    lastTickTime = now
    tickSound:Play()
end

gui = Instance.new("ScreenGui")
gui.Name         = "K7HubGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent       = LocalPlayer:WaitForChild("PlayerGui")

main = Instance.new("Frame")
main.Name             = "Main"
main.Size             = UDim2.new(0, 560, 0, 540)
main.Position         = UDim2.new(0, 20, 0, 20)
main.BackgroundColor3 = C_BG
main.BorderSizePixel  = 0
main.Active           = true
main.ClipsDescendants = true
main.Parent           = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 24)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color     = Color3.fromRGB(60, 0, 90)
mainStroke.Thickness = 1.5

do
    local drag = false; local ds, sp
    main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true ds=inp.Position sp=main.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local batEmoji = Instance.new("TextLabel")
batEmoji.Size=UDim2.new(0,40,0,40) batEmoji.Position=UDim2.new(0,14,0,8)
batEmoji.BackgroundTransparency=1 batEmoji.Text="🦇" batEmoji.TextColor3=C_PURPLE
batEmoji.Font=Enum.Font.GothamBlack batEmoji.TextSize=32 batEmoji.ZIndex=4 batEmoji.Parent=main

local titleLbl = Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,0,0,36) titleLbl.Position=UDim2.new(0,0,0,12)
titleLbl.BackgroundTransparency=1 titleLbl.Text="K7 HUB" titleLbl.TextColor3=C_PURPLE
titleLbl.Font=Enum.Font.GothamBlack titleLbl.TextSize=28 titleLbl.TextXAlignment=Enum.TextXAlignment.Center
titleLbl.ZIndex=4 titleLbl.Parent=main

local byLbl = Instance.new("TextLabel")
byLbl.Size=UDim2.new(1,0,0,14) byLbl.Position=UDim2.new(0,0,0,50)
byLbl.BackgroundTransparency=1 byLbl.Text="tyke313" byLbl.TextColor3=C_DIM
byLbl.Font=Enum.Font.GothamBold byLbl.TextSize=11 byLbl.TextXAlignment=Enum.TextXAlignment.Center
byLbl.ZIndex=4 byLbl.Parent=main

local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,28,0,28) closeBtn.Position=UDim2.new(1,-38,0,12)
closeBtn.BackgroundTransparency=1 closeBtn.Text="x" closeBtn.TextColor3=C_DIM
closeBtn.Font=Enum.Font.GothamBold closeBtn.TextSize=18 closeBtn.ZIndex=6 closeBtn.Parent=main
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.12),{TextColor3=Color3.fromRGB(255,60,60)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.12),{TextColor3=C_DIM}):Play() end)

local sep = Instance.new("Frame")
sep.Size=UDim2.new(1,-40,0,1) sep.Position=UDim2.new(0,20,0,68)
sep.BackgroundColor3=Color3.fromRGB(30,0,45) sep.BorderSizePixel=0 sep.ZIndex=3 sep.Parent=main

local scroll = Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,0,1,-74) scroll.Position=UDim2.new(0,0,0,74)
scroll.BackgroundTransparency=1 scroll.BorderSizePixel=0 scroll.ScrollBarThickness=3
scroll.ScrollBarImageColor3=C_DIM scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0) scroll.ZIndex=2 scroll.Parent=main

local vstack = Instance.new("Frame")
vstack.Size=UDim2.new(1,0,0,0) vstack.AutomaticSize=Enum.AutomaticSize.Y
vstack.BackgroundTransparency=1 vstack.BorderSizePixel=0 vstack.Parent=scroll
local vstackLayout = Instance.new("UIListLayout")
vstackLayout.SortOrder=Enum.SortOrder.LayoutOrder vstackLayout.Padding=UDim.new(0,0) vstackLayout.Parent=vstack
local vstackPad = Instance.new("UIPadding")
vstackPad.PaddingLeft=UDim.new(0,18) vstackPad.PaddingRight=UDim.new(0,18)
vstackPad.PaddingTop=UDim.new(0,8) vstackPad.PaddingBottom=UDim.new(0,14) vstackPad.Parent=vstack

local VisualSetters = {}

local function makeSwitch(parent, enabledKey, defaultOn)
    local swBg = Instance.new("Frame")
    swBg.Size=UDim2.new(0,44,0,22) swBg.Position=UDim2.new(1,-48,0.5,-11)
    swBg.BackgroundColor3=defaultOn and C_PURPLE or C_SW_OFF swBg.BorderSizePixel=0 swBg.ZIndex=5 swBg.Parent=parent
    Instance.new("UICorner",swBg).CornerRadius=UDim.new(1,0)
    local swCircle = Instance.new("Frame")
    swCircle.Size=UDim2.new(0,16,0,16)
    swCircle.Position=defaultOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    swCircle.BackgroundColor3=C_WHITE swCircle.BorderSizePixel=0 swCircle.ZIndex=6 swCircle.Parent=swBg
    Instance.new("UICorner",swCircle).CornerRadius=UDim.new(1,0)
    if enabledKey=="AutoLeftEnabled"  then _G_AL_swBg=swBg  _G_AL_swCircle=swCircle end
    if enabledKey=="AutoRightEnabled" then _G_AR_swBg=swBg  _G_AR_swCircle=swCircle end
    local isOn = defaultOn
    local function setVisual(state)
        isOn=state
        TweenService:Create(swBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=isOn and C_PURPLE or C_SW_OFF}):Play()
        TweenService:Create(swCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=isOn and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    end
    VisualSetters[enabledKey]=setVisual
    return swBg,swCircle,setVisual
end

local radiusDropOpen=nil
local KeybindDisplayLabels={}

local function makeRow(keybindRefName, labelTxt, enabledKey, order, onToggle)
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1 container.BorderSizePixel=0 container.LayoutOrder=order
    container.AutomaticSize=Enum.AutomaticSize.Y container.Size=UDim2.new(1,0,0,0)
    container.ClipsDescendants=false container.Parent=vstack
    local containerList=Instance.new("UIListLayout")
    containerList.SortOrder=Enum.SortOrder.LayoutOrder containerList.Padding=UDim.new(0,0) containerList.Parent=container
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,44) row.BackgroundColor3=C_ROW_BG row.BorderSizePixel=0
    row.LayoutOrder=1 row.ZIndex=3 row.Parent=container
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    if keybindRefName~="" then
        local kbBox=Instance.new("Frame")
        kbBox.Size=UDim2.new(0,30,0,18) kbBox.Position=UDim2.new(0,10,0.5,-9)
        kbBox.BackgroundColor3=C_PURPLE kbBox.BackgroundTransparency=0.5 kbBox.BorderSizePixel=0 kbBox.ZIndex=5 kbBox.Parent=row
        Instance.new("UICorner",kbBox).CornerRadius=UDim.new(0,5)
        local kbTxt=Instance.new("TextLabel")
        kbTxt.Size=UDim2.new(1,0,1,0) kbTxt.BackgroundTransparency=1
        kbTxt.Text=Keybinds[keybindRefName] and Keybinds[keybindRefName].Name or keybindRefName
        kbTxt.TextColor3=C_WHITE kbTxt.Font=Enum.Font.GothamBold kbTxt.TextSize=10
        kbTxt.TextXAlignment=Enum.TextXAlignment.Center kbTxt.ZIndex=6 kbTxt.Parent=kbBox
        KeybindDisplayLabels[keybindRefName]=kbTxt
    end
    local nameX=keybindRefName~="" and 48 or 14
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-(nameX+60),1,0) nameLbl.Position=UDim2.new(0,nameX,0,0)
    nameLbl.BackgroundTransparency=1 nameLbl.Text=labelTxt nameLbl.TextColor3=C_PURPLE
    nameLbl.Font=Enum.Font.GothamBold nameLbl.TextSize=13 nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.ZIndex=5 nameLbl.Parent=row
    local defaultOn=Enabled[enabledKey] or false
    local ,,setVisual=makeSwitch(row,enabledKey,defaultOn)
    local isOn=defaultOn
    local dropPanel=nil local dropInput=nil
    if enabledKey=="AutoSteal" then
        dropPanel=Instance.new("Frame")
        dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.BackgroundTransparency=1 dropPanel.BorderSizePixel=0
        dropPanel.ClipsDescendants=true dropPanel.LayoutOrder=2 dropPanel.ZIndex=4 dropPanel.Parent=container
        local dropInner=Instance.new("Frame")
        dropInner.Size=UDim2.new(1,0,1,0) dropInner.BackgroundColor3=Color3.fromRGB(10,0,16)
        dropInner.BorderSizePixel=0 dropInner.ZIndex=4 dropInner.Parent=dropPanel
        Instance.new("UICorner",dropInner).CornerRadius=UDim.new(0,10)
        local dropList=Instance.new("UIListLayout")
        dropList.SortOrder=Enum.SortOrder.LayoutOrder dropList.Padding=UDim.new(0,4) dropList.Parent=dropInner
        local dropPad=Instance.new("UIPadding")
        dropPad.PaddingLeft=UDim.new(0,14) dropPad.PaddingRight=UDim.new(0,14)
        dropPad.PaddingTop=UDim.new(0,8) dropPad.PaddingBottom=UDim.new(0,8) dropPad.Parent=dropInner
        local radiusRow=Instance.new("Frame")
        radiusRow.Size=UDim2.new(1,0,0,24) radiusRow.BackgroundTransparency=1
        radiusRow.BorderSizePixel=0 radiusRow.LayoutOrder=1 radiusRow.Parent=dropInner
        local radiusLbl=Instance.new("TextLabel")
        radiusLbl.Size=UDim2.new(0.5,0,1,0) radiusLbl.Position=UDim2.new(0,0,0,0)
        radiusLbl.BackgroundTransparency=1 radiusLbl.Text="Steal Radius" radiusLbl.TextColor3=C_DIM
        radiusLbl.Font=Enum.Font.GothamBold radiusLbl.TextSize=12 radiusLbl.TextXAlignment=Enum.TextXAlignment.Left
        radiusLbl.ZIndex=5 radiusLbl.Parent=radiusRow
        dropInput=Instance.new("TextBox")
        dropInput.Size=UDim2.new(0,58,0,24) dropInput.Position=UDim2.new(1,-58,0,0)
        dropInput.BackgroundColor3=Color3.fromRGB(20,0,30) dropInput.BorderSizePixel=0
        dropInput.Text=tostring(Values.STEAL_RADIUS) dropInput.TextColor3=C_PURPLE
        dropInput.Font=Enum.Font.GothamBold dropInput.TextSize=13 dropInput.ZIndex=5 dropInput.Parent=radiusRow
        Instance.new("UICorner",dropInput).CornerRadius=UDim.new(0,7)
        local rStr=Instance.new("UIStroke",dropInput) rStr.Color=C_DIM rStr.Thickness=1
        dropInput.Focused:Connect(function() TweenService:Create(rStr,TweenInfo.new(0.15),{Color=C_PURPLE}):Play() end)
        dropInput.FocusLost:Connect(function()
            local n=tonumber(dropInput.Text)
            if n then Values.STEAL_RADIUS=math.clamp(math.floor(n),1,500) dropInput.Text=tostring(Values.STEAL_RADIUS)
                if RadiusInput then RadiusInput.Text=tostring(Values.STEAL_RADIUS) end
            else dropInput.Text=tostring(Values.STEAL_RADIUS) end
            TweenService:Create(rStr,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        end)
        local durationRow=Instance.new("Frame")
        durationRow.Size=UDim2.new(1,0,0,24) durationRow.BackgroundTransparency=1
        durationRow.BorderSizePixel=0 durationRow.LayoutOrder=2 durationRow.Parent=dropInner
        local durationLbl=Instance.new("TextLabel")
        durationLbl.Size=UDim2.new(0.5,0,1,0) durationLbl.Position=UDim2.new(0,0,0,0)
        durationLbl.BackgroundTransparency=1 durationLbl.Text="Steal Duration (s)" durationLbl.TextColor3=C_DIM
        durationLbl.Font=Enum.Font.GothamBold durationLbl.TextSize=12 durationLbl.TextXAlignment=Enum.TextXAlignment.Left
        durationLbl.ZIndex=5 durationLbl.Parent=durationRow
        local durationInput=Instance.new("TextBox")
        durationInput.Size=UDim2.new(0,58,0,24) durationInput.Position=UDim2.new(1,-58,0,0)
        durationInput.BackgroundColor3=Color3.fromRGB(20,0,30) durationInput.BorderSizePixel=0
        durationInput.Text=tostring(Values.STEAL_DURATION) durationInput.TextColor3=C_PURPLE
        durationInput.Font=Enum.Font.GothamBold durationInput.TextSize=13 durationInput.ZIndex=5 durationInput.Parent=durationRow
        Instance.new("UICorner",durationInput).CornerRadius=UDim.new(0,7)
        local dStr=Instance.new("UIStroke",durationInput) dStr.Color=C_DIM dStr.Thickness=1
        DurationInput=durationInput
        durationInput.Focused:Connect(function() TweenService:Create(dStr,TweenInfo.new(0.15),{Color=C_PURPLE}):Play() end)
        durationInput.FocusLost:Connect(function()
            local n=tonumber(durationInput.Text)
            if n then Values.STEAL_DURATION=math.clamp(n,0.1,10) durationInput.Text=tostring(Values.STEAL_DURATION)
                if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
            else durationInput.Text=tostring(Values.STEAL_DURATION) end
            TweenService:Create(dStr,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        end)
    end
    local clk=Instance.new("TextButton")
    clk.Size=UDim2.new(1,0,0,44) clk.BackgroundTransparency=1 clk.Text="" clk.ZIndex=7 clk.Parent=row
    local pressStartTime=nil local pressConnection=nil local longPressTriggered=false
    clk.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            pressStartTime=tick() longPressTriggered=false
            if pressConnection then pressConnection:Disconnect() end
            pressConnection=RunService.Heartbeat:Connect(function()
                if pressStartTime and tick()-pressStartTime>=0.5 then
                    if dropPanel and not longPressTriggered then
                        longPressTriggered=true
                        if radiusDropOpen and radiusDropOpen~=dropPanel then
                            TweenService:Create(radiusDropOpen,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
                            task.delay(0.2,function() if radiusDropOpen then radiusDropOpen.Visible=false end end)
                            radiusDropOpen=nil
                        end
                        if dropPanel.Visible then
                            TweenService:Create(dropPanel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
                            task.delay(0.22,function() dropPanel.Visible=false end)
                            radiusDropOpen=nil
                        else
                            if dropInput then dropInput.Text=tostring(Values.STEAL_RADIUS) end
                            if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
                            dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.Visible=true
                            TweenService:Create(dropPanel,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,72)}):Play()
                            radiusDropOpen=dropPanel
                        end
                    end
                    if pressConnection then pressConnection:Disconnect() pressConnection=nil end
                end
            end)
        end
    end)
    clk.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            local pressDuration=pressStartTime and (tick()-pressStartTime) or 0
            pressStartTime=nil
            if pressConnection then pressConnection:Disconnect() pressConnection=nil end
            if pressDuration<0.5 and not longPressTriggered then
                isOn=not isOn Enabled[enabledKey]=isOn setVisual(isOn)
                if onToggle then onToggle(isOn) end
            end
        end
    end)
    clk.MouseButton2Click:Connect(function()
        if not dropPanel then return end
        if radiusDropOpen and radiusDropOpen~=dropPanel then
            TweenService:Create(radiusDropOpen,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
            task.delay(0.2,function() if radiusDropOpen then radiusDropOpen.Visible=false end end)
            radiusDropOpen=nil
        end
        if dropPanel.Visible then
            TweenService:Create(dropPanel,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{Size=UDim2.new(1,0,0,0)}):Play()
            task.delay(0.22,function() dropPanel.Visible=false end) radiusDropOpen=nil
        else
            if dropInput then dropInput.Text=tostring(Values.STEAL_RADIUS) end
            if DurationInput then DurationInput.Text=tostring(Values.STEAL_DURATION) end
            dropPanel.Size=UDim2.new(1,0,0,0) dropPanel.Visible=true
            TweenService:Create(dropPanel,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,0,72)}):Play()
            radiusDropOpen=dropPanel
        end
    end)
    clk.MouseEnter:Connect(function()
        playTick()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_PURPLE2}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(18,0,26)}):Play()
    end)
    clk.MouseLeave:Connect(function()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_PURPLE}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=C_ROW_BG}):Play()
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.LayoutOrder=3 gap.Parent=container
    return container,setVisual
end

local function makeManualRow(keybindRefName, labelTxt, order)
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1 container.BorderSizePixel=0 container.LayoutOrder=order
    container.AutomaticSize=Enum.AutomaticSize.Y container.Size=UDim2.new(1,0,0,0) container.Parent=vstack
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,44) row.BackgroundColor3=C_ROW_BG row.BorderSizePixel=0 row.ZIndex=3 row.Parent=container
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
    if keybindRefName~="" then
        local kbBox=Instance.new("Frame")
        kbBox.Size=UDim2.new(0,30,0,18) kbBox.Position=UDim2.new(0,10,0.5,-9)
        kbBox.BackgroundColor3=C_PURPLE kbBox.BackgroundTransparency=0.5 kbBox.BorderSizePixel=0 kbBox.ZIndex=5 kbBox.Parent=row
        Instance.new("UICorner",kbBox).CornerRadius=UDim.new(0,5)
        local kbTxt=Instance.new("TextLabel")
        kbTxt.Size=UDim2.new(1,0,1,0) kbTxt.BackgroundTransparency=1
        kbTxt.Text=Keybinds[keybindRefName] and Keybinds[keybindRefName].Name or keybindRefName
        kbTxt.TextColor3=C_WHITE kbTxt.Font=Enum.Font.GothamBold kbTxt.TextSize=10
        kbTxt.TextXAlignment=Enum.TextXAlignment.Center kbTxt.ZIndex=6 kbTxt.Parent=kbBox
        KeybindDisplayLabels[keybindRefName]=kbTxt
    end
    local nameX=keybindRefName~="" and 48 or 14
    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-(nameX+60),1,0) nameLbl.Position=UDim2.new(0,nameX,0,0)
    nameLbl.BackgroundTransparency=1 nameLbl.Text=labelTxt nameLbl.TextColor3=C_PURPLE
    nameLbl.Font=Enum.Font.GothamBold nameLbl.TextSize=13 nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.ZIndex=5 nameLbl.Parent=row
    local swBg=Instance.new("Frame")
    swBg.Size=UDim2.new(0,44,0,22) swBg.Position=UDim2.new(1,-48,0.5,-11)
    swBg.BackgroundColor3=C_SW_OFF swBg.BorderSizePixel=0 swBg.ZIndex=5 swBg.Parent=row
    Instance.new("UICorner",swBg).CornerRadius=UDim.new(1,0)
    local swCircle=Instance.new("Frame")
    swCircle.Size=UDim2.new(0,16,0,16) swCircle.Position=UDim2.new(0,3,0.5,-8)
    swCircle.BackgroundColor3=C_WHITE swCircle.BorderSizePixel=0 swCircle.ZIndex=6 swCircle.Parent=swBg
    Instance.new("UICorner",swCircle).CornerRadius=UDim.new(1,0)
    local clk=Instance.new("TextButton")
    clk.Size=UDim2.new(1,0,0,44) clk.BackgroundTransparency=1 clk.Text="" clk.ZIndex=7 clk.Parent=row
    clk.MouseEnter:Connect(function()
        playTick()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_PURPLE2}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(18,0,26)}):Play()
    end)
    clk.MouseLeave:Connect(function()
        TweenService:Create(nameLbl,TweenInfo.new(0.1),{TextColor3=C_PURPLE}):Play()
        TweenService:Create(row,TweenInfo.new(0.12),{BackgroundColor3=C_ROW_BG}):Play()
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=container
    return clk,swBg,swCircle,nameLbl,row
end

local function makeSectionLbl(txt, order)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,24) f.BackgroundTransparency=1 f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=vstack
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,1,0) l.BackgroundTransparency=1 l.Text=txt:upper()
    l.TextColor3=Color3.fromRGB(55,0,80) l.Font=Enum.Font.GothamBold l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left l.ZIndex=4 l.Parent=f
end

local o=0
local function O() o=o+1 return o end

makeSectionLbl("Features", O())
local _,setAutoSteal   = makeRow("",  "Auto Steal",       "AutoSteal",        O(), function(s) if s then startAutoSteal()      else stopAutoSteal()      end end)
local _,setAntiRagdoll = makeRow("",  "Anti Ragdoll",     "AntiRagdoll",      O(), function(s) if s then startAntiRagdoll()    else stopAntiRagdoll()    end end)
local _,setInfJump     = makeRow("InfiniteJump","Infinite Jump","InfiniteJump",O(), function(s) if s then startInfiniteJump()  else stopInfiniteJump()   end end)
local _,setShiny       = makeRow("",  "Shiny Graphics",   "ShinyGraphics",    O(), function(s) if s then enableShinyGraphics() else disableShinyGraphics() end end)
local _,setOptimizer   = makeRow("",  "Optimizer + XRay", "Optimizer",        O(), function(s) if s then enableOptimizer()    else disableOptimizer()    end end)
local _,setUnwalk      = makeRow("",  "Unwalk",           "Unwalk",           O(), function(s) if s then startUnwalk()        else stopUnwalk()          end end)

makeSectionLbl("Movement", O())
local _,setAutoLeft  = makeRow("AutoLeft",  "Auto Left",  "AutoLeftEnabled",  O(), function(s) AutoLeftEnabled=s  Enabled.AutoLeftEnabled=s  if s then startAutoLeft()  else stopAutoLeft()  end end)
local _,setAutoRight = makeRow("AutoRight", "Auto Right", "AutoRightEnabled", O(), function(s) AutoRightEnabled=s Enabled.AutoRightEnabled=s if s then startAutoRight() else stopAutoRight() end end)

local speedClk,_speedSwBg,_speedSwCircle = makeManualRow("SpeedToggle","Carry Mode",O())
speedSwBg=_speedSwBg speedSwCircle=_speedSwCircle
speedClk.MouseButton1Click:Connect(function()
    speedToggled=not speedToggled
    TweenService:Create(speedSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=speedToggled and C_PURPLE or C_SW_OFF}):Play()
    TweenService:Create(speedSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=speedToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
end)

local batClk,_batSwBg,_batSwCircle = makeManualRow("AutoBat","Auto-Bat",O())
batSwBg=_batSwBg batSwCircle=_batSwCircle
batClk.MouseButton1Click:Connect(function()
    autoBatToggled=not autoBatToggled
    TweenService:Create(batSwBg,    TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=autoBatToggled and C_PURPLE or C_SW_OFF}):Play()
    TweenService:Create(batSwCircle,TweenInfo.new(0.2,Enum.EasingStyle.Back), {Position=autoBatToggled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
end)

local function makeInputBox(parent, lbl, defaultTxt, onDone)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.58,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0,70,0,26) box.Position=UDim2.new(1,-80,0.5,-13) box.BackgroundColor3=Color3.fromRGB(14,0,22)
    box.BorderSizePixel=0 box.Text=defaultTxt box.TextColor3=C_PURPLE box.Font=Enum.Font.GothamBold
    box.TextSize=13 box.ClearTextOnFocus=false box.ZIndex=4 box.Parent=wrap
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,8)
    local bs=Instance.new("UIStroke",box) bs.Color=C_DIM bs.Thickness=1
    box.Focused:Connect(function() TweenService:Create(bs,TweenInfo.new(0.15),{Color=C_PURPLE}):Play() end)
    box.FocusLost:Connect(function()
        TweenService:Create(bs,TweenInfo.new(0.15),{Color=C_DIM}):Play()
        if onDone then onDone(box.Text,box) end
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=parent
    return box
end

local function makeSlider(parent, lbl, minVal, maxVal, defaultVal, onChanged)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.35,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local valTxt=Instance.new("TextLabel")
    valTxt.Size=UDim2.new(0,50,0,20) valTxt.Position=UDim2.new(1,-60,0.5,-10) valTxt.BackgroundTransparency=1
    valTxt.Text=tostring(math.floor(defaultVal)) valTxt.TextColor3=C_PURPLE valTxt.Font=Enum.Font.GothamBold
    valTxt.TextSize=13 valTxt.TextXAlignment=Enum.TextXAlignment.Right valTxt.ZIndex=5 valTxt.Parent=wrap
    local trackBg=Instance.new("Frame")
    trackBg.Size=UDim2.new(0,200,0,6) trackBg.Position=UDim2.new(0.38,0,0.5,-3)
    trackBg.BackgroundColor3=Color3.fromRGB(14,0,22) trackBg.BorderSizePixel=0 trackBg.ZIndex=4 trackBg.Parent=wrap
    Instance.new("UICorner",trackBg).CornerRadius=UDim.new(1,0)
    local trackFill=Instance.new("Frame")
    trackFill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    trackFill.BackgroundColor3=C_PURPLE trackFill.BorderSizePixel=0 trackFill.ZIndex=5 trackFill.Parent=trackBg
    Instance.new("UICorner",trackFill).CornerRadius=UDim.new(1,0)
    local thumb=Instance.new("TextButton")
    thumb.Size=UDim2.new(0,14,0,14) thumb.Position=UDim2.new((defaultVal-minVal)/(maxVal-minVal),-7,0.5,-7)
    thumb.BackgroundColor3=C_WHITE thumb.BorderSizePixel=0 thumb.ZIndex=6 thumb.Text=""
    thumb.AutoButtonColor=false thumb.Parent=trackBg
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0)
    local dragging=false local dragConnection=nil local lastUpdate=0
    local function updateSlider(inputPos)
        local relX=math.clamp((inputPos.X-trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
        local value=minVal+(maxVal-minVal)*relX
        trackFill.Size=UDim2.new(relX,0,1,0) thumb.Position=UDim2.new(relX,-7,0.5,-7)
        if lbl=="FOV" then valTxt.Text=tostring(math.floor(value))
        elseif lbl=="UI Scale" then valTxt.Text=string.format("%.1f",value)
        else valTxt.Text=tostring(math.floor(value)) end
        if lbl=="UI Scale" then
            local now=tick()
            if now-lastUpdate>=0.08 or not dragging then lastUpdate=now if onChanged then onChanged(value) end end
        else if onChanged then onChanged(value) end end
    end
    thumb.MouseButton1Down:Connect(function()
        dragging=true
        if dragConnection then dragConnection:Disconnect() end
        dragConnection=UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseMovement then updateSlider(inp.Position) end
        end)
    end)
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            if dragConnection then dragConnection:Disconnect() end
            dragConnection=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then
                    dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end return
                end
                updateSlider(inp.Position)
            end)
        end
    end)
    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true updateSlider(inp.Position)
            if dragConnection then dragConnection:Disconnect() end
            dragConnection=inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then
                    dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end return
                end
                updateSlider(inp.Position)
            end)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false if dragConnection then dragConnection:Disconnect() dragConnection=nil end
        end
    end)
    trackBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then updateSlider(inp.Position) end
    end)
    local gap=Instance.new("Frame")
    gap.Size=UDim2.new(1,0,0,5) gap.BackgroundTransparency=1 gap.BorderSizePixel=0 gap.Parent=parent
    return wrap
end

local function makeKeybindRow(parent, lbl, keybindRefName, onChanged)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,0,0,44) wrap.BackgroundColor3=C_ROW_BG wrap.BorderSizePixel=0 wrap.ZIndex=3 wrap.Parent=parent
    Instance.new("UICorner",wrap).CornerRadius=UDim.new(0,10)
    local lbTxt=Instance.new("TextLabel")
    lbTxt.Size=UDim2.new(0.58,0,1,0) lbTxt.Position=UDim2.new(0,14,0,0) lbTxt.BackgroundTransparency=1
    lbTxt.Text=lbl lbTxt.TextColor3=C_DIM lbTxt.Font=Enum.Font.GothamBold lbTxt.TextSize=12
    lbTxt.TextXAlignment=Enum.TextXAlignment.Left lbTxt.ZIndex=4 lbTxt.Parent=wrap
    local kbBtn=Instance.new("TextButton")
    kbBtn.Size=UDim2.new(0,70,0,26) kbBtn.Position=UDim2.new(1,-80,0.5,-13) kbBtn.BackgroundColor3=Color3.fromRGB(14,0,22)
    kbBtn.BorderSizePixel=0 kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_PURPLE
    kbBtn.Font=Enum.Font.GothamBold kbBtn.TextSize=11 kbBtn.ZIndex=4 kbBtn.Parent=wrap
    Instance.new("UICorner",kbBtn).CornerRadius=UDim.new(0,8)
    local ks=Instance.new("UIStroke",kbBtn) ks.Color=C_DIM ks.Thickness=1
    kbBtn.MouseButton1Click:Connect(function()
        if waitingForKey==kbBtn then
            waitingForKey=nil kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_PURPLE
            TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_DIM}):Play() return
        end
        if waitingForKey then waitingForKey.TextColor3=C_PURPLE end
        waitingForKey=kbBtn kbBtn.Text="..." kbBtn.TextColor3=C_PURPLE2
        TweenService:Create(ks,TweenInfo.new(0.15),{Color=C_PURPLE}):Play()
    end)
    UserInputService.InputBegan:Connect(function(inp,gpe)
        if waitingForKey~=kbBtn then return end
        if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
        local kc=inp.KeyCode
        if kc==Enum.KeyCode.Escape then
            kbBtn.Text=Keybinds[keybindRefName].Name kbBtn.TextColor3=C_PURPLE
            Twee
