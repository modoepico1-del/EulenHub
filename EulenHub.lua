_G.HeadSize = 15
local SIDE_TEXT = "El1TE HUB"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local hitboxEnabled = false
local FACES = {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom}
local currentTarget = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local HitboxBtn = Instance.new("TextButton")
HitboxBtn.Size = UDim2.new(0, 150, 0, 50)
HitboxBtn.Position = UDim2.new(0, 20, 0, 20)
HitboxBtn.Text = "Hitbox: OFF"
HitboxBtn.BackgroundColor3 = Color3.fromRGB(100,0,200)
HitboxBtn.TextColor3 = Color3.fromRGB(255,255,255)
HitboxBtn.Font = Enum.Font.GothamBold
HitboxBtn.TextScaled = true
HitboxBtn.Parent = ScreenGui

local hitboxGlow = Instance.new("UICorner")
hitboxGlow.Parent = HitboxBtn

local function applyHitbox(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	for _, c in ipairs(hrp:GetChildren()) do
		if c:IsA("SurfaceGui") then c:Destroy() end
	end

	for _, face in ipairs(FACES) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.Adornee = hrp
		sg.AlwaysOnTop = true
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.CanvasSize = Vector2.new(100, 100)
		sg.Parent = hrp

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.Text = SIDE_TEXT
		txt.TextColor3 = Color3.fromRGB(180,0,255)
		txt.TextScaled = true
		txt.Font = Enum.Font.GothamBold
		txt.Parent = sg
	end
end

local function clearHitbox(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for _, c in ipairs(hrp:GetChildren()) do
		if c:IsA("SurfaceGui") then c:Destroy() end
	end
end

local function getTargetPlayer()
	local nearestPlayer = nil
	local shortestDistance = math.huge
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
			if dist < shortestDistance then
				shortestDistance = dist
				nearestPlayer = player
			end
		end
	end
	return nearestPlayer
end

HitboxBtn.MouseButton1Click:Connect(function()
	hitboxEnabled = not hitboxEnabled
	HitboxBtn.Text = hitboxEnabled and "Hitbox: ON" or "Hitbox: OFF"
	HitboxBtn.BackgroundColor3 = hitboxEnabled and Color3.fromRGB(180,0,255) or Color3.fromRGB(100,0,200)
end)

RunService.RenderStepped:Connect(function()
	if not hitboxEnabled then
		if currentTarget then
			clearHitbox(currentTarget)
			currentTarget = nil
		end
		return
	end

	local target = getTargetPlayer()
	if target ~= currentTarget then
		if currentTarget then
			clearHitbox(currentTarget)
		end
		currentTarget = target
		if currentTarget then
			applyHitbox(currentTarget)
		end
	end

	if currentTarget and currentTarget.Character then
		local hrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Size = Vector3.new(_G.HeadSize,_G.HeadSize,_G.HeadSize)
			hrp.Transparency = 0.7
			hrp.BrickColor = BrickColor.new("Black")
			hrp.Material = Enum.Material.Neon
			hrp.CanCollide = false
		end
	end
end)
