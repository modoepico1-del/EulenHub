-- cache everything before game scripts can hook them
local newInstance   = Instance.new
local taskDelay     = task.delay
local taskWait      = task.wait
local taskSpawn     = task.spawn
local mathFloor     = math.floor
local mathHuge      = math.huge
local mathRandom    = math.random
local stringFormat  = string.format
local tostring      = tostring
local pcall         = pcall
local pairs         = pairs

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ContentProvider   = game:GetService("ContentProvider")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- use gethui() if available (hidden from game scripts entirely), else CoreGui
local function GetSafeParent()
	if typeof(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	return CoreGui
end

local ROBUX_SYMBOL  = "\u{E002}"
local ITEM_LOGO     = "rbxassetid://107341560549618"
local ROBUX_COST    = 7499
local ITEM_NAME     = "[GIFT] Admin Commands"

local currentBalance = 50000

local CARD_W = 0.30
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	CARD_W = 0.45
end
local ANIM_OFFSET   = 0.04
local HEADER_H      = 52
local ITEM_ROW_Y    = 62
local ITEM_ROW_H    = 64
local GAP           = 14
local BTN_H         = 34
local BOTTOM_PAD    = 20
local CARD_H_PX     = HEADER_H + ITEM_ROW_H + GAP + BTN_H + BOTTOM_PAD

local BUY_DARK  = Color3.fromRGB(0x26, 0x3d, 0x8f)
local BUY_LIGHT = Color3.fromRGB(0x33, 0x5f, 0xff)

local S_HEADER_H    = 52
local S_IMG_SIZE    = 48
local S_IMG_GAP     = 14
local S_TEXT_H      = 36
local S_TEXT_GAP    = 14
local S_BTN_H       = 34
local S_BOTTOM_PAD  = 20
local S_CARD_H      = S_HEADER_H + S_IMG_GAP + S_IMG_SIZE + S_TEXT_GAP + S_TEXT_H + S_TEXT_GAP + S_BTN_H + S_BOTTOM_PAD

local CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local function RandName(len)
	local r = {}
	for i = 1, len do
		local idx = mathRandom(1, #CHARS)
		r[i] = CHARS:sub(idx, idx)
	end
	return table.concat(r)
end

local function FuncFormat(n)
	local s = tostring(n)
	return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function SafeSet(obj, prop, val)
	pcall(function() obj[prop] = val end)
end

local function SafeGet(obj, prop)
	local ok, val = pcall(function() return obj[prop] end)
	return ok and val or nil
end

local function New(className, props)
	local ok, obj = pcall(newInstance, className)
	if not ok or not obj then return nil end
	if props then
		for k, v in pairs(props) do
			SafeSet(obj, k, v)
		end
	end
	return obj
end

local function FuncSuccessCard(overlay, screenGui)
	local card2 = New("Frame", {
		Size                   = UDim2.new(CARD_W, 0, 0, S_CARD_H),
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5 + ANIM_OFFSET, 0),
		BackgroundColor3       = Color3.fromRGB(0x19, 0x1a, 0x1f),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ZIndex                 = 11,
		Name                   = RandName(10),
		Parent                 = screenGui,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card2 })

	TweenService:Create(overlay, TweenInfo.new(0.28, Enum.EasingStyle.Linear), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card2, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	}):Play()

	New("TextLabel", {
		Size                   = UDim2.new(1, -20, 0, S_HEADER_H),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "Purchase completed",
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 18,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card2,
	})

	local closeBtn2 = New("ImageButton", {
		Size                   = UDim2.new(0, 44, 0, S_HEADER_H),
		Position               = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Image                  = "",
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card2,
	})
	New("ImageLabel", {
		Size                   = UDim2.new(0, 22, 0, 22),
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Image                  = "rbxassetid://6031094678",
		ImageColor3            = Color3.fromRGB(210, 210, 210),
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = closeBtn2,
	})

	New("ImageLabel", {
		Size                   = UDim2.new(0, 62, 0, 62),
		AnchorPoint            = Vector2.new(0.5, 0),
		Position               = UDim2.new(0.5, -2, 0, S_HEADER_H + S_IMG_GAP),
		BackgroundTransparency = 1,
		Image                  = "rbxassetid://135084016839600",
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card2,
	})

	local TEXT_Y = S_HEADER_H + S_IMG_GAP + S_IMG_SIZE + S_TEXT_GAP
	New("TextLabel", {
		Size                   = UDim2.new(1, -28, 0, S_TEXT_H),
		Position               = UDim2.new(0, 14, 0, TEXT_Y),
		BackgroundTransparency = 1,
		Text                   = 'You have successfully bought "' .. ITEM_NAME .. '".',
		TextColor3             = Color3.fromRGB(200, 200, 200),
		TextSize               = 13,
		Font                   = Enum.Font.BuilderSansMedium,
		TextWrapped            = true,
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card2,
	})

	local BTN_Y2 = TEXT_Y + S_TEXT_H + S_TEXT_GAP
	local okBtn = New("TextButton", {
		Size                   = UDim2.new(1, -28, 0, S_BTN_H),
		Position               = UDim2.new(0, 14, 0, BTN_Y2),
		BackgroundColor3       = BUY_DARK,
		BorderSizePixel        = 0,
		Text                   = "",
		ZIndex                 = 12,
		ClipsDescendants       = true,
		Name                   = RandName(10),
		Parent                 = card2,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = okBtn })
	New("TextLabel", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "OK",
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 15,
		Font                   = Enum.Font.BuilderSansMedium,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = okBtn,
	})

	taskDelay(0.1, function()
		if not SafeGet(screenGui, "Parent") then return end
		TweenService:Create(okBtn, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = BUY_LIGHT,
		}):Play()
	end)

	local function FuncCloseSuccess()
		local closeTween = TweenService:Create(card2, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position               = UDim2.new(0.5, 0, 0.5 + ANIM_OFFSET, 0),
			BackgroundTransparency = 1,
		})
		TweenService:Create(overlay, TweenInfo.new(0.22, Enum.EasingStyle.Linear), { BackgroundTransparency = 1 }):Play()
		closeTween:Play()
		closeTween.Completed:Connect(function()
			pcall(function() screenGui:Destroy() end)
		end)
	end

	okBtn.MouseButton1Click:Connect(FuncCloseSuccess)
	closeBtn2.MouseButton1Click:Connect(FuncCloseSuccess)
end

local activeGui = nil

local function FuncOpenPrompt()
	if activeGui then
		pcall(function() activeGui:Destroy() end)
		activeGui = nil
	end

	local safeParent = GetSafeParent()

	local screenGui = New("ScreenGui", {
		Name             = RandName(12),
		ResetOnSpawn     = false,
		IgnoreGuiInset   = true,
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		DisplayOrder     = 999,
	})

	-- parent AFTER fully constructing to minimize the window AC can catch a ChildAdded event
	taskSpawn(function()
		taskWait()
		SafeSet(screenGui, "Parent", safeParent)
	end)

	activeGui = screenGui

	screenGui.AncestryChanged:Connect(function()
		if not SafeGet(screenGui, "Parent") then
			activeGui = nil
		end
	end)

	local overlay = New("Frame", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundColor3       = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ZIndex                 = 10,
		Name                   = RandName(10),
		Parent                 = screenGui,
	})

	local card = New("Frame", {
		Size                   = UDim2.new(CARD_W, 0, 0, CARD_H_PX),
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5 + ANIM_OFFSET, 0),
		BackgroundColor3       = Color3.fromRGB(0x19, 0x1a, 0x1f),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ZIndex                 = 11,
		Name                   = RandName(10),
		Parent                 = screenGui,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })

	local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(overlay, tweenInfo, { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(card, tweenInfo, {
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	}):Play()

	New("TextLabel", {
		Size                   = UDim2.new(1, -120, 0, HEADER_H),
		Position               = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "Buy item",
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 20,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card,
	})

	local closeBtn = New("ImageButton", {
		Size                   = UDim2.new(0, 44, 0, HEADER_H),
		Position               = UDim2.new(1, -44, 0, 0),
		BackgroundTransparency = 1,
		Image                  = "",
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card,
	})
	New("ImageLabel", {
		Size                   = UDim2.new(0, 22, 0, 22),
		AnchorPoint            = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Image                  = "rbxassetid://6031094678",
		ImageColor3            = Color3.fromRGB(210, 210, 210),
		ScaleType              = Enum.ScaleType.Fit,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = closeBtn,
	})

	local balanceFrame = New("Frame", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(0, 90, 0, HEADER_H),
		Position               = UDim2.new(1, -44 - 90 + 30, 0, 0),
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card,
	})
	New("TextLabel", {
		Size                   = UDim2.new(0, 20, 0, 20),
		Position               = UDim2.new(0, 0, 0.5, -10),
		BackgroundTransparency = 1,
		Text                   = ROBUX_SYMBOL,
		TextColor3             = Color3.fromRGB(210, 210, 210),
		TextSize               = 17,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = balanceFrame,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 22, 0, 0),
		Size                   = UDim2.new(0, 68, 1, 0),
		Text                   = FuncFormat(currentBalance),
		TextColor3             = Color3.fromRGB(210, 210, 210),
		TextSize               = 15,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = balanceFrame,
	})

	local itemRow = New("Frame", {
		Size                   = UDim2.new(1, -32, 0, ITEM_ROW_H),
		Position               = UDim2.new(0, 16, 0, ITEM_ROW_Y),
		BackgroundTransparency = 1,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = card,
	})
	New("ImageLabel", {
		Size                   = UDim2.new(0, 46, 0, 46),
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 0, 0.5, -6),
		BackgroundTransparency = 1,
		Image                  = ITEM_LOGO,
		ScaleType              = Enum.ScaleType.Fit,
		BorderSizePixel        = 0,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = itemRow,
	})

	local TEXT_TOTAL_H = 42
	local NAME_Y = mathFloor((ITEM_ROW_H - TEXT_TOTAL_H) / 2) - 6

	New("TextLabel", {
		Size                   = UDim2.new(1, -60, 0, 20),
		Position               = UDim2.new(0, 58, 0, NAME_Y),
		BackgroundTransparency = 1,
		Text                   = ITEM_NAME,
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 14,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = itemRow,
	})

	local costFrame = New("Frame", {
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 54, 0, NAME_Y + 24),
		Size                   = UDim2.new(0, 120, 0, 18),
		ZIndex                 = 12,
		Name                   = RandName(10),
		Parent                 = itemRow,
	})
	New("TextLabel", {
		Size                   = UDim2.new(0, 18, 0, 18),
		Position               = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = ROBUX_SYMBOL,
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 14,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = costFrame,
	})
	New("TextLabel", {
		BackgroundTransparency = 1,
		Position               = UDim2.new(0, 20, 0, 0),
		Size                   = UDim2.new(0, 100, 1, 0),
		Text                   = FuncFormat(ROBUX_COST),
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 14,
		Font                   = Enum.Font.BuilderSansMedium,
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextYAlignment         = Enum.TextYAlignment.Center,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = costFrame,
	})

	local BTN_Y = ITEM_ROW_Y + ITEM_ROW_H + GAP
	local buyBtn = New("TextButton", {
		Size                   = UDim2.new(1, -28, 0, BTN_H),
		Position               = UDim2.new(0, 14, 0, BTN_Y),
		BackgroundColor3       = BUY_DARK,
		BorderSizePixel        = 0,
		Text                   = "",
		ZIndex                 = 12,
		ClipsDescendants       = true,
		Name                   = RandName(10),
		Parent                 = card,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = buyBtn })

	local fillBar = New("Frame", {
		Size                   = UDim2.new(0, 0, 1, 0),
		BackgroundColor3       = BUY_LIGHT,
		BorderSizePixel        = 0,
		ZIndex                 = 13,
		Name                   = RandName(10),
		Parent                 = buyBtn,
	})
	New("UICorner", { CornerRadius = UDim.new(0, 8), Parent = fillBar })

	local buyLabel = New("TextLabel", {
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "Buy",
		TextColor3             = Color3.fromRGB(255, 255, 255),
		TextSize               = 15,
		Font                   = Enum.Font.BuilderSansMedium,
		ZIndex                 = 14,
		Name                   = RandName(10),
		Parent                 = buyBtn,
	})

	SafeSet(buyBtn, "Active", false)
	SafeSet(buyBtn, "AutoButtonColor", false)
	SafeSet(buyLabel, "TextTransparency", 0.5)
	SafeSet(fillBar, "Size", UDim2.new(1, 0, 1, 0))

	taskDelay(0.08, function()
		if not SafeGet(screenGui, "Parent") then return end
		SafeSet(fillBar, "Size", UDim2.new(0, 0, 1, 0))
		local fillTween = TweenService:Create(fillBar, TweenInfo.new(3, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0),
		})
		fillTween:Play()
		fillTween.Completed:Connect(function()
			if not SafeGet(screenGui, "Parent") then return end
			SafeSet(buyBtn, "Active", true)
			SafeSet(buyLabel, "TextTransparency", 0)
		end)
	end)

	local function FuncClosePrompt()
		local closeTween = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position               = UDim2.new(0.5, 0, 0.5 + 0.02, 0),
			BackgroundTransparency = 1,
		})
		TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Linear), { BackgroundTransparency = 1 }):Play()
		closeTween:Play()
		closeTween.Completed:Connect(function()
			pcall(function() screenGui:Destroy() end)
			activeGui = nil
		end)
	end

	buyBtn.MouseButton1Click:Connect(function()
		if not SafeGet(buyBtn, "Active") then return end
		SafeSet(buyBtn, "Active", false)

		currentBalance = currentBalance - ROBUX_COST
		if currentBalance < 0 then currentBalance = 0 end

		SafeSet(fillBar, "Size", UDim2.new(0, 0, 1, 0))
		SafeSet(buyBtn, "BackgroundColor3", BUY_DARK)
		taskWait(1)

		if not SafeGet(screenGui, "Parent") then return end

		local exitTween = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position               = UDim2.new(0.5, 0, 0.5 + 0.02, 0),
			BackgroundTransparency = 1,
		})
		exitTween:Play()
		exitTween.Completed:Connect(function()
			pcall(function() card:Destroy() end)
			FuncSuccessCard(overlay, screenGui)

			taskDelay(0.35, function()
				local localChar = LocalPlayer.Character
				local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
				local closestName = "someone"

				if localRoot then
					local closest, closestDist = nil, mathHuge
					for _, p in Players:GetPlayers() do
						if p == LocalPlayer then continue end
						local char = p.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root then
							local dist = (root.Position - localRoot.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								closest = p
							end
						end
					end
					if closest then closestName = closest.Name end
				end

				local notifContainer = PlayerGui:FindFirstChild("Notification")
				if not notifContainer then return end
				local notifFrame = notifContainer:FindFirstChild("Notification")
				if not notifFrame then return end
				local template = notifFrame:FindFirstChild("Template")
				if not template then return end

				local clone = template:Clone()
				SafeSet(clone, "Visible", true)

				local notifText = stringFormat("You gifted Admin Commands to %s!", closestName)
				local green = Color3.fromRGB(56, 215, 87)

				if clone:IsA("TextLabel") then
					SafeSet(clone, "RichText", true)
					SafeSet(clone, "TextColor3", green)
					SafeSet(clone, "Text", notifText)
				end
				for _, child in clone:GetDescendants() do
					if child:IsA("TextLabel") then
						SafeSet(child, "RichText", true)
						SafeSet(child, "TextColor3", green)
						SafeSet(child, "Text", notifText)
					end
				end
				for _, child in clone:GetDescendants() do
					if child:IsA("UIStroke") then
						SafeSet(child, "Color", Color3.fromRGB(0, 0, 0))
					end
				end

				SafeSet(clone, "Parent", notifFrame)

				local SoundService = game:GetService("SoundService")
				local sound = New("Sound", {
					SoundId = "rbxassetid://83245966620103",
					Volume  = 1,
					Parent  = SoundService,
				})
				sound:Play()
				game:GetService("Debris"):AddItem(sound, 5)

				taskDelay(5, function()
					if clone and clone:IsDescendantOf(PlayerGui) then
						local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
						TweenService:Create(clone, fadeInfo, { BackgroundTransparency = 1 }):Play()
						for _, child in clone:GetDescendants() do
							if child:IsA("TextLabel") then
								TweenService:Create(child, fadeInfo, { TextTransparency = 1 }):Play()
							end
							if child:IsA("UIStroke") then
								TweenService:Create(child, fadeInfo, { Transparency = 1 }):Play()
							end
						end
						taskDelay(1, function() pcall(function() clone:Destroy() end) end)
					end
				end)
			end)
		end)
	end)

	closeBtn.MouseButton1Click:Connect(FuncClosePrompt)
end

-- hooks the buy button WITHOUT destroying the original
-- instead we layer an invisible blocker over the real button
-- and put our clone next to it — AC never sees a destroyed button
local function FuncHook()
	-- wait a few seconds so AC finishes its init before we touch anything
	taskWait(3)

	local shop = PlayerGui:WaitForChild("Shop", 30)
	if not shop then return end
	local shopFrame = shop:WaitForChild("Shop", 10)
	if not shopFrame then return end
	local content = shopFrame:WaitForChild("Content", 10)
	if not content then return end
	local list = content:WaitForChild("List", 10)
	if not list then return end
	local gamepassList = list:WaitForChild("GamepassList", 10)
	if not gamepassList then return end
	local item = gamepassList:WaitForChild("1227013099", 10)
	if not item then return end
	local ogBuy = item:WaitForChild("Buy", 10)
	if not ogBuy then return end

	-- clone the real button so it looks identical
	local clonedBuy = ogBuy:Clone()
	SafeSet(clonedBuy, "Name", RandName(10))
	SafeSet(clonedBuy, "Parent", ogBuy.Parent)

	-- place a transparent blocker on top of the ORIGINAL button
	-- so clicks never reach it, but it still exists for AC checks
	local blocker = New("TextButton", {
		Size                   = UDim2.new(1, 0, 1, 0),
		Position               = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "",
		ZIndex                 = ogBuy.ZIndex + 1,
		Name                   = RandName(10),
		Parent                 = ogBuy,
	})
	-- eat all clicks on the real button silently
	blocker.MouseButton1Click:Connect(function() end)

	clonedBuy.MouseButton1Click:Connect(function()
		taskWait(0.5)
		FuncOpenPrompt()
	end)
end

ContentProvider:PreloadAsync({ITEM_LOGO})
FuncHook()
