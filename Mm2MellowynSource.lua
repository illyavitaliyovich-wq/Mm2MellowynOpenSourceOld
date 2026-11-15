--[[
	mellowyn.ft GUI v13 | Roblox Delta
	Loading screen + HUD + draggable menu
	Paste into executor
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove old GUI if it exists
local guiParent = playerGui
do
	local okHui, hui = pcall(function()
		return gethui and gethui()
	end)
	if okHui and hui then
		guiParent = hui
	else
		local okCore, core = pcall(function()
			return game:GetService("CoreGui")
		end)
		if okCore and core then
			guiParent = core
		end
	end
end
for _, root in ipairs({playerGui, guiParent}) do
	pcall(function()
		local old = root:FindFirstChild("MellowynGUI")
		if old then old:Destroy() end
	end)
end
if Lighting:FindFirstChild("MellowynBlur") then
	Lighting.MellowynBlur:Destroy()
end

-- ===================== HELPERS =====================
local WHITE = Color3.fromRGB(255, 255, 255)
local TAU = math.pi * 2

local function tween(obj, props, time, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	local t = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
	t:Play()
	return t
end

-- Soft UI sounds (separate sounds for menu and feature toggles)
local function playUISound(soundId, volume, speed)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Volume = volume or 0.35
	sound.PlaybackSpeed = speed or 1
	sound.Parent = game:GetService("SoundService")
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(4, function()
		if sound.Parent then sound:Destroy() end
	end)
end

local TOGGLE_ON_SOUND = 6895079853
local TOGGLE_OFF_SOUND = 6895079853

local function getDevice()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	end
	return "PC"
end

local function getPing()
	local ok, ping = pcall(function()
		return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
	end)
	return ok and ping or 0
end

local function getClock()
	return os.date("%H:%M")
end

local function measure(text, size, font)
	return math.ceil(TextService:GetTextSize(text, size, font, Vector2.new(3000, 300)).X)
end

-- ===================== BLUR =====================
local blur = Instance.new("BlurEffect")
blur.Name = "MellowynBlur"
blur.Size = 0
blur.Parent = Lighting

-- ===================== SCREEN GUI =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MellowynGUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
local okParent = pcall(function()
	screenGui.Parent = guiParent
end)
if not okParent or not screenGui.Parent then
	screenGui.Parent = playerGui
end

-- Roblox auto-translates GUI text on non-English clients (that is what turned
-- "Invisible" into Russian and broke "inviz"). Turn it off for every element.
pcall(function() screenGui.AutoLocalize = false end)
screenGui.DescendantAdded:Connect(function(d)
	if d:IsA("GuiBase2d") then
		pcall(function() d.AutoLocalize = false end)
	end
end)

local connections = {}
screenGui.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
end)

-- ===================== TOAST (errors / notices) =====================
-- Thin rounded panel that slides in from the right edge of the screen.
-- A white line along the bottom runs out from left to right (2 s),
-- then the panel slides back out to the right.
local UI = {}
do
	local TOAST_Y, TOAST_H = 48, 34
	local current, token = nil, 0

	function UI.toast(text, seconds)
		text = tostring(text)
		seconds = seconds or 2
		token = token + 1
		local my = token
		if current then
			pcall(function() current:Destroy() end)
			current = nil
		end

		local textW = math.min(measure(text, 12, Enum.Font.GothamMedium), 260)
		local w = textW + 54

		local f = Instance.new("Frame")
		f.Name = "Toast"
		f.AnchorPoint = Vector2.new(1, 0)
		f.Size = UDim2.new(0, w, 0, TOAST_H)
		f.Position = UDim2.new(1, w + 24, 0, TOAST_Y)
		f.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		f.BackgroundTransparency = 0.12
		f.BorderSizePixel = 0
		f.ZIndex = 400
		f.Parent = screenGui
		current = f

		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 8)
		fc.Parent = f

		local fs = Instance.new("UIStroke")
		fs.Color = WHITE
		fs.Thickness = 1
		fs.Transparency = 0.55
		fs.Parent = f

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 18, 0, 18)
		icon.Position = UDim2.new(0, 9, 0.5, -2)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundColor3 = WHITE
		icon.BorderSizePixel = 0
		icon.Text = "!"
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 12
		icon.TextColor3 = Color3.fromRGB(10, 10, 10)
		icon.ZIndex = 401
		icon.Parent = f
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(1, 0)
		ic.Parent = icon

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -38, 1, -4)
		label.Position = UDim2.new(0, 33, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextColor3 = WHITE
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.ZIndex = 401
		label.Parent = f

		-- timer line: right edge stays, left edge runs to the right (left -> right)
		local line = Instance.new("Frame")
		line.Name = "Timer"
		line.AnchorPoint = Vector2.new(1, 1)
		line.Position = UDim2.new(1, -9, 1, -4)
		line.Size = UDim2.new(1, -18, 0, 2)
		line.BackgroundColor3 = WHITE
		line.BorderSizePixel = 0
		line.ZIndex = 401
		line.Parent = f
		local lc = Instance.new("UICorner")
		lc.CornerRadius = UDim.new(1, 0)
		lc.Parent = line

		task.spawn(function()
			tween(f, {Position = UDim2.new(1, -12, 0, TOAST_Y)}, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			task.wait(0.35)
			if my ~= token then return end
			tween(line, {Size = UDim2.new(0, 0, 0, 2)}, seconds, Enum.EasingStyle.Linear)
			task.wait(seconds)
			if my ~= token then return end
			tween(f, {Position = UDim2.new(1, w + 24, 0, TOAST_Y)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.wait(0.32)
			if current == f then current = nil end
			pcall(function() f:Destroy() end)
		end)
	end
end

local dark = Instance.new("Frame")
dark.Name = "DarkOverlay"
dark.Size = UDim2.new(1, 0, 1, 0)
dark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dark.BackgroundTransparency = 1
dark.BorderSizePixel = 0
dark.ZIndex = 1
dark.Parent = screenGui

-- ===================== CENTER-REVEAL TEXT =====================
-- Text that expands from the middle to both sides
local function makeRevealText(name, text, size)
	local font = Enum.Font.GothamBold
	local w = measure(text, size, font) + 30
	local h = size + 24

	local holder = Instance.new("Frame")
	holder.Name = name
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.5, 0)
	holder.Size = UDim2.new(0, 0, 0, h)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true
	holder.Visible = false
	holder.ZIndex = 10
	holder.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.Size = UDim2.new(0, w, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = font
	label.TextSize = size
	label.TextColor3 = WHITE
	label.ZIndex = 11
	label.Parent = holder

	return holder, w, h
end

local welcome, welcomeW, welcomeH = makeRevealText("Welcome", "Welcome!", 68)
local success, successW, successH = makeRevealText("Success", "Script successfully loaded!", 32)

-- ===================== LOADING =====================
local loadFrame = Instance.new("Frame")
loadFrame.Name = "LoadingFrame"
loadFrame.Size = UDim2.new(0, 440, 0, 90)
loadFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
loadFrame.AnchorPoint = Vector2.new(0.5, 0.5)
loadFrame.BackgroundTransparency = 1
loadFrame.Visible = false
loadFrame.ZIndex = 10
loadFrame.Parent = screenGui

local loadTitle = Instance.new("TextLabel")
loadTitle.Name = "Title"
loadTitle.Size = UDim2.new(1, 0, 0, 36)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "Loading..."
loadTitle.Font = Enum.Font.GothamBold
loadTitle.TextSize = 28
loadTitle.TextColor3 = WHITE
loadTitle.TextTransparency = 1
loadTitle.ZIndex = 11
loadTitle.Parent = loadFrame

local barBg = Instance.new("Frame")
barBg.Name = "BarBackground"
barBg.Size = UDim2.new(1, 0, 0, 8)
barBg.Position = UDim2.new(0, 0, 0, 46)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barBg.BackgroundTransparency = 1
barBg.BorderSizePixel = 0
barBg.ZIndex = 11
barBg.Parent = loadFrame

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBg

local barStroke = Instance.new("UIStroke")
barStroke.Color = WHITE
barStroke.Thickness = 1.2
barStroke.Transparency = 1
barStroke.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 12
barFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "Percent"
percentLabel.Size = UDim2.new(1, 0, 0, 28)
percentLabel.Position = UDim2.new(0, 0, 0, 60)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextSize = 22
percentLabel.TextColor3 = WHITE
percentLabel.TextTransparency = 1
percentLabel.ZIndex = 11
percentLabel.Parent = loadFrame

-- ===================== TOP RIGHT HUD =====================
local HUD_FONT = Enum.Font.GothamMedium
local HUD_SIZE = 12
local HUD_W = measure("mellowyn.ft | free  00:00  000 FPS  000 Ping | Mobile", HUD_SIZE, HUD_FONT) + 22
local HUD_H = 28
local HUD_GAP = 6 -- 6px spacing after the Telegram panel

-- Telegram rectangle (placed before the FPS / ping rectangle)
local TG_TEXT = "t.me/MellowynScripts    "
local tgTextW = measure(TG_TEXT, 11, Enum.Font.GothamBold)
local TG_W = tgTextW + 8 + 36 + 5 + 10

local tgBox = Instance.new("Frame")
tgBox.Name = "TelegramBox"
tgBox.Size = UDim2.new(0, 0, 0, HUD_H)
tgBox.Position = UDim2.new(1, -(12 + HUD_W + HUD_GAP), 0, 12)
tgBox.AnchorPoint = Vector2.new(1, 0)
tgBox.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
tgBox.BackgroundTransparency = 0.15
tgBox.BorderSizePixel = 0
tgBox.ClipsDescendants = true
tgBox.Visible = false
tgBox.ZIndex = 200
tgBox.Parent = screenGui

local tgCorner = Instance.new("UICorner")
tgCorner.CornerRadius = UDim.new(0, 6)
tgCorner.Parent = tgBox

local tgBoxIcon = Instance.new("ImageLabel")
tgBoxIcon.Size = UDim2.new(0, 36, 0, 36)
tgBoxIcon.Position = UDim2.new(0, 8, 0.5, 0)
tgBoxIcon.AnchorPoint = Vector2.new(0, 0.5)
tgBoxIcon.BackgroundTransparency = 1
tgBoxIcon.Image = "rbxassetid://92043286504244"
tgBoxIcon.ScaleType = Enum.ScaleType.Fit
tgBoxIcon.ZIndex = 201
tgBoxIcon.Parent = tgBox

local tgBoxText = Instance.new("TextLabel")
tgBoxText.Size = UDim2.new(0, tgTextW + 4, 1, 0)
tgBoxText.Position = UDim2.new(0, 42, 0, 0)
tgBoxText.BackgroundTransparency = 1
tgBoxText.Text = TG_TEXT
tgBoxText.TextTruncate = Enum.TextTruncate.None
tgBoxText.Font = Enum.Font.GothamBold
tgBoxText.TextSize = 11
tgBoxText.TextColor3 = WHITE
tgBoxText.TextXAlignment = Enum.TextXAlignment.Left
tgBoxText.ZIndex = 201
tgBoxText.Parent = tgBox

-- FPS / ping rectangle
local hud = Instance.new("TextButton")
hud.Name = "HUD"
hud.Size = UDim2.new(0, 0, 0, HUD_H)
hud.Position = UDim2.new(1, -12, 0, 12)
hud.AnchorPoint = Vector2.new(1, 0)
hud.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
hud.BackgroundTransparency = 0.15
hud.BorderSizePixel = 0
hud.Text = ""
hud.AutoButtonColor = false
hud.ClipsDescendants = true
hud.Visible = false
hud.ZIndex = 200
hud.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 6)
hudCorner.Parent = hud

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = WHITE
hudStroke.Thickness = 1
hudStroke.Transparency = 0.55
hudStroke.Parent = hud

local hudText = Instance.new("TextLabel")
hudText.Name = "Info"
hudText.Size = UDim2.new(0, HUD_W - 12, 1, 0)
hudText.Position = UDim2.new(0, 10, 0, 0)
hudText.BackgroundTransparency = 1
hudText.Text = ""
hudText.Font = HUD_FONT
hudText.TextSize = HUD_SIZE
hudText.TextColor3 = Color3.fromRGB(230, 230, 230)
hudText.TextXAlignment = Enum.TextXAlignment.Left
hudText.ZIndex = 201
hudText.Parent = hud

-- ===================== MAIN MENU =====================
local MENU_W, MENU_H = 365, 360
local SIDEBAR_W = 92
local TOPBAR_H = 30
-- functions area (right of the vertical line, under the horizontal line)
local BG_W = MENU_W - SIDEBAR_W - 1
local BG_H = MENU_H - TOPBAR_H - 1

local menu = Instance.new("CanvasGroup")
menu.Name = "MainMenu"
menu.Size = UDim2.new(0, MENU_W, 0, MENU_H)
menu.Position = UDim2.new(0.5, 0, 0.5, 0)
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
menu.BackgroundTransparency = 0.05
menu.BorderSizePixel = 0
menu.GroupTransparency = 1
menu.Active = true
menu.Visible = false
menu.ZIndex = 100
menu.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menu

local menuScale = Instance.new("UIScale")
menuScale.Scale = 0.92
menuScale.Parent = menu

-- ---------- Background layer ----------
-- Kept as an empty layer so the menu remains clean (no decorative triangles).

-- ---------- Content layer (above the background) ----------
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 1, 0)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ZIndex = 2
content.Parent = menu

-- Photo (top left)
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 44, 0, 44)
logo.Position = UDim2.new(0, (SIDEBAR_W - 44) / 2, 0, 8)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://119217319086863"
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = content

-- Vertical line (right of the photo, top to bottom)
local vLine = Instance.new("Frame")
vLine.Name = "VerticalLine"
vLine.Size = UDim2.new(0, 1, 1, 0)
vLine.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
vLine.BackgroundColor3 = WHITE
vLine.BackgroundTransparency = 0.5
vLine.BorderSizePixel = 0
vLine.Parent = content

-- Horizontal line (30px from the top, from the vertical line to the right edge)
local hLine = Instance.new("Frame")
hLine.Name = "HorizontalLine"
hLine.Size = UDim2.new(1, -(SIDEBAR_W + 1), 0, 1)
hLine.Position = UDim2.new(0, SIDEBAR_W + 1, 0, TOPBAR_H)
hLine.BackgroundColor3 = WHITE
hLine.BackgroundTransparency = 0.5
hLine.BorderSizePixel = 0
hLine.Parent = content

-- Top bar
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(0, 225, 0, TOPBAR_H)
topBar.Position = UDim2.new(0, SIDEBAR_W + 8, 0, 0)
topBar.BackgroundTransparency = 1
topBar.BorderSizePixel = 0
topBar.Parent = content

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.SortOrder = Enum.SortOrder.LayoutOrder
topLayout.Padding = UDim.new(0, 6)
topLayout.Parent = topBar

-- Nick rectangle: avatar square + bold nick
local nickPill = Instance.new("Frame")
nickPill.AutomaticSize = Enum.AutomaticSize.X
nickPill.Size = UDim2.new(0, 0, 0, 20)
nickPill.BackgroundTransparency = 1
nickPill.BorderSizePixel = 0
nickPill.LayoutOrder = 1
nickPill.Parent = topBar

local pillCorner = Instance.new("UICorner")
pillCorner.CornerRadius = UDim.new(0, 6)
pillCorner.Parent = nickPill

local pillStroke = Instance.new("UIStroke")
pillStroke.Color = WHITE
pillStroke.Thickness = 1
pillStroke.Transparency = 0.7
pillStroke.Parent = nickPill

local pillPadding = Instance.new("UIPadding")
pillPadding.PaddingLeft = UDim.new(0, 5)
pillPadding.PaddingRight = UDim.new(0, 5)
pillPadding.Parent = nickPill

local pillLayout = Instance.new("UIListLayout")
pillLayout.FillDirection = Enum.FillDirection.Horizontal
pillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
pillLayout.Padding = UDim.new(0, 4)
pillLayout.Parent = nickPill

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 14, 0, 14)
avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
avatar.BorderSizePixel = 0
avatar.ScaleType = Enum.ScaleType.Crop
avatar.LayoutOrder = 1
avatar.Parent = nickPill

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(0, 4)
avatarCorner.Parent = avatar

local nickText = Instance.new("TextLabel")
nickText.AutomaticSize = Enum.AutomaticSize.X
nickText.Size = UDim2.new(0, 0, 1, 0)
nickText.BackgroundTransparency = 1
nickText.Text = player.Name
nickText.Font = Enum.Font.GothamBold
nickText.TextSize = 10
nickText.TextColor3 = WHITE
nickText.TextXAlignment = Enum.TextXAlignment.Left
nickText.TextTruncate = Enum.TextTruncate.AtEnd
nickText.LayoutOrder = 2
nickText.Parent = nickPill

local nickLimit = Instance.new("UISizeConstraint")
nickLimit.MaxSize = Vector2.new(60, math.huge)
nickLimit.Parent = nickText

task.spawn(function()
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
	end)
	if ok and img then
		avatar.Image = img
	end
end)

-- Profile image sits outside the menu, above its top-right corner.
local profileButton = Instance.new("ImageButton")
profileButton.Name = "ProfileImage"
profileButton.Size = UDim2.new(0, 55, 0, 55) -- 2.5x the previous 22px size
profileButton.AnchorPoint = Vector2.new(0.5, 0.5)
profileButton.BackgroundTransparency = 1
profileButton.BorderSizePixel = 0
profileButton.AutoButtonColor = false
profileButton.Image = "rbxassetid://76713996585078"
profileButton.ScaleType = Enum.ScaleType.Fit
profileButton.ZIndex = 300
profileButton.Visible = false
profileButton.Parent = screenGui

local profileCorner = Instance.new("UICorner")
profileCorner.CornerRadius = UDim.new(0, 0)
profileCorner.Parent = profileButton

local profileScale = Instance.new("UIScale")
profileScale.Scale = 1
profileScale.Parent = profileButton

local function updateProfilePosition()
	profileButton.Position = UDim2.new(
		0.5, menu.Position.X.Offset + MENU_W / 2 - 29,
		0.5, menu.Position.Y.Offset - MENU_H / 2 - 10
	)
end
updateProfilePosition()

profileButton.MouseButton1Down:Connect(function()
	tween(profileScale, {Scale = 0.88}, 0.08)
end)
profileButton.MouseButton1Up:Connect(function()
	tween(profileScale, {Scale = 1}, 0.12)
end)
profileButton.MouseLeave:Connect(function()
	tween(profileScale, {Scale = 1}, 0.12)
end)

-- ---------- Tabs ----------
local BLACK = Color3.fromRGB(0, 0, 0)
local tabs = {}

local closeSettingsPanel = function() end
local updateSettingsPosition = function() end

-- "World" is a sub-tab of "Visual": it slides out under Visual while Visual / World is open
local tabState = {worldShown = false, layout = function() end}

local function selectTab(selected)
	for _, t in pairs(tabs) do
		local on = (t == selected)
		tween(t.button, {BackgroundTransparency = on and 0.75 or 1}, 0.25)
		tween(t.bar, {BackgroundTransparency = on and 0 or 1}, 0.25)
		tween(t.label, {TextTransparency = on and 0 or 0.5}, 0.25)
		tween(t.icon, {ImageTransparency = on and 0 or 0.5}, 0.25)
		if t.fades then
			for _, fd in ipairs(t.fades) do
				tween(fd[1], {[fd[2]] = on and 0 or 0.5}, 0.25)
			end
		end
		t.page.Visible = on
	end
	local wantWorld = (selected == tabs.Visual or selected == tabs.World)
	if wantWorld ~= tabState.worldShown then
		tabState.worldShown = wantWorld
		tabState.layout()
	end
	closeSettingsPanel()
	if selected == tabs.Fling and tabState.onFling then
		tabState.onFling()
	end
	if selected == tabs.Tp and tabState.onTp then
		tabState.onTp()
	end
end

local function createTab(name, iconId, y, drawIcon)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(0, SIDEBAR_W - 12, 0, 28)
	button.Position = UDim2.new(0, 6, 0, y)
	button.BackgroundColor3 = WHITE
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	-- white vertical rounded bar on the left (shown when selected)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0, 14)
	bar.Position = UDim2.new(0, 3, 0.5, 0)
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.BackgroundColor3 = WHITE
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Parent = button

	local barCornerTab = Instance.new("UICorner")
	barCornerTab.CornerRadius = UDim.new(1, 0)
	barCornerTab.Parent = bar

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 18, 0, 18)
	icon.Position = UDim2.new(0, 11, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId and ("rbxassetid://" .. iconId) or ""
	icon.ImageTransparency = 0.5
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -34, 1, 0)
	label.Position = UDim2.new(0, 34, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextColor3 = WHITE
	label.TextTransparency = 0.5
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = button

	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = Color3.new(1, 1, 1)
	page.ScrollBarImageTransparency = 0.6
	page.ElasticBehavior = Enum.ElasticBehavior.Never
	page.Position = UDim2.new(0, SIDEBAR_W + 1, 0, TOPBAR_H + 1)
	page.Size = UDim2.new(0, BG_W, 0, BG_H)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Visible = false
	page.Parent = content

	local tab = {button = button, bar = bar, icon = icon, label = label, page = page,
		fades = drawIcon and drawIcon(icon) or nil}
	tabs[name] = tab

	button.MouseButton1Click:Connect(function()
		selectTab(tab)
	end)

	return tab
end

local mainTab = createTab("Main", "76764433656133", 62)
local visualTab = createTab("Visual", "121957543090566", 94)
local aimTab = createTab("Aim", "112551152303551", 126)

-- Fling tab: the lowest one in the sidebar (icon = three wind lines drawn from frames, no asset needed)
local flingTab = createTab("Fling", nil, 158, function(icon)
	local fades = {}
	for i, wv in ipairs({1, 0.7, 0.85}) do
		local b = Instance.new("Frame")
		b.Size = UDim2.new(wv, 0, 0, 2)
		b.Position = UDim2.new(0, 0, 0, 3 + (i - 1) * 5)
		b.BackgroundColor3 = WHITE
		b.BackgroundTransparency = 0.5
		b.BorderSizePixel = 0
		b.Parent = icon
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = b
		fades[#fades + 1] = {b, "BackgroundTransparency"}
	end
	return fades
end)

-- Tp tab: below Fling (icon = ring + dot drawn from frames, no asset needed)
createTab("Tp", nil, 190, function(icon)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.new(1, -2, 1, -2)
	ring.Position = UDim2.new(0.5, 0, 0.5, 0)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = icon
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring
	local rs = Instance.new("UIStroke")
	rs.Color = WHITE
	rs.Thickness = 1.4
	rs.Transparency = 0.5
	rs.Parent = ring
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(0.5, 0, 0.5, 0)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = WHITE
	dot.BackgroundTransparency = 0.5
	dot.BorderSizePixel = 0
	dot.Parent = icon
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(1, 0)
	dc.Parent = dot
	return {{rs, "Transparency"}, {dot, "BackgroundTransparency"}}
end)

-- Skin Changer tab: below Tp (icon = a small diamond drawn from a frame, no asset needed)
createTab("Skin", nil, 222, function(icon)
	local dia = Instance.new("Frame")
	dia.Size = UDim2.new(0, 12, 0, 12)
	dia.Position = UDim2.new(0.5, 0, 0.5, 0)
	dia.AnchorPoint = Vector2.new(0.5, 0.5)
	dia.Rotation = 45
	dia.BackgroundTransparency = 1
	dia.BorderSizePixel = 0
	dia.Parent = icon
	local ds = Instance.new("UIStroke")
	ds.Color = WHITE
	ds.Thickness = 1.4
	ds.Transparency = 0.5
	ds.Parent = dia
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 4, 0, 4)
	dot.Position = UDim2.new(0.5, 0, 0.5, 0)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Rotation = 45
	dot.BackgroundColor3 = WHITE
	dot.BackgroundTransparency = 0.5
	dot.BorderSizePixel = 0
	dot.Parent = icon
	return {{ds, "Transparency"}, {dot, "BackgroundTransparency"}}
end)
do
	-- "Skin Changer" is longer than the other labels: shrink the text to fit the sidebar
	local lb = tabs.Skin.label
	lb.Text = "Skin Changer"
	lb.TextScaled = true
	local lim = Instance.new("UITextSizeConstraint")
	lim.MaxTextSize = 12
	lim.MinTextSize = 7
	lim.Parent = lb
end

-- Vote Duper tab
createTab("Vote", nil, 254, function(icon)
	local b1 = Instance.new("Frame")
	b1.Size = UDim2.new(0.7, 0, 0, 2)
	b1.Position = UDim2.new(0.15, 0, 0.25, 0)
	b1.BackgroundColor3 = WHITE
	b1.BackgroundTransparency = 0.5
	b1.BorderSizePixel = 0
	b1.Parent = icon
	local b2 = Instance.new("Frame")
	b2.Size = UDim2.new(0.7, 0, 0, 2)
	b2.Position = UDim2.new(0.15, 0, 0.5, 0)
	b2.BackgroundColor3 = WHITE
	b2.BackgroundTransparency = 0.5
	b2.BorderSizePixel = 0
	b2.Parent = icon
	local b3 = Instance.new("Frame")
	b3.Size = UDim2.new(0.7, 0, 0, 2)
	b3.Position = UDim2.new(0.15, 0, 0.75, 0)
	b3.BackgroundColor3 = WHITE
	b3.BackgroundTransparency = 0.5
	b3.BorderSizePixel = 0
	b3.Parent = icon
	return {{b1, "BackgroundTransparency"}, {b2, "BackgroundTransparency"}, {b3, "BackgroundTransparency"}}
end)
do
	local lb = tabs.Vote.label
	lb.Text = "Vote Duper"
	lb.TextScaled = true
	local lim = Instance.new("UITextSizeConstraint")
	lim.MaxTextSize = 11
	lim.MinTextSize = 7
	lim.Parent = lb
end

-- Config tab
createTab("Config", nil, 286, function(icon)
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0.7, 0, 0.7, 0)
	box.Position = UDim2.new(0.15, 0, 0.15, 0)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Parent = icon
	local st = Instance.new("UIStroke")
	st.Color = WHITE
	st.Thickness = 1.4
	st.Transparency = 0.5
	st.Parent = box
	local ln = Instance.new("Frame")
	ln.Size = UDim2.new(0.6, 0, 0, 1.5)
	ln.Position = UDim2.new(0.2, 0, 0.35, 0)
	ln.BackgroundColor3 = WHITE
	ln.BackgroundTransparency = 0.5
	ln.BorderSizePixel = 0
	ln.Parent = icon
	local ln2 = Instance.new("Frame")
	ln2.Size = UDim2.new(0.45, 0, 0, 1.5)
	ln2.Position = UDim2.new(0.2, 0, 0.55, 0)
	ln2.BackgroundColor3 = WHITE
	ln2.BackgroundTransparency = 0.5
	ln2.BorderSizePixel = 0
	ln2.Parent = icon
	return {{st, "Transparency"}, {ln, "BackgroundTransparency"}, {ln2, "BackgroundTransparency"}}
end)


-- World sub-tab (small globe icon drawn from frames, no asset needed)
local worldTab = createTab("World", nil, 126, function(icon)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.new(1, -2, 1, -2)
	ring.Position = UDim2.new(0.5, 0, 0.5, 0)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = icon
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring
	local rs = Instance.new("UIStroke")
	rs.Color = WHITE
	rs.Thickness = 1.4
	rs.Transparency = 0.5
	rs.Parent = ring

	local mer = Instance.new("Frame")
	mer.Size = UDim2.new(0.46, 0, 1, -2)
	mer.Position = UDim2.new(0.5, 0, 0.5, 0)
	mer.AnchorPoint = Vector2.new(0.5, 0.5)
	mer.BackgroundTransparency = 1
	mer.BorderSizePixel = 0
	mer.Parent = icon
	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(1, 0)
	mc.Parent = mer
	local ms = Instance.new("UIStroke")
	ms.Color = WHITE
	ms.Thickness = 1.2
	ms.Transparency = 0.5
	ms.Parent = mer

	local eq = Instance.new("Frame")
	eq.Size = UDim2.new(1, -2, 0, 1.4)
	eq.Position = UDim2.new(0.5, 0, 0.5, 0)
	eq.AnchorPoint = Vector2.new(0.5, 0.5)
	eq.BackgroundColor3 = WHITE
	eq.BackgroundTransparency = 0.5
	eq.BorderSizePixel = 0
	eq.Parent = icon

	return {{rs, "Transparency"}, {ms, "Transparency"}, {eq, "BackgroundTransparency"}}
end)
worldTab.button.ClipsDescendants = true
worldTab.button.Size = UDim2.new(0, SIDEBAR_W - 12, 0, 0)
worldTab.button.Visible = false

tabState.layout = function()
	local show = tabState.worldShown
	if show then worldTab.button.Visible = true end
	tween(worldTab.button, {Size = UDim2.new(0, SIDEBAR_W - 12, 0, show and 28 or 0)}, 0.25)
	tween(aimTab.button, {Position = UDim2.new(0, 6, 0, show and 158 or 126)}, 0.25)
	tween(flingTab.button, {Position = UDim2.new(0, 6, 0, show and 190 or 158)}, 0.25)
	tween(tabs.Tp.button, {Position = UDim2.new(0, 6, 0, show and 222 or 190)}, 0.25)
	tween(tabs.Skin.button, {Position = UDim2.new(0, 6, 0, show and 254 or 222)}, 0.25)
	if tabs.Vote then tween(tabs.Vote.button, {Position = UDim2.new(0, 6, 0, show and 286 or 254)}, 0.25) end
	if tabs.Config then tween(tabs.Config.button, {Position = UDim2.new(0, 6, 0, show and 318 or 286)}, 0.25) end
	if not show then
		task.delay(0.28, function()
			if not tabState.worldShown then worldTab.button.Visible = false end
		end)
	end
end

-- ---------- Main page: two cards ----------
local CARD_SIZE = 124
local CARD_PAD = 8
-- Two crisp straight strokes meet exactly at one endpoint (no curved glyph).
local function buildCheck(box)
	local strokes = {}
	local points = {
		Vector2.new(3.0, 9.0),
		Vector2.new(7.0, 13.0),
		Vector2.new(15.0, 4.0)
	}
	for i = 1, 2 do
		local a, b = points[i], points[i + 1]
		local delta = b - a
		local stroke = Instance.new("Frame")
		stroke.Name = "CheckStroke" .. i
		stroke.AnchorPoint = Vector2.new(0.5, 0.5)
		stroke.Position = UDim2.new(0, (a.X + b.X) / 2, 0, (a.Y + b.Y) / 2)
		stroke.Size = UDim2.new(0, delta.Magnitude + 0.8, 0, 1.1)
		stroke.Rotation = math.deg(math.atan2(delta.Y, delta.X))
		stroke.BackgroundColor3 = BLACK
		stroke.BackgroundTransparency = 1
		stroke.BorderSizePixel = 0
		stroke.ZIndex = box.ZIndex + 1
		stroke.Parent = box
		strokes[i] = stroke
	end
	return strokes
end

local function makeCheckAnimator(strokes)
	return function(on)
		for _, stroke in ipairs(strokes) do
			tween(stroke, {BackgroundTransparency = on and 0 or 1}, 0.12)
		end
	end
end

local function makeCardHeader(card, title)
	-- bold title at the top
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -16, 0, 20)
	header.Position = UDim2.new(0, 8, 0, 0)
	header.BackgroundTransparency = 1
	header.Text = title
	header.Font = Enum.Font.GothamBold
	header.TextSize = 12
	header.TextColor3 = WHITE
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = card

	-- white line 20px from the top, 50% transparent
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 0, 20)
	line.BackgroundColor3 = WHITE
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel = 0
	line.Parent = card
end

-- ===================== CONFIG REGISTRY =====================
-- Every persistent menu control registers here under a stable key.
-- Save reads get(); load calls set(), which runs the control's own onChange,
-- so the checkbox, the Feat state and the real feature move together.
UI.CFG = {reg = {}, order = {}}
function UI.cfgAdd(key, kind, get, set)
	if not key or key == "" then return end
	local reg = UI.CFG.reg
	if reg[key] then
		local n = 2
		while reg[key .. "#" .. n] do n = n + 1 end
		key = key .. "#" .. n
	end
	reg[key] = {kind = kind, get = get, set = set}
	UI.CFG.order[#UI.CFG.order + 1] = key
end

-- Toggle row (checkbox + text). Returns a controller {row, set, get}.
-- key (optional): registers the row in the config registry.
local function makeToggleRow(parent, y, text, onChange, reserve, key)
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Position = UDim2.new(0, 0, 0, y)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.Parent = parent

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 18, 0, 18)
	box.Position = UDim2.new(0, 6, 0.5, 0)
	box.AnchorPoint = Vector2.new(0, 0.5)
	box.BackgroundColor3 = BLACK
	box.BackgroundTransparency = 0.2
	box.BorderSizePixel = 0
	box.Parent = row

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = box

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = WHITE
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.6
	boxStroke.Parent = box

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -(28 + (reserve or 8)), 1, 0)
	label.Position = UDim2.new(0, 28, 0, 0)
	label.BackgroundTransparency = 1
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.None
	label.Text = text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local labelLimit = Instance.new("UITextSizeConstraint")
	labelLimit.MaxTextSize = 12
	labelLimit.MinTextSize = 7
	labelLimit.Parent = label

	local setCheck = makeCheckAnimator(buildCheck(box))
	local checked = false
	local ctrl = {row = row}

	function ctrl.get()
		return checked
	end

	function ctrl.set(state, silent, quiet)
		checked = state and true or false
		tween(box, {BackgroundColor3 = checked and WHITE or BLACK}, 0.3)
		setCheck(checked)
		if not silent then
			if not quiet then
				playUISound(checked and TOGGLE_ON_SOUND or TOGGLE_OFF_SOUND, 0.28, checked and 1.04 or 0.96)
			end
			if onChange then
				onChange(checked)
			end
		end
	end

	row.MouseButton1Click:Connect(function()
		ctrl.set(not checked)
	end)

	if key then
		UI.cfgAdd(key, "bool", ctrl.get, function(v)
			v = (v == true)
			if ctrl.get() ~= v then ctrl.set(v, false, true) end
		end)
	end

	return ctrl
end

-- Gear icon built from simple shapes (no external asset needed)
local function makeGearButton(parentRow)
	local btn = Instance.new("TextButton")
	btn.Name = "SettingsGear"
	btn.Size = UDim2.new(0, 20, 0, 20)
	btn.Position = UDim2.new(1, -8, 0.5, 0)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parentRow

	local gear = Instance.new("Frame")
	gear.Name = "Gear"
	gear.Size = UDim2.new(0, 16, 0, 16)
	gear.Position = UDim2.new(0.5, 0, 0.5, 0)
	gear.AnchorPoint = Vector2.new(0.5, 0.5)
	gear.BackgroundTransparency = 1
	gear.Parent = btn

	for i = 0, 3 do
		local tooth = Instance.new("Frame")
		tooth.Size = UDim2.new(0, 16, 0, 3)
		tooth.Position = UDim2.new(0.5, 0, 0.5, 0)
		tooth.AnchorPoint = Vector2.new(0.5, 0.5)
		tooth.Rotation = i * 45
		tooth.BackgroundColor3 = WHITE
		tooth.BackgroundTransparency = 0.1
		tooth.BorderSizePixel = 0
		tooth.Parent = gear
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0, 1)
		tc.Parent = tooth
	end

	local body = Instance.new("Frame")
	body.Size = UDim2.new(0, 11, 0, 11)
	body.Position = UDim2.new(0.5, 0, 0.5, 0)
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.BackgroundColor3 = WHITE
	body.BackgroundTransparency = 0.1
	body.BorderSizePixel = 0
	body.Parent = gear
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(1, 0)
	bc.Parent = body

	local hole = Instance.new("Frame")
	hole.Size = UDim2.new(0, 5, 0, 5)
	hole.Position = UDim2.new(0.5, 0, 0.5, 0)
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.BackgroundColor3 = BLACK
	hole.BorderSizePixel = 0
	hole.Parent = gear
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(1, 0)
	hc.Parent = hole

	return btn, gear
end

-- ===================== FEATURES (logic, ported from MM2 script) =====================
local GuiService = game:GetService("GuiService")

local Feat = {
	ST = {
		invis = false, antiaim = false, chams = false, spin = false, antifling = false, water = false,
		speed = false, bunny = false, infjump = false, noclip = false, fly = false,
		autograb = false, autofarm = false, fov = false, stretch = false,
		esp = false, boxfill = false, espline = false, avatar = false,
		chamsfx = false, trail = false, dtrail = false, jcircle = false,
	},
	P = {
		WalkSpeed = 32, FlySpeed = 50, SpinSpeed = 10, AARange = 10,
		Fov = 90, Stretch = 0.65,
		BoxColor = Color3.fromRGB(0, 220, 130), FillColor = Color3.fromRGB(0, 220, 130),
		LineColor = Color3.fromRGB(0, 220, 130),
		BoxStyle = "Box", -- "Box" | "Corner"
		ChamsColor = Color3.fromRGB(0, 220, 130), ChamsMode = "Default", ChamsAll = false,
		TrailColor = Color3.fromRGB(255, 255, 255), DTrailColor = Color3.fromRGB(255, 255, 255),
		JumpColor = Color3.fromRGB(255, 255, 255), JumpRadius = 8,
		-- gradients: on/off + second colour (ESP box and its fill share Box*, Esp Line, Chams)
		BoxGrad = true, BoxGrad2 = Color3.fromRGB(0, 140, 255),
		LineGrad = true, LineGrad2 = Color3.fromRGB(0, 140, 255),
		ChamsGrad = true, ChamsGrad2 = Color3.fromRGB(0, 140, 255),
	},
	Bunny = {Max = 60, Gain = 14, Auto = true, speed = nil, landedAt = 0},
	-- filled in by the Aim section (Zenith role detection): "Murderer" / "Sheriff" / "Hero" / "Innocent"
	getRole = function() return nil end,
}

do
	local ST, P, Bunny = Feat.ST, Feat.P, Feat.Bunny

	local function track(c)
		table.insert(connections, c)
		return c
	end
	Feat.track = track

	local partCache = setmetatable({}, {__mode = "k"})
	local function cachedParts(char)
		local c = partCache[char]
		if not c or tick() - c.t > 1 then
			c = {t = tick(), parts = {}}
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") then
					table.insert(c.parts, d)
				end
			end
			partCache[char] = c
		end
		return c.parts
	end
	local function getHum(char)
		return char and char:FindFirstChildOfClass("Humanoid")
	end
	local function getRoot(char)
		return char and char:FindFirstChild("HumanoidRootPart")
	end
	local function hasTool(plr, toolName)
		local char = plr.Character
		local bp = plr:FindFirstChild("Backpack")
		return (char and char:FindFirstChild(toolName)) or (bp and bp:FindFirstChild(toolName)) or nil
	end

	-- ---------- desync core (Invisible / Anti Aim / Auto Grab hitbox) ----------
	local invisReal, desynced = nil, false
	local realVel, realAng = nil, nil
	local rnd = Random.new()
	local INVIS_BASE = Vector3.new(10000000, 2000000, 300000)
	local RESTORE_BIND = "MellowynDesyncRestore"
	local forcedHitbox = nil -- CFrame: hitbox is put here for a moment (Auto Grab Gun)
	local extForced = nil    -- CFrame: hitbox override set by other modules (Shoot Murderer)
	local chamsPart = nil
	local shotHold = 0 -- >0: Invisible / Anti Aim are paused (real body is sent to the server while a shot is fired)

	local function destroyChams()
		if chamsPart then
			chamsPart:Destroy()
			chamsPart = nil
		end
	end
	local function updateChams(cf)
		if not (ST.antiaim and ST.chams) then
			destroyChams()
			return
		end
		if not (chamsPart and chamsPart.Parent) then
			chamsPart = Instance.new("Part")
			chamsPart.Name = "Mellowyn_HitboxChams"
			chamsPart.Anchored = true
			chamsPart.CanCollide = false
			chamsPart.CanQuery = false
			chamsPart.CanTouch = false
			chamsPart.Massless = true
			chamsPart.Material = Enum.Material.Neon
			chamsPart.Color = Color3.fromRGB(0, 255, 80)
			chamsPart.Transparency = 0.45
			chamsPart.Size = Vector3.new(3.6, 5.5, 2)
			chamsPart.Parent = workspace
		end
		chamsPart.CFrame = cf
	end

	-- Anti Aim: fast orbit teleport around the local character (no hitbox spam)
	local aaAngle = 0
	local function aaCFrame(real)
		local range = math.max(P.AARange or 8, 2)
		aaAngle = (aaAngle + 0.85) % (math.pi * 2)
		local ox = math.cos(aaAngle) * range
		local oz = math.sin(aaAngle) * range
		local oy = math.sin(aaAngle * 2.3) * (range * 0.15)
		local p = real.Position + Vector3.new(ox, oy, oz)
		return CFrame.new(p, real.Position)
	end

	-- Auto Grab Gun (runs every frame, before the desync handler)
	local grab = {drop = nil, started = nil, tried = {}, block = false}
	-- VotePads lookup is cached (a deep FindFirstChild every frame was eating the frame time)
	local padsCache, padsAt = nil, 0
	local function votePads()
		if padsCache and padsCache.Parent then return padsCache end
		padsCache = nil
		if tick() - padsAt < 2 then return nil end
		padsAt = tick()
		padsCache = workspace:FindFirstChild("VotePads", true)
		return padsCache
	end
	local function inLobby(root)
		if root.Position.Y > 450 then return true end
		local pads = votePads()
		if pads then
			local ok, pivot = pcall(function()
				return pads:GetPivot().Position
			end)
			if ok then
				local flat = Vector3.new(pivot.X - root.Position.X, 0, pivot.Z - root.Position.Z).Magnitude
				if flat < 150 and math.abs(pivot.Y - root.Position.Y) < 120 then return true end
			end
		end
		return false
	end
	local function hookDeath(char)
		local hum = char and char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				grab.block = true
			end)
		end
	end
	if player.Character then task.spawn(hookDeath, player.Character) end
	track(player.CharacterAdded:Connect(function(char)
		task.spawn(hookDeath, char)
	end))
	local grabStep
	track(workspace.DescendantAdded:Connect(function(d)
		if d.Name == "GunDrop" and d:IsA("BasePart") then
			grab.drop = d
			-- grab on the very frame the gun appears, don't wait for the next Heartbeat
			if ST.autograb and grabStep then task.defer(grabStep) end
		end
	end))

	-- touch burst: root + a few limbs, several times per frame
	local GRAB_PARTS = {"HumanoidRootPart", "Head", "LeftFoot", "RightFoot", "Left Leg", "Right Leg", "LowerTorso", "Torso"}
	local GRAB_BURST = 3

	grabStep = function()
		if not ST.autograb then
			forcedHitbox = nil
			return
		end
		local drop = grab.drop
		if not (drop and drop.Parent) then
			grab.drop = nil
			-- deep scan only 3 times a second (DescendantAdded already catches new drops)
			if tick() - (grab.scanAt or 0) > 0.3 then
				grab.scanAt = tick()
				local f = workspace:FindFirstChild("GunDrop", true)
				if f and f:IsA("BasePart") then grab.drop = f end
			end
			if not grab.drop then
				grab.tried = {}
				grab.block = false
				grab.started = nil
				forcedHitbox = nil
				return
			end
			drop = grab.drop
		end
		local char = player.Character
		local root, hum = getRoot(char), getHum(char)
		if not (root and hum) or hum.Health <= 0 or grab.block or grab.tried[drop]
			or hasTool(player, "Knife") or inLobby(root) then
			forcedHitbox = nil
			return
		end
		if hasTool(player, "Gun") then
			grab.tried[drop] = true
			grab.started = nil
			forcedHitbox = nil
			return
		end
		grab.started = grab.started or tick()
		if tick() - grab.started > 1.5 then
			grab.tried[drop] = true
			grab.started = nil
			forcedHitbox = nil
			return
		end
		-- hitbox goes straight into the gun, touch burst is fired every frame
		forcedHitbox = drop.CFrame
		if firetouchinterest then
			pcall(function()
				for _ = 1, GRAB_BURST do
					for _, nm in ipairs(GRAB_PARTS) do
						local part = char:FindFirstChild(nm)
						if part and part:IsA("BasePart") then
							firetouchinterest(part, drop, 0)
							firetouchinterest(part, drop, 1)
						end
					end
				end
			end)
		end
	end
	track(RunService.Heartbeat:Connect(grabStep))
	-- Stepped too: the hitbox is already on the gun before the physics step of the same frame
	track(RunService.Stepped:Connect(function()
		if ST.autograb and grab.drop then pcall(grabStep) end
	end))

	-- main Heartbeat: Spin, then desync (forced hitbox / invisible / anti aim)
	track(RunService.Heartbeat:Connect(function()
		local char = player.Character
		local root = getRoot(char)
		if not root then return end
		if Feat.Aim and Feat.Aim.tpBusy then return end
		if Feat.Fling and Feat.Fling.busy then return end

		local fh = forcedHitbox or extForced
		if fh then
			invisReal = root.CFrame
			desynced = true
			root.CFrame = fh
			return
		end

		if ST.spin then
			local hum = getHum(char)
			if hum and hum.AutoRotate then hum.AutoRotate = false end
			root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(P.SpinSpeed), 0)
		end

		if shotHold > 0 then
			-- shot window: no desync, the server sees the real body
		elseif ST.invis then
			invisReal = root.CFrame
			desynced = true
			local j = Vector3.new(rnd:NextNumber(-80, 80), rnd:NextNumber(-80, 80), rnd:NextNumber(-80, 80))
			root.CFrame = CFrame.new(INVIS_BASE + j)
		elseif ST.antiaim then
			invisReal = root.CFrame
			realVel = root.AssemblyLinearVelocity
			realAng = root.AssemblyAngularVelocity
			desynced = true
			local fake = aaCFrame(invisReal)
			root.CFrame = fake
			-- changing velocity keeps the server replicating even when you stand still
			root.AssemblyLinearVelocity = Vector3.new(rnd:NextNumber(-70, 70), rnd:NextNumber(-70, 70), rnd:NextNumber(-70, 70))
			root.AssemblyAngularVelocity = Vector3.new(rnd:NextNumber(-90, 90), rnd:NextNumber(-90, 90), rnd:NextNumber(-90, 90))
			updateChams(fake)
		end
	end))

	-- real position is restored BEFORE the camera updates, so camera and controls stay on your skin
	RunService:BindToRenderStep(RESTORE_BIND, Enum.RenderPriority.First.Value, function()
		if desynced then
			desynced = false
			local root = getRoot(player.Character)
			if root and invisReal then
				root.CFrame = invisReal
				if realVel then
					root.AssemblyLinearVelocity = realVel
					root.AssemblyAngularVelocity = realAng or Vector3.zero
				end
			end
			realVel, realAng = nil, nil
		end
	end)

	local function restoreFromDesync()
		desynced = false
		local root = getRoot(player.Character)
		if root and invisReal then
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = invisReal
		end
		invisReal = nil
	end

	-- while invisible you are semi-transparent (only you see it)
	track(RunService.RenderStepped:Connect(function()
		if not ST.invis then return end
		local char = player.Character
		if not char then return end
		for _, p in ipairs(cachedParts(char)) do
			if p.Name ~= "HumanoidRootPart" and (p.LocalTransparencyModifier or 0) < 0.55 then
				p.LocalTransparencyModifier = 0.55
			end
		end
	end))

	-- Anti Aim keeps normal collisions (same as Invisible): you can NOT walk through walls.

	function Feat.setInvis(on)
		ST.invis = on
		if not on then
			if not ST.antiaim then restoreFromDesync() end
			local char = player.Character
			if char then
				for _, p in ipairs(cachedParts(char)) do
					p.LocalTransparencyModifier = 0
				end
			end
		end
	end

	function Feat.setAntiAim(on)
		ST.antiaim = on
		if not on then
			destroyChams()
			if not ST.invis then restoreFromDesync() end
		end
	end

	function Feat.setChams(on)
		ST.chams = on
		if not on then destroyChams() end
	end

	-- other modules (Shoot Murderer) move only the server-side hitbox; the camera stays on your real body
	function Feat.setExtHitbox(cf)
		extForced = cf
	end

	-- Shot window: Invisible / Anti Aim go OFF `pre` sec before fn() (so the server gets the real position),
	-- fn() fires the shot, `post` sec later they come back ON. Not desynced -> fn() runs at once, no delay.
	-- fn may yield. Safe to nest / run in parallel (counter).
	local function holdWait(sec)
		local t0 = tick()
		repeat RunService.Heartbeat:Wait() until tick() - t0 >= sec
	end
	function Feat.shotGuard(fn, pre, post)
		if shotHold == 0 and not (ST.invis or ST.antiaim) then return fn() end
		local first = shotHold == 0
		shotHold += 1
		local res = table.pack(pcall(function()
			if first then holdWait(pre or 0.08) end
			return fn()
		end))
		holdWait(post or 0.08)
		shotHold = math.max(shotHold - 1, 0)
		if not res[1] then error(res[2], 0) end
		return table.unpack(res, 2, res.n)
	end

	track(player.CharacterAdded:Connect(function()
		desynced = false
		shotHold = 0
		invisReal = nil
		realVel, realAng = nil, nil
	end))

	-- ---------- Spin (AutoRotate is off, so it keeps spinning while you walk) ----------
	function Feat.setSpin(on)
		ST.spin = on
		local hum = getHum(player.Character)
		if hum then hum.AutoRotate = not on end
	end

	-- ---------- Anti Fling ----------
	track(RunService.Stepped:Connect(function()
		if not ST.antifling then return end
		if Feat.Fling and Feat.Fling.busy then return end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and plr.Character then
				for _, p in ipairs(cachedParts(plr.Character)) do
					p.CanCollide = false
				end
			end
		end
	end))
	track(RunService.Heartbeat:Connect(function()
		if not ST.antifling then return end
		if Feat.Fling and Feat.Fling.busy then return end
		local root = getRoot(player.Character)
		if root and (root.AssemblyAngularVelocity.Magnitude > 60 or root.AssemblyLinearVelocity.Magnitude > 250) then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end))
	function Feat.setAntiFling(on)
		ST.antifling = on
	end

	-- ---------- OffDamageWater ----------
	local waterParts = {}
	local waterConn = nil
	local function isWaterPart(d)
		local a = d
		while a and a ~= workspace do
			if string.find(string.lower(a.Name), "water", 1, true) then return true end
			a = a.Parent
		end
		return false
	end
	local function disableWater(d)
		if d:IsA("BasePart") and d.CanTouch and isWaterPart(d) then
			waterParts[d] = true
			d.CanTouch = false
		end
	end
	function Feat.setWater(on)
		ST.water = on
		if waterConn then
			waterConn:Disconnect()
			waterConn = nil
		end
		if on then
			task.spawn(function()
				local n = 0
				for _, d in ipairs(workspace:GetDescendants()) do
					if not ST.water then break end
					disableWater(d)
					n = n + 1
					if n % 400 == 0 then task.wait() end
				end
			end)
			waterConn = track(workspace.DescendantAdded:Connect(function(d)
				task.wait()
				if ST.water then disableWater(d) end
			end))
		else
			for p in pairs(waterParts) do
				if p.Parent then p.CanTouch = true end
				waterParts[p] = nil
			end
		end
	end

	-- ---------- Noclip ----------
	track(RunService.Stepped:Connect(function()
		if not ST.noclip then return end
		local char = player.Character
		if char then
			for _, p in ipairs(cachedParts(char)) do
				p.CanCollide = false
			end
		end
	end))
	function Feat.setNoclip(on)
		ST.noclip = on
	end

	-- ---------- Fly ----------
	local flyBV, flyBG
	local function stopFly()
		if flyBV then flyBV:Destroy() flyBV = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
		local hum = getHum(player.Character)
		if hum then hum.PlatformStand = false end
	end
	local function startFly()
		stopFly()
		local char = player.Character
		local root, hum = getRoot(char), getHum(char)
		if not (root and hum) then return end

		flyBV = Instance.new("BodyVelocity")
		flyBV.Name = "Mellowyn_FlyBV"
		flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBV.Velocity = Vector3.zero
		flyBV.Parent = root

		flyBG = Instance.new("BodyGyro")
		flyBG.Name = "Mellowyn_FlyBG"
		flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBG.P = 9e4
		flyBG.CFrame = root.CFrame
		flyBG.Parent = root

		hum.PlatformStand = true
	end
	track(RunService.Heartbeat:Connect(function()
		if not ST.fly then return end
		local char = player.Character
		local root, hum = getRoot(char), getHum(char)
		if not (root and hum) or hum.Health <= 0 then return end
		if not (flyBV and flyBV.Parent and flyBG and flyBG.Parent) then
			startFly()
			return
		end
		local cam = workspace.CurrentCamera
		local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
		look = look.Magnitude > 0 and look.Unit or Vector3.zero
		right = right.Magnitude > 0 and right.Unit or Vector3.zero

		local md = hum.MoveDirection
		local dir = cam.CFrame.LookVector * md:Dot(look) + cam.CFrame.RightVector * md:Dot(right)
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		flyBV.Velocity = dir * P.FlySpeed
		flyBG.CFrame = cam.CFrame
	end))
	function Feat.setFly(on)
		ST.fly = on
		if on then startFly() else stopFly() end
	end


	-- ---------- Anti invalid position (speed functions) ----------
	-- Roblox kicks with "Invalid position" when you move too far too fast for too long.
	-- Soft-clamp root velocity while any speed feature is on.
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				local c = player.Character
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if not hrp or not hum then return end
				local speedOn = (Feat.ST and (Feat.ST.walkspeed or Feat.ST.fly or Feat.ST.bunny or Feat.ST.spin or Feat.ST.speedglitch))
					or (hum.WalkSpeed or 0) > 40
				if speedOn then
					local v = hrp.AssemblyLinearVelocity
					local max = 140
					if v.Magnitude > max then
						hrp.AssemblyLinearVelocity = v.Unit * max
					end
					-- tiny micro-correct so the server keeps a valid sample
					if tick() % 1.5 < 0.05 then
						hrp.CFrame = hrp.CFrame
					end
				end
			end)
			task.wait(0.08)
		end
	end)

	-- ---------- WalkSpeed ----------
	track(RunService.Heartbeat:Connect(function()
		if not ST.speed or ST.bunny then return end
		local hum = getHum(player.Character)
		if hum and hum.WalkSpeed ~= P.WalkSpeed then
			hum.WalkSpeed = P.WalkSpeed
		end
	end))
	function Feat.setSpeed(on)
		ST.speed = on
		if not on and not ST.bunny then
			local hum = getHum(player.Character)
			if hum then hum.WalkSpeed = 16 end
		end
	end

	-- ---------- Bunny Hop ----------
	track(RunService.Heartbeat:Connect(function(dt)
		if not ST.bunny then return end
		local hum = getHum(player.Character)
		if not hum or hum.Health <= 0 then return end
		local base = ST.speed and P.WalkSpeed or 16
		Bunny.speed = Bunny.speed or base

		local moving = hum.MoveDirection.Magnitude > 0.1
		local inAir = hum.FloorMaterial == Enum.Material.Air
		local wantJump = hum.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space)

		if inAir and moving then
			Bunny.speed = math.min(Bunny.speed + Bunny.Gain * dt, Bunny.Max)
			Bunny.landedAt = tick()
		elseif not inAir then
			if tick() - Bunny.landedAt > 0.3 or not moving then
				Bunny.speed = math.max(Bunny.speed - Bunny.Gain * 3 * dt, base)
			end
			if Bunny.Auto and wantJump and moving then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
		if hum.WalkSpeed ~= Bunny.speed then
			hum.WalkSpeed = Bunny.speed
		end
	end))
	function Feat.setBunny(on)
		ST.bunny = on
		Bunny.speed = nil
		if not on then
			local hum = getHum(player.Character)
			if hum then hum.WalkSpeed = ST.speed and P.WalkSpeed or 16 end
		end
	end

	-- ---------- Infinite Jump ----------
	track(UserInputService.JumpRequest:Connect(function()
		if ST.infjump then
			local hum = getHum(player.Character)
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end))
	function Feat.setInfJump(on)
		ST.infjump = on
	end

	-- ---------- Auto Grab Gun / Auto Farm ----------
	function Feat.setAutoGrab(on)
		ST.autograb = on
		grab.tried = {}
		grab.started = nil
		grab.block = false
		if not on then forcedHitbox = nil end
	end

	local Farm = {TweenSpeed = 25, UndergroundOffset = 4, MaxDistance = 600, CoinLimit = 45}
	local farm = {visited = 0, done = false, ignored = {}, gen = 0, tween = nil, container = nil}

	track(player.CharacterAdded:Connect(function()
		farm.visited = 0
		farm.done = false
	end))

	local function nearestCoin(fromPos)
		local container = farm.container
		if not (container and container.Parent) then
			container = workspace:FindFirstChild("CoinContainer", true)
			farm.container = container
		end
		if not container then return nil end
		local best, bestDist
		for _, coin in ipairs(container:GetChildren()) do
			if coin:IsA("BasePart") and coin.Name == "Coin_Server" then
				local at = farm.ignored[coin]
				if not at or tick() - at > 6 then
					local d = (coin.Position - fromPos).Magnitude
					if d <= Farm.MaxDistance and (not bestDist or d < bestDist) then
						best, bestDist = coin, d
					end
				end
			end
		end
		return best
	end

	local function farmStep()
		local char = player.Character
		local root, hum = getRoot(char), getHum(char)
		if not (root and hum) or hum.Health <= 0 then
			task.wait(0.5)
			return
		end
		if farm.done then
			-- back in the lobby = a new round soon: reset and farm again
			if inLobby(root) then
				farm.done = false
				farm.visited = 0
			end
			task.wait(0.5)
			return
		end
		if farm.visited >= Farm.CoinLimit then
			farm.done = true
			return
		end
		local coin = nearestCoin(root.Position)
		if not coin then
			task.wait(0.4)
			return
		end

		local target = coin.Position - Vector3.new(0, Farm.UndergroundOffset, 0)
		local duration = math.max((root.Position - target).Magnitude / Farm.TweenSpeed, 0.05)
		farm.tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(target)})
		local finished = false
		local c = farm.tween.Completed:Connect(function() finished = true end)
		farm.tween:Play()
		while not finished and ST.autofarm and root.Parent and hum.Health > 0 do
			RunService.Heartbeat:Wait()
		end
		c:Disconnect()
		if not finished then farm.tween:Cancel() end
		farm.tween = nil

		if not ST.autofarm or not root.Parent or hum.Health <= 0 then return end
		if coin.Parent then root.CFrame = CFrame.new(coin.Position) end
		task.wait(0.25)

		farm.visited = farm.visited + 1
		if coin.Parent then farm.ignored[coin] = tick() end
	end

	track(RunService.Stepped:Connect(function()
		if ST.autofarm then
			local char = player.Character
			local root = getRoot(char)
			if char then
				for _, p in ipairs(cachedParts(char)) do
					p.CanCollide = false
				end
			end
			if root then root.AssemblyLinearVelocity = Vector3.zero end
		end
	end))

	function Feat.setFarm(on)
		ST.autofarm = on
		farm.gen = farm.gen + 1
		if not on then
			if farm.tween then farm.tween:Cancel() end
			return
		end
		farm.done = false
		farm.visited = 0
		local my = farm.gen
		task.spawn(function()
			while ST.autofarm and my == farm.gen do
				local ok, err = pcall(farmStep)
				if not ok then
					warn("[Mellowyn] AutoFarm: " .. tostring(err))
					task.wait(0.5)
				end
			end
		end)
	end

	-- ---------- FOV / Stretch Screen ----------
	local origFov = nil
	RunService:BindToRenderStep("Mellowyn_FOV", Enum.RenderPriority.Camera.Value + 1, function()
		if ST.fov then
			local cam = workspace.CurrentCamera
			if cam and cam.FieldOfView ~= P.Fov then cam.FieldOfView = P.Fov end
		end
	end)
	function Feat.setFov(on)
		local cam = workspace.CurrentCamera
		if on then
			origFov = cam and cam.FieldOfView or 70
		elseif cam and origFov then
			cam.FieldOfView = origFov
		end
		ST.fov = on
	end
	RunService:BindToRenderStep("Mellowyn_Stretch", Enum.RenderPriority.Camera.Value + 2, function()
		if ST.stretch then
			local cam = workspace.CurrentCamera
			if cam then
				cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, P.Stretch, 0, 0, 0, 1)
			end
		end
	end)
	function Feat.setStretch(on)
		ST.stretch = on
	end

	-- ---------- cleanup when the GUI is destroyed ----------
	function Feat.cleanup()
		pcall(Feat.setInvis, false)
		pcall(Feat.setAntiAim, false)
		pcall(Feat.setSpin, false)
		pcall(Feat.setFly, false)
		pcall(Feat.setBunny, false)
		pcall(Feat.setSpeed, false)
		pcall(Feat.setWater, false)
		pcall(Feat.setFov, false)
		pcall(Feat.setFarm, false)
		ST.antifling, ST.noclip, ST.infjump = false, false, false
		ST.autograb, ST.stretch = false, false
		forcedHitbox = nil
		extForced = nil
		shotHold = 0
		destroyChams()
		for _, name in ipairs({RESTORE_BIND, "Mellowyn_FOV", "Mellowyn_Stretch"}) do
			pcall(function()
				RunService:UnbindFromRenderStep(name)
			end)
		end
	end
end
screenGui.Destroying:Connect(function()
	Feat.cleanup()
end)

-- ===================== VISUALS (ESP / Chams / World) =====================
do
	local ST, P = Feat.ST, Feat.P
	local track = Feat.track

	-- Murderer = red, Sheriff (and Hero who picked the gun up) = blue, everybody else = chosen colour
	local RED = Color3.fromRGB(255, 50, 50)
	local BLUE = Color3.fromRGB(60, 140, 255)
	local function roleColor(plr, default)
		local r = Feat.getRole(plr)
		if r == "Murderer" then return RED end
		if r == "Sheriff" or r == "Hero" then return BLUE end
		return default
	end
	Feat.roleColor = roleColor

	-- ---------- gradient helpers (ESP box / fill / line, 3D preview) ----------
	-- ColorSequence of 3 keypoints around the base colour: hue drifts +-0.12 and the middle is a bit paler.
	-- The phase moves with time, so the colours keep changing; UIGradient.Rotation turns the gradient too.
	local GRAD_SPEED = 1.8
	local function gradSeq(base, t, phase, c2)
		local p = t * GRAD_SPEED + (phase or 0)
		if c2 then
			-- two-colour gradient: the three keypoints swing between the base colour and the gradient colour
			local function k(off)
				return base:Lerp(c2, 0.5 + 0.5 * math.sin(p + off))
			end
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, k(0)),
				ColorSequenceKeypoint.new(0.5, k(2.1)),
				ColorSequenceKeypoint.new(1, k(4.2)),
			})
		end
		-- no second colour (murderer / sheriff colours): the old hue drift around the base colour
		local h, s, v = base:ToHSV()
		local function c(off, ds)
			return Color3.fromHSV((h + off) % 1, math.clamp(s * ds, 0, 1), v)
		end
		return ColorSequence.new({
			ColorSequenceKeypoint.new(0, c(0.12 * math.sin(p), 1)),
			ColorSequenceKeypoint.new(0.5, c(0.12 * math.sin(p + 2.1), 0.8)),
			ColorSequenceKeypoint.new(1, c(0.12 * math.sin(p + 4.2), 1)),
		})
	end
	Feat.gradSeq = gradSeq
	-- gradient switch: off = one plain colour, on = moving two-colour gradient
	function Feat.gradFor(base, t, phase, on, c2)
		if not on then return ColorSequence.new(base) end
		return gradSeq(base, t, phase, c2)
	end
	-- ESP colour of a player: murderer / sheriff colours keep the hue drift, own colours use the gradient settings
	local function espSeq(plr, def, t, phase, on, c2)
		local col = roleColor(plr, def)
		if not on then return ColorSequence.new(col) end
		if col ~= def then return gradSeq(col, t, phase) end
		return gradSeq(col, t, phase, c2)
	end

	-- ---------- GUI box shared by ESP and the 3D preview ----------
	-- Box    : one Frame + UIStroke(+UIGradient)
	-- Corner : 4 clipped Frames; inside each, ONE big stroked frame sticks out of the clip window, so only its
	--          corner is visible = one continuous L-shaped stroke per corner (not two separate lines)
	local BOX_T = 1.5
	function Feat.newEspBox(parent, z)
		local o = {}
		local function frame(name)
			local f = Instance.new("Frame")
			f.Name = name
			f.BackgroundColor3 = Color3.new(1, 1, 1)
			f.BackgroundTransparency = 1
			f.BorderSizePixel = 0
			f.ZIndex = z
			f.Visible = false
			f.Parent = parent
			return f
		end
		local function stroked(f)
			local st = Instance.new("UIStroke")
			st.Color = Color3.new(1, 1, 1)
			st.Thickness = BOX_T
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			st.LineJoinMode = Enum.LineJoinMode.Miter
			st.Parent = f
			local g = Instance.new("UIGradient")
			g.Parent = st
			return g
		end
		o.fill = frame("EspFill")
		o.fill.BackgroundTransparency = 0.7
		o.fillGrad = Instance.new("UIGradient")
		o.fillGrad.Parent = o.fill
		o.box = frame("EspBox")
		o.boxGrad = stroked(o.box)
		o.cor = {}
		for i = 1, 4 do
			local sx, sy = (i % 2 == 0) and 1 or 0, (i > 2) and 1 or 0
			local clip = frame("EspCorner" .. i)
			clip.ClipsDescendants = true
			local inner = Instance.new("Frame")
			inner.BackgroundTransparency = 1
			inner.BorderSizePixel = 0
			inner.ZIndex = z
			inner.AnchorPoint = Vector2.new(sx, sy)
			inner.Parent = clip
			o.cor[i] = {clip = clip, inner = inner, grad = stroked(inner), sx = sx, sy = sy}
		end

		function o.update(x, y, w, h, style, showBox, showFill, boxSeq, fillSeq, rot)
			x, y, w, h = math.floor(x), math.floor(y), math.floor(w), math.floor(h)
			if showFill then
				o.fill.Position = UDim2.fromOffset(x, y)
				o.fill.Size = UDim2.fromOffset(w, h)
				o.fillGrad.Color = fillSeq
				o.fillGrad.Rotation = rot
				o.fill.Visible = true
			else
				o.fill.Visible = false
			end
			if showBox and style == "Corner" then
				o.box.Visible = false
				local arm = math.max(math.floor(math.min(w, h) * 0.32), 6)
				local ox, oy = x - BOX_T, y - BOX_T
				local ow, oh = w + BOX_T * 2, h + BOX_T * 2
				for _, c in ipairs(o.cor) do
					c.clip.Position = UDim2.fromOffset(c.sx == 0 and ox or ox + ow - arm, c.sy == 0 and oy or oy + oh - arm)
					c.clip.Size = UDim2.fromOffset(arm, arm)
					c.inner.Position = UDim2.new(c.sx, c.sx == 0 and BOX_T or -BOX_T, c.sy, c.sy == 0 and BOX_T or -BOX_T)
					c.inner.Size = UDim2.fromOffset(arm * 2 + BOX_T * 4, arm * 2 + BOX_T * 4)
					c.grad.Color = boxSeq
					c.grad.Rotation = rot
					c.clip.Visible = true
				end
			elseif showBox then
				for _, c in ipairs(o.cor) do c.clip.Visible = false end
				o.box.Position = UDim2.fromOffset(x, y)
				o.box.Size = UDim2.fromOffset(w, h)
				o.boxGrad.Color = boxSeq
				o.boxGrad.Rotation = rot
				o.box.Visible = true
			else
				o.box.Visible = false
				for _, c in ipairs(o.cor) do c.clip.Visible = false end
			end
		end
		function o.hide()
			o.fill.Visible = false
			o.box.Visible = false
			for _, c in ipairs(o.cor) do c.clip.Visible = false end
		end
		function o.destroy()
			pcall(function() o.fill:Destroy() end)
			pcall(function() o.box:Destroy() end)
			for _, c in ipairs(o.cor) do pcall(function() c.clip:Destroy() end) end
		end
		return o
	end

	-- ---------- ESP: Box / Corner / Fill / Esp Line / Avatar ----------
	local AV_SIZE = 26
	local avatarLayer = Instance.new("Frame")
	avatarLayer.Name = "AvatarLayer"
	avatarLayer.Size = UDim2.new(1, 0, 1, 0)
	avatarLayer.BackgroundTransparency = 1
	avatarLayer.BorderSizePixel = 0
	avatarLayer.ZIndex = 5
	avatarLayer.Parent = screenGui

	local espLayer = Instance.new("Frame")
	espLayer.Name = "EspLayer"
	espLayer.Size = UDim2.new(1, 0, 1, 0)
	espLayer.BackgroundTransparency = 1
	espLayer.BorderSizePixel = 0
	espLayer.ZIndex = 4
	espLayer.Parent = screenGui

	local espObjs = {}

	local function newEntry(plr)
		local o = {phase = (plr.UserId % 628) / 100}
		o.gbox = Feat.newEspBox(espLayer, 4)
		o.line = Instance.new("Frame")
		o.line.Name = "EspLine"
		o.line.AnchorPoint = Vector2.new(0.5, 0.5)
		o.line.BackgroundColor3 = Color3.new(1, 1, 1)
		o.line.BorderSizePixel = 0
		o.line.ZIndex = 4
		o.line.Visible = false
		o.line.Parent = espLayer
		o.lineGrad = Instance.new("UIGradient")
		o.lineGrad.Parent = o.line
		-- fixed-size 2D avatar square (does not scale with distance)
		local av = Instance.new("ImageLabel")
		av.Name = "Avatar_" .. plr.Name
		av.AnchorPoint = Vector2.new(0.5, 1)
		av.Size = UDim2.new(0, AV_SIZE, 0, AV_SIZE)
		av.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		av.BorderSizePixel = 0
		av.ScaleType = Enum.ScaleType.Crop
		av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=48&h=48"
		av.Visible = false
		av.ZIndex = 6
		av.Parent = avatarLayer
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0, 4)
		ac.Parent = av
		local ast = Instance.new("UIStroke")
		ast.Thickness = 2
		ast.Color = Color3.new(1, 1, 1)
		ast.Parent = av
		o.av, o.avStroke = av, ast
		espObjs[plr] = o
		return o
	end

	local function hideEntry(o)
		o.gbox.hide()
		o.line.Visible = false
		o.av.Visible = false
	end

	local function removeEntry(plr)
		local o = espObjs[plr]
		if not o then return end
		pcall(function()
			o.gbox.destroy()
			o.line:Destroy()
			o.av:Destroy()
		end)
		espObjs[plr] = nil
	end
	track(Players.PlayerRemoving:Connect(removeEntry))

	track(RunService.RenderStepped:Connect(function()
		if not (ST.esp or ST.espline or ST.avatar) then
			for _, o in pairs(espObjs) do hideEntry(o) end
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vs = cam.ViewportSize
		local t = os.clock()
		local rot = (t * 50) % 360
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local o = espObjs[plr]
				local shown = false
				if hum and root and hum.Health > 0 then
					local v, onScreen = cam:WorldToViewportPoint(root.Position)
					if onScreen then
						o = o or newEntry(plr)
						local top = cam:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
						local bottom = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
						local height = math.abs(top.Y - bottom.Y)
						local width = height / 2

						local showFill = ST.esp and ST.boxfill
						local boxSeq = ST.esp and espSeq(plr, P.BoxColor, t, o.phase, P.BoxGrad, P.BoxGrad2) or nil
						local fillSeq = showFill and espSeq(plr, P.FillColor, t, o.phase + 0.8, P.BoxGrad, P.BoxGrad2) or nil
						o.gbox.update(v.X - width / 2, top.Y, width, height, P.BoxStyle, ST.esp, showFill,
							boxSeq, fillSeq, (rot + o.phase * 30) % 360)

						-- Esp Line: thin line from the bottom centre of the screen to the bottom-middle of the box
						if ST.espline then
							local a = Vector2.new(vs.X / 2, vs.Y)
							local b = Vector2.new(v.X, top.Y + height)
							local d = b - a
							o.line.Size = UDim2.fromOffset(d.Magnitude, 1.5)
							o.line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
							o.line.Rotation = math.deg(math.atan2(d.Y, d.X))
							o.lineGrad.Color = espSeq(plr, P.LineColor, t, o.phase + 1.6, P.LineGrad, P.LineGrad2)
							o.line.Visible = true
						else
							o.line.Visible = false
						end

						if ST.avatar then
							o.av.Position = UDim2.new(0, math.floor(v.X), 0, math.floor(top.Y - 6))
							o.avStroke.Color = roleColor(plr, Color3.new(1, 1, 1))
							o.av.Visible = true
						else
							o.av.Visible = false
						end
						shown = true
					end
				end
				if not shown and o then hideEntry(o) end
			end
		end
	end))
	function Feat.setEsp(on) ST.esp = on end
	function Feat.setBoxFill(on) ST.boxfill = on end
	function Feat.setEspLine(on) ST.espline = on end
	function Feat.setAvatar(on) ST.avatar = on end

	-- ---------- Chams (Default / Outline / Ghost) ----------
	-- FPS notes ("Chams All" used to tank the framerate):
	--  * the part list of every character is cached and rescanned only once per CHAMS_SCAN seconds
	--    (the old code walked every descendant of every player several times a second)
	--  * properties are only written when the value really changes
	--  * the gradient is animated at ~15 Hz instead of every frame
	--  * per-part colours are only touched for characters within CHAMS_RANGE studs (everyone else still gets the
	--    animated Highlight); Gradient OFF = nothing is animated at all
	local CHAMS_SCAN, CHAMS_RANGE, CHAMS_STEP = 1, 110, 1 / 15
	local chamsHl, chamsMats = {}, {}
	local weak = {__mode = "k"}
	-- char -> {parts, ks, root, at, mode, fresh, col, grad, base, c2}
	local chamsInfo = setmetatable({}, weak)

	local function restoreMats(keep)
		for part, o in pairs(chamsMats) do
			if not keep or not keep[o[3]] then
				if part.Parent then
					pcall(function()
						part.Material = o[1]
						part.Color = o[2]
					end)
				end
				chamsMats[part] = nil
			end
		end
	end
	local function clearHighlights()
		for char, hl in pairs(chamsHl) do
			pcall(function() hl:Destroy() end)
			chamsHl[char] = nil
		end
	end
	local function chamsClear()
		clearHighlights()
		restoreMats()
		table.clear(chamsInfo)
	end

	local function hueShift(c)
		local h, s, v = c:ToHSV()
		return Color3.fromHSV((h + 0.12) % 1, s, v)
	end

	-- cached body-part list of a character; `k` = height of the part on the body (0 feet .. 1 head)
	local function chamsScan(char, mode)
		local e = chamsInfo[char]
		local now = os.clock()
		if e and e.mode == mode and now - e.at < CHAMS_SCAN then
			e.fresh = false
			return e
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		local rcf = root and root.CFrame
		local parts, ks = {}, {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1
				and not d:FindFirstAncestorOfClass("Tool") then
				local n = #parts + 1
				parts[n] = d
				ks[n] = rcf and (rcf:PointToObjectSpace(d.Position).Y + 3) / 6 or 0.5
				if not chamsMats[d] then chamsMats[d] = {d.Material, d.Color, char} end
			end
		end
		e = e or {}
		e.parts, e.ks, e.root, e.at, e.mode, e.fresh = parts, ks, root, now, mode, true
		e.col, e.grad = nil, nil
		chamsInfo[char] = e
		return e
	end

	local DEPTH_TOP, DEPTH_OCC = Enum.HighlightDepthMode.AlwaysOnTop, Enum.HighlightDepthMode.Occluded
	local function applyChams(char, col, mode, col2)
		local hl = chamsHl[char]
		if not hl or hl.Parent ~= char then
			if hl then pcall(function() hl:Destroy() end) end
			hl = Instance.new("Highlight")
			hl.Name = "MellowynChams"
			hl.Parent = char
			chamsHl[char] = hl
		end
		if not hl.Enabled then hl.Enabled = true end

		if mode == "Ghost" then
			-- ghost: see-through body, NOT visible through walls
			local e = chamsScan(char, "Ghost")
			if hl.DepthMode ~= DEPTH_OCC then hl.DepthMode = DEPTH_OCC end
			if hl.FillTransparency ~= 0.9 then hl.FillTransparency = 0.9 end
			if hl.OutlineTransparency ~= 0.25 then hl.OutlineTransparency = 0.25 end
			if hl.FillColor ~= col then hl.FillColor = col end
			if hl.OutlineColor ~= col then hl.OutlineColor = col end
			if e.fresh or e.col ~= col then
				e.col = col
				for _, d in ipairs(e.parts) do
					if d.Parent then
						if d.Material ~= Enum.Material.ForceField then d.Material = Enum.Material.ForceField end
						if d.Color ~= col then d.Color = col end
					end
				end
			end
		elseif mode == "Outline" then
			if hl.DepthMode ~= DEPTH_TOP then hl.DepthMode = DEPTH_TOP end
			if hl.FillTransparency ~= 1 then hl.FillTransparency = 1 end
			if hl.OutlineTransparency ~= 0 then hl.OutlineTransparency = 0 end
			if hl.FillColor ~= col then hl.FillColor = col end
			if hl.OutlineColor ~= col then hl.OutlineColor = col end
		else
			-- default: neon body + highlight, visible through walls.
			-- Gradient ON : the animator below blends base colour <-> gradient colour (body coloured by height)
			-- Gradient OFF: one plain colour, written once, nothing is animated
			local e = chamsScan(char, "Default")
			if hl.DepthMode ~= DEPTH_TOP then hl.DepthMode = DEPTH_TOP end
			if hl.FillTransparency ~= 0.6 then hl.FillTransparency = 0.6 end
			if hl.OutlineTransparency ~= 0 then hl.OutlineTransparency = 0 end
			local gradOn = P.ChamsGrad
			e.base, e.c2 = col, col2
			if e.fresh then
				for _, d in ipairs(e.parts) do
					if d.Parent and d.Material ~= Enum.Material.Neon then d.Material = Enum.Material.Neon end
				end
			end
			if e.fresh or e.col ~= col or e.grad ~= gradOn then
				e.col, e.grad = col, gradOn
				if gradOn then
					hl.FillColor, hl.OutlineColor = col, col2
				else
					hl.FillColor, hl.OutlineColor = col, col
					for _, d in ipairs(e.parts) do
						if d.Parent and d.Color ~= col then d.Color = col end
					end
				end
			end
		end
	end

	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				if not ST.chamsfx then
					if next(chamsHl) then clearHighlights() end
					if next(chamsMats) then restoreMats() end
					if next(chamsInfo) then table.clear(chamsInfo) end
					return
				end
				local mode = P.ChamsMode
				local list = {}
				if P.ChamsAll then
					for _, plr in ipairs(Players:GetPlayers()) do list[#list + 1] = plr end
				else
					list[1] = player
				end
				local keep = {}
				for _, plr in ipairs(list) do
					local char = plr.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if char and hum and hum.Health > 0 then
						keep[char] = true
						local col = roleColor(plr, P.ChamsColor)
						-- role colours (red / blue) keep a small hue drift, own colour uses the chosen gradient colour
						local col2 = (col == P.ChamsColor) and P.ChamsGrad2 or hueShift(col)
						applyChams(char, col, mode, col2)
					end
				end
				for char, hl in pairs(chamsHl) do
					if not keep[char] then
						pcall(function() hl:Destroy() end)
						chamsHl[char] = nil
					end
				end
				for char in pairs(chamsInfo) do
					if not keep[char] then chamsInfo[char] = nil end
				end
				if mode == "Ghost" or mode == "Default" then
					restoreMats(keep)
				else
					restoreMats()
					if next(chamsInfo) then table.clear(chamsInfo) end
				end
			end)
			task.wait(0.12)
		end
	end)

	-- gradient animator (Default mode, Gradient ON): ~15 Hz, parts coloured by height (feet -> head)
	local chamsAcc = 0
	track(RunService.RenderStepped:Connect(function(dt)
		if not ST.chamsfx or P.ChamsMode ~= "Default" or not P.ChamsGrad then return end
		chamsAcc = chamsAcc + dt
		if chamsAcc < CHAMS_STEP then return end
		chamsAcc = 0
		local t = os.clock()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position
		local a = 0.5 + 0.5 * math.sin(t * GRAD_SPEED)
		local mine = player.Character
		for char, hl in pairs(chamsHl) do
			local e = chamsInfo[char]
			if e and e.base and hl.Parent then
				local base, c2 = e.base, e.c2
				hl.FillColor = base:Lerp(c2, a)
				hl.OutlineColor = base:Lerp(c2, 1 - a)
				local root = e.root
				if root and root.Parent
					and (char == mine or not camPos or (root.Position - camPos).Magnitude < CHAMS_RANGE) then
					local parts, ks = e.parts, e.ks
					for i = 1, #parts do
						local d = parts[i]
						if d.Parent then
							d.Color = base:Lerp(c2, 0.5 + 0.5 * math.sin(t * GRAD_SPEED + ks[i] * 3))
						end
					end
				end
			end
		end
	end))
	function Feat.setChamsFx(on)
		ST.chamsfx = on
		if not on then chamsClear() end
	end

	-- ---------- Trail / Double Trail (no glow, chosen colour only) ----------
	local trails = {
		main = {char = nil, objs = {}, list = {}},
		double = {char = nil, objs = {}, list = {}},
	}
	local LIMBS = {
		"Left Arm", "Right Arm", "Left Leg", "Right Leg",
		"LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
		"LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg",
	}
	local function clearTrail(kind)
		local t = trails[kind]
		for _, o in ipairs(t.objs) do
			pcall(function() o:Destroy() end)
		end
		t.objs, t.list, t.char = {}, {}, nil
	end
	local function addTrail(t, part, col, y0, y1, width)
		local a0 = Instance.new("Attachment")
		a0.Name = "Mellowyn_TA0"
		a0.Position = Vector3.new(0, y0, 0)
		a0.Parent = part
		local a1 = Instance.new("Attachment")
		a1.Name = "Mellowyn_TA1"
		a1.Position = Vector3.new(0, y1, 0)
		a1.Parent = part
		local tr = Instance.new("Trail")
		tr.Name = "Mellowyn_Trail"
		tr.Attachment0, tr.Attachment1 = a0, a1
		tr.Lifetime = 0.45
		tr.MinLength = 0.08
		tr.LightEmission = 0 -- no neon / glow
		tr.FaceCamera = true
		tr.WidthScale = NumberSequence.new({
			NumberSequenceKeypoint.new(0, width),
			NumberSequenceKeypoint.new(1, 0),
		})
		tr.Color = ColorSequence.new(col)
		tr.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.65, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		tr.Parent = part
		table.insert(t.objs, a0)
		table.insert(t.objs, a1)
		table.insert(t.objs, tr)
		table.insert(t.list, tr)
	end
	local function buildTrail(kind, char)
		clearTrail(kind)
		local t = trails[kind]
		t.char = char
		if kind == "main" then
			local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
				or char:FindFirstChild("UpperTorso")
			if root then addTrail(t, root, P.TrailColor, 0.9, -0.9, 0.3) end
		else
			for _, n in ipairs(LIMBS) do
				local limb = char:FindFirstChild(n)
				if limb then addTrail(t, limb, P.DTrailColor, 0.4, -0.4, 0.18) end
			end
		end
	end
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				local char = player.Character
				for _, spec in ipairs({
					{"main", ST.trail, P.TrailColor},
					{"double", ST.dtrail, P.DTrailColor},
				}) do
					local kind, on, col = spec[1], spec[2], spec[3]
					local t = trails[kind]
					if not on or not char then
						if t.char then clearTrail(kind) end
					else
						local first = t.list[1]
						if t.char ~= char or not first or not first.Parent then
							buildTrail(kind, char)
						end
						for _, tr in ipairs(t.list) do
							tr.Color = ColorSequence.new(col)
						end
					end
				end
			end)
			task.wait(0.25)
		end
	end)
	function Feat.setTrail(on)
		ST.trail = on
		if not on then clearTrail("main") end
	end
	function Feat.setDoubleTrail(on)
		ST.dtrail = on
		if not on then clearTrail("double") end
	end

	-- ---------- Jump Circle: ring spreads out from the landing point and fades away ----------
	local lastRing = 0
	local function spawnRing(root, hum)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {player.Character}
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -10, 0), rp)
		local x, z = root.Position.X, root.Position.Z
		local y = hit and (hit.Position.Y + 0.06)
			or (root.Position.Y - hum.HipHeight - root.Size.Y / 2 + 0.06)
		local radius = math.clamp(P.JumpRadius, 1, 80)
		local col = P.JumpColor

		local function ring(delay, life, scale, thick, fillAlpha)
			task.delay(delay, function()
				local part = Instance.new("Part")
				part.Name = "Mellowyn_JumpCircle"
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				part.Transparency = 1
				part.Size = Vector3.new(0.4, 0.05, 0.4)
				part.CFrame = CFrame.new(x, y, z)
				part.Parent = workspace

				local sg = Instance.new("SurfaceGui")
				sg.Face = Enum.NormalId.Top
				sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
				sg.CanvasSize = Vector2.new(256, 256)
				sg.LightInfluence = 0
				sg.Adornee = part
				sg.Parent = part

				local fr = Instance.new("Frame")
				fr.Size = UDim2.new(1, 0, 1, 0)
				fr.BackgroundColor3 = col
				fr.BackgroundTransparency = fillAlpha
				fr.BorderSizePixel = 0
				fr.Parent = sg
				local fc = Instance.new("UICorner")
				fc.CornerRadius = UDim.new(1, 0)
				fc.Parent = fr
				local fs = Instance.new("UIStroke")
				fs.Color = col
				fs.Thickness = thick
				fs.Transparency = 0.05
				fs.Parent = fr

				local d = radius * 2 * scale
				local ti = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(part, ti, {Size = Vector3.new(d, 0.05, d)}):Play()
				local fade = TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				TweenService:Create(fs, fade, {Transparency = 1}):Play()
				TweenService:Create(fr, fade, {BackgroundTransparency = 1}):Play()
				task.delay(life + 0.1, function()
					pcall(function() part:Destroy() end)
				end)
			end)
		end
		ring(0, 0.9, 1, 10, 0.8)      -- main ring
		ring(0.12, 0.8, 0.62, 6, 0.9) -- smaller inner ring
	end

	local function hookChar(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if not hum then return end
		track(hum.StateChanged:Connect(function(_, new)
			if not ST.jcircle then return end
			if new == Enum.HumanoidStateType.Landed and tick() - lastRing > 0.25 then
				lastRing = tick()
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then pcall(spawnRing, root, hum) end
			end
		end))
	end
	if player.Character then task.spawn(hookChar, player.Character) end
	track(player.CharacterAdded:Connect(function(char)
		task.spawn(hookChar, char)
	end))
	function Feat.setJumpCircle(on)
		ST.jcircle = on
	end

	-- ---------- cleanup ----------
	function Feat.cleanupVisual()
		ST.esp, ST.espline, ST.avatar = false, false, false
		ST.chamsfx, ST.trail, ST.dtrail, ST.jcircle = false, false, false, false
		for plr in pairs(espObjs) do removeEntry(plr) end
		chamsClear()
		clearTrail("main")
		clearTrail("double")
		pcall(function() avatarLayer:Destroy() end)
		pcall(function() espLayer:Destroy() end)
	end
	screenGui.Destroying:Connect(Feat.cleanupVisual)
end

-- ===================== AIM (ported from the Zenith MM2 script) =====================
-- Silent Aim / Auto Shoot / Shoot Button / Kill All (murderer)
Feat.Aim = {
	on = false,         -- Silent Aim
	autoshoot = false,  -- Auto Shoot
	wallbang = false,
	predMul = 1,
	aimHeight = 0.2,
	killDelay = 0.0001,   -- pause after every stab in Kill All (lower = faster)
	tpBusy = false,     -- true while we teleport (peek shot / Kill All): desync is paused
	passThrough = false,-- our own FireServer calls must not be rewritten by the hook
	target = nil,
	ping = 0.08,
	pingOverride = 0,   -- ms, 0 = automatic (measured Data Ping)
	wcSilent = true,    -- Wall Check per aim: no shot when the murderer is behind a wall
	wcAuto = true,
	wcButton = true,
	smDistance = 10,    -- Shoot Murderer: studs behind the murderer
	shotGuard = true,   -- Invisible / Anti Aim are switched OFF around Silent Aim / Shoot Button / Auto Shoot shots
	shotPre = nil,      -- sec of real body BEFORE the shot (nil = ping/2 + 0.03)
	shotPost = nil,     -- sec of real body AFTER the shot (nil = ping/2 + 0.05)
	jitter = 0,         -- smoothed |ping - mean ping| (sec), measured live
	predExtra = 0,      -- extra delay (sec) between computing the aim point and the shot leaving (set per shot)
	conf = 1,           -- last prediction confidence (1 = steady runner, <1 = zig-zag / jittery ping)
}

do
	local Aim = Feat.Aim
	local genv = (getgenv and getgenv()) or _G
	local StarterGui = game:GetService("StarterGui")
	local RS = game:GetService("ReplicatedStorage")
	local cc = checkcaller or function() return false end

	-- errors / notices use the custom slide-in toast (see UI.toast)
	local function notify(text)
		pcall(UI.toast, text)
	end

	-- ---------- roles (who is the murderer) ----------
	local roles, deadF = {}, {}
	local sheriffGone = false

	local function hostileRole(r)
		if r == "Murderer" then return true end
		if type(r) ~= "string" then return false end
		local l = string.lower(r)
		return string.find(l, "zomb", 1, true) ~= nil or string.find(l, "infect", 1, true) ~= nil
	end

	local function readData(tbl)
		if typeof(tbl) ~= "table" then return end
		for k, d in pairs(tbl) do
			local p = typeof(k) == "Instance" and k or Players:FindFirstChild(tostring(k))
			local role = typeof(d) == "table" and (d.Role or d.role)
			if p and role then roles[p] = role end
			if p and typeof(d) == "table" then
				deadF[p] = (d.Dead == true or d.Killed == true) or nil
			end
		end
	end

	local function resetRound()
		table.clear(roles)
		table.clear(deadF)
		sheriffGone = false
		if Aim.flingReset then pcall(Aim.flingReset) end
	end

	for _, r in ipairs(RS:GetDescendants()) do
		pcall(function()
			if r:IsA("RemoteEvent") and r.Name == "PlayerDataChanged" then
				table.insert(connections, r.OnClientEvent:Connect(function(...) readData((...)) end))
			elseif r:IsA("RemoteEvent") and r.Name == "LoadingMap" then
				table.insert(connections, r.OnClientEvent:Connect(resetRound))
			elseif r:IsA("RemoteFunction") and r.Name == "GetPlayerData" then
				task.spawn(function()
					local ok, res = pcall(function() return r:InvokeServer() end)
					if ok then readData(res) end
				end)
			end
		end)
	end

	table.insert(connections, workspace.DescendantAdded:Connect(function(d)
		if d.Name == "GunDrop" then sheriffGone = true end
	end))

	local function toolCheck(p, ch)
		if ch.Name == "Knife" then
			roles[p] = "Murderer"
		elseif ch.Name == "Gun" and roles[p] ~= "Sheriff" and roles[p] ~= "Murderer" then
			roles[p] = sheriffGone and "Hero" or "Sheriff"
		end
	end

	local function watchPlayer(p)
		local function hook(c)
			for _, ch in ipairs(c:GetChildren()) do toolCheck(p, ch) end
			table.insert(connections, c.ChildAdded:Connect(function(ch) toolCheck(p, ch) end))
		end
		if p.Character then hook(p.Character) end
		table.insert(connections, p.CharacterAdded:Connect(hook))
	end
	for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
	table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
	table.insert(connections, Players.PlayerRemoving:Connect(function(p)
		roles[p] = nil
		deadF[p] = nil
	end))

	-- Exposed for ESP / Chams. Same source as Zenith: PlayerDataChanged + GetPlayerData
	-- (roles are known the moment the round starts, before anybody pulls out a weapon).
	function Feat.getRole(p)
		return roles[p]
	end

	-- ---------- helpers ----------
	local function aliveChar(p)
		local c = p.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local r = c and c:FindFirstChild("HumanoidRootPart")
		if c and h and h.Health > 0 and r then return c, r, h end
	end

	local function inRound(p)
		if deadF[p] then return false end
		if next(roles) ~= nil and roles[p] == nil then return false end
		return true
	end

	local function hasKnife()
		local c = player.Character
		local bp = player:FindFirstChildOfClass("Backpack")
		return (c and c:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) or nil
	end

	local function findGun()
		local places = {}
		if player.Character then places[#places + 1] = player.Character end
		local bp = player:FindFirstChildOfClass("Backpack")
		if bp then places[#places + 1] = bp end
		for _, pl in ipairs(places) do
			for _, t in ipairs(pl:GetChildren()) do
				if t:IsA("Tool") then
					local r = t:FindFirstChild("Shoot")
					if r and r:IsA("RemoteEvent") then return t, r end
				end
			end
		end
	end

	function Aim.hasGun()
		return findGun() ~= nil
	end

	local function touch(a, b)
		if firetouchinterest then
			firetouchinterest(a, b, 0)
			firetouchinterest(a, b, 1)
		end
	end

	-- nearest alive murderer (or zombie in infection)
	local function nearestHostile()
		local me = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, bd
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local c, r = aliveChar(p)
				if c and (hostileRole(roles[p]) or c:FindFirstChild("Knife")) then
					if not me then return r end
					local d = (r.Position - me.Position).Magnitude
					if not bd or d < bd then best, bd = r, d end
				end
			end
		end
		return best
	end

	-- ---------- target + velocity history (for prediction) ----------
	local hist = setmetatable({}, {__mode = "k"})

	local function updateTargets()
		local now = tick()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local c, r = aliveChar(p)
				if c then
					local rec = hist[r]
					if rec then
						local dt = now - rec.t
						if dt > 0.0005 then
							local nv = (r.Position - rec.p) / dt
							if nv.Magnitude > 150 then nv = Vector3.zero end
							rec.v = rec.v:Lerp(nv, math.min(1, dt * 14))
							rec.p, rec.t = r.Position, now
							-- heading + turn rate (rad/s): steady turn -> arc lead, zig-zag -> shorter lead
							local hx, hz = rec.v.X, rec.v.Z
							if hx * hx + hz * hz > 16 then
								local hd = math.atan2(hx, hz)
								if rec.h then
									local dh = (hd - rec.h + math.pi) % (math.pi * 2) - math.pi
									local w = math.clamp(dh / dt, -12, 12)
									rec.w = (rec.w or 0) + (w - (rec.w or 0)) * math.min(1, dt * 6)
									rec.wAbs = (rec.wAbs or 0) + (math.abs(w) - (rec.wAbs or 0)) * math.min(1, dt * 3)
								end
								rec.h = hd
							else
								rec.h = nil
								rec.w = (rec.w or 0) * 0.8
								rec.wAbs = (rec.wAbs or 0) * 0.9
							end
							if not rec.st or now - rec.st >= 0.12 then
								rec.vPrev = rec.vSnap or rec.v
								rec.vSnap = rec.v
								rec.st = now
							end
						end
					else
						hist[r] = {p = r.Position, t = now, v = Vector3.zero}
					end
				end
			end
		end
		Aim.target = nearestHostile()
		Aim.aimPos = Aim.target and Aim.target.Position or nil
	end

	local function velOf(t)
		local r = hist[t]
		local v = t.AssemblyLinearVelocity
		local av = Vector3.new(v.X, 0, v.Z)
		local hv = r and Vector3.new(r.v.X, 0, r.v.Z) or Vector3.zero
		if av.Magnitude < 1 and hv.Magnitude > 4 then av = hv end
		return av, v.Y
	end

	-- measured ping (smoothed) or the manual value from the Silent Aim panel
	local function pingNow()
		local o = Aim.pingOverride
		if o and o > 0 then return math.clamp(o / 1000, 0, 0.8) end
		return math.clamp(Aim.ping or 0.08, 0, 0.8)
	end

	local function ignoreList()
		local t = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then t[#t + 1] = p.Character end
		end
		return t
	end

	local prRP = RaycastParams.new()
	prRP.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function() prRP.RespectCanCollide = true end)
	pcall(function() prRP.IgnoreWater = true end)

	-- Aim.latency(): time between "I see him here" and "the server judges my shot":
	--   ping (sampled 10x/s: rises fast, falls slowly) + interpolation delay (grows a little with ping)
	--   + the delay WE add before the shot leaves (Invisible / Anti Aim pause window, Aim.predExtra).
	function Aim.latency()
		local p = pingNow()
		local interp = math.clamp(0.07 + p * 0.12, 0.07, 0.2)
		return p + interp + (Aim.predExtra or 0)
	end

	-- Adaptive prediction, recomputed from live data for every shot (any ping):
	--  1. lead = latency * predMul, shortened for start / stop / sharp turns (vPrev logic, as before)
	--  2. steady turn (running in a circle) -> the lead follows an ARC instead of a straight line
	--  3. zig-zag (turn rate without a steady direction) or a jittery ping -> the lead shrinks towards his
	--     current position: a long straight guess at 300+ ms misses more often than it hits
	--  4. never lead through a wall, no vertical lead for somebody standing on the floor
	local function predict(t, k)
		local fv, vy = velOf(t)
		local rec = hist[t]
		local lead = Aim.latency() * k
		if rec and rec.vPrev then
			local a = Vector3.new(rec.v.X, 0, rec.v.Z)
			local b = Vector3.new(rec.vPrev.X, 0, rec.vPrev.Z)
			local ma, mb = a.Magnitude, b.Magnitude
			local f = 1
			if ma > 4 and mb > 4 then
				local dot = math.clamp(a.Unit:Dot(b.Unit), -1, 1)
				f = 0.6 + 0.4 * math.max(dot, 0)
			elseif ma < 3 and mb > 6 then
				f = 0.45
			elseif ma > 6 and mb < 2 then
				f = 0.8
			end
			lead = lead * f
		end
		local sp = fv.Magnitude
		local w, wAbs = rec and rec.w or 0, rec and rec.wAbs or 0
		local steady = sp < 4 and 0 or math.clamp(math.abs(w) / (wAbs + 0.15), 0, 1)
		local noiseW = math.max(wAbs - math.abs(w) * steady, 0)
		local jit = Aim.jitter or 0
		local conf = 1 / (1 + (noiseW * lead / 0.7) ^ 2 + (jit * sp / 5) ^ 2)
		Aim.conf = conf
		lead = math.min(lead * conf, 1.0)
		local base = t.Position
		local disp = fv * lead
		if steady > 0.5 and math.abs(w) > 0.3 then
			local th = w * lead * steady
			local chord = math.abs(th) > 1e-3 and math.sin(th / 2) / (th / 2) or 1
			disp = CFrame.Angles(0, th / 2, 0):VectorToWorldSpace(fv) * lead * chord
		end
		local p = base + disp
		if disp.Magnitude > 1 then
			prRP.FilterDescendantsInstances = ignoreList()
			local hit = workspace:Raycast(base, p - base, prRP)
			if hit then
				p = hit.Position - disp.Unit * 1.2
				p = Vector3.new(p.X, base.Y, p.Z)
			end
		end
		local hum = t.Parent and t.Parent:FindFirstChildOfClass("Humanoid")
		local inAir = (not hum) or hum.FloorMaterial == Enum.Material.Air
		if inAir and math.abs(vy) > 3 then
			local dy = vy * lead - 0.5 * 196.2 * lead * lead
			p = p + Vector3.new(0, math.clamp(dy, -6, 6), 0)
		end
		return p
	end

	-- ---------- Wall Check ----------
	-- true when the line to the shot point AND to the body (root or head) is free of walls.
	-- Players do not block (same as the gun).
	local function visibleFrom(origin, tChar, aim)
		prRP.FilterDescendantsInstances = ignoreList()
		local function clear(pt)
			return workspace:Raycast(origin, pt - origin, prRP) == nil
		end
		if aim and not clear(aim) then return false end
		local hrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
		local head = tChar and tChar:FindFirstChild("Head")
		if hrp and clear(hrp.Position) then return true end
		if head and clear(head.Position) then return true end
		return false
	end

	local lastWallNote = 0
	local function wallNote()
		if tick() - lastWallNote > 1 then
			lastWallNote = tick()
			notify("Murderer is behind a wall")
		end
	end

	-- ---------- wallbang helpers ----------
	local stRP = RaycastParams.new()
	stRP.FilterType = Enum.RaycastFilterType.Exclude
	local wbOP = OverlapParams.new()
	wbOP.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function() wbOP.RespectCanCollide = true end)

	local function wbOrigin(p, me, tChar)
		local ignore = {tChar}
		if player.Character then ignore[2] = player.Character end
		stRP.FilterDescendantsInstances = ignore
		wbOP.FilterDescendantsInstances = ignore
		local dir = p - me
		dir = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0, -1)
		local side = Vector3.new(-dir.Z, 0, dir.X)
		side = side.Magnitude > 0.01 and side.Unit or Vector3.new(1, 0, 0)
		local up = Vector3.new(0, 1, 0)
		local offs = {-dir, (-dir + up * 0.6).Unit, up, side, -side, (-dir + side).Unit, (-dir - side).Unit, (up + side).Unit, (up - side).Unit}
		for _, dist in ipairs({2, 3, 4.5, 6, 8}) do
			for _, off in ipairs(offs) do
				local o = p + off * dist
				if not workspace:Raycast(o, p - o, stRP) then
					local ok, parts = pcall(function() return workspace:GetPartBoundsInRadius(o, 0.35, wbOP) end)
					if not ok or #parts == 0 then return o end
				end
			end
		end
		return p - dir * 2
	end

	local function gunOrigin()
		local c = player.Character
		local gun = c and c:FindFirstChild("Gun")
		if not gun then return nil end
		local h = gun:FindFirstChild("Handle")
		local att = gun:FindFirstChild("GunRaycastAttachment1", true)
		if att and att:IsA("Attachment") then
			if att.Parent and att.Parent:IsA("BasePart") then return att.WorldPosition end
			if h then return (h.CFrame * att.CFrame).Position end
		end
		return h and h.Position or nil
	end

	local function findPeek(me, aim, tChar, R)
		local c = player.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local ignore = {tChar, c}
		stRP.FilterDescendantsInstances = ignore
		wbOP.FilterDescendantsInstances = ignore
		local base = hrp.Position
		local gunOff = me - base
		local flat = aim - base
		flat = Vector3.new(flat.X, 0, flat.Z)
		local fwd = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		local right = Vector3.new(-fwd.Z, 0, fwd.X)
		local ANGLES = {90, -90, 65, -65, 115, -115, 40, -40, 140, -140, 15, -15, 165, -165, 0, 180}
		local box = Vector3.new(1.8, 4.4, 1.4)
		for _, h in ipairs({0, 2.5}) do
			for _, dist in ipairs({1.5, 2.5, 3.5, 5, 7, 9.5, 12, 15, 19, 24, 30, 35, 40}) do
				if dist <= R then
					for _, deg in ipairs(ANGLES) do
						local a = math.rad(deg)
						local dir = fwd * math.cos(a) + right * math.sin(a)
						local p = base + dir * dist + Vector3.new(0, h, 0)
						local g = p + gunOff
						if not workspace:Raycast(g, aim - g, stRP) then
							local ok, parts = pcall(function()
								return workspace:GetPartBoundsInBox(CFrame.new(p), box, wbOP)
							end)
							if not ok or #parts == 0 then
								return {hrp = p, gun = g, dist = dist}
							end
						end
					end
				end
			end
		end
		return nil
	end

	local function moveGunAttachment(point)
		local c = player.Character
		local gun = c and c:FindFirstChild("Gun")
		local att = gun and gun:FindFirstChild("GunRaycastAttachment1", true)
		local h = gun and gun:FindFirstChild("Handle")
		if not (att and att:IsA("Attachment") and h) then return end
		local old = att.CFrame
		pcall(function()
			if att.Parent and att.Parent:IsA("BasePart") then
				att.WorldPosition = point
			else
				att.CFrame = h.CFrame:ToObjectSpace(CFrame.new(point))
			end
		end)
		task.delay(0.25, function()
			pcall(function() att.CFrame = old end)
		end)
	end

	-- fires a remote without our own hook touching the arguments
	local function fire(remote, a)
		Aim.passThrough = true
		pcall(function() remote:FireServer(table.unpack(a, 1, a.n)) end)
		Aim.passThrough = false
	end

	-- runs a shot inside the desync pause window (Invisible / Anti Aim off -> shot -> on again)
	local function shotTimes()
		local p = pingNow()
		return Aim.shotPre or math.clamp(p * 0.5 + 0.03, 0.04, 0.25),
			Aim.shotPost or math.clamp(p * 0.5 + 0.05, 0.06, 0.3)
	end
	local function guardedShot(fn)
		if not Aim.shotGuard or Aim.wallbang or not Feat.shotGuard then return fn() end
		local pre, post = shotTimes()
		return Feat.shotGuard(fn, pre, post)
	end

	-- steps out to a free spot (no wall in the way), shoots, comes back
	local function peekShot(remote, tp)
		local c = player.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if not hrp or Aim.tpBusy then return end
		Aim.tpBusy = true
		local old = hrp.CFrame
		local cam0 = workspace.CurrentCamera
		local camCF, camType = cam0.CFrame, cam0.CameraType
		local look = tp.a[2]
		local face = typeof(look) == "CFrame" and look.Position or nil
		local spot = CFrame.new(tp.hrp) * old.Rotation
		if face then
			local fl = Vector3.new(face.X, tp.hrp.Y, face.Z)
			if (fl - tp.hrp).Magnitude > 0.1 then spot = CFrame.lookAt(tp.hrp, fl) end
		end
		pcall(function()
			cam0.CameraType = Enum.CameraType.Scriptable
			cam0.CFrame = camCF
		end)
		pcall(function()
			local t0 = tick()
			repeat
				hrp.CFrame = spot
				hrp.AssemblyLinearVelocity = Vector3.zero
				cam0.CFrame = camCF
				RunService.Heartbeat:Wait()
			until tick() - t0 >= 0.1
			fire(remote, tp.a)
			local t1 = tick()
			repeat
				hrp.CFrame = spot
				hrp.AssemblyLinearVelocity = Vector3.zero
				cam0.CFrame = camCF
				RunService.Heartbeat:Wait()
			until tick() - t1 >= 0.05
		end)
		hrp.CFrame = old
		hrp.AssemblyLinearVelocity = Vector3.zero
		pcall(function()
			cam0.CameraType = camType
			cam0.CFrame = camCF
		end)
		Aim.tpBusy = false
	end

	-- returns {{originOrNil, aimPoint, peek = hrpPosOrNil}}
	local function calcAll(me, t, wb, wc)
		local aim = predict(t, Aim.predMul or 1) + Vector3.new(0, Aim.aimHeight or 0.2, 0)
		Aim.aimPos = aim
		local toT = aim - me
		local d = toT.Magnitude > 0.01 and toT.Unit or Vector3.new(0, 0, -1)
		if wc then
			-- Wall Check: shoot only when the murderer is really visible, no peeking / wallbang
			if not visibleFrom(me, t.Parent, aim) then return nil end
			return {{nil, aim + d * 2}}
		end
		if wb then
			local ignore = {t.Parent}
			if player.Character then ignore[2] = player.Character end
			stRP.FilterDescendantsInstances = ignore
			if workspace:Raycast(me, toT, stRP) then
				local pk = findPeek(me, aim, t.Parent, 40)
				if pk then
					local d2 = aim - pk.gun
					d2 = d2.Magnitude > 0.01 and d2.Unit or d
					return {{pk.gun, aim + d2 * 3, peek = pk.hrp}}
				end
				local o = wbOrigin(aim, me, t.Parent)
				moveGunAttachment(o)
				local d2 = aim - o
				d2 = d2.Magnitude > 0.01 and d2.Unit or d
				return {{o, aim + d2 * 3}}
			end
		end
		return {{nil, aim + d * 2}}
	end

	-- ---------- Silent Aim: rewrite our own Gun.Shoot calls ----------
	local function handler(remote, ...)
		if not Aim.on or Aim.passThrough then return end
		local t = Aim.target
		if not (t and t.Parent) then return end
		local par = remote.Parent
		if not (par and par.Name == "Gun") then return end
		if Aim.wallbang then
			task.spawn(Aim.wbShot, remote)
			return "swallow"
		end
		local args = table.pack(...)
		local pend, tp
		local blocked = false
		-- Invisible / Anti Aim pause window delays the shot by `pre`: lead the target by that too
		if Aim.shotGuard and (Feat.ST.invis or Feat.ST.antiaim) then
			Aim.predExtra = (shotTimes())
		end
		local ok = pcall(function()
			local first, second
			for i = 1, args.n do
				if typeof(args[i]) == "CFrame" then
					if not first then
						first = i
					else
						second = i
						break
					end
				end
			end
			if not first then error("no cframe") end
			local me = gunOrigin() or args[first].Position
			local list = calcAll(me, t, Aim.wallbang, Aim.wcSilent)
			if not list then
				blocked = true
				return
			end
			local function make(v)
				local a = table.pack(table.unpack(args, 1, args.n))
				a[first] = CFrame.lookAt(v[1] or me, v[2])
				if second then a[second] = CFrame.new(v[2]) end
				return a
			end
			pend = {}
			for i = 2, #list do pend[#pend + 1] = make(list[i]) end
			args = make(list[1])
			if list[1].peek then tp = {a = args, hrp = list[1].peek} end
		end)
		Aim.predExtra = 0
		if blocked then
			wallNote()
			return "swallow"
		end
		if not ok then return end
		if tp then
			task.spawn(peekShot, remote, tp)
			return "swallow"
		end
		if Aim.shotGuard and (Feat.ST.invis or Feat.ST.antiaim) then
			-- Invisible / Anti Aim: swallow the shot, go real, fire the rewritten shot, go back
			local pa, pp = args, pend
			task.spawn(function()
				pcall(guardedShot, function()
					fire(remote, pa)
					for _, x in ipairs(pp or {}) do fire(remote, x) end
				end)
			end)
			return "swallow"
		end
		return "replace", args, pend
	end

	local function safeHandler(...)
		local ok, a, b, c = pcall(handler, ...)
		if ok then return a, b, c end
	end
	genv.MellowynAimHandler = safeHandler

	if hookmetamethod and getnamecallmethod then
		if not genv.MellowynAimHooked then
			local okHook = pcall(function()
				local wrap = newcclosure or function(f) return f end
				local old
				old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
					local m = getnamecallmethod()
					if m == "FireServer" and typeof(self) == "Instance" and self.Name == "Shoot" and not cc() then
						local h = genv.MellowynAimHandler
						if h then
							local act, args, pend = h(self, ...)
							if setnamecallmethod then setnamecallmethod(m) end
							if act == "swallow" then return nil end
							if act == "replace" and args then
								local r = old(self, table.unpack(args, 1, args.n))
								for _, x in ipairs(pend or {}) do
									if setnamecallmethod then setnamecallmethod(m) end
									old(self, table.unpack(x, 1, x.n))
								end
								return r
							end
						end
					end
					if setnamecallmethod then setnamecallmethod(m) end
					return old(self, ...)
				end))
			end)
			if okHook then genv.MellowynAimHooked = true end
		end
	else
		notify("Executor has no hookmetamethod: Silent Aim won't redirect manual shots")
	end

	-- ---------- Auto Shoot / Shoot Button ----------
	local lastShot = 0
	local AS = {equipAt = 0, fireAt = 0, busy = false}
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude

	local function autoShootStep(wc)
		if roles[player] == "Murderer" then return end
		local gun, remote = findGun()
		if not gun then return end
		local t = nearestHostile()
		if not t then return end
		local char = player.Character
		local mhrp = char and char:FindFirstChild("HumanoidRootPart")
		local me = gunOrigin() or ((mhrp and mhrp.Position or t.Position) + Vector3.new(0, 1.5, 0))
		if Aim.wallbang then
			lastShot = tick()
			return Aim.wbShot(remote) and true or false
		end
		local list = calcAll(me, t, Aim.wallbang, wc)
		if not list then return false end -- behind a wall: no shot
		local aim = list[1][2]
		if not wc and not Aim.wallbang then
			rp.FilterDescendantsInstances = {char, t.Parent}
			if workspace:Raycast(me, aim - me, rp) ~= nil then return end
		end
		lastShot = tick()
		Aim.aimPos = aim
		for i, v in ipairs(list) do
			local origin = v[1] or me
			local a = table.pack(CFrame.lookAt(origin, v[2]), CFrame.new(v[2]))
			if v.peek then
				peekShot(remote, {a = a, hrp = v.peek})
			else
				fire(remote, a)
			end
			if i < #list then task.wait() end
		end
		return true
	end

	local function autoShootTick()
		if AS.busy or roles[player] == "Murderer" or Aim.tpBusy then return end
		local ch = player.Character
		if not aliveChar(player) then return end
		local t = nearestHostile()
		if not t then return end
		local gun = findGun()
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not gun or not hrp then return end
		if Aim.wallbang then
			-- Wallbang mode: the shot comes from behind the murderer, no wall check
		elseif Aim.wcAuto then
			-- Wall Check (Auto Shoot): wait quietly until the murderer is visible
			local o = gunOrigin() or (hrp.Position + Vector3.new(0, 1.5, 0))
			if not visibleFrom(o, t.Parent, nil) then return end
		elseif not Aim.wallbang then
			rp.FilterDescendantsInstances = {ch, t.Parent}
			if workspace:Raycast(hrp.Position + Vector3.new(0, 1.5, 0), t.Position - hrp.Position, rp) then return end
		end
		if gun.Parent ~= ch then
			if tick() - AS.equipAt > 1 then
				AS.equipAt = tick()
				local hum = ch:FindFirstChildOfClass("Humanoid")
				if hum then pcall(function() hum:EquipTool(gun) end) end
			end
			return
		end
		if tick() - AS.fireAt < 0.8 then return end
		AS.fireAt = tick()
		AS.busy = true
		local okS, res = pcall(guardedShot, function() return autoShootStep(Aim.wcAuto) end)
		if okS and res == false then AS.fireAt = 0 end -- predicted point behind a wall: try again at once
		AS.busy = false
	end

	function Aim.shootNow()
		if AS.busy then return end
		if roles[player] == "Murderer" or hasKnife() then
			notify("You are the murderer: no gun")
			return
		end
		local gun = findGun()
		if not gun then
			notify("No gun in your hands")
			return
		end
		local c = player.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum and gun.Parent ~= c then
			hum:EquipTool(gun)
			for _ = 1, 12 do
				if gun.Parent == c then break end
				task.wait(0.05)
			end
			task.wait(0.1)
		end
		if not nearestHostile() then
			notify("Murderer not found")
			return
		end
		AS.busy = true
		lastShot = tick()
		local okS, res = pcall(guardedShot, function() return autoShootStep(Aim.wcButton) end)
		AS.busy = false
		if okS and res == false then wallNote() end
	end

	-- ---------- Kill All (murderer) - fast version ----------
	-- 1) everybody is hit in the same couple of frames (throw + touch volley, no waits)
	-- 2) only the survivors are visited, one frame per teleport, tiny delay after the stab
	local killBusy = false
	function Aim.killAll()
		if killBusy then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end
		local knife = hasKnife()
		if not knife then
			notify("No knife in your hands")
			return
		end
		killBusy = true
		Aim.tpBusy = true
		local back = hrp.CFrame

		local function waitFrames(sec)
			if sec <= 0 then return end
			local t0 = tick()
			while tick() - t0 < sec do RunService.Heartbeat:Wait() end
		end

		local ok, err = pcall(function()
			if knife.Parent ~= char then
				hum:EquipTool(knife)
				local t0 = tick()
				while knife.Parent ~= char and tick() - t0 < 0.5 do
					RunService.Heartbeat:Wait()
				end
			end
			knife = char:FindFirstChild("Knife") or knife
			local ev = knife:FindFirstChild("Events")
			local thrown = ev and ev:FindFirstChild("KnifeThrown")
			local ht = ev and ev:FindFirstChild("HandleTouched")
			local stab = ev and ev:FindFirstChild("KnifeStabbed")
			local handle = knife:FindFirstChild("Handle")

			local targets = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and aliveChar(p) and inRound(p) then targets[#targets + 1] = p end
			end
			if #targets == 0 then
				notify("Nobody to kill")
				return
			end

			-- volley 1: knife thrown at everybody at once
			if thrown and handle then
				for _, p in ipairs(targets) do
					local c, r = aliveChar(p)
					if c then
						pcall(function() thrown:FireServer(handle.CFrame, CFrame.new(r.Position)) end)
					end
				end
			end
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()

			-- volley 2: hit confirmation on everybody at once
			if ht then
				for _, p in ipairs(targets) do
					local c, r = aliveChar(p)
					if c then
						pcall(function() ht:FireServer(r) end)
						local head = c:FindFirstChild("Head")
						if head then pcall(function() ht:FireServer(head) end) end
					end
				end
			end

			-- let the deaths replicate (about one ping), then clean up the survivors
			waitFrames(math.clamp((Aim.ping or 0.08) + 0.04, 0.06, 0.3))
			for _ = 1, 3 do
				if hum.Health <= 0 then break end
				local left = {}
				for _, p in ipairs(targets) do
					if aliveChar(p) then left[#left + 1] = p end
				end
				if #left == 0 then break end
				for _, p in ipairs(left) do
					local c, r = aliveChar(p)
					if c and hum.Health > 0 then
						hrp.CFrame = r.CFrame * CFrame.new(0, 0, 1.6)
						hrp.AssemblyLinearVelocity = Vector3.zero
						RunService.Heartbeat:Wait()
						c, r = aliveChar(p)
						if c then
							if stab then pcall(function() stab:FireServer() end) end
							pcall(function() knife:Activate() end)
							if handle then
								for _, nm in ipairs({"HumanoidRootPart", "Head", "UpperTorso", "Torso"}) do
									local part = c:FindFirstChild(nm)
									if part then pcall(touch, handle, part) end
								end
							end
							if ht then pcall(function() ht:FireServer(r) end) end
							waitFrames(Aim.killDelay or 0.04)
						end
					end
				end
			end
		end)

		if hrp.Parent then
			hrp.CFrame = back
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		Aim.tpBusy = false
		killBusy = false
		if not ok then
			warn("[mellowyn.ft] Kill All: " .. tostring(err))
			notify("Kill All error")
		end
	end

	-- ---------- Shoot Murderer ----------
	-- Only the server-side hitbox goes `smDistance` studs behind the murderer's back (same desync as Invisible,
	-- your camera and your real body stay where they are, you can walk around). The shot is fired from there
	-- only at a "safe" moment: gun ready, nothing between us, murderer on the ground and moving steadily.
	local SM = {on = false, since = nil, lastShot = 0, lastAng = 0, equipAt = 0}
	local smLocalOff = Vector3.new(0, 1.5, 0)
	local smRP = RaycastParams.new()
	smRP.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function() smRP.RespectCanCollide = true end)
	local smOP = OverlapParams.new()
	smOP.FilterType = Enum.RaycastFilterType.Exclude
	pcall(function() smOP.RespectCanCollide = true end)

	local function smStop()
		Feat.setExtHitbox(nil)
		SM.since = nil
	end

	local function smPickSpot(tr, myHalf, dist0)
		local tpos = tr.Position
		local look = tr.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		local behind = -flat
		local side = Vector3.new(-behind.Z, 0, behind.X)
		local D = dist0 or 10
		local ign = ignoreList()
		smRP.FilterDescendantsInstances = ign
		smOP.FilterDescendantsInstances = ign
		local aimPt = tpos + Vector3.new(0, 0.5, 0)
		local angs = {SM.lastAng, 0, 20, -20, 40, -40, 65, -65, 90, -90, 120, -120, 150, -150, 180}
		for _, dist in ipairs({D, D * 0.75, D * 1.25}) do
			for _, deg in ipairs(angs) do
				local a = math.rad(deg)
				local dir = behind * math.cos(a) + side * math.sin(a)
				local fp = tpos + dir * dist
				local gr = workspace:Raycast(fp + Vector3.new(0, 6, 0), Vector3.new(0, -26, 0), smRP)
				if gr then
					local pos = Vector3.new(fp.X, gr.Position.Y + myHalf, fp.Z)
					local okB, parts = pcall(function()
						return workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(2, 4.4, 1.5), smOP)
					end)
					if okB and #parts == 0 and visibleFrom(pos + smLocalOff, tr.Parent, aimPt) then
						SM.lastAng = deg
						return pos
					end
				end
			end
		end
		return nil
	end

	local function smStep()
		if not SM.on or Aim.tpBusy or killBusy or (Feat.Fling and Feat.Fling.busy) then return end
		local char, hrp, hum = aliveChar(player)
		if not char or roles[player] == "Murderer" or hasKnife() then smStop() return end
		local gun, remote = findGun()
		if not gun then smStop() return end
		local tr = nearestHostile()
		if not tr or not tr.Parent then smStop() return end

		local g = gunOrigin()
		if g then smLocalOff = hrp.CFrame:PointToObjectSpace(g) end
		local myHalf = (hum.RigType == Enum.HumanoidRigType.R15) and (hrp.Size.Y / 2 + hum.HipHeight) or 3
		local spot = smPickSpot(tr, myHalf, 10)
		if not spot then smStop() return end
		local tp = tr.Position
		local cf = CFrame.lookAt(spot, Vector3.new(tp.X, spot.Y, tp.Z))
		Feat.setExtHitbox(cf)

		local now = tick()
		SM.since = SM.since or now
		if gun.Parent ~= char then
			if now - SM.equipAt > 1 then
				SM.equipAt = now
				pcall(function() hum:EquipTool(gun) end)
			end
			return
		end
		local rtt = pingNow()
		if now - SM.since < rtt * 0.5 + 0.12 then return end -- the server has to see us at the spot first
		if now - SM.lastShot < 1.2 then return end          -- gun cooldown
		local relaxed = now - SM.since > 3                   -- after 3 s of waiting accept a worse moment
		local th = tr.Parent:FindFirstChildOfClass("Humanoid")
		if th and th.FloorMaterial == Enum.Material.Air and not relaxed then return end
		local rec = hist[tr]
		if rec and rec.vPrev then
			local dv = (Vector3.new(rec.v.X, 0, rec.v.Z) - Vector3.new(rec.vPrev.X, 0, rec.vPrev.Z)).Magnitude
			if dv > (relaxed and 12 or 5) then return end    -- turning / starting / stopping
		end

		local origin = cf:PointToWorldSpace(smLocalOff)
		local aim = predict(tr, Aim.predMul or 1) + Vector3.new(0, Aim.aimHeight or 0.2, 0)
		if not visibleFrom(origin, tr.Parent, aim) then return end
		local d = aim - origin
		d = d.Magnitude > 0.01 and d.Unit or Vector3.new(0, 0, -1)
		local far = aim + d * 2
		SM.lastShot = now
		Aim.aimPos = aim
		fire(remote, table.pack(CFrame.lookAt(origin, far), CFrame.new(far)))

		local tchar = tr.Parent
		task.delay(0.8 + rtt, function()
			if not SM.on then return end
			local pl = Players:GetPlayerFromCharacter(tchar)
			if not (pl and aliveChar(pl)) then
				Aim.setShootMurderer(false)
				notify("Murderer shot")
				if Aim.onShootMurdererDone then pcall(Aim.onShootMurdererDone) end
			end
		end)
	end

	-- Wallbang: hitbox jumps 7 studs behind the murderer (camera / real body stay), shoots, comes back
	local wbBusy = false
	function Aim.wbShot(remote)
		if wbBusy or Aim.tpBusy or killBusy or (Feat.Fling and Feat.Fling.busy) then return false end
		local char, hrp, hum = aliveChar(player)
		local tr = nearestHostile()
		if not (char and tr and tr.Parent) then return false end
		wbBusy = true
		local fired = false
		pcall(function()
			local g = gunOrigin()
			local localOff = g and hrp.CFrame:PointToObjectSpace(g) or Vector3.new(0, 1.5, 0)
			smLocalOff = localOff
			local myHalf = (hum.RigType == Enum.HumanoidRigType.R15) and (hrp.Size.Y / 2 + hum.HipHeight) or 3
			local spot = smPickSpot(tr, myHalf, 7)
			if not spot then notify("No free spot behind murderer") return end
			local cf
			local t0 = tick()
			local settle = pingNow() * 0.5 + 0.1
			repeat
				local sp = tr.Parent and smPickSpot(tr, myHalf, 7) or spot
				spot = sp or spot
				local tp = tr.Position
				cf = CFrame.lookAt(spot, Vector3.new(tp.X, spot.Y, tp.Z))
				Feat.setExtHitbox(cf)
				RunService.Heartbeat:Wait()
			until tick() - t0 >= settle or not tr.Parent
			if not tr.Parent then return end
			local origin = cf:PointToWorldSpace(localOff)
			local aim = predict(tr, Aim.predMul or 1) + Vector3.new(0, Aim.aimHeight or 0.2, 0)
			local d = aim - origin
			d = d.Magnitude > 0.01 and d.Unit or Vector3.new(0, 0, -1)
			local far = aim + d * 2
			Aim.aimPos = aim
			fire(remote, table.pack(CFrame.lookAt(origin, far), CFrame.new(far)))
			fired = true
			local t1 = tick()
			repeat
				Feat.setExtHitbox(cf)
				RunService.Heartbeat:Wait()
			until tick() - t1 >= 0.08
		end)
		if not SM.on then Feat.setExtHitbox(nil) end
		wbBusy = false
		return fired
	end

	function Aim.setShootMurderer(on)
		if on then
			if roles[player] == "Murderer" or hasKnife() then
				notify("You are the murderer: no gun")
				return false
			end
			if not findGun() then notify("No gun yet: waiting for it") end
			SM.on = true
			SM.since = nil
			return true
		end
		SM.on = false
		smStop()
		return true
	end

	table.insert(connections, RunService.Heartbeat:Connect(function()
		if SM.on then pcall(smStep) end
	end))

	-- ---------- Fling (ported from Zenith: "Skid" method) ----------
	-- lead = extra seconds (on top of ping/2) the target is predicted ahead while he walks; raise it if you hit behind him, lower if in front
	local Fling = {busy = false, time = 2.2, lead = 0.1, autoRole = {}, autoP = {}, state = {}}
	Feat.Fling = Fling
	local flingCooldown = {}

	local function sig(name, fb)
		local okS, v = pcall(function() return RunService[name] end)
		if okS and v then return v end
		return RunService[fb]
	end
	local PRE_SIM = sig("PreSimulation", "Stepped")
	local SHERIFF_SET = {Sheriff = true, Hero = true}

	local function findRole(kind)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local c = aliveChar(p)
				if c then
					local r = roles[p]
					if kind == "Murderer" and (r == "Murderer" or c:FindFirstChild("Knife")) then return p end
					if kind == "Sheriff" and (SHERIFF_SET[r] or c:FindFirstChild("Gun")) then return p end
				end
			end
		end
	end

	local function camHome()
		local cam0 = workspace.CurrentCamera
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if cam0 and h then
			cam0.CameraType = Enum.CameraType.Custom
			cam0.CameraSubject = h
		end
	end

	-- returns nil = not started, true = target flung away / dead, false = tried but he is still here
	local function flingOne(p)
		if Fling.busy or killBusy or Aim.tpBusy then return nil end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not (char and hrp and hum) or hum.Health <= 0 or char.Parent ~= workspace then return nil end
		local tc, tr0, th = aliveChar(p)
		if not tc then return nil end
		if Feat.ST.autofarm then notify("Turn off Auto Farm first") return nil end

		Fling.busy, Aim.tpBusy = true, true
		local wasInvis, wasAA = Feat.ST.invis, Feat.ST.antiaim
		if wasInvis then pcall(Feat.setInvis, false) end
		if wasAA then pcall(Feat.setAntiAim, false) end
		if (wasInvis or wasAA) and Fling.syncUI then pcall(Fling.syncUI) end
		if wasInvis or wasAA then
			RunService.Heartbeat:Wait()
			RunService.Heartbeat:Wait()
		end
		local old = hrp.CFrame
		local fpdh = workspace.FallenPartsDestroyHeight
		pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)
		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
		local cam0 = workspace.CurrentCamera
		local head = tc:FindFirstChild("Head")
		pcall(function() cam0.CameraSubject = head or th end)
		local bv = Instance.new("BodyVelocity")
		bv.Name = "MellowynFlingBV"
		bv.Velocity = Vector3.new(9e8, 9e8, 9e8)
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.Parent = hrp
		local base = tr0
		if head and (tr0.Position - head.Position).Magnitude > 5 then base = head end
		local t0 = tick()
		local angle = 0

		local function done()
			if not screenGui.Parent or hum.Health <= 0 then return true end
			if not base.Parent or p.Character ~= tc or p.Parent ~= Players then return true end
			if th.Health <= 0 or th.Sit then return true end
			if base.AssemblyLinearVelocity.Magnitude > 500 then return true end
			return tick() - t0 > Fling.time
		end

		-- ---- moving target: we only see him where he WAS (replication + interpolation), so aim at where he IS ----
		local hist = {}
		local function flatVelocity()
			local now = tick()
			hist[#hist + 1] = {now, base.Position}
			while #hist > 1 and now - hist[1][1] > 0.25 do table.remove(hist, 1) end
			local est = Vector3.zero
			local a, b = hist[1], hist[#hist]
			local dt = b[1] - a[1]
			if dt >= 0.08 then
				local d = b[2] - a[2]
				est = Vector3.new(d.X, 0, d.Z) / dt
			end
			local av = base.AssemblyLinearVelocity
			local rep = Vector3.new(av.X, 0, av.Z)
			local v = rep.Magnitude > est.Magnitude and rep or est
			if v.Magnitude > 80 then v = v.Unit * 80 end
			return v
		end
		local curCenter, curDir, curSpeed = base.Position, Vector3.zero, 0
		local function refreshTarget()
			-- stick tight to the real hitbox center; no forward lead so we don't fly off in front
			local fv = flatVelocity()
			curSpeed = fv.Magnitude
			curCenter = base.Position
			if curSpeed < 2 then
				curDir = Vector3.zero
			else
				curDir = fv.Unit
			end
		end

		local function fpos(pos, ang)
			local cf = CFrame.new(curCenter) * pos * ang
			hrp.CFrame = cf
			pcall(function() char:PivotTo(cf) end)
			hrp.AssemblyLinearVelocity = Vector3.new(9e7, 9e7 * 10, 9e7)
			hrp.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
			task.wait()
			refreshTarget() -- a fresh prediction for the next frame
			return done()
		end

		pcall(function()
			refreshTarget()
			repeat
				local v = base.AssemblyLinearVelocity.Magnitude
				if v < 50 then
					angle += 100
					local a = CFrame.Angles(math.rad(angle), 0, 0)
					-- walking: a small step ahead of the predicted point; standing: m = 0 (same as before)
					local dir = curDir
					-- tiny offsets only, stay inside the target hitbox
					local m = dir * math.min(curSpeed * 0.02, 0.35)
					if fpos(CFrame.new(0, 0.4, 0) + m, a) then break end
					if fpos(CFrame.new(0, -0.4, 0) + m, a) then break end
					if fpos(CFrame.new(0.6, 0.3, -0.6) + m, a) then break end
					if fpos(CFrame.new(-0.6, -0.3, 0.6) + m, a) then break end
					if fpos(CFrame.new(0, 0.2, 0), a) then break end
					if fpos(CFrame.new(0, -0.2, 0), a) then break end
				else
					local ws = th.WalkSpeed
					local up90 = CFrame.Angles(math.rad(90), 0, 0)
					local zero = CFrame.Angles(0, 0, 0)
					if fpos(CFrame.new(0, 1.5, ws), up90) then break end
					if fpos(CFrame.new(0, -1.5, -ws), zero) then break end
					if fpos(CFrame.new(0, 1.5, ws), up90) then break end
					if fpos(CFrame.new(0, 1.5, v / 1.25), up90) then break end
					if fpos(CFrame.new(0, -1.5, -v / 1.25), zero) then break end
					if fpos(CFrame.new(0, 1.5, v / 1.25), up90) then break end
					if fpos(CFrame.new(0, -1.5, 0), up90) then break end
					if fpos(CFrame.new(0, -1.5, 0), zero) then break end
					if fpos(CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0)) then break end
					if fpos(CFrame.new(0, -1.5, 0), zero) then break end
				end
			until done()
		end)

		local flung = (not base.Parent) or base.AssemblyLinearVelocity.Magnitude > 500 or th.Health <= 0
		pcall(function() bv:Destroy() end)
		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
		camHome()
		-- go back to where we were and stop all the spinning
		local t1 = tick()
		repeat
			if not hrp.Parent or player.Character ~= char then break end
			hrp.CFrame = old * CFrame.new(0, 0.5, 0)
			pcall(function() char:PivotTo(old * CFrame.new(0, 0.5, 0)) end)
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
			for _, x in ipairs(char:GetChildren()) do
				if x:IsA("BasePart") then
					x.AssemblyLinearVelocity = Vector3.zero
					x.AssemblyAngularVelocity = Vector3.zero
				end
			end
			task.wait()
		until (hrp.Position - old.Position).Magnitude < 25 or tick() - t1 > 2.5
		pcall(function() workspace.FallenPartsDestroyHeight = fpdh end)
		camHome()
		flingCooldown[p] = tick()
		Fling.busy, Aim.tpBusy = false, false
		-- flung: Invisible / Anti Aim come back
		if wasInvis then pcall(Feat.setInvis, true) end
		if wasAA then pcall(Feat.setAntiAim, true) end
		if (wasInvis or wasAA) and Fling.syncUI then pcall(Fling.syncUI) end
		return flung
	end

	function Fling.flingPlayer(p)
		if not p or p == player or not aliveChar(p) then
			notify("Player is not alive")
			return
		end
		flingOne(p)
	end

	function Fling.flingRole(kind)
		local p = findRole(kind)
		if not p then
			notify(kind .. " not found")
			return
		end
		flingOne(p)
	end

	function Fling.setAutoRole(kind, on)
		Fling.autoRole[kind] = on or nil
		Fling.state[kind] = nil
	end

	function Fling.setAutoPlayer(p, on)
		Fling.autoP[p] = on or nil
	end

	function Fling.isAuto(p)
		return Fling.autoP[p] == true
	end

	-- new round: every role may be tried (max 2 times) again
	Aim.flingReset = function()
		table.clear(Fling.state)
	end

	table.insert(connections, Players.PlayerRemoving:Connect(function(p)
		Fling.autoP[p] = nil
		flingCooldown[p] = nil
	end))

	task.spawn(function()
		while screenGui.Parent do
			task.wait(0.25)
			if not Fling.busy and not killBusy and not Aim.tpBusy then
				pcall(function()
					-- Auto Fling Sheriff / Murderer: 2 attempts per round, then wait for the next round
					for _, kind in ipairs({"Sheriff", "Murderer"}) do
						if Fling.autoRole[kind] then
							local p = findRole(kind)
							if p then
								local st = Fling.state[kind]
								if not st or st.plr ~= p then
									st = {plr = p, tries = 0, done = false}
									Fling.state[kind] = st
								end
								if not st.done and st.tries < 2 then
									local r = flingOne(p)
									if r ~= nil then
										st.tries = st.tries + 1
										if r then st.done = true end
										return
									end
								end
							end
						end
					end
					-- Auto Fling on a single player: fling, he dies, fling again when he is back
					for p in pairs(Fling.autoP) do
						if p.Parent == Players and aliveChar(p) and (flingCooldown[p] or 0) + 3 < tick() then
							flingOne(p)
							return
						end
					end
				end)
			end
		end
	end)

	-- ---------- loops ----------
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				local raw = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
				if raw > 0 then
					if not Aim.pingSeeded then
						Aim.ping, Aim.jitter, Aim.pingSeeded = raw, 0, true
					else
						local dev = math.abs(raw - Aim.ping)
						Aim.jitter = Aim.jitter + (dev - Aim.jitter) * 0.15
						-- spike -> the lead grows at once; calm down -> it relaxes slowly
						local a = raw > Aim.ping and 0.6 or 0.2
						Aim.ping = Aim.ping + (raw - Aim.ping) * a
					end
				end
			end)
			task.wait(0.1)
		end
	end)

	table.insert(connections, RunService.RenderStepped:Connect(function()
		if Aim.on or Aim.autoshoot or SM.on then
			updateTargets()
		else
			Aim.target = nil
		end
	end))

	table.insert(connections, RunService.Heartbeat:Connect(function()
		if Aim.autoshoot and not AS.busy and tick() - AS.fireAt >= 0.05 and tick() - lastShot >= 0.05 then
			task.spawn(autoShootTick)
		end
	end))

	function Aim.cleanup()
		Aim.on, Aim.autoshoot = false, false
		SM.on = false
		pcall(smStop)
		table.clear(Fling.autoRole)
		table.clear(Fling.autoP)
		Aim.target = nil
		if genv.MellowynAimHandler == safeHandler then
			genv.MellowynAimHandler = nil
		end
	end
	screenGui.Destroying:Connect(Aim.cleanup)
end

-- ===================== ON-SCREEN BUTTONS =====================
local BTN_SIZE = 64
local function makeScreenButton(text, slot, isOn, onClick)
	local api = {}
	local col = math.floor(slot / 3)
	local rowIdx = slot % 3

	local holder = Instance.new("Frame")
	holder.Name = text .. "Holder"
	holder.Size = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
	holder.Position = UDim2.new(1, -(BTN_SIZE + 24 + col * (BTN_SIZE + 10)), 0, 60 + rowIdx * (BTN_SIZE + 10))
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Visible = false
	holder.ZIndex = 150
	holder.Parent = screenGui

	local holderScale = Instance.new("UIScale")
	holderScale.Scale = 1
	holderScale.Parent = holder

	local btn = Instance.new("TextButton")
	btn.Name = "MainButton"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundColor3 = BLACK
	btn.BackgroundTransparency = 0.5
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = WHITE
	btn.TextTransparency = 0.2
	btn.TextWrapped = false
	btn.TextScaled = false
	btn.RichText = false
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center
	btn.TextTruncate = Enum.TextTruncate.None
	btn.ZIndex = 151
	btn.Parent = holder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	-- small square top right: "-" = can be moved, "+" = locked
	local lockBtn = Instance.new("TextButton")
	lockBtn.Name = "LockButton"
	lockBtn.Size = UDim2.new(0, 16, 0, 16)
	lockBtn.AnchorPoint = Vector2.new(1, 0)
	lockBtn.Position = UDim2.new(1, -4, 0, 4)
	lockBtn.BackgroundColor3 = BLACK
	lockBtn.BackgroundTransparency = 0.35
	lockBtn.BorderSizePixel = 0
	lockBtn.AutoButtonColor = false
	lockBtn.Text = "-"
	lockBtn.Font = Enum.Font.GothamBold
	lockBtn.TextSize = 14
	lockBtn.TextColor3 = WHITE
	lockBtn.ZIndex = 152
	lockBtn.Parent = holder

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, 4)
	lockCorner.Parent = lockBtn

	local locked = false
	lockBtn.MouseButton1Click:Connect(function()
		locked = not locked
		lockBtn.Text = locked and "+" or "-"
		playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
	end)

	function api.refresh()
		local on = isOn()
		tween(btn, {
			BackgroundTransparency = on and 0.2 or 0.5,
			TextTransparency = on and 0 or 0.2,
		}, 0.2)
	end

	function api.setVisible(v)
		if v then
			api.refresh()
			holderScale.Scale = 0.5
			holder.Visible = true
			tween(holderScale, {Scale = 1}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			holder.Visible = false
		end
	end

	-- drag (only when unlocked); a tap without moving = click
	local pressed, moved = false, false
	local dragInput, startInput, startAbs = nil, nil, nil

	btn.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		pressed = true
		moved = false
		dragInput = input
		startInput = input.Position
		startAbs = holder.AbsolutePosition
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				if pressed and not moved then
					onClick()
				end
				pressed = false
			end
		end)
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not pressed or locked then return end
		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
		if not (isMouse or isTouch) then return end

		local delta = input.Position - startInput
		if not moved and delta.Magnitude < 6 then return end
		moved = true

		local vp = screenGui.AbsoluteSize
		local sz = holder.AbsoluteSize
		local nx = math.clamp(startAbs.X + delta.X, 0, math.max(0, vp.X - sz.X))
		local ny = math.clamp(startAbs.Y + delta.Y, 0, math.max(0, vp.Y - sz.Y))
		holder.Position = UDim2.new(0, nx, 0, ny)
	end))

	api.holder = holder
	return api
end

local ctrls = {}
local btns = {}
btns.invis = makeScreenButton("inviz", 0, function() return Feat.ST.invis end, function()
	ctrls.invis.set(not ctrls.invis.get())
end)
btns.speed = makeScreenButton("Speed", 1, function() return Feat.ST.speed end, function()
	ctrls.speed.set(not ctrls.speed.get())
end)
btns.fly = makeScreenButton("Fly", 2, function() return Feat.ST.fly end, function()
	ctrls.fly.set(not ctrls.fly.get())
end)
btns.noclip = makeScreenButton("Noclip", 3, function() return Feat.ST.noclip end, function()
	ctrls.noclip.set(not ctrls.noclip.get())
end)
btns.jump = makeScreenButton("Inf Jump", 4, function() return Feat.ST.infjump end, function()
	ctrls.jump.set(not ctrls.jump.get())
end)
btns.shoot = makeScreenButton("Shoot", 5, function() return false end, function()
	task.spawn(Feat.Aim.shootNow)
end)

-- number input row (label + box)
local function makeInputRow(parent, y, text, default, onChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Position = UDim2.new(0, 0, 0, y)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextColor3 = WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = false
	label.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 52, 0, 20)
	box.Position = UDim2.new(1, -8, 0.5, 0)
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.BackgroundColor3 = BLACK
	box.BackgroundTransparency = 0.2
	box.BorderSizePixel = 0
	box.Text = tostring(default)
	box.PlaceholderText = ""
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 12
	box.TextColor3 = WHITE
	box.ClearTextOnFocus = false
	box.Parent = row

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 4)
	boxCorner.Parent = box

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = WHITE
	boxStroke.Thickness = 1
	boxStroke.Transparency = 0.6
	boxStroke.Parent = box

	local last = tostring(default)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			last = box.Text
			onChange(n)
		else
			box.Text = last
		end
	end)
	local function getNum()
		return tonumber(box.Text)
	end
	local function setNum(n)
		box.Text = tostring(n)
		last = box.Text
		onChange(n)
	end
	return row, getNum, setNum
end

-- colour row: label + small colour swatch (click = open / close the palette)
local function makeColorRow(parent, text, default)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextColor3 = WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = false
	label.Parent = row

	local swatch = Instance.new("TextButton")
	swatch.Size = UDim2.new(0, 40, 0, 18)
	swatch.Position = UDim2.new(1, -8, 0.5, 0)
	swatch.AnchorPoint = Vector2.new(1, 0.5)
	swatch.BackgroundColor3 = default
	swatch.BorderSizePixel = 0
	swatch.AutoButtonColor = false
	swatch.Text = ""
	swatch.Parent = row

	local swCorner = Instance.new("UICorner")
	swCorner.CornerRadius = UDim.new(0, 5)
	swCorner.Parent = swatch

	local swStroke = Instance.new("UIStroke")
	swStroke.Color = WHITE
	swStroke.Thickness = 1
	swStroke.Transparency = 0.5
	swStroke.Parent = swatch

	return {
		row = row,
		swatch = swatch,
		setColor = function(c)
			swatch.BackgroundColor3 = c
		end,
	}
end

-- HSV palette: saturation/value square + hue bar
local PICKER_H = 100
local insetMode = nil -- true: input.Position excludes the top inset (we add it)
local function inputToAbs(input, frame)
	local p0 = Vector2.new(input.Position.X, input.Position.Y)
	if not screenGui.IgnoreGuiInset then return p0 end
	local ins = GuiService:GetGuiInset()
	local p1 = p0 + ins
	local pos, size = frame.AbsolutePosition, frame.AbsoluteSize
	local function inside(p)
		return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
	end
	if insetMode == nil then
		local in0, in1 = inside(p0), inside(p1)
		if in1 and not in0 then
			insetMode = true
		elseif in0 and not in1 then
			insetMode = false
		end
	end
	if insetMode == false then return p0 end
	return p1
end

local function makePicker(parent, initial, onChange)
	local h, s, v = initial:ToHSV()

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, PICKER_H)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Visible = false
	holder.Parent = parent

	local sv = Instance.new("Frame")
	sv.Size = UDim2.new(1, -16, 0, 70)
	sv.Position = UDim2.new(0, 8, 0, 2)
	sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	sv.BorderSizePixel = 0
	sv.ClipsDescendants = true
	sv.Parent = holder
	local svCorner = Instance.new("UICorner")
	svCorner.CornerRadius = UDim.new(0, 4)
	svCorner.Parent = sv

	local white = Instance.new("Frame")
	white.Size = UDim2.new(1, 0, 1, 0)
	white.BackgroundColor3 = Color3.new(1, 1, 1)
	white.BorderSizePixel = 0
	white.Parent = sv
	local whiteGrad = Instance.new("UIGradient")
	whiteGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	whiteGrad.Parent = white

	local black = Instance.new("Frame")
	black.Size = UDim2.new(1, 0, 1, 0)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BorderSizePixel = 0
	black.Parent = sv
	local blackGrad = Instance.new("UIGradient")
	blackGrad.Rotation = 90
	blackGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	blackGrad.Parent = black

	local svCursor = Instance.new("Frame")
	svCursor.Size = UDim2.new(0, 10, 0, 10)
	svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	svCursor.BackgroundTransparency = 1
	svCursor.BorderSizePixel = 0
	svCursor.Parent = sv
	local curCorner = Instance.new("UICorner")
	curCorner.CornerRadius = UDim.new(1, 0)
	curCorner.Parent = svCursor
	local curStroke = Instance.new("UIStroke")
	curStroke.Color = Color3.new(1, 1, 1)
	curStroke.Thickness = 2
	curStroke.Parent = svCursor

	local hue = Instance.new("Frame")
	hue.Size = UDim2.new(1, -16, 0, 12)
	hue.Position = UDim2.new(0, 8, 0, 78)
	hue.BackgroundColor3 = Color3.new(1, 1, 1)
	hue.BorderSizePixel = 0
	hue.Parent = holder
	local hueCorner = Instance.new("UICorner")
	hueCorner.CornerRadius = UDim.new(0, 4)
	hueCorner.Parent = hue
	local hueGrad = Instance.new("UIGradient")
	local stops = {}
	for i = 0, 6 do
		table.insert(stops, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, 0.999), 1, 1)))
	end
	hueGrad.Color = ColorSequence.new(stops)
	hueGrad.Parent = hue

	local hueCursor = Instance.new("Frame")
	hueCursor.Size = UDim2.new(0, 4, 1, 4)
	hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	hueCursor.BackgroundTransparency = 1
	hueCursor.BorderSizePixel = 0
	hueCursor.Parent = hue
	local hcCorner = Instance.new("UICorner")
	hcCorner.CornerRadius = UDim.new(0, 2)
	hcCorner.Parent = hueCursor
	local hcStroke = Instance.new("UIStroke")
	hcStroke.Color = Color3.new(1, 1, 1)
	hcStroke.Thickness = 2
	hcStroke.Parent = hueCursor

	local function refreshVisual()
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
	end
	refreshVisual()

	local dragging, dragInput = nil, nil
	local function apply(which, input)
		local frame = which == "sv" and sv or hue
		local abs = inputToAbs(input, frame)
		local rel = (abs - frame.AbsolutePosition) / frame.AbsoluteSize
		if which == "sv" then
			s = math.clamp(rel.X, 0, 1)
			v = 1 - math.clamp(rel.Y, 0, 1)
		else
			h = math.clamp(rel.X, 0, 0.999)
		end
		refreshVisual()
		onChange(Color3.fromHSV(h, s, v))
	end
	local function bind(which, frame)
		frame.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			dragging = which
			dragInput = input
			apply(which, input)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End and dragInput == input then
					dragging = nil
				end
			end)
		end)
	end
	bind("sv", sv)
	bind("hue", hue)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or (input.UserInputType == Enum.UserInputType.Touch and input == dragInput) then
			apply(dragging, input)
		end
	end))

	local function setPickerColor(c)
		h, s, v = c:ToHSV()
		h = math.min(h, 0.999)
		refreshVisual()
	end

	return holder, setPickerColor
end

-- ===================== SETTINGS SIDE PANELS (slide out to the right) =====================
local SETTINGS_W = 150
local settingsPanels = {}

local function updateOnePanel(sp)
	local p = sp.progress.Value
	local slide = -(1 - p) * (SETTINGS_W + 8)
	sp.frame.Position = UDim2.new(
		0.5, menu.Position.X.Offset + MENU_W / 2 + 8 + slide,
		0.5, menu.Position.Y.Offset - MENU_H / 2 + TOPBAR_H + 1 + CARD_PAD
	)
	sp.frame.GroupTransparency = 1 - p
	sp.frame.Visible = p > 0.001
end

updateSettingsPosition = function()
	for _, sp in ipairs(settingsPanels) do
		updateOnePanel(sp)
	end
end

local function setPanelOpen(sp, open)
	sp.open = open
	tween(sp.progress, {Value = open and 1 or 0}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if sp.icon then
		tween(sp.icon, {Rotation = open and 90 or 0}, 0.3)
	end
end

closeSettingsPanel = function()
	for _, sp in ipairs(settingsPanels) do
		if sp.open then
			setPanelOpen(sp, false)
		end
	end
end

-- rounded button: the outline goes around the BUTTON (Border mode), not around its text
local function makeOutlineButton(parent, text)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = BLACK
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = text
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 12
	b.TextColor3 = WHITE
	b.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 5)
	bc.Parent = b
	local bs = Instance.new("UIStroke")
	bs.Color = WHITE
	bs.Thickness = 1
	bs.Transparency = 0.5
	bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bs.Parent = b
	b.MouseButton1Down:Connect(function()
		tween(bs, {Transparency = 0.1}, 0.08)
	end)
	local function release()
		tween(bs, {Transparency = 0.5}, 0.2)
	end
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)
	b.MouseButton1Click:Connect(function()
		playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
	end)
	return b
end

-- items: {type = "toggle"|"input"|"color"|"dropdown"|"button", text, default, onChange}
local function createSettings(title, items)
	local sp = {open = false}
	sp.progress = Instance.new("NumberValue")
	sp.progress.Value = 0

	local frame = Instance.new("CanvasGroup")
	frame.Name = title .. "Settings"
	frame.Size = UDim2.new(0, SETTINGS_W, 0, 60)
	frame.BackgroundColor3 = BLACK
	frame.BackgroundTransparency = 0.10
	frame.BorderSizePixel = 0
	frame.GroupTransparency = 1
	frame.Visible = false
	frame.ZIndex = 99 -- below the menu (100): slides out from behind it
	frame.Parent = screenGui
	sp.frame = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Thickness = 0.8
	stroke.Transparency = 0.55
	stroke.Parent = frame

	makeCardHeader(frame, title)

	local elems = {}
	for itemIdx, it in ipairs(items) do
		local e = {}
		local cfgKey = "panel:" .. title .. "/" .. tostring(it.text or (tostring(it.type) .. itemIdx))
		if it.type == "toggle" then
			local tc = makeToggleRow(frame, 0, it.text, it.onChange, nil, cfgKey)
			e.row = tc.row
			if it.default then tc.set(true, true) end
		elseif it.type == "color" then
			local cr = makeColorRow(frame, it.text, it.default)
			e.row = cr.row
			local curColor = it.default
			local pk, pkSet = makePicker(frame, it.default, function(c)
				curColor = c
				cr.setColor(c)
				it.onChange(c)
			end)
			e.picker = pk
			UI.cfgAdd(cfgKey, "color", function() return curColor end, function(c)
				curColor = c
				cr.setColor(c)
				pkSet(c)
				it.onChange(c)
			end)
			cr.swatch.MouseButton1Click:Connect(function()
				e.open = not e.open
				sp.layout(false)
			end)
		elseif it.type == "button" then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 28)
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Parent = frame
			local b = makeOutlineButton(row, it.text)
			b.Size = UDim2.new(1, -16, 0, 22)
			b.Position = UDim2.new(0, 8, 0.5, 0)
			b.AnchorPoint = Vector2.new(0, 0.5)
			b.MouseButton1Click:Connect(function()
				if it.onChange then task.spawn(it.onChange) end
			end)
			e.row = row
		elseif it.type == "segment" then
			-- flat buttons side by side, NO outline; the chosen one is bright with a soft fill
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 28)
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Parent = frame
			local n = #it.options
			local segCur = it.default or it.options[1]
			local bw = (SETTINGS_W - 16 - 4 * (n - 1)) / n
			local segBtns = {}
			local function mark(selected, instant)
				for name, b in pairs(segBtns) do
					local sel = (name == selected)
					if instant then
						b.TextTransparency = sel and 0 or 0.5
						b.BackgroundTransparency = sel and 0.8 or 1
					else
						tween(b, {TextTransparency = sel and 0 or 0.5, BackgroundTransparency = sel and 0.8 or 1}, 0.15)
					end
				end
			end
			for i, name in ipairs(it.options) do
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0, bw, 0, 22)
				b.Position = UDim2.new(0, 8 + (i - 1) * (bw + 4), 0.5, 0)
				b.AnchorPoint = Vector2.new(0, 0.5)
				b.BackgroundColor3 = WHITE
				b.BackgroundTransparency = 1
				b.BorderSizePixel = 0
				b.AutoButtonColor = false
				b.Text = name
				b.Font = Enum.Font.GothamMedium
				b.TextSize = 12
				b.TextColor3 = WHITE
				b.TextTransparency = 0.5
				b.Parent = row
				local sc = Instance.new("UICorner")
				sc.CornerRadius = UDim.new(0, 5)
				sc.Parent = b
				segBtns[name] = b
				b.MouseButton1Click:Connect(function()
					mark(name)
					segCur = name
					playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
					if it.onChange then it.onChange(name) end
				end)
			end
			mark(it.default or it.options[1], true)
			e.row = row
			UI.cfgAdd(cfgKey, "string", function() return segCur end, function(name)
				if segBtns[name] then
					segCur = name
					mark(name)
					if it.onChange then it.onChange(name) end
				end
			end)
		elseif it.type == "dropdown" then
			-- rectangle with the current value; click = the other options open below it
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 28)
			row.BackgroundTransparency = 1
			row.BorderSizePixel = 0
			row.Parent = frame

			local main = Instance.new("TextButton")
			main.Size = UDim2.new(1, -16, 0, 22)
			main.Position = UDim2.new(0, 8, 0.5, 0)
			main.AnchorPoint = Vector2.new(0, 0.5)
			main.BackgroundColor3 = BLACK
			main.BackgroundTransparency = 0.2
			main.BorderSizePixel = 0
			main.AutoButtonColor = false
			main.Text = it.default
			main.Font = Enum.Font.GothamMedium
			main.TextSize = 12
			main.TextColor3 = WHITE
			main.Parent = row
			local mcorner = Instance.new("UICorner")
			mcorner.CornerRadius = UDim.new(0, 5)
			mcorner.Parent = main
			local mstroke = Instance.new("UIStroke")
			mstroke.Color = WHITE
			mstroke.Thickness = 1
			mstroke.Transparency = 0.5
			mstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			mstroke.Parent = main

			local holder = Instance.new("Frame")
			holder.Size = UDim2.new(1, 0, 0, #it.options * 24 + 2)
			holder.BackgroundTransparency = 1
			holder.BorderSizePixel = 0
			holder.Visible = false
			holder.Parent = frame

			local optButtons = {}
			local ddCur = it.default
			local function mark(selected)
				for name, ob in pairs(optButtons) do
					local sel = (name == selected)
					tween(ob.btn, {TextTransparency = sel and 0 or 0.4}, 0.15)
					tween(ob.stroke, {Transparency = sel and 0.15 or 0.75}, 0.15)
				end
			end
			for i, name in ipairs(it.options) do
				local ob = Instance.new("TextButton")
				ob.Size = UDim2.new(1, -16, 0, 22)
				ob.Position = UDim2.new(0, 8, 0, 2 + (i - 1) * 24)
				ob.BackgroundColor3 = BLACK
				ob.BackgroundTransparency = 0.35
				ob.BorderSizePixel = 0
				ob.AutoButtonColor = false
				ob.Text = name
				ob.Font = Enum.Font.GothamMedium
				ob.TextSize = 12
				ob.TextColor3 = WHITE
				ob.TextTransparency = 0.4
				ob.Parent = holder
				local oc = Instance.new("UICorner")
				oc.CornerRadius = UDim.new(0, 5)
				oc.Parent = ob
				local os = Instance.new("UIStroke")
				os.Color = WHITE
				os.Thickness = 1
				os.Transparency = 0.75
				os.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				os.Parent = ob
				optButtons[name] = {btn = ob, stroke = os}
				ob.MouseButton1Click:Connect(function()
					main.Text = name
					ddCur = name
					mark(name)
					e.open = false
					sp.layout(false)
					playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
					it.onChange(name)
				end)
			end
			mark(it.default)
			UI.cfgAdd(cfgKey, "string", function() return ddCur end, function(name)
				if optButtons[name] then
					main.Text = name
					ddCur = name
					mark(name)
					it.onChange(name)
				end
			end)

			e.row = row
			e.picker = holder
			e.pickerH = #it.options * 24 + 2
			main.MouseButton1Click:Connect(function()
				e.open = not e.open
				sp.layout(false)
			end)
		else
			local irow, iget, iset = makeInputRow(frame, 0, it.text, it.default, it.onChange)
			e.row = irow
			UI.cfgAdd(cfgKey, "number", iget, iset)
		end
		table.insert(elems, e)
	end

	function sp.layout(instant)
		local y = 24
		for _, e in ipairs(elems) do
			if instant then
				e.row.Position = UDim2.new(0, 0, 0, y)
			else
				tween(e.row, {Position = UDim2.new(0, 0, 0, y)}, 0.18)
			end
			y = y + 28
			if e.picker then
				if e.open then
					e.picker.Position = UDim2.new(0, 0, 0, y)
					e.picker.Visible = true
					y = y + (e.pickerH or PICKER_H)
				else
					e.picker.Visible = false
				end
			end
		end
		local size = UDim2.new(0, SETTINGS_W, 0, y + 6)
		if instant then
			frame.Size = size
		else
			tween(frame, {Size = size}, 0.18)
		end
	end
	sp.layout(true)

	-- change the text of an "input" row from code (e.g. after a preset moved the value)
	function sp.setText(index, value)
		local e = elems[index]
		local tb = e and e.row and e.row:FindFirstChildOfClass("TextBox")
		if tb then tb.Text = tostring(value) end
	end

	sp.progress.Changed:Connect(function()
		updateOnePanel(sp)
	end)
	table.insert(settingsPanels, sp)
	updateOnePanel(sp)
	return sp
end

-- gear icon at the end of a toggle row opens its panel (only one panel open at a time)
local function attachGear(toggle, sp)
	local gearBtn, gearIcon = makeGearButton(toggle.row)
	sp.icon = gearIcon
	gearBtn.MouseButton1Click:Connect(function()
		local opening = not sp.open
		for _, other in ipairs(settingsPanels) do
			if other ~= sp and other.open then
				setPanelOpen(other, false)
			end
		end
		setPanelOpen(sp, opening)
		playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
	end)
end

local spInvis = createSettings("invisible", {
	{type = "toggle", text = "Invisible Button", onChange = function(v) btns.invis.setVisible(v) end},
})
local spAA = createSettings("anti aim", {
	{type = "input", text = "Range (studs)", default = Feat.P.AARange, onChange = function(n)
		Feat.P.AARange = math.clamp(n, 1, 300)
	end},
	{type = "toggle", text = "Hitbox Chams", onChange = function(v) Feat.setChams(v) end},
})
local spSpin = createSettings("spin", {
	{type = "input", text = "Spin Speed", default = Feat.P.SpinSpeed, onChange = function(n)
		Feat.P.SpinSpeed = math.clamp(n, -360, 360)
	end},
})
local spSpeed = createSettings("walkspeed", {
	{type = "input", text = "Walk Speed", default = Feat.P.WalkSpeed, onChange = function(n)
		Feat.P.WalkSpeed = math.clamp(n, 0, 500)
	end},
	{type = "toggle", text = "Speed Button", onChange = function(v) btns.speed.setVisible(v) end},
})
local spBunny = createSettings("bunny hop", {
	{type = "input", text = "Max Speed", default = Feat.Bunny.Max, onChange = function(n)
		Feat.Bunny.Max = math.clamp(n, 16, 300)
	end},
	{type = "input", text = "Gain / sec", default = Feat.Bunny.Gain, onChange = function(n)
		Feat.Bunny.Gain = math.clamp(n, 1, 200)
	end},
	{type = "toggle", text = "Auto Jump", onChange = function(v) Feat.Bunny.Auto = v end},
})
local spJump = createSettings("infinite jump", {
	{type = "toggle", text = "Inf Jump Button", onChange = function(v) btns.jump.setVisible(v) end},
})
local spFly = createSettings("fly", {
	{type = "input", text = "Fly Speed", default = Feat.P.FlySpeed, onChange = function(n)
		Feat.P.FlySpeed = math.clamp(n, 1, 500)
	end},
	{type = "toggle", text = "Fly Button", onChange = function(v) btns.fly.setVisible(v) end},
})
local spNoclip = createSettings("noclip", {
	{type = "toggle", text = "Noclip Button", onChange = function(v) btns.noclip.setVisible(v) end},
})
local spFov = createSettings("fov", {
	{type = "input", text = "FOV Value", default = Feat.P.Fov, onChange = function(n)
		Feat.P.Fov = math.clamp(n, 1, 120)
	end},
})
local spStretch = createSettings("stretch screen", {
	{type = "input", text = "Stretch (0.2-1)", default = Feat.P.Stretch, onChange = function(n)
		Feat.P.Stretch = math.clamp(n, 0.2, 1)
	end},
})
local spEsp = createSettings("esp box", {
	{type = "segment", options = {"Box", "Corner"}, default = "Box", onChange = function(name) Feat.P.BoxStyle = name end},
	{type = "toggle", text = "Box Fill", onChange = function(v) Feat.setBoxFill(v) end},
	{type = "color", text = "Box Color", default = Feat.P.BoxColor, onChange = function(c) Feat.P.BoxColor = c end},
	{type = "color", text = "Fill Color", default = Feat.P.FillColor, onChange = function(c) Feat.P.FillColor = c end},
	{type = "toggle", text = "Gradient", default = Feat.P.BoxGrad, onChange = function(v) Feat.P.BoxGrad = v end},
	{type = "color", text = "Gradient Color", default = Feat.P.BoxGrad2, onChange = function(c) Feat.P.BoxGrad2 = c end},
})

-- ===================== CARDS =====================
local function createCard(parent, title, x, y, rows)
	local h = 24 + #rows * 28 + 6
	local card = Instance.new("Frame")
	card.Name = title .. "Card"
	card.Size = UDim2.new(0, CARD_SIZE, 0, h)
	card.Position = UDim2.new(0, x, 0, y)
	card.BackgroundColor3 = BLACK
	card.BackgroundTransparency = 0.10
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = WHITE
	cardStroke.Thickness = 0.8
	cardStroke.Transparency = 0.55
	cardStroke.Parent = card

	makeCardHeader(card, title)
	local toggles = {}
	for i, r in ipairs(rows) do
		toggles[i] = makeToggleRow(card, 24 + (i - 1) * 28, r.text, r.onChange, r.gear and 26 or 8,
			(not r.nosave) and (title .. "/" .. r.text) or nil)
	end
	return card, toggles, h
end

local COL2_X = CARD_PAD * 2 + CARD_SIZE

-- ---------- MAIN ----------
local _, tA, hA = createCard(mainTab.page, "player", CARD_PAD, CARD_PAD, {
	{text = "Invisible", gear = true, onChange = function(v)
		if v and Feat.ST.autofarm then
			ctrls.invis.set(false, true)
			UI.toast("Turn off Auto Farm first")
			return
		end
		if v and Feat.ST.antiaim then
			Feat.setAntiAim(false)
			ctrls.aa.set(false, true)
		end
		Feat.setInvis(v)
		btns.invis.refresh()
	end},
	{text = "Anti Aim", gear = true, onChange = function(v)
		if v and Feat.ST.autofarm then
			ctrls.aa.set(false, true)
			UI.toast("Turn off Auto Farm first")
			return
		end
		if v and Feat.ST.invis then
			Feat.setInvis(false)
			ctrls.invis.set(false, true)
			btns.invis.refresh()
		end
		Feat.setAntiAim(v)
	end},
	{text = "Spin", gear = true, onChange = function(v) Feat.setSpin(v) end},
	{text = "Anti Fling", onChange = function(v) Feat.setAntiFling(v) end},
	{text = "OffDamageWater", onChange = function(v) Feat.setWater(v) end},
})
ctrls.invis = tA[1]
ctrls.aa = tA[2]
attachGear(tA[1], spInvis)
attachGear(tA[2], spAA)
attachGear(tA[3], spSpin)

local _, tB, hB = createCard(mainTab.page, "movement", COL2_X, CARD_PAD, {
	{text = "WalkSpeed", gear = true, onChange = function(v)
		Feat.setSpeed(v)
		btns.speed.refresh()
	end},
	{text = "Bunny Hop", gear = true, onChange = function(v) Feat.setBunny(v) end},
	{text = "Infinite Jump", gear = true, onChange = function(v)
		Feat.setInfJump(v)
		btns.jump.refresh()
	end},
	{text = "Noclip", gear = true, onChange = function(v)
		Feat.setNoclip(v)
		btns.noclip.refresh()
	end},
	{text = "Fly", gear = true, onChange = function(v)
		Feat.setFly(v)
		btns.fly.refresh()
	end},
})
ctrls.speed = tB[1]
ctrls.jump = tB[3]
ctrls.noclip = tB[4]
ctrls.fly = tB[5]
attachGear(tB[1], spSpeed)
attachGear(tB[2], spBunny)
attachGear(tB[3], spJump)
attachGear(tB[4], spNoclip)
attachGear(tB[5], spFly)

local row2Y = CARD_PAD * 2 + math.max(hA, hB)
local _, tC, hC = createCard(mainTab.page, "game", CARD_PAD, row2Y, {
	{text = "Auto Grab Gun", onChange = function(v) Feat.setAutoGrab(v) end},
	{text = "Auto Farm", onChange = function(v)
		if v then
			if Feat.ST.invis then
				Feat.setInvis(false)
				ctrls.invis.set(false, true)
				btns.invis.refresh()
			end
			if Feat.ST.antiaim then
				Feat.setAntiAim(false)
				ctrls.aa.set(false, true)
			end
		end
		Feat.setFarm(v)
	end},
})

local _, tD, hD = createCard(mainTab.page, "camera", COL2_X, row2Y, {
	{text = "FOV", gear = true, onChange = function(v) Feat.setFov(v) end},
	{text = "Stretch Screen", gear = true, onChange = function(v) Feat.setStretch(v) end},
})
attachGear(tD[1], spFov)
attachGear(tD[2], spStretch)

mainTab.page.CanvasSize = UDim2.new(0, 0, 0, row2Y + math.max(hC, hD) + CARD_PAD)

-- ---------- VISUAL ----------
do
	local spLine = createSettings("esp line", {
		{type = "color", text = "Line Color", default = Feat.P.LineColor, onChange = function(c)
			Feat.P.LineColor = c
		end},
		{type = "toggle", text = "Gradient", default = Feat.P.LineGrad, onChange = function(v) Feat.P.LineGrad = v end},
		{type = "color", text = "Gradient Color", default = Feat.P.LineGrad2, onChange = function(c)
			Feat.P.LineGrad2 = c
		end},
	})
	local spChams = createSettings("chams", {
		{type = "toggle", text = "Chams All", onChange = function(v) Feat.P.ChamsAll = v end},
		{type = "dropdown", options = {"Default", "Outline", "Ghost"}, default = "Default", onChange = function(name)
			Feat.P.ChamsMode = name
		end},
		{type = "color", text = "Chams Color", default = Feat.P.ChamsColor, onChange = function(c)
			Feat.P.ChamsColor = c
		end},
		{type = "toggle", text = "Gradient", default = Feat.P.ChamsGrad, onChange = function(v) Feat.P.ChamsGrad = v end},
		{type = "color", text = "Gradient Color", default = Feat.P.ChamsGrad2, onChange = function(c)
			Feat.P.ChamsGrad2 = c
		end},
	})

	-- ===== 3D Preview: a rotating clone of your character; ESP box / line / avatar / chams show up on it =====
	local function buildPreview(parent, x, y, w, h)
		local ST, P = Feat.ST, Feat.P
		local card = Instance.new("Frame")
		card.Name = "PreviewCard"
		card.Size = UDim2.new(0, w, 0, h)
		card.Position = UDim2.new(0, x, 0, y)
		card.BackgroundColor3 = BLACK
		card.BackgroundTransparency = 0.10
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.Parent = parent
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 6)
		cc.Parent = card
		local cs = Instance.new("UIStroke")
		cs.Color = WHITE
		cs.Thickness = 0.8
		cs.Transparency = 0.55
		cs.Parent = card
		makeCardHeader(card, "3d preview")

		-- the view is a button: tap = pause / resume the rotation
		local view = Instance.new("TextButton")
		view.Position = UDim2.new(0, 6, 0, 26)
		view.Size = UDim2.new(1, -12, 1, -32)
		view.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		view.BackgroundTransparency = 0.15
		view.BorderSizePixel = 0
		view.AutoButtonColor = false
		view.Text = ""
		view.ClipsDescendants = true
		view.Parent = card
		local vc = Instance.new("UICorner")
		vc.CornerRadius = UDim.new(0, 5)
		vc.Parent = view
		local vs2 = Instance.new("UIStroke")
		vs2.Color = WHITE
		vs2.Thickness = 1
		vs2.Transparency = 0.75
		vs2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		vs2.Parent = view

		local vp = Instance.new("ViewportFrame")
		vp.BackgroundTransparency = 1
		vp.Size = UDim2.new(1, 0, 1, 0)
		vp.Ambient = Color3.fromRGB(170, 170, 180)
		vp.LightColor = Color3.fromRGB(255, 255, 255)
		vp.LightDirection = Vector3.new(-0.4, -1, 0.6)
		vp.Parent = view
		local vcam = Instance.new("Camera")
		vcam.FieldOfView = 40
		vcam.Parent = vp
		vp.CurrentCamera = vcam

		local ov = Instance.new("Frame")
		ov.BackgroundTransparency = 1
		ov.Size = UDim2.new(1, 0, 1, 0)
		ov.ZIndex = 3
		ov.Parent = view
		local fill = Instance.new("Frame")
		fill.BorderSizePixel = 0
		fill.BackgroundTransparency = 0.7
		fill.ZIndex = 3
		fill.Visible = false
		fill.Parent = ov
		local function newLine()
			local l = Instance.new("Frame")
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.BorderSizePixel = 0
			l.BackgroundColor3 = WHITE
			l.ZIndex = 4
			l.Visible = false
			l.Parent = ov
			return l
		end
		local function seg(l, a, b2, col, th)
			local d = b2 - a
			l.Size = UDim2.fromOffset(d.Magnitude + 1, th or 1.5)
			l.Position = UDim2.fromOffset((a.X + b2.X) / 2, (a.Y + b2.Y) / 2)
			l.Rotation = math.deg(math.atan2(d.Y, d.X))
			l.BackgroundColor3 = col
			l.Visible = true
		end
		local pbox = Feat.newEspBox(ov, 3)
		local lineL = newLine()
		local lineGrad = Instance.new("UIGradient")
		lineGrad.Parent = lineL
		local av = Instance.new("ImageLabel")
		av.Size = UDim2.fromOffset(22, 22)
		av.AnchorPoint = Vector2.new(0.5, 1)
		av.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		av.BorderSizePixel = 0
		av.ScaleType = Enum.ScaleType.Crop
		av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=48&h=48"
		av.ZIndex = 5
		av.Visible = false
		av.Parent = ov
		local avc = Instance.new("UICorner")
		avc.CornerRadius = UDim.new(0, 4)
		avc.Parent = av
		local avs = Instance.new("UIStroke")
		avs.Thickness = 1.5
		avs.Color = WHITE
		avs.Parent = av
		local hint = Instance.new("TextLabel")
		hint.BackgroundTransparency = 1
		hint.AnchorPoint = Vector2.new(0.5, 1)
		hint.Position = UDim2.new(0.5, 0, 1, -2)
		hint.Size = UDim2.new(1, 0, 0, 12)
		hint.Text = "tap: pause / spin"
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 9
		hint.TextColor3 = WHITE
		hint.TextTransparency = 0.6
		hint.ZIndex = 5
		hint.Parent = ov

		local model, charRef, hl = nil, nil, nil
		local orig = {}
		local yaw, paused, lastKey = 0.4, false, nil
		view.MouseButton1Click:Connect(function() paused = not paused end)

		local function buildModel()
			if model then pcall(function() model:Destroy() end) end
			model, hl = nil, nil
			table.clear(orig)
			local ch = player.Character
			charRef = ch
			if not ch then return end
			local okc, cl = pcall(function()
				local old = ch.Archivable
				ch.Archivable = true
				local x2 = ch:Clone()
				ch.Archivable = old
				return x2
			end)
			if not okc or not cl then return end
			for _, d in ipairs(cl:GetChildren()) do
				if d:IsA("Tool") then d:Destroy() end
			end
			for _, d in ipairs(cl:GetDescendants()) do
				pcall(function()
					if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ParticleEmitter") or d:IsA("BillboardGui")
						or d:IsA("Highlight") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("ForceField") then
						d:Destroy()
					elseif d:IsA("Humanoid") then
						d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					elseif d:IsA("BasePart") then
						d.Anchored = true
						pcall(function() d.LocalTransparencyModifier = 0 end)
						if d.Name == "HumanoidRootPart" then d.Transparency = 1 end
						orig[d] = {d.Color, d.Material, d.Transparency}
					end
				end)
			end
			pcall(function() cl:PivotTo(CFrame.new()) end)
			cl.Parent = vp
			model = cl
			local okb, bcf, bsize = pcall(function() return cl:GetBoundingBox() end)
			local sizeY = okb and bsize.Y or 5.5
			local mid = okb and bcf.Position or Vector3.zero
			local dist = (sizeY / 2) / math.tan(math.rad(vcam.FieldOfView / 2)) * 1.55
			vcam.CFrame = CFrame.lookAt(mid + Vector3.new(0, 0, -dist), mid)
		end

		local function paint()
			local on, mode, col = ST.chamsfx, P.ChamsMode, P.ChamsColor
			for part, o in pairs(orig) do
				if part.Parent and o[3] < 1 then
					if on and mode == "Default" then
						part.Material, part.Color, part.Transparency = Enum.Material.Neon, col, 0.2
					elseif on and mode == "Ghost" then
						part.Material, part.Color, part.Transparency = Enum.Material.ForceField, col, o[3]
					elseif on and mode == "Outline" then
						part.Material, part.Color, part.Transparency = o[2], o[1]:Lerp(col, 0.25), o[3]
					else
						part.Material, part.Color, part.Transparency = o[2], o[1], o[3]
					end
				end
			end
			if on and mode == "Outline" and model then
				if not hl or hl.Parent ~= model then
					pcall(function()
						hl = Instance.new("Highlight")
						hl.Parent = model
					end)
				end
				if hl then
					pcall(function()
						hl.FillTransparency = 1
						hl.OutlineTransparency = 0
						hl.OutlineColor = col
						hl.FillColor = col
						hl.Enabled = true
					end)
				end
			elseif hl then
				pcall(function() hl.Enabled = false end)
			end
		end

		local function overlay()
			local W, H = view.AbsoluteSize.X, view.AbsoluteSize.Y
			if W < 10 or H < 10 then return end
			local tanH = math.tan(math.rad(vcam.FieldOfView) / 2)
			local function proj(pos)
				local rel = vcam.CFrame:PointToObjectSpace(pos)
				local z = -rel.Z
				if z <= 0.05 then return nil end
				local hh = 2 * z * tanH
				local ww = hh * (W / H)
				return Vector2.new(W / 2 + rel.X / ww * W, H / 2 - rel.Y / hh * H)
			end
			local top = proj(Vector3.new(0, 3, 0))
			local bot = proj(Vector3.new(0, -3, 0))
			if not (top and bot) then return end
			local height = bot.Y - top.Y
			local width = height / 2
			local cx = top.X
			local x1, x2, y1, y2 = cx - width / 2, cx + width / 2, top.Y, bot.Y
			local tt = os.clock()
			if ST.esp then
				pbox.update(x1, y1, width, height, P.BoxStyle, true, ST.boxfill,
					Feat.gradFor(P.BoxColor, tt, 0, P.BoxGrad, P.BoxGrad2), Feat.gradFor(P.FillColor, tt, 0.8, P.BoxGrad, P.BoxGrad2), (tt * 50) % 360)
			else
				pbox.hide()
			end
			if ST.espline then
				seg(lineL, Vector2.new(W / 2, H), Vector2.new(cx, y2), WHITE, 1.5)
				lineGrad.Color = Feat.gradFor(P.LineColor, tt, 1.6, P.LineGrad, P.LineGrad2)
			else
				lineL.Visible = false
			end
			if ST.avatar then
				av.Position = UDim2.fromOffset(cx, y1 - 4)
				av.Visible = true
			else
				av.Visible = false
			end
		end

		table.insert(connections, RunService.RenderStepped:Connect(function(dt)
			if not (visualTab.page.Visible and menu.Visible) then return end
			if player.Character ~= charRef then
				buildModel()
				lastKey = nil
			end
			if model then
				if not paused then yaw = yaw + dt * 0.7 end
				pcall(function() model:PivotTo(CFrame.Angles(0, yaw, 0)) end)
			end
			local key = tostring(ST.chamsfx) .. tostring(P.ChamsMode) .. tostring(P.ChamsGrad) .. P.ChamsColor:ToHex()
			if key ~= lastKey then
				lastKey = key
				paint()
			end
			if ST.chamsfx and P.ChamsMode == "Default" and P.ChamsGrad then
				-- same moving gradient as the real chams
				local tc = os.clock()
				local c1, c2 = P.ChamsColor, P.ChamsGrad2
				for part, o in pairs(orig) do
					if part.Parent and o[3] < 1 then
						local kk = (part.Position.Y + 3) / 6
						part.Color = c1:Lerp(c2, 0.5 + 0.5 * math.sin(tc * 1.8 + kk * 3))
					end
				end
			end
			overlay()
		end))
	end

	local PREV_H = 158
	local rowY = CARD_PAD * 2 + PREV_H
	buildPreview(visualTab.page, CARD_PAD, CARD_PAD, CARD_SIZE * 2 + CARD_PAD, PREV_H)

	local _, tE, hE = createCard(visualTab.page, "esp", CARD_PAD, rowY, {
		{text = "ESP Box", gear = true, onChange = function(v) Feat.setEsp(v) end},
		{text = "Esp Line", gear = true, onChange = function(v) Feat.setEspLine(v) end},
		{text = "Avatar", onChange = function(v) Feat.setAvatar(v) end},
	})
	attachGear(tE[1], spEsp)
	attachGear(tE[2], spLine)

	local _, tCh, hCh = createCard(visualTab.page, "chams", COL2_X, rowY, {
		{text = "Chams", gear = true, onChange = function(v) Feat.setChamsFx(v) end},
	})
	attachGear(tCh[1], spChams)

	visualTab.page.CanvasSize = UDim2.new(0, 0, 0, rowY + math.max(hE, hCh) + CARD_PAD)
end

-- ---------- WORLD (sub-tab of Visual) ----------
do
	local spTrail = createSettings("trail", {
		{type = "color", text = "Trail Color", default = Feat.P.TrailColor, onChange = function(c)
			Feat.P.TrailColor = c
		end},
	})
	local spDTrail = createSettings("double trail", {
		{type = "color", text = "Trail Color", default = Feat.P.DTrailColor, onChange = function(c)
			Feat.P.DTrailColor = c
		end},
	})
	local spJumpC = createSettings("jump circle", {
		{type = "input", text = "Radius (studs)", default = Feat.P.JumpRadius, onChange = function(n)
			Feat.P.JumpRadius = math.clamp(n, 1, 80)
		end},
		{type = "color", text = "Circle Color", default = Feat.P.JumpColor, onChange = function(c)
			Feat.P.JumpColor = c
		end},
	})

	local _, tT, hT = createCard(worldTab.page, "trail", CARD_PAD, CARD_PAD, {
		{text = "Trail", gear = true, onChange = function(v) Feat.setTrail(v) end},
		{text = "Double Trail", gear = true, onChange = function(v) Feat.setDoubleTrail(v) end},
	})
	attachGear(tT[1], spTrail)
	attachGear(tT[2], spDTrail)

	local _, tJ, hJ = createCard(worldTab.page, "effects", COL2_X, CARD_PAD, {
		{text = "Jump Circle", gear = true, onChange = function(v) Feat.setJumpCircle(v) end},
	})
	attachGear(tJ[1], spJumpC)

	-- ===================== WORLD processing: Visual FX (ported from the Zenith script) =====================
	local W = {
		shaders = false, grade = true, blackSky = true, fogOn = true, fog = 350, density = 0.45,
		bloom = 1.6, contrast = 0.3, sat = 0.4, dof = 0.12, bright = 1.6,
		fullbright = false, xray = false, xrayTransp = 0.6, potato = false,
	}
	Feat.W = W

	local look = {
		tint = Color3.fromRGB(190, 215, 255),
		amb = Color3.fromRGB(40, 80, 170),
		fogColor = Color3.fromRGB(25, 70, 200),
	}
	local PRESETS = {
		BlueFog = {tint = Color3.fromRGB(190, 215, 255), amb = Color3.fromRGB(40, 80, 170),
			fogColor = Color3.fromRGB(25, 70, 200), bloom = 1.6, sat = 0.4, fog = 350, density = 0.45},
		Neon = {tint = Color3.fromRGB(215, 190, 255), amb = Color3.fromRGB(70, 60, 110),
			fogColor = Color3.fromRGB(90, 40, 200), bloom = 1.8, sat = 0.5, fog = 500, density = 0.3},
		Ice = {tint = Color3.fromRGB(200, 235, 255), amb = Color3.fromRGB(90, 130, 190),
			fogColor = Color3.fromRGB(120, 180, 255), bloom = 1.0, sat = 0.2, fog = 250, density = 0.6},
		Abyss = {tint = Color3.fromRGB(150, 190, 255), amb = Color3.fromRGB(15, 35, 90),
			fogColor = Color3.fromRGB(5, 20, 80), bloom = 1.2, sat = 0.3, fog = 150, density = 0.7},
	}
	local PRESET_NAMES = {"BlueFog", "Neon", "Ice", "Abyss"}

	-- ---------- shaders ----------
	local sh = {fx = nil, saved = nil, removed = {}}

	local function shadersOn()
		if sh.fx then
			-- the game may have thrown our effects out: put them back
			for k, v in pairs(sh.fx) do
				if k ~= "sky" and v.Parent ~= Lighting then v.Parent = Lighting end
			end
			return
		end
		sh.saved = {
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness, ExposureCompensation = Lighting.ExposureCompensation,
			FogColor = Lighting.FogColor, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
			ClockTime = Lighting.ClockTime,
		}
		sh.removed = {}
		for _, v in ipairs(Lighting:GetChildren()) do
			if (v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky")) and v.Name ~= "MellowynBlur" then
				sh.removed[#sh.removed + 1] = v
				v.Parent = nil
			end
		end
		local fx = {}
		fx.bloom = Instance.new("BloomEffect", Lighting)
		fx.cc = Instance.new("ColorCorrectionEffect", Lighting)
		fx.rays = Instance.new("SunRaysEffect", Lighting)
		fx.dof = Instance.new("DepthOfFieldEffect", Lighting)
		fx.atm = Instance.new("Atmosphere", Lighting)
		fx.sky = Instance.new("Sky")
		fx.sky.StarCount = 0
		fx.sky.CelestialBodiesShown = false
		sh.fx = fx
	end

	local function shadersApply()
		local fx = sh.fx
		if not fx then return end
		local g = W.grade -- Color Grade off = bloom / contrast / saturation / blur / brightness neutral
		fx.bloom.Intensity, fx.bloom.Size, fx.bloom.Threshold = g and W.bloom or 0, 45, 0.75
		fx.cc.Contrast, fx.cc.Saturation, fx.cc.TintColor = g and W.contrast or 0, g and W.sat or 0, look.tint
		fx.rays.Intensity, fx.rays.Spread = 0.15, 0.8
		fx.dof.FarIntensity, fx.dof.NearIntensity = g and W.dof or 0, 0
		fx.dof.FocusDistance, fx.dof.InFocusRadius = 60, 80
		fx.atm.Density = W.fogOn and W.density or 0
		fx.atm.Haze = W.fogOn and 2 or 0
		fx.atm.Offset = 0.2
		fx.atm.Color, fx.atm.Decay = look.fogColor, look.fogColor
		Lighting.Ambient, Lighting.OutdoorAmbient = look.amb, look.amb
		Lighting.Brightness = g and W.bright or 2
		Lighting.ExposureCompensation = 0.3
		Lighting.FogColor, Lighting.FogStart = look.fogColor, 0
		Lighting.FogEnd = W.fogOn and W.fog or 100000
		if W.blackSky then Lighting.ClockTime = 0 end
		fx.sky.Parent = W.blackSky and Lighting or nil
	end

	local function shadersOff()
		local fx = sh.fx
		if not fx then return end
		sh.fx = nil
		for _, v in pairs(fx) do pcall(function() v:Destroy() end) end
		for _, v in ipairs(sh.removed) do pcall(function() v.Parent = Lighting end) end
		sh.removed = {}
		if sh.saved then
			for k, v in pairs(sh.saved) do pcall(function() Lighting[k] = v end) end
		end
	end

	local function setShaders(v)
		W.shaders = v
		if v then
			shadersOn()
			shadersApply()
		else
			shadersOff()
		end
	end
	local function reshade()
		if W.shaders then shadersApply() end
	end
	local function applyPreset(name)
		local p = PRESETS[name]
		if not p then return end
		look.tint, look.amb, look.fogColor = p.tint, p.amb, p.fogColor
		W.bloom, W.sat, W.fog, W.density = p.bloom, p.sat, p.fog, p.density
		reshade()
	end

	-- the game keeps resetting the lighting: re-apply once a second while shaders are on
	task.spawn(function()
		while screenGui.Parent do
			if W.shaders then
				pcall(function()
					shadersOn()
					shadersApply()
				end)
			end
			task.wait(1)
		end
	end)

	-- ---------- fullbright ----------
	local fbSaved
	local function fbRestore()
		if fbSaved then
			for k, v in pairs(fbSaved) do pcall(function() Lighting[k] = v end) end
			fbSaved = nil
		end
	end
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				if W.fullbright and not W.shaders then
					if not fbSaved then
						fbSaved = {
							Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
							GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
							OutdoorAmbient = Lighting.OutdoorAmbient,
						}
					end
					Lighting.Brightness = 2
					Lighting.ClockTime = 14
					Lighting.FogEnd = 100000
					Lighting.GlobalShadows = false
					Lighting.Ambient = Color3.fromRGB(180, 180, 180)
					Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
				elseif fbSaved and not W.fullbright then
					fbRestore()
				end
			end)
			task.wait(0.5)
		end
	end)

	-- ---------- x-ray (the map becomes see-through) ----------
	local xr = {map = nil, saved = {}}
	local function xrSkip(part)
		local n = part.Name
		if n:find("Coin", 1, true) or n:find("Spawn", 1, true) or n == "GunDrop" or n == "HumanoidRootPart" then
			return true
		end
		local m = part:FindFirstAncestorOfClass("Model")
		if m and m:FindFirstChildOfClass("Humanoid") then return true end
		return false
	end
	local function xrApply(part)
		if not part:IsA("BasePart") or xr.saved[part] ~= nil then return end
		if part.Transparency >= W.xrayTransp or xrSkip(part) then return end
		xr.saved[part] = part.Transparency
		part.Transparency = W.xrayTransp
	end
	local function xrRestore()
		for part, t in pairs(xr.saved) do
			pcall(function() part.Transparency = t end)
		end
		table.clear(xr.saved)
		xr.map = nil
	end
	local function xrRefresh()
		for part in pairs(xr.saved) do
			pcall(function() part.Transparency = W.xrayTransp end)
		end
	end
	table.insert(connections, workspace.DescendantAdded:Connect(function(d)
		if W.xray and xr.map and d:IsA("BasePart") and d:IsDescendantOf(xr.map) then
			xrApply(d)
		end
	end))
	task.spawn(function()
		while screenGui.Parent do
			pcall(function()
				if W.xray then
					local m = Feat.findMap()
					if m ~= xr.map then
						xrRestore()
						xr.map = m
						if m then
							local n = 0
							for _, d in ipairs(m:GetDescendants()) do
								xrApply(d)
								n = n + 1
								if n % 400 == 0 then task.wait() end
							end
						end
					end
				elseif next(xr.saved) then
					xrRestore()
				end
			end)
			task.wait(1)
		end
	end)

	-- ---------- potato / studs graphics ----------
	local function isOurs(d)
		local a = d
		while a and a ~= workspace do
			if a.Name:sub(1, 8) == "Mellowyn" then return true end
			if a:IsA("Model") and a:FindFirstChildOfClass("Humanoid") then return true end
			a = a.Parent
		end
		return false
	end

	local potSaved, potLight, potActive = {}, nil, false
	local function potatoRestore()
		for d, v in pairs(potSaved) do
			if d.Parent then
				pcall(function()
					if d:IsA("BasePart") then
						d.Material, d.Reflectance = v[1], v[2]
					elseif d:IsA("Decal") or d:IsA("Texture") then
						d.Transparency = v[1]
					else
						d.Enabled = v[1]
					end
				end)
			end
		end
		table.clear(potSaved)
		if potLight then
			for k, v in pairs(potLight) do pcall(function() Lighting[k] = v end) end
			potLight = nil
		end
		pcall(function() workspace.Terrain.Decoration = true end)
		potActive = false
	end
	local function potatoApply()
		potActive = true
		if not potLight then
			potLight = {GlobalShadows = Lighting.GlobalShadows, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
				EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale}
		end
		Lighting.GlobalShadows = false
		pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
		pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
		pcall(function() workspace.Terrain.Decoration = false end)
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			n = n + 1
			if n % 1500 == 0 then task.wait() end
			if potSaved[d] == nil then
				if d:IsA("BasePart") then
					if not isOurs(d) then
						potSaved[d] = {d.Material, d.Reflectance}
						d.Material = Enum.Material.SmoothPlastic
						d.Reflectance = 0
					end
				elseif d:IsA("Decal") or d:IsA("Texture") then
					if not isOurs(d) then
						potSaved[d] = {d.Transparency}
						d.Transparency = 1
					end
				elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
					if not isOurs(d) then
						potSaved[d] = {d.Enabled}
						d.Enabled = false
					end
				end
			end
		end
	end

	local studSaved, studActive = {}, false
	local SURF = {"TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface"}
	local function studsRestore()
		for d, o in pairs(studSaved) do
			if d.Parent then
				pcall(function()
					d.Material = o[1]
					for k, nm in ipairs(SURF) do d[nm] = o[k + 1] end
				end)
			end
		end
		table.clear(studSaved)
		studActive = false
	end
	local function studsApply()
		studActive = true
		local n = 0
		for _, d in ipairs(workspace:GetDescendants()) do
			n = n + 1
			if n % 1500 == 0 then task.wait() end
			if d:IsA("Part") and studSaved[d] == nil and not isOurs(d) then
				local o = {d.Material}
				for k, nm in ipairs(SURF) do o[k + 1] = d[nm] end
				studSaved[d] = o
				d.Material = Enum.Material.Plastic
				for _, nm in ipairs(SURF) do d[nm] = Enum.SurfaceType.Studs end
			end
		end
	end
	task.spawn(function()
		while screenGui.Parent do
			if false and W.studs then
				pcall(studsApply)
			elseif studActive then
				pcall(studsRestore)
			end
			task.wait(4)
		end
	end)
	task.spawn(function()
		while screenGui.Parent do
			if W.potato then
				pcall(potatoApply)
			elseif potActive then
				pcall(potatoRestore)
			end
			task.wait(4)
		end
	end)

	screenGui.Destroying:Connect(function()
		pcall(shadersOff)
		pcall(fbRestore)
		pcall(xrRestore)
		pcall(potatoRestore)
		pcall(studsRestore)
	end)

	-- ---------- UI: every Zenith world option, small cards + side panels ----------
	local function num(lo, hi, key, after)
		return function(n)
			W[key] = math.clamp(n, lo, hi)
			if after then after() end
		end
	end

	local spShaders, spGrade
	spShaders = createSettings("shaders", {
		{type = "dropdown", options = PRESET_NAMES, default = "BlueFog", onChange = function(name)
			applyPreset(name)
			-- the preset moves these values: show them
			spShaders.setText(4, W.fog)
			spShaders.setText(5, W.density)
			spGrade.setText(1, W.bloom)
			spGrade.setText(3, W.sat)
		end},
		{type = "toggle", text = "Black Sky", default = true, onChange = function(v) W.blackSky = v reshade() end},
		{type = "toggle", text = "Fog", default = true, onChange = function(v) W.fogOn = v reshade() end},
		{type = "input", text = "Fog Distance", default = W.fog, onChange = num(50, 2000, "fog", reshade)},
		{type = "input", text = "Fog Density", default = W.density, onChange = num(0, 1, "density", reshade)},
	})
	spGrade = createSettings("color grade", {
		{type = "input", text = "Bloom", default = W.bloom, onChange = num(0, 4, "bloom", reshade)},
		{type = "input", text = "Contrast", default = W.contrast, onChange = num(-0.5, 1, "contrast", reshade)},
		{type = "input", text = "Saturation", default = W.sat, onChange = num(-1, 1, "sat", reshade)},
		{type = "input", text = "Blur", default = W.dof, onChange = num(0, 1, "dof", reshade)},
		{type = "input", text = "Brightness", default = W.bright, onChange = num(0, 5, "bright", reshade)},
	})
	local spXray = createSettings("x-ray", {
		{type = "input", text = "Transparency", default = W.xrayTransp, onChange = num(0.1, 0.9, "xrayTransp", xrRefresh)},
	})

	local y1 = CARD_PAD * 2 + hT
	local _, tS, hS = createCard(worldTab.page, "shaders", CARD_PAD, y1, {
		{text = "Visual FX", gear = true, onChange = function(v) setShaders(v) end},
		{text = "Color Grade", gear = true, onChange = function(v) W.grade = v reshade() end},
	})
	tS[2].set(true, true)
	attachGear(tS[1], spShaders)
	attachGear(tS[2], spGrade)

	local y2 = CARD_PAD * 2 + hJ
	local _, tW, hW = createCard(worldTab.page, "world", COL2_X, y2, {
		{text = "Fullbright", onChange = function(v) W.fullbright = v end},
		{text = "X-Ray", gear = true, onChange = function(v) W.xray = v end},
		{text = "Potato Graphics", onChange = function(v) W.potato = v end},
		})
	attachGear(tW[2], spXray)

	worldTab.page.CanvasSize = UDim2.new(0, 0, 0, math.max(y1 + hS, y2 + hW) + CARD_PAD)
end


-- ---------- AIM ----------
do
	local spSilent = createSettings("silent aim", {
		{type = "toggle", text = "Wallbang", default = false, onChange = function(v) Feat.Aim.wallbang = v end},
		{type = "input", text = "Prediction", default = Feat.Aim.predMul, onChange = function(n)
			Feat.Aim.predMul = math.clamp(n, 0, 3)
		end},
	})

	local _, tF = createCard(aimTab.page, "aim", CARD_PAD, CARD_PAD, {
		{text = "Silent Aim", gear = true, onChange = function(v)
			Feat.Aim.on = v
			if v and not Feat.Aim.hasGun() then UI.toast("No gun in your hands") end
		end},
		{text = "Auto Shoot", onChange = function(v)
			Feat.Aim.autoshoot = v
			if v and not Feat.Aim.hasGun() then UI.toast("No gun in your hands") end
		end},
		{text = "Shoot Button", onChange = function(v) btns.shoot.setVisible(v) end},
	})
	attachGear(tF[1], spSilent)

	local _, tG = createCard(aimTab.page, "murderer", COL2_X, CARD_PAD, {
		{text = "Kill All", nosave = true, onChange = function(v)
			if not v then return end
			task.spawn(function()
				Feat.Aim.killAll()
				ctrls.killall.set(false, true)
			end)
		end},
		{text = "Shoot Murderer", nosave = true, onChange = function(v)
			local ok = Feat.Aim.setShootMurderer(v)
			if v and not ok then ctrls.shootm.set(false, true) end
		end},
	})
	ctrls.killall = tG[1]
	ctrls.shootm = tG[2]
	Feat.Fling.syncUI = function()
		ctrls.invis.set(Feat.ST.invis, true)
		ctrls.aa.set(Feat.ST.antiaim, true)
		btns.invis.refresh()
	end
	Feat.Aim.onShootMurdererDone = function()
		ctrls.shootm.set(false, true)
	end
end

-- ---------- FLING ----------
do
	local page = flingTab.page
	local SQ_W = math.floor((BG_W - CARD_PAD * 4) / 3)
	local SQ_H = 126

	-- right-hand panel outside the menu: slides out while the Fling tab is open
	local spFling = createSettings("fling", {
		{type = "button", text = "Fling Sheriff", onChange = function() Feat.Fling.flingRole("Sheriff") end},
		{type = "button", text = "Fling Murderer", onChange = function() Feat.Fling.flingRole("Murderer") end},
		{type = "toggle", text = "Auto Fling Sheriff", onChange = function(v) Feat.Fling.setAutoRole("Sheriff", v) end},
		{type = "toggle", text = "Auto Fling Murderer", onChange = function(v) Feat.Fling.setAutoRole("Murderer", v) end},
	})
	local function openFlingPanel()
		for _, other in ipairs(settingsPanels) do
			if other ~= spFling and other.open then setPanelOpen(other, false) end
		end
		setPanelOpen(spFling, true)
	end
	tabState.onFling = openFlingPanel
	menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if menu.Visible and page.Visible then openFlingPanel() end
	end)

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Size = UDim2.new(1, -16, 0, 24)
	emptyLabel.Position = UDim2.new(0, 8, 0, 8)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "no other players on the server"
	emptyLabel.Font = Enum.Font.GothamMedium
	emptyLabel.TextSize = 11
	emptyLabel.TextColor3 = WHITE
	emptyLabel.TextTransparency = 0.5
	emptyLabel.Visible = false
	emptyLabel.Parent = page

	local squares = {}

	local function makeSquare(plr)
		local card = Instance.new("Frame")
		card.Name = "Player_" .. plr.Name
		card.Size = UDim2.new(0, SQ_W, 0, SQ_H)
		card.BackgroundColor3 = BLACK
		card.BackgroundTransparency = 0.10
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.Parent = page
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = card
		local cst = Instance.new("UIStroke")
		cst.Color = WHITE
		cst.Thickness = 0.8
		cst.Transparency = 0.55
		cst.Parent = card

		-- rounded avatar square on top, centred
		local av = Instance.new("ImageLabel")
		av.Size = UDim2.new(0, 40, 0, 40)
		av.AnchorPoint = Vector2.new(0.5, 0)
		av.Position = UDim2.new(0.5, 0, 0, 6)
		av.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		av.BorderSizePixel = 0
		av.ScaleType = Enum.ScaleType.Crop
		av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=100&h=100"
		av.Parent = card
		local avc = Instance.new("UICorner")
		avc.CornerRadius = UDim.new(0, 10)
		avc.Parent = av
		local avs = Instance.new("UIStroke")
		avs.Color = WHITE
		avs.Thickness = 1
		avs.Transparency = 0.5
		avs.Parent = av

		-- nickname under the avatar
		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -8, 0, 14)
		nm.Position = UDim2.new(0, 4, 0, 50)
		nm.BackgroundTransparency = 1
		nm.Text = plr.Name
		nm.Font = Enum.Font.GothamMedium
		nm.TextSize = 11
		nm.TextScaled = true
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextColor3 = WHITE
		nm.Parent = card
		local nlim = Instance.new("UITextSizeConstraint")
		nlim.MaxTextSize = 11
		nlim.MinTextSize = 7
		nlim.Parent = nm

		-- bottom: Auto Fling toggle, then the Fling button
		makeToggleRow(card, 66, "Auto Fling", function(v)
			Feat.Fling.setAutoPlayer(plr, v)
		end, 4)
		local fb = makeOutlineButton(card, "Fling")
		fb.Size = UDim2.new(1, -16, 0, 22)
		fb.Position = UDim2.new(0, 8, 0, 98)
		fb.MouseButton1Click:Connect(function()
			task.spawn(Feat.Fling.flingPlayer, plr)
		end)

		card.ZIndex = 10
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("GuiObject") then d.ZIndex = 10 end
		end
		squares[plr] = card
		return card
	end

	local function layoutSquares()
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then list[#list + 1] = plr end
		end
		table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
		local alive = {}
		for i, plr in ipairs(list) do
			alive[plr] = true
			local card = squares[plr] or makeSquare(plr)
			local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
			card.Position = UDim2.new(0, CARD_PAD + col * (SQ_W + CARD_PAD), 0, CARD_PAD + row * (SQ_H + CARD_PAD))
		end
		for plr, card in pairs(squares) do
			if not alive[plr] then
				pcall(function() card:Destroy() end)
				squares[plr] = nil
			end
		end
		emptyLabel.Visible = #list == 0
		page.CanvasSize = UDim2.new(0, 0, 0, CARD_PAD + math.ceil(#list / 3) * (SQ_H + CARD_PAD))
	end
	layoutSquares()
	table.insert(connections, Players.PlayerAdded:Connect(function() task.defer(layoutSquares) end))
	table.insert(connections, Players.PlayerRemoving:Connect(function() task.defer(layoutSquares) end))
end

-- ---------- MAP / BASE teleports (ported from the Zenith script: TP Lobby -> "TP Base", TP Map) ----------
do
	local function coinish(n)
		n = string.lower(n)
		return string.find(n, "coin", 1, true) ~= nil or string.find(n, "cand", 1, true) ~= nil
	end
	local function hasCoinBox(m, deep)
		for _, d in ipairs(deep and m:GetDescendants() or m:GetChildren()) do
			if (d:IsA("Model") or d:IsA("Folder")) and coinish(d.Name)
				and string.find(string.lower(d.Name), "container", 1, true) then
				return true
			end
		end
		return false
	end
	-- the map = the model / folder that holds the coin container
	local function findMap()
		for _, root in ipairs({workspace, RunService}) do
			for _, ch in ipairs(root:GetChildren()) do
				if (ch:IsA("Model") or ch:IsA("Folder")) and hasCoinBox(ch, false) then return ch end
			end
		end
		for _, root in ipairs({workspace, RunService}) do
			for _, ch in ipairs(root:GetChildren()) do
				if (ch:IsA("Model") or ch:IsA("Folder")) and not Players:GetPlayerFromCharacter(ch)
					and hasCoinBox(ch, true) then
					return ch
				end
			end
		end
	end
	-- the base = the lobby
	local function findLobby()
		local l = workspace:FindFirstChild("Lobby")
		if l then return l end
		for _, ch in ipairs(workspace:GetChildren()) do
			if (ch:IsA("Model") or ch:IsA("Folder")) and ch.Name:lower():find("lobby", 1, true) then return ch end
		end
	end
	local function spawnPoints(container)
		local list = {}
		if not container then return list end
		local sf = container:FindFirstChild("Spawns", true)
		local scan = sf or container
		for _, d in ipairs(scan:GetDescendants()) do
			if d:IsA("SpawnLocation") or (sf and d:IsA("BasePart")) then list[#list + 1] = d end
		end
		return list
	end
	local function destCF(container)
		if not container then return nil end
		local pts = spawnPoints(container)
		if #pts > 0 then
			return pts[math.random(#pts)].CFrame + Vector3.new(0, 4, 0)
		end
		local base = container:FindFirstChild("Base", true)
		if base and base:IsA("BasePart") then return base.CFrame + Vector3.new(0, 6, 0) end
		local ok, pv = pcall(function() return container:GetPivot() end)
		if ok then return pv + Vector3.new(0, 8, 0) end
	end
	local function tpTo(cf)
		if not cf then return false end
		local c = player.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then
			UI.toast("You are dead")
			return true -- already reported
		end
		hrp.CFrame = cf
		hrp.AssemblyLinearVelocity = Vector3.zero
		return true
	end
	local function ready()
		if Feat.ST.autofarm then
			UI.toast("Turn off Auto Farm first")
			return false
		end
		if Feat.Tp and Feat.Tp.stop then Feat.Tp.stop() end
		return true
	end

	function Feat.tpBase()
		if not ready() then return end
		local cf = destCF(findLobby())
		if not cf then
			local m = findMap()
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("SpawnLocation") and not (m and d:IsDescendantOf(m)) then
					cf = d.CFrame + Vector3.new(0, 4, 0)
					break
				end
			end
		end
		local wasInvis = Feat.ST and Feat.ST.invis
		if wasInvis then pcall(Feat.setInvis, false) end
		local ok = tpTo(cf)
		if wasInvis then task.defer(function() pcall(Feat.setInvis, true) end) end
		if not ok then UI.toast("Base not found") end
	end
	function Feat.tpMap()
		if not ready() then return end
		local wasInvis = Feat.ST and Feat.ST.invis
		if wasInvis then pcall(Feat.setInvis, false) end
		local ok = tpTo(destCF(findMap()))
		if wasInvis then task.defer(function() pcall(Feat.setInvis, true) end) end
		if not ok then UI.toast("Map not found") end
	end
	Feat.findMap = findMap
end

-- ---------- TP ----------
do
	local page = tabs.Tp.page
	local SQ_W = math.floor((BG_W - CARD_PAD * 3) / 2)
	local SQ_H = 126

	-- "V zad": stand right behind the player and keep moving back / forward
	-- speed = full back-forward cycles per second, studs = how far the back-forward travel goes
	local Tp = {speed = 2, studs = 5, near = 1.5, target = nil, conn = nil}
	Feat.Tp = Tp
	local buttons, behind = {}, {}

	local function refreshButtons()
		for plr, b in pairs(buttons) do
			if b.Parent then b.Text = (Tp.target == plr) and "Stop" or "Tp" end
		end
	end

	local function mine()
		local c = player.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if c and hrp and hum and hum.Health > 0 then return c, hrp end
	end
	local function theirs(plr)
		local c = plr.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if c and hrp and hum and hum.Health > 0 then return c, hrp end
	end

	function Tp.stop()
		if Tp.conn then Tp.conn:Disconnect() end
		Tp.conn, Tp.target = nil, nil
		refreshButtons()
	end

	-- `d` studs behind the target (flat: follows only his yaw, not tilt / ragdoll)
	local function place(hrp, tr, d)
		local look = tr.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		local pos = tr.Position - flat * d
		hrp.CFrame = CFrame.lookAt(pos, Vector3.new(tr.Position.X, pos.Y, tr.Position.Z))
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	-- osc = false: one plain teleport behind him; osc = true: teleport, then back / forward until Stop
	function Tp.go(plr, osc)
		local _, hrp = mine()
		if not hrp then UI.toast("You are dead") return end
		local _, tr = theirs(plr)
		if not tr then UI.toast(plr.Name .. " is not alive") return end
		if Feat.ST.autofarm then UI.toast("Turn off Auto Farm first") return end
		if Feat.Aim.tpBusy or (Feat.Fling and Feat.Fling.busy) then return end
		Tp.stop()
		if not osc then
			place(hrp, tr, Tp.near + 1)
			return
		end
		Tp.target = plr
		local t0 = os.clock()
		-- Stepped = before physics: Invisible / Anti Aim read this position as the real one
		Tp.conn = RunService.Stepped:Connect(function()
			if Feat.Aim.tpBusy or (Feat.Fling and Feat.Fling.busy) then return end
			local _, me = mine()
			local _, tgt = theirs(plr)
			if not me then
				Tp.stop()
				UI.toast("You are dead")
				return
			end
			if not tgt or plr.Parent ~= Players then
				Tp.stop()
				UI.toast(plr.Name .. " is gone")
				return
			end
			local f = math.max(Tp.speed, 0.1)
			local travel = math.max(Tp.studs, 0)
			local d = Tp.near + travel * (0.5 - 0.5 * math.cos((os.clock() - t0) * f * math.pi * 2))
			place(me, tgt, d)
		end)
		refreshButtons()
	end
	screenGui.Destroying:Connect(Tp.stop)

	-- right-hand panel (slides out while the Tp tab is open, like Fling): TP Base / TP Map + the "V zad" settings
	local spTp = createSettings("tp", {
		{type = "button", text = "TP Base", onChange = function() Feat.tpBase() end},
		{type = "button", text = "TP Map", onChange = function() Feat.tpMap() end},
		{type = "input", text = "V Zad Speed", default = Tp.speed, onChange = function(n)
			Tp.speed = math.clamp(n, 0.1, 20)
		end},
		{type = "input", text = "V Zad Studs", default = Tp.studs, onChange = function(n)
			Tp.studs = math.clamp(n, 0, 40)
		end},
	})
	local function openTpPanel()
		for _, other in ipairs(settingsPanels) do
			if other ~= spTp and other.open then setPanelOpen(other, false) end
		end
		setPanelOpen(spTp, true)
	end
	tabState.onTp = openTpPanel
	menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if menu.Visible and page.Visible then openTpPanel() end
	end)

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Size = UDim2.new(1, -16, 0, 24)
	emptyLabel.Position = UDim2.new(0, 8, 0, 8)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "no other players on the server"
	emptyLabel.Font = Enum.Font.GothamMedium
	emptyLabel.TextSize = 11
	emptyLabel.TextColor3 = WHITE
	emptyLabel.TextTransparency = 0.5
	emptyLabel.Visible = false
	emptyLabel.Parent = page

	local squares = {}

	local function makeSquare(plr)
		local card = Instance.new("Frame")
		card.Name = "TpPlayer_" .. plr.Name
		card.Size = UDim2.new(0, SQ_W, 0, SQ_H)
		card.BackgroundColor3 = BLACK
		card.BackgroundTransparency = 0.10
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.Parent = page
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = card
		local cst = Instance.new("UIStroke")
		cst.Color = WHITE
		cst.Thickness = 0.8
		cst.Transparency = 0.55
		cst.Parent = card

		-- avatar square on top, centred
		local av = Instance.new("ImageLabel")
		av.Size = UDim2.new(0, 40, 0, 40)
		av.AnchorPoint = Vector2.new(0.5, 0)
		av.Position = UDim2.new(0.5, 0, 0, 6)
		av.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		av.BorderSizePixel = 0
		av.ScaleType = Enum.ScaleType.Crop
		av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=100&h=100"
		av.Parent = card
		local avc = Instance.new("UICorner")
		avc.CornerRadius = UDim.new(0, 10)
		avc.Parent = av
		local avs = Instance.new("UIStroke")
		avs.Color = WHITE
		avs.Thickness = 1
		avs.Transparency = 0.5
		avs.Parent = av

		-- nickname under the avatar
		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -8, 0, 14)
		nm.Position = UDim2.new(0, 4, 0, 50)
		nm.BackgroundTransparency = 1
		nm.Text = plr.Name
		nm.Font = Enum.Font.GothamMedium
		nm.TextSize = 11
		nm.TextScaled = true
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextColor3 = WHITE
		nm.Parent = card
		local nlim = Instance.new("UITextSizeConstraint")
		nlim.MaxTextSize = 11
		nlim.MinTextSize = 7
		nlim.Parent = nm

		-- V zad toggle (its Speed / Studs live in the right-hand panel), then the Tp button
		makeToggleRow(card, 66, "V zad", function(v)
			behind[plr] = v
			if not v and Tp.target == plr then Tp.stop() end
		end, 8)
		local tb = makeOutlineButton(card, "Tp")
		tb.Size = UDim2.new(1, -16, 0, 22)
		tb.Position = UDim2.new(0, 8, 0, 98)
		tb.MouseButton1Click:Connect(function()
			if Tp.target == plr then
				Tp.stop()
				return
			end
			Tp.go(plr, behind[plr] == true)
		end)
		buttons[plr] = tb

		card.ZIndex = 10
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("GuiObject") then d.ZIndex = 10 end
		end
		squares[plr] = card
		return card
	end

	local function layoutSquares()
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then list[#list + 1] = plr end
		end
		table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
		local alive = {}
		for i, plr in ipairs(list) do
			alive[plr] = true
			local card = squares[plr] or makeSquare(plr)
			local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
			card.Position = UDim2.new(0, CARD_PAD + col * (SQ_W + CARD_PAD), 0, CARD_PAD + row * (SQ_H + CARD_PAD))
		end
		for plr, card in pairs(squares) do
			if not alive[plr] then
				pcall(function() card:Destroy() end)
				squares[plr], buttons[plr], behind[plr] = nil, nil, nil
			end
		end
		emptyLabel.Visible = #list == 0
		page.CanvasSize = UDim2.new(0, 0, 0, CARD_PAD + math.ceil(#list / 2) * (SQ_H + CARD_PAD))
	end
	layoutSquares()
	table.insert(connections, Players.PlayerAdded:Connect(function() task.defer(layoutSquares) end))
	table.insert(connections, Players.PlayerRemoving:Connect(function() task.defer(layoutSquares) end))
end

-- ---------- SKIN CHANGER ----------
-- Works on EVERYTHING knife / gun that is on you: the weapon in your hands, the ones in the backpack, the knife on your
-- back, the gun on your leg / hip, any part / model / accessory of your character whose name contains knife or gun.
do
	local page = tabs.Skin.page
	local Skin = {enabled = true, knife = "", gun = "", type = "Knife", list = {}, byKey = {}, applied = {}, lastScan = 0,
		-- weapons holstered on the body (back / leg) that are not parented to the character:
		radius = 5,        -- studs around HumanoidRootPart that are searched (only when nearScan = true)
		-- fixed body position (rotation around the mesh origin) for every variant of these three guns
		adjustPresets = {
			["gingerscope"] = "0.9986,-0.0091,-0.0525,0.0091,-0.9420,0.3354,-0.0526,-0.3354,-0.9406",
			["icepiercer"] = "0.2537,0.9587,-0.1289,-0.2103,-0.0754,-0.9747,-0.9441,0.2744,0.1825",
			["harvester"] = "0.2537,0.9587,-0.1289,-0.2103,-0.0754,-0.9747,-0.9441,0.2744,0.1825",
		},
		nearScan = false,  -- OFF: your own knife / gun displays come from DisplayRefKnife / DisplayRefGun, so other players are never touched
		deepScan = false,  -- true = walk the whole workspace (also finds parts with CanQuery = false, slower)
		debug = false,     -- print the full path of every new holstered weapon found (F9 console)
		keep = {},         -- display parts found by the last scan (not restored while they are in range)
		seen = setmetatable({}, {__mode = "k"})}
	Feat.Skin = Skin

	-- ================================================================================================
	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   PASTE SKIN DATA HERE   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	--  one skin per line:   key|name|K or G|rarity|meshId|textureId|scaleX|scaleY|scaleZ|thumbnailId|grip
	--  K = knife, G = gun; grip = K / G (or 12 numbers of a CFrame)
	--  Replace or extend EVERYTHING between  [[  and  ]]  (the lines below are only the default list)
	-- ================================================================================================
	local SKIN_DATA = [[GhostK2018|Ghost 2018|K|Legendary|121944778|2514800940|1|1|1|2513732969|K
Biogun|Biogun|G|Uncommon|79401392|4659589763|1.5|1.5|1.5|4659627458|G
Skulls_K_2021|Skulls 2021|K|Uncommon|121944778|7756610618|1|1|1|7800220325|K
AmericaGun|America|G|Classic|25298496|164669251|1.5|1.5|1.5|164676043|G
Frozen_K_2022|Frozen 2022|K|Common|121944778|4528568803|1|1|1|11834404402|K
Gingerscythe|Gingerscythe (Rare)|K|Rare|15397894467|15397714781|0.9733|0.9733|0.9733|15683138101|0,-0.9894,0,1,0,0,0,1,0,0,0,1
Gingerscythe_Legendary|Gingerscythe (Legendary)|K|Legendary|15397894467|15397484015|0.9733|0.9733|0.9733|15683140564|0,-0.9894,0,1,0,0,0,1,0,0,0,1
Jack|Jack|K|Rare|121944778|315094945|1.0005|1|1|315099010|K
Space|Space|K|Rare|957726558|3183404232|1|1|1|3183607442|K
Splash|Splash|K|Legendary|121944778|235343795|1|1|1|235371439|K
Gifts_K_2019|Gifts 2019|K|Common|957726558|4534828383|1|1|1|4534856285|K
Bones_K_2024|Bones 2024|K|Uncommon|6600901997|89105172362040|1|1|1|0|K
RandLuger|Glitch2|K|Common|121944778|191784815|1|1|1|196751515|K
Kool|Yellow|K|Common|121944778|473621021|1|1|1|473625906|K
WebbedK|Webbed|K|Common|957726558|4210410097|1|1|1|4210949599|K
Witch_K_2022|Witchbrew|K|Uncommon|957726558|11245959206|1|1|1|11254115609|K
PredatorKnife|Predator|K|Legendary|121944778|199611278|1|1|1|235372015|K
Eyeball_K_2022|Eyeball|K|Common|121944778|11217645677|1|1|1|11254065007|K
Heart_K_2023|Heart|K|Rare|10855586895|12248435132|1|1|1|12339327069|K
Tulip|Tulip|K|Common|121944778|387468258|1|1|1|387874661|K
Sharky_K_2024|Sharky|K|Rare|6600901997|18321899067|1|1|1|0|K
MLG|Shiny|K|Legendary|121944778|473623765|1|1|1|473626979|K
Slate|Slate|K|Common|121944778|161577504|1|1|1|198453556|K
Cherry|Cherry|K|Common|121944778|155195316|1|1|1|6711852603|K
Love|Love|K|Common|121944778|192527236|1|1|1|196750845|K
Snoop|Red|K|Uncommon|121944778|473621136|1|1|1|473626150|K
Linked|Linked|K|Common|121944778|172762850|1|1|1|198453528|K
Elite|Elite|K|Legendary|121944778|241077941|1|1|1|241095344|K
ZombieK2018|Zombie 2018|K|Uncommon|121944778|103728247210594|1|1|1|2513734908|K
Eyes_K_2020|Watcher 2020|K|Common|957726558|5866358413|1|1|1|5866438542|K
Aurora_K_2019|Aurora 2019|K|Rare|957726558|4534823003|1|1|1|4534860689|K
Gingerbread_K_2022|Gingerbread 2022|K|Rare|121944778|11802560347|1|1|1|11834399071|K
SlimyK|Slimy|K|Common|957726558|4210874138|1|1|1|4210932676|K
Witched|Witched|K|Legendary|957726558|4210410129|1|1|1|4210938270|K
MoltenKnife|Molten|K|Rare|121944778|472483450|1|1|1|235371809|K
Moons|Moons|K|Uncommon|121944778|531835087|1|1|1|531873154|K
VampireK2018|Vampire 2018|K|Rare|121944778|2513708625|1|1|1|2513734708|K
JD|JD|K|Legendary|121944778|559676009|1|1|1|566867312|K
Pumpkin_K_2020|Pumpkin 2020|K|Uncommon|957726558|5872477622|1|1|1|5872490600|K
Ghosts_K_2023|Ghosts 2023|K|Common|121944778|15037729398|1|1|1|15091326116|K
Fireplace_K_2023|Fireplace|K|Uncommon|121944778|15382624195|1|1|1|15635558021|K
Gift_K_2020|Wrap|K|Uncommon|121944778|6121854102|1|1|1|6121854816|K
Survivors_K_2022|Makeshift|K|Rare|121944778|11218956882|1|1|1|11254180750|K
Love_K_2023|Love 2023|K|Common|10855586895|12248652835|1|1|1|12339328595|K
Fade|Fade|K|Legendary|121944778|288136894|1|1|1|315501640|K
Branches|Branches|K|Uncommon|957726558|4210409800|1|1|1|4210943691|K
Candle_K_2020|Candle|K|Common|957726558|5872478022|1|1|1|5872491708|K
Wavy_K_2024|Wavy|K|Common|6600901997|16846003250|1|1|1|0|K
Frostflame_K_2024|Frostflame|K|Rare|6600901997|121019096457803|1|1|1|104988218477551|K
Leaves_K_2023|Leaves|K|Common|6600901997|15081802321|1|1|1|15091400883|K
Sparkle4|Sparkle4|K|Common|121944778|306917565|1|1|1|310712788|K
Wolf|Wolf|K|Uncommon|121944778|531835092|1|1|1|531873487|K
Tailslide|Tailslide|K|Common|121944778|240942385|1|1|1|305506822|K
Squire|Squire|K|Rare|121944778|243372276|1|1|1|315501560|K
Clan|Clan|K|Common|121944778|161495171|1|1|1|235366460|K
Ghosts_K_2020|Ghosts 2020|K|Uncommon|957726558|5866362606|1|1|1|5866442790|K
Ornaments_K_2020|Ornaments 2020|K|Common|957726558|6121852598|1|1|1|6121853160|K
Bats|Bats (Rare)|K|Rare|121944778|531836446|1|1|1|531873625|K
Stockings_K_2022|Stockings 2022|K|Uncommon|957726558|11824212997|1|1|1|11834392930|K
Ghastly_K_2023|Ghastly|K|Rare|121944778|15029785979|1|1|1|15091407068|K
Cookie_K_2021|Cookie|K|Uncommon|121944778|8275035982|1|1|1|8304752586|K
Web|Web|K|Legendary|121944778|315110729|1|1|1|315104004|K
Santa_K_2018|Santa 2018|K|Common|121944778|2659488082|1|1|1|2669637780|K
CandySwirl_K_2019|Candy Swirl|K|Rare|957726558|4534829449|1|1|1|4534860226|K
Cane_K_2018|Cane 2018|K|Rare|121944778|2659489980|1|1|1|2669638508|K
Meltdown_K_2023|Meltdown|K|Uncommon|957726558|15035536803|1|1|1|15091340751|K
Snowy2017|Snowy 2017|K|Rare|121944778|1268287181|1|1|1|1268705947|K
Slashed_K_2020|Slashed|K|Common|957726558|5929316036|1|1|1|5929317433|K
GreenFire|Green Fire|K|Legendary|121944778|1268253789|1|1|1|1268706374|K
Snowflakes_K_2019|Snowflakes 2019|K|Common|121944778|4534831727|1|1|1|4534855045|K
Shaded|Shaded|K|Common|957726558|4659587929|1|1|1|4659636085|K
Canes_K_2023|Canes|K|Uncommon|121944778|15381447325|1|1|1|15635574962|K
CamoKnife|Camo|K|Uncommon|121944778|3183403069|1|1|1|3183606225|K
SketchYT|Sketchy|K|Common|121944778|539831264|1|1|1|546161470|K
Hunter_K_2022|Hunter|K|Common|121944778|11246309889|1|1|1|11254154978|K
OverseerKnife|Overseer|K|Legendary|121944778|198299790|1|1|1|198458910|K
SilentNight_K_2020|Silent Night|K|Rare|957726558|6121850778|1|1|1|6121851313|K
Beach_K_2023|Beach|K|Legendary|6600901997|13894391232|1|1|1|13944136198|K
Clownfish_K_2024|Clownfish|K|Common|6600901997|18321899540|1|1|1|0|K
Moon_K_2021|Moon|K|Common|121944778|7756612294|1|1|1|7800224197|K
Skulls|Skulls|K|Legendary|957726558|4210409968|1|1|1|4210915060|K
Sweetheart|Sweetheart|K|Common|121944778|363142139|1|1|1|363150761|K
SnakebiteK|Snakebite|K|Rare|957726558|4210409981|1|1|1|4210939388|K
Waves_K_2024|Waves 2024|K|Rare|6600901997|18321898887|1|1|1|0|K
CandyCorn_K_2022|Candy Corn 2022|K|Common|121944778|11217550170|1|1|1|11254057417|K
CottonCandy|Cotton Candy|K|Legendary|121944778|435754345|1|1|1|435933179|K
Static|Static|K|Common|121944778|365566391|1|1|1|365568163|K
Bats_K_2020|Bats 2020|K|Common|957726558|5930584000|1|1|1|5930729222|K
Portal_K_2020|Portal|K|Rare|957726558|5866364902|1|1|1|5866444722|K
Gingerbread_K_2019|Gingerbread 2019|K|Uncommon|957726558|4534824961|1|1|1|4534856940|K
GhostRbx_K_2022|Ghostly|K|Uncommon|121944778|11117362816|1|1|1|11117375743|K
Rose_K_2023|Rose|K|Uncommon|10855586895|12238708500|1|1|1|12339325736|K
LMFAO|Pink|K|Uncommon|121944778|473621215|1|1|1|473626473|K
Swirl_K_2021|Swirl|K|Rare|121944778|8294015413|1|1|1|8304757110|K
Dew|Black|K|Rare|121944778|473621267|1|1|1|473626646|K
Holly_K_2018|Holly|K|Uncommon|121944778|2664997532|1|1|1|2669638990|K
Ribbon_K_2023|Ribbon|K|Common|957726558|15332484220|1|1|1|15635552019|K
Chips|Blue|K|Uncommon|121944778|473621164|1|1|1|473626317|K
Ghosts_K_2024|Ghosts 2024|K|Common|6600901997|128247285156176|1|1|1|0|K
Gingerbread2017|Gingerbread 2017|K|Rare|121944778|1268295971|1|1|1|1268705527|K
Hearts|Hearts|K|Common|121944778|363311795|1|1|1|363362737|K
Sweater_K_2018|Sweater 2018|K|Uncommon|121944778|2664997385|1|1|1|2669640567|K
Candied_K_2022|Candied|K|Common|121944778|11802560748|1|1|1|11834384755|K
Cracks_K_2021|Cracks|K|Common|121944778|7756612787|1|1|1|7800224981|K
Aurora_K_2021|Aurora 2021|K|Legendary|121944778|8275036346|1|1|1|8304750877|K
MummyK2018|Mummy 2018|K|Uncommon|121944778|2513648136|1|1|1|2513733542|K
Sparkle2|Sparkle2|K|Common|121944778|306914370|1|1|1|310710191|K
PumpkinPie_K_2023|Pumpkin Pie|K|Uncommon|121944778|15320084464|1|1|1|15413117611|K
Sparkle9|Sparkle9|K|Common|121944778|306919809|1|1|1|310715104|K
Doritos|Purple|K|Rare|121944778|473621310|1|1|1|473626740|K
Grind|Grind|K|Common|121944778|240937041|1|1|1|305503942|K
Blossom|Blossom|K|Common|121944778|363138170|1|1|1|363150561|K
Cane_K_2021|Cane 2021|K|Common|121944778|8293557762|1|1|1|8304750295|K
Sandy|Sandy|K|Common|121944778|365566396|1|1|1|365568056|K
Stainless|Stainless|K|Common|121944778|91790701|1|1|1|235366771|K
Tiger|Tiger|K|Uncommon|957726558|3183403283|1|1|1|3183606579|K
Kraken_K_2024|Kraken|K|Rare|6600901997|127474140762204|1|1|1|0|K
PumpkinPatch|Pumpkin|K|Common|957726558|4210409792|1|1|1|4210931354|K
Fusion|Fusion|K|Legendary|121944778|365566399|1|1|1|365569686|K
Future|Future|K|Uncommon|121944778|163926951|1|1|1|197639041|K
Ollie|Ollie|K|Common|121944778|240941633|1|1|1|305504399|K
ToxicK|Toxic|K|Rare|121944778|2513648163|1|1|1|2513734535|K
Dark_K_2023|Darkknife|K|Rare|121944778|15081468336|1|1|1|15091343579|K
Chromatic_K_2023|Chromatic|K|Legendary|6600901997|12927939898|1|1|1|12965304445|K
Frostfade_K_2023|Frostfade|K|Legendary|6600901997|15344578184|1|1|1|15635565488|K
Sub|Sub|K|Common|121944778|545569636|1|1|1|546159250|K
Hardened|Hardened|K|Common|957726558|3183401814|1|1|1|3183605810|K
Robot_K_2024|Robot|K|Rare|6600901997|16833551908|1|1|1|0|K
Spider_K_2023|Spider 2023|K|Common|957726558|15091217506|1|1|1|15091399982|K
Jellyfish_K_2024|Jellyfish|K|Uncommon|6600901997|18321899333|1|1|1|0|K
Circuit|Circuit|K|Uncommon|121944778|155356565|1|1|1|235366945|K
Infected_K_2022|Infected 2022|K|Common|121944778|11217988441|1|1|1|11254175272|K
HauntedK|Haunted|K|Common|121944778|2513648134|1|1|1|2513733741|K
Sweater|Sweater|K|Uncommon|121944778|1268293368|1|1|1|1268704902|K
Missing|Missing|K|Uncommon|121944778|163625649|1|1|1|198455936|K
Webs|Webs|K|Uncommon|121944778|1133322612|1|1|1|1133325465|K
DeepSea|Deep Sea|K|Rare|957726558|4659571247|1|1|1|4659634072|K
Galaxy|Galaxy|K|Rare|121944778|192367012|1|1|1|192480941|K
Spring_K_2024|Spring|K|Rare|957726558|16830850572|1|1|1|0|K
Coal_K_2022|Coal 2022|K|Common|121944778|11802560508|1|1|1|11834390120|K
Leaf|Leaf|K|Common|957726558|4659588788|1|1|1|4659636452|K
Emerald|Emerald|K|Legendary|121944778|173946596|1|1|1|198461276|K
Starry_K_2021|Starry 2021|K|Rare|121944778|8303534347|1|1|1|8304757707|K
Ginger_K_2018|Ginger 2018|K|Legendary|121944778|2659488706|1|1|1|2669638742|K
Snowfall_K_2023|Snowfall|K|Common|957726558|15381549802|1|1|1|15635568751|K
Brains|Brains|K|Common|121944778|531864479|1|1|1|531873956|K
Skool|Skool|K|Common|121944778|178200933|1|1|1|295269977|K
Valentine|Valentine|K|Common|121944778|363139123|1|1|1|363362726|K
Frosty|Frosty|K|Uncommon|121944778|1268375270|1|1|1|1268704507|K
Giftbag_K_2020|Gift Bag|K|Common|957726558|6121846201|1|1|1|6121847170|K
CandyCorn_K_2020|Candy Corn 2020|K|Common|957726558|5866354929|1|1|1|5866435364|K
Frozen_K_2019|Frozen 2019|K|Uncommon|957726558|4528568803|1|1|1|4534857523|K
OrangeMarble|Orange Marble|K|Rare|121944778|531653125|1|1|1|531873011|K
Gifted|Gifted|K|Uncommon|121944778|190131936|1|1|1|197627734|K
Dungeon|Dungeon|K|Rare|957726558|4210409814|1|1|1|4210920512|K
Sparkle5|Sparkle5|K|Common|121944778|306909649|1|1|1|310713235|K
Rainbow|Rainbow (Rare)|K|Rare|121944778|157019835|1|1|1|159747377|K
Cardboard|Cardboard|K|Common|121944778|159435782|1|1|1|235366729|K
Passion|Passion|K|Common|121944778|363139004|1|1|1|363150334|K
Rune|Rune|K|Legendary|121944778|3183404423|1|1|1|3183607894|K
Bleached|Bleached|K|Common|121944778|311711104|1|1|1|315500879|K
Vines_K_2023|Vines|K|Common|957726558|15037307112|1|1|1|15091325210|K
Snowman_K_2021|Snowman 2021|K|Uncommon|121944778|8275035798|1|1|1|8304753468|K
Ghosts_K_2021|Wraiths|K|Uncommon|121944778|7808358755|1|1|1|7808362279|K
Krypto|Krypto|K|Rare|121944778|155572642|1|1|1|198458841|K
Reptile|Reptile|K|Common|121944778|162671092|1|1|1|162672131|K
Snowflake_K_2022|Snowflake 2022|K|Uncommon|957726558|11823783274|1|1|1|11834397133|K
Eclipse_K_2023|Eclipse|K|Uncommon|121944778|15081587332|1|1|1|15091404278|K
Storm_K_2024|Storm|K|Rare|6600901997|124972846638078|1|1|1|0|K
Scratch|Scratch|K|Legendary|121944778|531835091|1|1|1|531873371|K
SantasMagic|Santa's Magic|K|Legendary|957726558|4535479726|1|1|1|4535483042|K
Palms_K_2024|Palms|K|Legendary|6600901997|18351264716|1|1|1|0|K
Darkness_K_2022|Darkness|K|Common|121944778|11217282454|1|1|1|11254081561|K
Adurite|Adurite|K|Uncommon|121944778|192482160|1|1|1|192492943|K
Prism|Prism|K|Common|121944778|297795989|1|1|1|306046703|K
Marble_K_2023|Marble|K|Uncommon|6600901997|12926768989|1|1|1|12965302237|K
Steel_K_2023|Steel|K|Uncommon|957726558|15028885294|1|1|1|15091405483|K
SantasSpirit|Santa's Spirit|K|Legendary|957726558|6123356424|1|1|1|6123357775|K
Doge|Doge|K|Uncommon|121944778|159758190|1|1|1|235371276|K
EliteBlue|Blue Elite|K|Legendary|121944778|1269369946|1|1|1|1269374321|K
Log|Log|K|Common|121944778|365566383|1|1|1|365567962|K
Bunny|Bunny|K|Common|121944778|387366668|1|1|1|387874365|K
Combat|Combat|K|Common|121944778|3183532466|1|1|1|3183604570|K
Mistletoe_K_2022|Mistletoe|K|Uncommon|957726558|11823994753|1|1|1|11834394793|K
Nether|Nether|K|Rare|121944778|166089996|1|1|1|197657098|K
Starfish_K_2024|Starfish|K|Common|6600901997|18321898656|1|1|1|0|K
Brush|Brush|K|Uncommon|121944778|5435976404|1|1|1|365568602|K
RedFire|Red Fire|K|Legendary|121944778|1269255990|1|1|1|1269256860|K
Goo|Goo|K|Common|121944778|178402851|1|1|1|237336076|K
Wanwood|Wanwood|K|Uncommon|121944778|159653725|1|1|1|192132094|K
TNL|TNL|K|Common|121944778|201480146|1|1|1|201542790|K
Stalker|Stalker|K|Uncommon|121944778|155313728|1|1|1|198455980|K
Hazard_K_2022|Hazard|K|Uncommon|121944778|11217121434|1|1|1|11254083234|K
Lovely|Lovely|K|Common|957726558|4659572197|1|1|1|4659635584|K
Copper|Copper|K|Common|121944778|3183401534|1|1|1|3183605392|K
Vampire_K_2022|Vampire 2022|K|Legendary|121944778|11215450234|1|1|1|11254125546|K
Abstract|Abstract|K|Rare|121944778|5437299417|1|1|1|365569428|K
Arctic_K_2022|Arctic|K|Legendary|121944778|11802561076|1|1|1|11834401547|K
Jigsaw|Jigsaw|K|Uncommon|121944778|365566397|1|1|1|365569126|K
Nova|Nova|K|Rare|121944778|198766824|1|1|1|235371686|K
Xbox|Xbox|K|Common|121944778|450680781|1|1|1|439325100|K
Zombie|Zombie|K|Common|121944778|1782551901|1|1|1|1133331875|K
Musical|Musical|K|Rare|121944778|365566387|1|1|1|365569566|K
Sidewinder|Sidewinder|K|Common|121944778|295302778|1|1|1|305503783|K
Choco|Choco|K|Common|121944778|386204101|1|1|1|387874991|K
Sparkle10|Sparkle10|K|Common|121944778|306921666|1|1|1|310715768|K
Sparkle8|Sparkle8|K|Common|121944778|306913268|1|1|1|310714407|K
Korblox|Korblox|K|Rare|121944778|313561541|1|1|1|315501501|K
Aqua|Aqua|K|Common|121944778|250006854|1|1|1|315501208|K
Donut|Donut|K|Uncommon|121944778|161529618|1|1|1|235366815|K
Spectrum|Spectrum|K|Rare|121944778|162718300|1|1|1|198458862|K
SlimeK|Slime|K|Common|121944778|2513648162|1|1|1|2513734227|K
Damp|Damp|K|Rare|121944778|161673042|1|1|1|198461253|K
Snowman|Snowman|K|Uncommon|121944778|5538532923|1|1|1|331745799|K
Phantom|Phantom|K|Common|121944778|1132701173|1|1|1|1133332075|K
Ice|Ice|K|Common|121944778|161313071|1|1|1|191976710|K
Denis|Denis|K|Common|121944778|539825831|1|1|1|546161062|K
BatsK|Bats (Common)|K|Common|121944778|2513648113|1|1|1|2513732731|K
Coal|Coal|K|Common|121944778|1268280806|1|1|1|1268699677|K
Hive|Hive|K|Uncommon|121944778|314921929|1|1|1|315501434|K
Euro|Euro|K|Common|121944778|240940193|1|1|1|305504173|K
Corl|Corl|K|Common|121944778|545392975|1|1|1|546161858|K
Sparkle3|Sparkle3|K|Common|121944778|306916804|1|1|1|310710694|K
Carrot|Carrot|K|Common|121944778|387418042|1|1|1|387874071|K
Oily|Oily|K|Common|121944778|314421009|1|1|1|315501170|K
Fanta|Orange|K|Common|121944778|473621067|1|1|1|473626025|K
Witch|Witch|K|Common|121944778|531836445|1|1|1|531873553|K
Midnight|Midnight|K|Legendary|121944778|161367322|1|1|1|197664126|K
Borders|Borders|K|Common|121944778|155199285|1|1|1|198453499|K
Ecto|Ecto|K|Common|121944778|1132715027|1|1|1|1133331679|K
Plasmite|Plasmite|K|Legendary|121944778|161369273|1|1|1|161369368|K
Hazmat|Hazmat|K|Uncommon|121944778|311358906|1|1|1|315501297|K
Eco|Eco|K|Common|121944778|365566401|1|1|1|365567889|K
Indy|Indy|K|Common|121944778|240943629|1|1|1|305506951|K
Lucky|Lucky|K|Uncommon|121944778|365566400|1|1|1|365569265|K
Pepper|Brown|K|Common|121944778|473620934|1|1|1|473625645|K
Cheesy|Cheesy|K|Uncommon|121944778|161425686|1|1|1|198455898|K
Ghosty|Ghosty|K|Common|121944778|531835085|1|1|1|531873080|K
Paper|Paper|K|Uncommon|121944778|179035664|1|1|1|235366870|K
Bones|Bones|K|Common|121944778|531836449|1|1|1|531873816|K
MagmaK|Magma|K|Rare|121944778|1782168732|1|1|1|1133317890|K
Melon|Melon|K|Uncommon|121944778|311701292|1|1|1|315501369|K
Neon|Neon|K|Common|121944778|159653652|1|1|1|159746637|K
Eggs|Egg|K|Common|121944778|386052294|1|1|1|387875405|K
Roses|Roses|K|Common|121944778|361630297|1|1|1|363352002|K
Sparkle1|Sparkle1|K|Common|121944778|306912202|1|1|1|310709709|K
Checker|Checker|K|Uncommon|121944778|160167441|1|1|1|198461230|K
Cane|Cane|K|Rare|121944778|5359571109|1|1|1|331140746|K
Vampire|Vampire|K|Uncommon|121944778|531835090|1|1|1|531873248|K
G_DefaultGun|Default Gun|G|Common|79401392|91723031|1.6|1.6|1.6|197518111|G
G_Fragile_G_2023|Fragile|G|Common|79401392|12942152157|1.5|1.5|1.5|12965349193|G
G_GraveG|Grave|G|Common|2514719081|2513648170|1|1|1|2513731746|G
G_Wrapped_G_2018|Wrapped 2018|G|Common|79401392|124221082305936|1.6|1.6|1.6|2669787533|G
G_Wraith_G_2022|Wraith|G|Rare|79401392|83637468346183|1.6|1.6|1.6|11255504462|G
G_Webs_G_2022|Webs|G|Common|79401392|11255255382|1.6|1.6|1.6|11284147880|G
G_WebbedG|Webbed|G|Common|79401392|130141624327731|1.6|1.6|1.6|4210936652|G
G_Wavy_G_2024|Wavy|G|Common|79401392|16846545641|1.6|1.6|1.6|0|G
G_Vines_G_2023|Vines|G|Common|79401392|15045930187|1.6|1.6|1.6|15091402817|G
G_Vampire_G_2022|Vampire 2022|G|Legendary|79401392|11228808312|1.6|1.6|1.6|11255503583|G
G_Tree_G_2022|Tree 2022|G|Rare|79401392|77983878883558|1.6|1.6|1.6|11834441321|G
G_Traveler_G_2023|Traveler|G|Legendary|79401392|89199801409332|1.6|1.6|1.6|15091344462|G
G_ToxicG|Toxic|G|Rare|79401392|2513648169|1.6|1.6|1.6|2513742519|G
G_Sweater_G_2018|Sweater 2018|G|Uncommon|79401392|2664997267|1.6|1.6|1.6|2669787088|G
G_Stockings_G_2022|Stockings 2022|G|Uncommon|79401392|11831384378|1.6|1.6|1.6|11834440319|G
G_Stockings_G_2024|Stockings 2024|G|Common|6600918074|75065116268922|0.0384|0.0388|0.0369|76288270695961|G
G_StickersX_G_2022|Stickers 2022|G|Common|79401392|11830420444|1.6|1.6|1.6|11834432971|G
G_Stickers_X_G_2024|Stickers 2024|G|Common|6600918074|139997450438464|0.0384|0.0388|0.0369|91224254479440|G
G_Stickers_G_2021|Stickers 2021|G|Common|79401392|7758615144|1.5|1.5|1.5|7800257010|G
G_Stickers_G_2024|Stickers 2024|G|Common|79401392|89311097227409|1.5|1.5|1.5|0|G
G_Steel_G_2023|Steel|G|Uncommon|79401392|15044112684|1.6|1.6|1.6|15091341552|G
G_Stars_G_2023|Stars|G|Uncommon|79401392|15383997060|1.6|1.6|1.6|15635574031|G
G_Starry_G_2020|Starry 2020|G|Common|79401392|5930583738|1.6|1.6|1.6|5930731295|G
G_Starry_G_2021|Starry 2021|G|Rare|79401392|8303507091|1.5|1.5|1.5|8304772774|G
G_Starfish_G_2024|Starfish|G|Common|79401392|18321970590|1.6|1.6|1.6|0|G
G_Star|Star|G|Common|79401392|161642996|1.5|1.5|1.5|203807904|G
G_Splat|Splat|G|Common|79401392|3183406439|1.6|1.6|1.6|3183639522|G
G_Spectral_G_2021|Spectral|G|Legendary|79401392|7757802804|1.6|1.6|1.6|7800255531|G
G_Snowman_G_2023|Snowman 2023|G|Uncommon|79401392|15382659346|1.6|1.6|1.6|15635572427|G
G_Snowman_G_2022|Snowman 2022|G|Common|79401392|11830604534|1.6|1.6|1.6|11834436620|G
G_Snowman_G_2021|Snowman 2021|G|Uncommon|79401392|8275033129|1.5|1.5|1.5|8304766932|G
G_Snowman_G_2018|Snowman 2018|G|Common|79401392|2669119107|1.6|1.6|1.6|2669786846|G
G_SnowmanGun|Snowman|G|Uncommon|79401392|332496723|1.5|1.5|1.5|332497603|G
G_Snowflakes_G_2019|Snowflakes|G|Common|79401392|4534835479|1.6|1.6|1.6|4534866065|G
G_Snowflake_G_2023|Snowflake 2023|G|Rare|79401392|15351058932|1.6|1.6|1.6|15635575718|G
G_Snowflake_G_2022|Snowflake 2022|G|Uncommon|79401392|11830940122|1.6|1.6|1.6|11834437796|G
G_Snowflake_G_2018|Snowflake 2018|G|Uncommon|79401392|2659487954|1.6|1.6|1.6|2669786515|G
G_SnakebiteG|Snakebite|G|Rare|79401392|109575851098597|1.6|1.6|1.6|4210925026|G
G_SlimeG|Slime|G|Common|79401392|2513648152|1.6|1.6|1.6|2513742319|G
G_SilentNight_G_2020|Silent Night|G|Rare|79401392|6121861331|1.6|1.6|1.6|6121862034|G
G_Santa_G_2023|Santa 2023|G|Common|79401392|15349904283|1.6|1.6|1.6|15635550625|G
G_Santa_G_2018|Elf 2018|G|Common|79401392|2664997044|1.6|1.6|1.6|2669785184|G
G_SantaGun|Santa|G|Common|79401392|76370731428901|1.5|1.5|1.5|332496861|G
G_Sandy_G_2024|Sandy|G|Common|79401392|18323743340|1.6|1.6|1.6|0|G
G_RainbowGun|Rainbow|G|Rare|79401392|3183408196|1.6|1.6|1.6|3183640145|G
G_Pumpkin_G_2023|Pumpkin|G|Common|79401392|15044730839|1.6|1.6|1.6|15091327743|G
G_PotionG2018|Potion|G|Uncommon|79401392|2513648149|1.6|1.6|1.6|2513742133|G
G_Predator|Predator|G|Legendary|79401392|202773960|1.6|1.6|1.6|203810176|G
G_Portal_G_2020|Portal|G|Uncommon|79401392|5866372960|1.6|1.6|1.6|5866461926|G
G_Popsicle_G_2024|Popsicle|G|Uncommon|79401392|18321970792|1.6|1.6|1.6|0|G
G_Pirate|Pirate|G|Uncommon|79401392|78093206510643|1.6|1.6|1.6|3183639867|G
G_Pine_G_2019|Pine|G|Common|79401392|4534870630|1.6|1.6|1.6|4534871260|G
G_Palms_G_2024|Palms|G|Legendary|79401392|18321971106|1.6|1.6|1.6|0|G
G_Ornaments_G_2020|Ornaments|G|Common|79401392|6121862915|1.6|1.6|1.6|6121863515|G
G_Ornament2Gun|Ornament2|G|Common|79401392|332496722|1.5|1.5|1.5|332497550|G
G_Ornament1Gun|Ornament1|G|Common|79401392|332358313|1.5|1.5|1.5|332497144|G
G_Nutcracker|Nutcracker|G|Uncommon|79401392|5538506180|1.5|1.5|1.5|332497657|G
G_Nuke_G_2023|Nuke|G|Rare|79401392|12936824008|1.5|1.5|1.5|12965335931|G
G_Neon_G_2023|Neon|G|Rare|79401392|15382654157|1.6|1.6|1.6|15635560825|G
G_Nightfire|Nightfire|G|Rare|79401392|4659577665|1.5|1.5|1.5|4659626966|G
G_Night|Night|G|Uncommon|79401392|159882296|1.5|1.5|1.5|159971385|G
G_Mummy_G_2020|Mummy 2020|G|Uncommon|79401392|5866372623|1.5|1.5|1.5|5866463755|G
G_MummyG2018|Mummy 2018|G|Uncommon|79401392|2513708668|1.5|1.5|1.5|2513741663|G
G_Mummy|Mummy|G|Rare|79401392|315154445|1.6|1.6|1.6|315155591|G
G_Moonlight_G_2022|Moonlight|G|Uncommon|79401392|11254380241|1.6|1.6|1.6|11284143055|G
G_Mistletoe_G_2022|Mistletoe|G|Uncommon|79401392|11831277409|1.6|1.6|1.6|11834438982|G
G_Melon_G_2023|Melon|G|Uncommon|79401392|13904908523|1.5|1.5|1.5|13944154336|G
G_Magma_G_2021|Magma|G|Rare|79401392|7758322982|1.5|1.5|1.5|7800252572|G
G_Lights_G_2019|Lights 2019|G|Uncommon|79401392|4534840659|1.5|1.5|1.5|4534872673|G
G_Latte_G_2023|Latte|G|Legendary|79401392|15320206276|1.6|1.6|1.6|15413116029|G
G_Leaves_G_2024|Leaves|G|Uncommon|79401392|105437948088593|1.5|1.5|1.5|0|G
G_Infected_G_2022|Infected|G|Common|79401392|11227996367|1.6|1.6|1.6|11255502768|G
G_Icicles_G_2018|Icicles|G|Rare|79401392|2659488496|1.6|1.6|1.6|2669786044|G
G_Icedriller_G_2020|Icedriller|G|Legendary|79401392|6121865669|1.6|1.6|1.6|6121866490|G
G_IceCamo_G_2021|Ice Camo|G|Rare|79401392|8275032575|1.6|1.6|1.6|8304767724|G
G_Holly_G_2018|Holly|G|Uncommon|79401392|2664997622|1.6|1.6|1.6|2669786261|G
G_Hazard_G_2022|Hazard|G|Uncommon|79401392|11227146152|1.6|1.6|1.6|11255505449|G
G_HauntedG|Haunted|G|Common|79401392|2513648133|1.6|1.6|1.6|2513741901|G
G_Gingerbread_G_2022|Gingerbread 2022|G|Rare|79401392|11810420546|1.6|1.6|1.6|11834442414|G
G_Gingerbread_G_2021|Gingerbread 2021|G|Uncommon|79401392|8275032201|1.6|1.6|1.6|8304772140|G
G_Gingerbread_G_2020|Gingerbread 2020|G|Uncommon|79401392|6121859173|1.6|1.6|1.6|6121860619|G
G_Gingerbread_G_2019|Gingerbread 2019|G|Uncommon|79401392|4534842979|1.5|1.5|1.5|4534872116|G
G_Ginger_G_2018|Ginger 2018|G|Legendary|79401392|2659488834|1.6|1.6|1.6|2669785821|G
G_GingerLuger|Ginger Luger|G|Godly|95356090|2674981863|1.8|1.8|1.8|2674983099|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_GingerGun|Ginger|G|Rare|79401392|140264190350882|1.5|1.5|1.5|332497038|G
G_Gifts_G_2019|Gifts|G|Common|79401392|4534835908|1.6|1.6|1.6|4534867381|G
G_Giftbag_G_2020|Gift Bag|G|Common|79401392|6121864116|1.6|1.6|1.6|6121864813|G
G_Gift_G_2020|Wrap|G|Uncommon|79401392|6121866988|1.6|1.6|1.6|6121867603|G
G_Ghosts_G_2021|Wraiths|G|Uncommon|79401392|7758397251|1.6|1.6|1.6|7800251557|G
G_Ghosts_G_2020|Ghosts|G|Rare|79401392|5866372208|1.6|1.6|1.6|5866465099|G
G_Ghostfire_G_2022|Ghostfire|G|Rare|79401392|11254634864|1.6|1.6|1.6|11284140034|G
G_GhostG2018|Ghost|G|Legendary|79401392|2513648114|1.6|1.6|1.6|2513741407|G
G_Ghastly_G_2023|Ghastly|G|Rare|79401392|15045716708|1.6|1.6|1.6|15091342564|G
G_Frozen_G_2023|Frozen 2023|G|Common|79401392|15344638282|1.6|1.6|1.6|15635571468|G
G_Frozen_G_2019|Frozen 2019|G|Uncommon|79401392|4528661973|1.5|1.5|1.5|4534873956|G
G_Frostfade_G_2023|Frostfade|G|Legendary|79401392|15383614259|1.6|1.6|1.6|15635577623|G
G_Frosted_G_2019|Frosted|G|Common|79401392|4528661069|1.6|1.6|1.6|4534866678|G
G_Floatie_G_2024|Floatie|G|Uncommon|79401392|18321972013|1.6|1.6|1.6|0|G
G_Floral_G_2024|Floral|G|Rare|79401392|18323742549|1.5|1.5|1.5|0|G
G_FallCamo_G_2021|Fall Camo|G|Uncommon|79401392|7758737021|1.6|1.6|1.6|7800257544|G
G_Eyes_G_2020|Watcher 2020|G|Common|79401392|5866372450|1.6|1.6|1.6|5866459380|G
G_Elf_G_2023|Elf 2023|G|Common|79401392|15349698419|1.6|1.6|1.6|15635569893|G
G_ElfGun|Elf|G|Common|79401392|86899632763415|1.5|1.5|1.5|332767999|G
G_DefaultGun2|Default Gun|G|Common|79401392|91723031|1.6|1.6|1.6|197518111|G
G_Dark_G_2023|Darkgun|G|Rare|79401392|15082826256|1.6|1.6|1.6|15091406343|G
G_Darkness_G_2022|Darkness|G|Common|79401392|11242038756|1.6|1.6|1.6|11255507374|G
G_Cookie_G_2021|Cookie|G|Uncommon|79401392|8275032831|1.6|1.6|1.6|8304771148|G
G_Coal_G_2022|Coal 2022|G|Common|79401392|11809114380|1.6|1.6|1.6|11834434264|G
G_Coal_G_2021|Coal 2021|G|Common|79401392|8275033614|1.6|1.6|1.6|8304769409|G
G_Coal_G_2018|Coal 2018|G|Common|79401392|2669120201|1.6|1.6|1.6|2669784920|G
G_Clownfish_G_2024|Clownfish|G|Common|79401392|18321972771|1.6|1.6|1.6|0|G
G_Cavern_G_2019|Cavern|G|Legendary|79401392|128240852390197|1.6|1.6|1.6|4534875511|G
G_Cat_G_2021|Cat|G|Common|79401392|7759004533|1.6|1.6|1.6|7800253444|G
G_Carved_G_2020|Carved|G|Common|79401392|5866372800|1.6|1.6|1.6|5866457985|G
G_Carrot_G_2024|Carrot|G|Uncommon|79401392|16856497935|1.6|1.6|1.6|0|G
G_Canes_G_2023|Canes|G|Uncommon|79401392|15383886872|1.6|1.6|1.6|15635558982|G
G_Cane_G_2021|Cane 2021|G|Common|79401392|8275031710|1.5|1.5|1.5|8304768700|G
G_CandySwirl_G_2019|Candy Swirl|G|Rare|79401392|4534836730|1.6|1.6|1.6|4534874602|G
G_Cane_G_2018|Cane 2018|G|Rare|79401392|2659489762|1.6|1.6|1.6|2669785546|G
G_CandyCorn_G_2022|Candy Corn 2022|G|Common|79401392|11226919330|1.6|1.6|1.6|11255558166|G
G_CandyCorn_G_2024|Candy Corn 2024|G|Common|79401392|110799536201694|1.5|1.5|1.5|0|G
G_CandyCorn_G_2020|Candy Corn 2020|G|Common|79401392|5866371945|1.5|1.5|1.5|5866454590|G
G_Candied_G_2022|Candied|G|Common|79401392|11809753556|1.6|1.6|1.6|11834435627|G
G_Candleflame_G_2024|Candleflame|G|Rare|79401392|115359559909377|1.5|1.5|1.5|0|G
G_Camo|Camo|G|Uncommon|79401392|160024546|1.5|1.5|1.5|160024789|G
G_Buttons|Buttons|G|Common|79401392|19458045488|1.5|1.5|1.5|0|G
G_Brains_G_2022|Brains|G|Uncommon|79401392|11254925304|1.6|1.6|1.6|11284145298|G
G_Bones2019|Bones|G|Uncommon|79401392|4210405561|1.6|1.6|1.6|4210926347|G
G_Bats_G_2024|Bats 2024|G|Common|79401392|127442391741629|1.5|1.5|1.5|0|G
G_BatsG|Bats|G|Common|79401392|2513648112|1.6|1.6|1.6|2513741174|G
G_Bacon|Bacon|G|Rare|79401392|178240361|1.5|1.5|1.5|238546467|G
G_Apoc_G_2022|Apocalypse|G|Common|79401392|11228269165|1.6|1.6|1.6|11255501940|G 
G_Arctic_G_2022|Arctic|G|Legendary|79401392|85287913991189|1.6|1.6|1.6|11834443783|G
G_Aurora_G_2019|Aurora 2019|G|Rare|79401392|70440729181948|1.5|1.5|1.5|4534875165|G
G_Aurora_G_2021|Aurora 2021|G|Legendary|79401392|96698273353001|1.5|1.5|1.5|8304766165|G
G_Asteroid|Asteroid|G|Common|79401392|6394252363|1.5|1.5|1.5|476599365|G
G_Aliens_G_2021|Aliens|G|Common|79401392|94636545088559|1.5|1.5|1.5|7800250906|G
G_Aid|Juice|G|Common|79401392|7164849213|1.5|1.5|1.5|203807397|G
G_Ace|Ace|G|Rare|79401392|178208194|1.5|1.5|1.5|238546577|G
G_Golden|Golden|G|Classic|25298496|134632723|1.5|1.5|1.5|147835357|G
G_Wooden|Wooden|G|Uncommon|79401392|84001524223260|1.5|1.5|1.5|238546356|G
G_iRevolver|iRevolver|G|Rare|79401392|160219396|1.5|1.5|1.5|203809168|G
G_Sketch|Sketch|G|Uncommon|79401392|161976144|1.5|1.5|1.5|203808108|G
G_SlouseClownGun|Clown|G|Unique|79401392|4663058089|1.5|1.5|1.5|4659627976|G
G_ZombifiedG|Zombified|G|Uncommon|79401392|137443657929688|1.5|1.5|1.5|4210944924|G
G_CaneGun|Cane|G|Rare|79401392|112112286408164|1.5|1.5|1.5|332497187|G
G_Molten|Molten|G|Rare|79401392|160570263|1.5|1.5|1.5|203869308|G
G_Galactic|Galactic|G|Rare|79401392|173912996|1.5|1.5|1.5|173913533|G
G_Engraved|Engraved|G|Common|79401392|159670413|1.5|1.5|1.5|203807690|G
G_BluesteelGun|Bluesteel|G|Uncommon|79401392|161420087|1.5|1.5|1.5|162668203|G
G_Bleed|Rupture|G|Legendary|79401392|315010891|1.5|1.5|1.5|315100702|G
G_Marina|Marina|G|Uncommon|79401392|159899596|1.5|1.5|1.5|203808190|G
G_Caution|Caution|G|Uncommon|79401392|48737841|1.5|1.5|1.5|238546422|G
G_HL2|HL2|G|Common|79401392|181689885|1.5|1.5|1.5|238546100|G
G_WaterBalloons_G_2024|Balloons|G|Common|79401392|18323742698|1.5|1.5|1.5|0|G
G_Gun1|Cowboy|G|Classic|79401392|79401500|1.5|1.5|1.5|144290769|G
G_Phaser|Phaser|G|Classic|69486593|69486519|0.8|0.8|0.8|144325423|G
G_Disint|Laser (Classic)|G|Classic|18265627|18265614|1|1|1|54798135|G
G_Imbued|Imbued|G|Rare|79401392|156263287|1.5|1.5|1.5|162668312|G
G_Cola|Soda|G|Uncommon|79401392|320398770|1.5|1.5|1.5|238546400|G
G_Gothic_G_2021|Gothic|G|Uncommon|79401392|7758572472|1.5|1.5|1.5|7800253970|G
G_Monster|Monster|G|Rare|79401392|4210409812|1.5|1.5|1.5|4210941474|G
G_RIP|RIP|G|Common|79401392|4210409923|1.5|1.5|1.5|4210947993|G
G_Shark|Shark|G|Godly|118269783|203858007|0.3|0.43|0.4|3187421705|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_SharkChroma|Shark|G|Godly|118269783|3171214838|0.44|0.44|0.44|3187421856|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_Laser|Laser|G|Godly|130099641|161254231|0.5|0.5|0.5|3187422496|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_LaserChroma|Laser|G|Godly|130099641|0|0.5|0.5|0.5|3187422628|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_LugerChroma|Luger|G|Godly|95356090|0|1.8|1.8|1.8|3187399258|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Lugercane|Lugercane|G|Godly|95356090|4535479829|1.8|1.8|1.8|4535482609|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Amerilaser|Amerilaser|G|Godly|116657254|445884341|0.7|0.7|0.7|446050753|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Blaster|Blaster|G|Godly|92656610|90586029262535|0.4|0.45|0.5|386277381|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_ChromaDarkbringer|Darkbringer|G|Godly|4730813852|4728494788|0.039|0.039|0.039|4751507011|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_ChromaLightbringer|Lightbringer|G|Godly|4730813852|4728487789|0.039|0.039|0.039|4751507078|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Darkshot|Darkshot|G|Godly|15027451531|15027451643|0.04|0.04|0.04|15080280688|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_GreenLuger|Green Luger|G|Godly|95356090|126534866|1.8|1.8|1.8|332044679|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Ocean_G|Ocean|G|Godly|13928587755|90484783616182|0.0787|0.0431|0.0468|13933165014|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_Plasmabeam|Plasmabeam|G|Godly|9702755186|10015208201|0.0424|0.0463|0.0439|10014717343|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_Blossom_G|Blossom|G|Godly|12322809632|12322809917|0.0476|0.0441|0.0438|12339377105|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_ChromaDark|Darkbringer|G|Godly|4730813852|4728494788|0.039|0.039|0.039|4751507011|0,-0.5,0.5,1,0,0,0,1,0,0,0,1
G_Constellation_G_2024|Nightsky|G|Legendary|6600918074|140562006976774|0.0384|0.0388|0.0369|94311965719769|K
G_Wrapped_G_2024|Wrapped 2024|G|Uncommon|6600918074|137311445183389|0.0384|0.0388|0.0369|109929760056853|K
G_Gingerscope|Gingerscope|G|Ancient|15374602183|15409041564|0.0842|0.0842|0.0842|15666596216|0,-0.4,0.9,1,0,0,0,1,0,0,0,1
G_Gingerscope_Blue|Blue Gingerscope|G|Unique|15374602183|100142423147247|0.0842|0.0842|0.0842|0|0,-0.42,0.97,1,0,0,0,1,0,0,0,1
G_Gingerscope_Bronze|Bronze Gingerscope|G|Unique|15374602183|93684911189915|0.0842|0.0842|0.0842|0|0,-0.42,0.97,1,0,0,0,1,0,0,0,1
G_Gingerscope_Gold|Gold Gingerscope|G|Unique|15374602183|75888854860786|0.0842|0.0842|0.0842|0|0,-0.42,0.97,1,0,0,0,1,0,0,0,1
G_Gingerscope_Silver|Silver Gingerscope|G|Unique|15374602183|129527194826480|0.0842|0.0842|0.0842|0|0,-0.42,0.97,1,0,0,0,1,0,0,0,1
G_Harvester|Harvester|G|Ancient|7775027413|7775245551|0.06|0.05|0.05|7800847534|0,-0.5366,0.4983,1,0,0,0,1,0,0,0,1
G_BlueHarvester|Blue Harvester|G|Unique|7775027413|8266618476|0.06|0.05|0.05|8194219645|0,-0.54,0.4558,1,0,0,0,1,0,0,0,1
G_BronzeHarvester|Bronze Harvester|G|Unique|7775027413|8266617019|0.06|0.05|0.05|8194221072|0,-0.52,0.4158,1,0,0,0,1,0,0,0,1
G_GoldHarvester|Gold Harvester|G|Unique|7775027413|8266613473|0.06|0.05|0.05|8194222523|0,-0.52,0.4258,1,0,0,0,1,0,0,0,1
G_SilverHarvester|Silver Harvester|G|Unique|7775027413|8266615645|0.06|0.05|0.05|8194217388|0,-0.51,0.4458,1,0,0,0,1,0,0,0,1
G_ElderwoodGun|Elderwood Revolver|G|Godly|4210029922|4210038158|0.0298|0.0298|0.0298|4468571736|-0.5676,-0.1243,-0.0424,-0.0003,0.023,-0.9997,-0.0117,0.9997,0.023,0.9999,0.0117,0
G_ElderwoodGunSilver|Silver Elderwood|G|Unique|4210029922|5357372620|0.0407|0.0456|0.0406|4468583758|-0.6706,-0.1995,-0.0658,0.0161,0.0001,-0.9999,0.0208,0.9998,0.0005,0.9997,-0.0208,0.0161
G_ElderwoodGunBlue|Blue Elderwood|G|Unique|4210029922|5827160585|0.0407|0.0456|0.0406|4468574885|-0.6706,-0.1995,-0.0658,0.0161,0.0001,-0.9999,0.0208,0.9998,0.0005,0.9997,-0.0208,0.0161
G_ElderwoodGunBronze|Bronze Elderwood|G|Unique|4210029922|5355144249|0.0407|0.0456|0.0406|4468585407|-0.6706,-0.1995,-0.0658,0.0161,0.0001,-0.9999,0.0208,0.9998,0.0005,0.9997,-0.0208,0.0161
G_ElderwoodGunGold|Gold Elderwood|G|Unique|4210029922|126940459873407|0.0407|0.0456|0.0406|4468584345|-0.6706,-0.1995,-0.0658,0.0161,0.0001,-0.9999,0.0208,0.9998,0.0005,0.9997,-0.0208,0.0161
G_Raygun|Raygun|G|Godly|115447220952926|127881437685243|0.0471|0.0471|0.0471|139431943195380|0.0009,-0.554,0.7423,1,0,0,0,1,0,0,0,1
G_RaygunSilver|Silver Raygun|G|Unique|115447220952926|133327506424645|0.0471|0.0471|0.0471|71511736314707|0.0009,-0.554,0.7423,1,0,0,0,1,0,0,0,1
G_RaygunBronze|Bronze Raygun|G|Unique|115447220952926|122251377901095|0.0471|0.0471|0.0471|138881346504998|0.0009,-0.554,0.7423,1,0,0,0,1,0,0,0,1
G_RaygunGold|Gold Raygun|G|Unique|115447220952926|128241054560504|0.0471|0.0471|0.0471|76250851065456|0.0009,-0.554,0.7423,1,0,0,0,1,0,0,0,1
G_RaygunRed|Red Raygun|G|Unique|115447220952926|104160895526874|0.0471|0.0471|0.0471|132354489228618|0.0009,-0.554,0.7423,1,0,0,0,1,0,0,0,1
G_Flora|Flora|G|Godly|108253816085047|116621225933096|0.0457|0.0457|0.0457|139276091458016|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_Snowcannon|Snowcannon|G|Godly|99836890880541|122392330922281|0.05|0.05|0.05|129186939023729|0,-0.32,0.34,1,0,0,0,1,0,0,0,1
G_Treat|Treat|G|Godly|135790480817772|86649236464456|0.0538|0.0538|0.0538|131626924640663|0,0,0.6,1,0,0,0,1,0,0,0,1
G_XenoGun|Xenoshot|G|Godly|96867436912658|103568875118220|0.0534|0.0534|0.0534|96859273002742|0.0253,-0.0153,0.8973,1,0,0,0,1,0,0,0,1
G_Blizzard|Blizzard|G|Godly|77235373292363|131115493735176|0.043|0.043|0.043|88928894807422|0,-0.57,0.75,1,0,0,0,1,0,0,0,1
G_BlizzardChroma|Blizzard|G|Godly|77235373292363|97280881789656|0.0433|0.0433|0.0433|139495852635932|0,-0.32,0.34,1,0,0,0,1,0,0,0,1
G_SunsetGun|Sunrise|G|Godly|109742397574153|71731808219690|0.0458|0.0458|0.0458|129480661108374|0,-0.1086,0.6442,1,0,0,0,1,0,0,0,1
G_FlowerwoodGun|Flowerwood Gun|G|Godly|16895099893|16895448237|0.0519|0.0519|0.0519|0|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_HeartWand|Heart Wand|K|Godly|77738838473091|76246633927299|0.0782|0.0782|0.0782|118334707962654|0,-0.8,0.1,1,0,0,0,1,0,0,0,1
G_HeartWandChroma|Heart Wand|K|Godly|77738838473091|78842905206144|0.0782|0.0782|0.0782|99154743764163|0,-0.8,0.1,1,0,0,0,1,0,0,0,1
G_Sweet|Sweet|K|Godly|88250692342609|75844398224824|0.0691|0.0691|0.0691|126937716954396|0,-1,0.1,1,0,0,0,1,0,0,0,1
G_SweetChroma|Sweet|K|Godly|88250692342609|120707737118924|0.0691|0.0691|0.0691|90923771881248|0,-1,0.1,1,0,0,0,1,0,0,0,1
G_Frostflame_G_2024|Frostflame|G|Rare|79401392|76059118984667|1.6|1.6|1.6|114781759936576|G
G_SwirlGunBronze|Bronze Swirly|G|Unique|8310911339|113787938041112|1|1|1|9552063524|G
G_SwirlGunSilver|Silver Swirly|G|Unique|8310911339|108720084988330|1|1|1|9552064240|G
G_SwirlGunBlue|Blue Swirly|G|Unique|8310911339|104958144059634|1|1|1|9552060741|G
G_SwirlGunGold|Gold Swirly|G|Unique|8310911339|122072784662988|1|1|1|9552065167|G
G_SwirlGunChroma|Swirly Gun|G|Godly|8310911339|8293539377|1|1|1|8311453396|G
G_SwirlGun|Swirly Gun|G|Godly|8310911339|97363489382281|1|1|1|8305002569|G
G_TravelerGunChroma|Traveler's Gun|G|Godly|15090814396|132537117087610|0.0499|0.0499|0.0499|15097920149|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_VampireGun|Vampire's Gun|G|Godly|126591885289479|105399657891158|0.0483|0.0483|0.0483|0|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_VampireGunChroma|Vampire's Gun|G|Godly|126591885289479|104946799389637|0.05|0.05|0.05|0|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_WatergunChroma|Watergun|G|Godly|18280999342|129036269962882|0.0395|0.0395|0.0395|18351465514|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_AuroraGun|Borealis|G|Godly|16070198638|107873598804292|0.0469|0.0469|0.0469|108635848059846|0,-0.5,0.5,0.9999,-0.0087,-0.0087,0.0087,1,0,0.0087,-0.0001,1
G_Icebeam|Icebeam|G|Godly|8310908064|8231066536|1|1|1.0002|8305000161|G
G_Iceblaster|Iceblaster|G|Godly|6125828567|6120563948|1|1|1|6121579464|G
G_IceblasterSilver|Silver Iceblaster|G|Unique|6125828567|6246950589|1|1|1|6404166698|-0.0085,-0.7,-0.546,1,0,0,0,0,-1,0,1,0
G_IceblasterBronze|Bronze Iceblaster|G|Unique|6125828567|6246948951|1|1|1|6404167442|-0.0085,-0.7,-0.546,1,0,0,0,0,-1,0,1,0
G_IceblasterGold|Gold Iceblaster|G|Unique|6125828567|6246949956|1|1|1|6404165933|-0.0085,-0.7,-0.546,1,0,0,0,0,-1,0,1,0
G_IceblasterRed|Red Iceblaster|G|Unique|6125828567|6246951385|1|1|1|6404168049|-0.0085,-0.7,-0.546,1,0,0,0,0,-1,0,1,0
G_SwirlGunChroma2|Swirly Gun|G|Godly|8310911339|8293539377|1|1|1|8311453396|G
G_Hallowgun|Hallowgun|G|Godly|5841866437|5841868338|0.0408|0.0408|0.0408|5877089721|-0.6954,-0.2885,-0.036,-0.0467,0.056,-0.9973,0,0.9984,0.056,0.9989,0.0026,-0.0466
G_Jinglegun|Jinglegun|G|Godly|6125843704|6125843755|1|1|1|6121678262|G
G_Treats_G_2025|Treats|G|Uncommon|79401392|121735248301175|1.6|1.6|1.6|76537883908961|G
G_Hologram_G_2025|Hologram|G|Rare|79401392|130121703557220|1.6|1.6|1.6|108751717527377|G
G_CandyCorn_G_2025|Candy Corn 2025|G|Common|79401392|88054952272755|1.6|1.6|1.6|129781304866793|G
G_Eyes_G_2025|Eyes|G|Uncommon|79401392|81682248459741|1.6|1.6|1.6|90751163516480|G
G_Energized_G_2025|Energized|G|Legendary|79401392|96975375477860|1.6|1.6|1.6|114403390530326|G
G_UFOs_G_2025|UFOs|G|Common|79401392|81729797666928|1.6|1.6|1.6|84030107970606|G
G_Fall_G_2025|Fall|G|Common|79401392|72560612536240|1.6|1.6|1.6|78153346812503|G
G_Xeno_G_2025|Xeno|G|Rare|79401392|88277879999522|1.6|1.6|1.6|139755862211442|G
G_Butterflies_G_2025|Butterflies|G|Rare|79401392|124763121225655|1.6|1.6|1.6|135662872427976|G
G_Meadow_G_2025|Meadow|G|Uncommon|79401392|107182071164823|1.6|1.6|1.6|107321881182350|G
G_Sunny_G_2025|Sunny|G|Rare|79401392|105937622090347|1.6|1.6|1.6|93906279038399|G
G_Heartbreak_G_2026|Heartbreak|G|Rare|79401392|102957418708034|1.6|1.6|1.6|79235438948261|G
G_Paws_G_2026|Paws|G|Uncommon|79401392|108504597564281|1.6|1.6|1.6|120089556380493|G
G_Strawberries_G_2026|Strawberries|G|Common|79401392|103202994163470|1.6|1.6|1.6|128646835922561|G
G_Plaid_G_2026|Plaid|G|Common|79401392|100185145262613|1.6|1.6|1.6|121681210724670|G
G_Forest_G_2024|Forest|G|Uncommon|79401392|114741314080418|1.6|1.6|1.6|78199422065424|G
G_Peppermint_G_2025|Peppermint|G|Common|79401392|107986046289088|1.5|1.5|1.5|73148873488539|G
G_Snowball_G_2025|Snowball|G|Common|79401392|81738515769034|1.5|1.5|1.5|104416405402940|G
G_Frozen_G_2025|Frozen 2025|G|Legendary|79401392|87079980851460|1.5|1.5|1.5|90622014285727|G
G_Gingerbread_G_2025|Gingerbread 2025|G|Uncommon|79401392|77398327971959|1.5|1.5|1.5|74908113882525|G
G_Gingercookie_G_2025|Gingercookie|G|Rare|79401392|112196863510306|1.5|1.5|1.5|99160839686845|G
G_Lights_G_2025|Lights 2025|G|Common|79401392|80557940854587|1.5|1.5|1.5|104258636970738|G
G_Spearmint_G_2025|Spearmint|G|Rare|79401392|125101257679057|1.5|1.5|1.5|81352860339620|G
G_StickersX_G_2025|Stickers 2025|G|Common|79401392|123572826899313|1.5|1.5|1.5|127489830827583|G
G_Sweater_G_2025|Sweater 2025|G|Uncommon|79401392|83785504897240|1.5|1.5|1.5|118557229750245|G
G_Greengun|Default Green|G|Common|79401392|91723031|1.5|1.5|1.5|197518111|G
Icewing|Icewing|K|Ancient|3183449780|2279588369|0.085|0.085|0.085|2669997196|-0.0001,-1,-0.1,1,0,0,0,0.8625,-0.5061,0,0.5061,0.8625
IceShard|Ice Shard|K|Godly|188539751|188539820|0.85|0.85|0.85|1268710824|-0.0001,-0.0312,1.071,1,0,0,0,-0.0842,0.9965,0,-0.9965,-0.0842
IceDragon|Ice Dragon|K|Godly|165708869|165708903|0.5|0.5|0.5|585846454|-0.0001,-0.1514,1.2029,1,0,0,0,0.0802,0.9968,0,-0.9968,0.0802
HeatChroma|Heat|K|Godly|105333894|3171194706|0.3|0.3|0.3|3187444849|K
Heat|Heat|K|Godly|105333894|105334003|0.3|0.3|0.3|3187444758|K
Handsaw|Handsaw|K|Godly|54430772|54430066|0.4|0.6|0.53|332042435|0.0031,0.0461,-0.803,-1,-0.0004,0.0029,0.0029,-0.0614,0.9981,-0.0002,0.9981,0.0614
HallowsBlade|Hallow's Blade|K|Godly|179155055|1132750758|0.55|0.55|0.555|1132775323|K
Gingermint_KChroma|Cookiecane|K|Godly|11837984324|11837984504|0.0687|0.0687|0.0687|11979596437|K
GingerbladeChroma|Gingerblade|K|Godly|2248389833|2248390749|0.61|0.61|0.6095|2672351679|-0.5814,0.7932,-0.0418,0.042,0.6372,0.7696,0.0428,-0.7707,0.6358,0.9982,0.0062,-0.0597
GemstoneChroma|Gemstone|K|Godly|1626714161|3183577898|25|25|25|3183657875|K
Gemstone|Gemstone|K|Godly|1626714161|3183579677|25|25|25|3183657748|K
Frostsaber|Frostsaber|K|Godly|1192795322|1192795941|0.55|0.55|0.6|1268934541|0,-0.0706,1.1513,1,0,0,0,-0.0286,0.9996,0,-0.9996,-0.0286
Frostbite|Frostbite|K|Godly|4528435571|4528435630|1.1|1.1|1.1|4528373246|K
Flames|Flames|K|Godly|238314098|238314124|0.6|0.8|0.73|585873746|0,0.0027,1.1242,1,0,0,0,0.0654,0.9979,0,-0.9979,0.0654
FangChroma|Fang|K|Godly|117500241|0|0.4|0.4|0.4|3187397850|0,-1,-0.1,0.0872,0,-0.9962,0,1,0,0.9962,0,0.0872
Fang|Fang|K|Godly|117500241|117500388|0.4|0.4|0.4|3187397768|0,-1,-0.1,0.0872,0,-0.9962,0,1,0,0.9962,0,0.0872
EternalCane|Eternalcane|K|Godly|3132923779|4488374804|0.95|0.95|0.95|4488391411|K
Eternal4|Eternal IV|K|Godly|3132923779|4999951444|0.95|0.95|0.95|4999958740|K
Eternal3|Eternal III|K|Godly|3132923779|3279683257|0.95|0.95|0.95|3281170430|K
Eternal2|Eternal II|K|Godly|532155954|2545251852|0.5|0.5|0.5|2545253030|K
Eternal|Eternal|K|Godly|532155954|532156041|0.45|0.45|0.45|538706317|K
DeathshardChroma|Deathshard|K|Godly|62275962|3167029738|0.75|0.75|0.75|3187397317|0,-1,-0.1001,0,0,-1,0,1,0,1,0,0
Deathshard|Deathshard|K|Godly|62275962|192567360|0.75|0.75|0.75|3175017717|0,-1,-0.1,0,0,-1,0,1,0,1,0,0
Darksword|Darksword|K|Godly|15020899066|15020899218|0.08|0.08|0.08|15080267070|K
Clockwork|Clockwork|K|Godly|352571495|352570357|1.1|1.6|1.2|360609441|0.0002,0.0291,1.1578,1,0,0,0,-0.0018,1,0,-1,-0.0018
Chill|Chill|K|Godly|105329941|105978218|0.5|0.5|0.5|332022166|K
CandleflameChroma|Candleflame|K|Godly|7791364860|7791364988|0.065|0.065|0.065|7806149582|K
BonebladeChroma|Boneblade|K|Godly|1857106669|2516324337|0.7|0.7|0.7|2513597845|K
BlueSeer|Blue Seer|K|Godly|156092238|3184062977|0.7|0.91|1|3184139996|K
BattleAxe|BattleAxe|K|Godly|1084767698|1084767901|0.56|0.56|0.56|1133237368|K
Nightblade|Nightblade|K|Godly|103838505|103838996|0.7|0.45|0.5|475478854|K
OrangeSeer|Orange Seer|K|Godly|156092238|7443788709|0.7|0.91|1|3184139504|K
Peppermint|Peppermint|K|Godly|6085025295|6074789360|0.07|0.07|0.07|6076067750|K
Phantom2022|Phantom 2022|K|Godly|121944778|95338306077286|1|1|1|11229732037|K
Pixel|Pixel|K|Godly|361629844|361630114|3|3|3|365347166|0,-0.1546,0.9239,1,0,0,0,0,1,0,-1,0
Prismatic|Prismatic|K|Godly|5355753728|5355747943|0.06|0.0692|0.06|5360359935|K
Pumpking|Pumpking|K|Godly|94840342|1133078553|0.4|0.4|0.4|1133082421|K
PurpleSeer|Purple Seer|K|Godly|156092238|3184063317|0.7|0.91|1|3184140119|K
RedSeer|Red Seer|K|Godly|156092238|3184063443|0.7|0.91|1|3184139367|K
Saw|Saw|K|Godly|168119698|168119736|0.5|0.5|0.55|3187397991|K
YellowSeer|Yellow Seer|K|Godly|156092238|7443776855|0.7|0.91|1|3184139648|K
Xmas|Xmas|K|Godly|187852667|187852629|0.6|0.6|0.6|332077449|-0.0001,-0.124,1.1068,1,0,0,0,0,1,0,-1,0
WintersEdge|Winter's Edge|K|Godly|93108071|93112631|0.45|0.45|0.45|1268708987|0,-1,-0.1,0,0,-1,0,1,0,1,0,0
Virtual|Virtual|K|Godly|130101214|386250868|0.6|0.6|0.7|386276987|K
Turkey2023|Turkey|K|Godly|15320557481|86999625612475|0.056|0.056|0.056|15413162319|K
TidesChroma|Tides|K|Godly|238314382|3171168641|0.7|0.9|0.7|3187398906|0,-0.2257,1.0324,1,0.0025,0,0,-0.0191,0.9998,0.0025,-0.9998,-0.0191
Tides|Tides|K|Godly|238314382|238314431|0.7|0.9|0.7|3187398809|0,-0.226,1.032,1,0,0,0,0.048,0.9988,0,-0.9988,0.048
TheSeer|Seer|K|Godly|156092238|156092253|0.7|0.91|1|3184139765|K
Spider|Spider|K|Godly|302165984|315122091|0.55|0.57|0.52|315120760|0,-0.15,0.973,1,0,0,0,0,1,0,-1,0
Snowflake|Snowflake|K|Godly|582120569|582120836|0.6|0.6|0.6|1268932977|K
SlasherChroma|Slasher|K|Godly|283709822|3171107559|0.45|0.45|0.45|3187398385|K
Slasher|Slasher|K|Godly|283709822|313894904|0.45|0.45|0.45|3187398274|K
SeerChroma|Seer|K|Godly|156092238|3184059718|1|1|1|3184140321|K
Scythe|Batwing|K|Ancient|305826272|2511673515|1|1|1|375690925|K
AuroraKnife|Australis|K|Godly|16025287191|97521579968070|0.0753|0.0753|0.0753|101343256002049|0,-1.1615,-0.1,1,0,0,0,1,0,0,0,1
BattleAxe2|BattleAxe II|K|Godly|2397016406|2521633652|0.7357|0.7357|0.7357|2513535503|K
Bioblade|Bioblade|K|Godly|4662600017|4751538400|0.0624|0.0684|0.066|4751540097|K
Cookieblade|Cookieblade|K|Godly|6123168377|6123168583|1|1|1|6121574620|K
Eggblade|Eggblade|K|Godly|6596834762|6596824396|0.0686|0.0686|0.0686|6607512359|K
ElderwoodScythe|Elderwood Scythe|K|Ancient|4217523241|4210044808|0.0764|0.0764|0.0764|4468593654|K
FlowerwoodKnife|Flowerwood|K|Godly|16883629972|16895441338|0.0792|0.0792|0.0792|0|K
Ghostblade|Ghostblade|K|Godly|4217554208|4210531490|0.0535|0.0535|0.0535|4217586790|K
Hallowscythe|Hallowscythe|K|Ancient|5841877975|5841879647|0.0708|0.0708|0.0708|5877016863|K
Heartblade|Heartblade|K|Godly|6404140078|6413074818|1.1003|1.1003|1.1003|6413214382|K
Iceflake|Iceflake|K|Godly|8231045240|8231046270|0.0675|0.0675|0.0675|8304818186|K
Logchopper|Logchopper|K|Ancient|4535643726|4535641077|1|1|1|4528268775|K
Nebula|Nebula|K|Godly|6596839942|6256756879|1.1522|1.1522|1.1522|6598123521|K
Pearl_K|Pearl|K|Godly|18276861801|74986100175804|0.0697|0.0697|0.0697|0|K
Plasmablade|Plasmablade|K|Godly|9702732853|10015130416|0.0018|0.0016|0.0017|10014680882|K
Rainbow_K|Rainbow (Godly)|K|Godly|12921240966|12921241867|0.0652|0.0652|0.0652|12966184630|K
Sakura_K|Sakura|K|Godly|12307707430|12307707797|0.0741|0.0741|0.0741|12339366064|K
SwirlyAxe|Swirly Axe|K|Ancient|8293463844|8293464070|0.0579|0.0579|0.0579|8304801000|K
SwirlyBlade|Swirly Blade|K|Godly|8302964090|8302965681|0.0669|0.0669|0.0669|8304805693|K
VampiresEdge|Vampire's Edge|K|Godly|5841895234|5842343736|0.067|0.067|0.067|5873256998|K
Waves_K|Waves|K|Godly|13916938702|13916939964|0.0792|0.0792|0.0793|13933066522|K
WraithKnife|Spirit|K|Godly|112444333460928|131787177447081|0.1047|0.1047|0.1047|0|K
ZombieBat|Bat|K|Godly|11182796403|11192090515|0.0741|0.0741|0.0741|11229814357|K
Icebreaker|Icebreaker|K|Ancient|6124173614|6124173821|0.9685|0.9685|0.9685|6121572723|K
SilverIcebreaker|Silver Icebreaker|K|Unique|6124173614|6237992602|1|1|1|6404126280|K
BronzeIcebreaker|Bronze Icebreaker|K|Unique|6124173614|6237991982|1|1|1|6404127119|K
GoldIcebreaker|Gold Icebreaker|K|Unique|6124173614|6237993632|1|1|1|6404115112|K
RedIcebreaker|Red Icebreaker|K|Unique|6124173614|6237994207|1|1|1|6404129111|K
Reaver|Reaver (Rare)|K|Rare|121944778|118176521118205|1|1|1|7791484774|0,-1.0087,0,1,0,0,0,1,0,0,0,1
Reaver_Legendary|Reaver (Legendary)|K|Legendary|121944778|121291446597917|1|1|1|7791485669|0,-1.0087,0,1,0,0,0,1,0,0,0,1
Reaver_Godly|Reaver (Godly)|K|Godly|7774174974|7774175135|0.25|0.2499|0.25|7791511648|0,-0.9987,-0.0037,1,0,0,0,1,0,0,0,1
Reaver_Ancient|Reaver (Ancient)|K|Ancient|7774148738|7774148967|0.2726|0.2726|0.2726|7791640819|0,-0.094,0.0422,1,0,0,0,1,0,0,0,1
TravelerAxe|Traveler's Axe|K|Ancient|15057341638|15057460725|0.0681|0.0681|0.0681|15070870271|K
TravelerAxeRed|Red Traveler's|K|Unique|15057341638|129174189928841|0.0681|0.0681|0.0681|15695405379|K
TravelerAxeSilver|Silver Traveler's|K|Unique|15057341638|125312600693078|0.0681|0.0681|0.0681|15695407742|K
TravelerAxeBronze|Bronze Traveler's|K|Unique|15057341638|87152090639814|0.0681|0.0681|0.0681|15695407020|K
TravelerAxeGold|Gold Traveler's|K|Unique|15057341638|107837737026552|0.0681|0.0681|0.0681|15695408631|K
VampireAxe|Vampire's Axe (Ancient)|K|Ancient|92263601594064|73008954478338|0.0725|0.0725|0.0725|0|K
VampireAxe_Gold|Vampire's Axe|K|Unique|92263601594064|132843202397207|0.0725|0.0725|0.0725|0|K
VampireAxe_Purple|Vampire's Axe|K|Unique|92263601594064|125726996015099|0.0725|0.0725|0.0725|0|K
VampireAxe_Bronze|Vampire's Axe|K|Unique|92263601594064|117917193798694|0.0725|0.0725|0.0725|0|K
VampireAxe_Silver|Vampire's Axe|K|Unique|92263601594064|78665201678229|0.0725|0.0725|0.0725|0|K
ElderwoodKnife|Elderwood Blade|K|Godly|11238166013|11238176757|0.07|0.07|0.07|11254879631|K
ElderwoodKnifeBlue|Blue Elderwood|K|Unique|11238166013|14741388867|0.07|0.07|0.07|11505913287|0,-1.347,0,1,0,0,0,1,0,0,0,1
ElderwoodKnifeBronze|Bronze Elderwood|K|Unique|11238166013|14741383535|0.07|0.07|0.07|11505914752|0,-1.347,0,1,0,0,0,1,0,0,0,1
ElderwoodKnifeGold|Gold Elderwood|K|Unique|11238166013|14741358103|0.07|0.07|0.07|11505917850|0,-1.347,0,1,0,0,0,1,0,0,0,1
ElderwoodKnifeSilver|Silver Elderwood|K|Unique|11238166013|14741374486|0.07|0.07|0.07|11505916486|0,-1.3468,0,1,0,0,0,1,0,0,0,1
Gingerscythe_Ancient|Gingerscythe (Ancient)|K|Ancient|15395668244|15409195246|0.0638|0.0638|0.0638|15683188776|0,-0.22,0.944,1,0,0,0,1,0,0,0,1
Gingerscythe_Godly|Gingerscythe (Godly)|K|Godly|15397282571|15409017869|0.0696|0.0696|0.0697|15683175970|0,-0.94,-0.063,1,0,0,0,1,0,0,0,1
Gingerscythe_Blue|Blue Gingerscythe|K|Unique|15397282571|125204450826311|0.0696|0.0696|0.0697|0|0,-0.94,-0.063,1,0,0,0,1,0,0,0,1
Gingerscythe_Bronze|Bronze Gingerscythe|K|Unique|15397282571|88640690300238|0.0696|0.0696|0.0697|0|0,-0.94,-0.063,1,0,0,0,1,0,0,0,1
Gingerscythe_Gold|Gold Gingerscythe|K|Unique|15397282571|87952488946515|0.0696|0.0696|0.0697|0|0,-1.1001,0,1,0,0,0,1,0,0,0,1
Gingerscythe_Silver|Silver Gingerscythe|K|Unique|15397282571|110584978259893|0.0696|0.0696|0.0697|0|0,-1.1001,0,1,0,0,0,1,0,0,0,1
Celestial|Celestial|K|Ancient|109711282082830|117556526686597|0.0533|0.0533|0.0533|136673966529736|0,0.0018,0.2811,1,0,0,0,1,0,0,0,1
Celestial_Silver|Silver Celestial|K|Unique|109711282082830|119629165572031|0.0533|0.0533|0.0533|90241292303974|0,0.002,0.281,1,0,0,0,1,0,0,0,1
Celestial_Bronze|Bronze Celestial|K|Unique|109711282082830|118098317574486|0.0533|0.0533|0.0533|119399643874968|0,0.002,0.281,1,0,0,0,1,0,0,0,1
Celestial_Gold|Gold Celestial|K|Unique|109711282082830|74186573010586|0.0533|0.0533|0.0533|104229967982042|0,0.002,0.281,1,0,0,0,1,0,0,0,1
Celestial_Red|Red Celestial|K|Unique|109711282082830|91261836086535|0.0533|0.0533|0.0533|119157529694972|0,0.002,0.281,1,0,0,0,1,0,0,0,1
Constellation|Constellation|G|Godly|124598402927958|79010754957272|0.1007|0.1007|0.1007|114197436469014|0,-0.2701,0.7265,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
ConstellationChroma|Constellation|G|Godly|124598402927958|123603327635244|0.1012|0.1012|0.1012|98517109155878|0,-0.27,0.727,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
Constellation_Silver|Silver Constellation|G|Unique|124598402927958|88000474566609|0.1007|0.1007|0.1007|100747436297625|0,-0.27,0.727,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
Constellation_Bronze|Bronze Constellation|G|Unique|124598402927958|84518828644661|0.1007|0.1007|0.1007|112811587103866|0,-0.27,0.727,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
Constellation_Gold|Gold Constellation|G|Unique|124598402927958|129541547610095|0.1007|0.1007|0.1007|132975248521820|0,-0.27,0.727,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
Constellation_Red|Red Constellation|G|Unique|124598402927958|97613309386908|0.1007|0.1007|0.1007|85766514163212|0,-0.27,0.727,1,0,0,0,0.9999,0.0125,0,-0.0125,0.9999
Icepiercer|Icepiercer|G|Ancient|11868991644|11869075814|0.0548|0.0548|0.0548|11874071041|0,-0.5819,0.0324,1,0,0,0,0.9978,-0.0658,0,0.0658,0.9978
IcepiercerSilver|Silver Icepiercer|G|Unique|11868991644|122077395445706|0.0548|0.0548|0.0548|12226843957|0,-0.66,0.2344,1,0,0,0,1,0,0,0,1
IcepiercerBronze|Bronze Icepiercer|G|Unique|11868991644|136041212037383|0.0548|0.0548|0.0548|12226920195|0,-0.66,0.234,1,0,0,0,1,0,0,0,1
IcepiercerGold|Gold Icepiercer|G|Unique|11868991644|89221956008018|0.0548|0.0548|0.0548|12226688172|0,-0.66,0.234,1,0,0,0,1,0,0,0,1
IcepiercerRed|Red Icepiercer|G|Unique|11868991644|12196203001|0.0548|0.0548|0.0548|12227133450|0,-0.66,0.234,1,0,0,0,1,0,0,0,1
Synthwave|Synthwave (Rare)|K|Rare|6600901997|139525295603551|1|1|1|84935740002917|K
Synthwave_Ancient|Synthwave (Ancient)|K|Ancient|81344146777937|84281380230931|0.0741|0.0741|0.0741|133828016595037|0.0228,-0.64,0.2496,1,0,0,0,1,0,0,0,1
Synthwave_Godly|Synthwave (Godly)|K|Godly|132672824913652|81048398253986|0.0741|0.0741|0.0741|116075729415230|-0.0142,-1.06,0.0292,1,0,0,0,1,0,0,0,1
Synthwave_Legendary|Synthwave (Legendary)|K|Legendary|6600901997|115419740311345|1|1|1|132040985617451|K
IceHammer|Icecrusher (Rare)|K|Rare|957726558|11850788417|1|1|1|11855360152|K
IceHammer_Ancient|Icecrusher (Ancient)|K|Ancient|11848711686|11850483027|0.07|0.07|0.07|11855274019|-0.0075,-1.0949,0.0014,1,0,0,0,1,0,0,0,1
IceHammer_Godly|Icecrusher (Godly)|K|Godly|11855737283|11855737599|0.07|0.07|0.07|11855282546|K
IceHammer_Legendary|Icecrusher (Legendary)|K|Legendary|957726558|11851776706|1|1|1|11855361567|K
IceHammerGold|Gold Icecrusher|K|Unique|11848711686|132842079563749|0.0736|0.0736|0.0736|12227137860|0,-0.8,0,1,0,0,0,1,0,0,0,1
IceHammerBronze|Bronze Icecrusher|K|Unique|11848711686|88591542566831|0.0736|0.0736|0.0736|12227148356|0,-0.8,0,1,0,0,0,1,0,0,0,1
IceHammerRed|Red Icecrusher|K|Unique|11848711686|71714696554176|0.0736|0.0736|0.0736|12227186408|0,-0.8,0,1,0,0,0,1,0,0,0,1
IceHammerSilver|Silver Icecrusher|K|Unique|11848711686|108890976731643|0.0736|0.0736|0.0736|12227142478|0,-0.8,0,1,0,0,0,1,0,0,0,1
Snowstorm|Snowstorm|K|Godly|127534150487935|84853425379784|0.077|0.077|0.077|70973050894155|0,-1.26,-0.1,1,0,0,0,1,0,0,0,1
SnowstormChroma|Snowstorm|K|Godly|86944837615327|86253759560362|0.077|0.077|0.077|94202294092932|0,-1.18,-0.1,1,0,0,0,1,0,0,0,1
SnowDagger|Snow Dagger|K|Godly|140633396635861|77812964601215|0.0598|0.0598|0.0598|95328449981238|0,-1.15,0,1,0,0,0,1,0,0,0,1
BaubleKnife|Ornament (Godly)|K|Godly|116508096109443|135843404105980|0.0731|0.0731|0.0731|111092946728824|0,-1.15,0,1,0,0,0,1,0,0,0,1
Bloom|Bloom|K|Godly|73266355643345|103489229144925|0.079|0.079|0.079|132419834610569|K
XenoKnife|Xenoknife|K|Godly|136619680236977|113651973865393|0.0784|0.0784|0.0784|115021756767182|0,-1.2953,0.0848,1,0,0,0,1,0,0,0,1
Bunnies_K_2025|Bunnies|K|Legendary|121944778|104875261384354|1|1|1|90549252812333|K
Carrots_K_2025|Carrots|K|Common|121944778|137285542474252|1|1|1|76914260444878|K
Chick_K_2025|Chick|K|Common|121944778|116056287470892|1|1|1|116361515042274|K
UFOs_K_2025|UFOs|K|Common|6600901997|101182606016909|1|1|1|97641024072972|K
Xeno_K_2025|Xeno|K|Rare|6600901997|101379516858862|1|1|1|80492487454400|K
HauntedHouse_K_2025|Haunted 2025|K|Common|6600901997|96264372471629|1|1|1|90194465176219|K
PumpkinPatch_K_2025|Pumpkin 2025|K|Uncommon|6600901997|92052630861897|1|1|1|119626042140839|K
Bats_K_2025|Cats|K|Common|6600901997|116130292497156|1|1|1|140366567839959|K
Abduction_K_2025|Abduction|K|Uncommon|6600901997|125213231050513|1|1|1|107510647616718|K
Treats_K_2025|Treats|K|Uncommon|6600901997|117148660034316|1|1|1|115298865715727|K
StickersH_K_2025|Stickers 2025|K|Common|6600901997|91672438499477|1|1|1|100461386281007|K
CandyCorn_K_2025|Candy Corn 2025|K|Common|6600901997|84607607123689|1|1|1|86405207895194|K
Hologram_K_2025|Hologram|K|Rare|6600901997|139678078674313|1|1|1|77773918675860|K
Energized_K_2025|Energized|K|Legendary|6600901997|104379655242590|1|1|1|86258299490709|K
StickersT2025|Stickers 2025|K|Common|6600901997|113144896198208|1|1|1|115280072896190|-0.0224,-1.0551,0.0453,1,0,0,0,1,0,0,0,1
Stickers_K_2021|Stickers 2021|K|Common|121944778|7757619418|1|1|1|7800229084|K
XmasStickers_K_2021|Stickers 2021|K|Common|121944778|8275034832|1|1|1|8304755417|K
Stickers_K_2022|Stickers 2022|K|Common|121944778|11217750489|1|1|1|11254067158|K
StickersX_K_2022|Stickers 2022|K|Common|957726558|11823434191|1|1|1|11834387858|K
Summer_Stickers_K_2023|Stickers 2023|K|Common|6600901997|13895498375|1|1|1|13944129977|K
Stickers_K_2024|Stickers 2024|K|Common|6600901997|121348523107585|1|1|1|0|K
Stickers_X_K_2024|Stickers 2024|K|Common|6600901997|109835260607049|1|1|1|83843575465564|K
StickersX_K_2025|Stickers 2025|K|Common|6600901997|130231206599976|1|1|1|102283659356|K
Decorated_K_2025|Decorated|K|Uncommon|121944778|136070215876929|1|1|1|124860763249593|K
Turtle_K_2024|Turtle|K|Uncommon|6600901997|127394910308086|1|1|1|0|K
Patrick|Patrick|K|Common|121944778|7837986943|1|1|1|383476085|0,-0.9885,0,1,0,0,0,1,0,0,0,1
Potion|Potion|K|Uncommon|121944778|1782402938|1|1|1|1133366632|0,-0.9885,0,1,0,0,0,1,0,0,0,1
Alex|Alex|K|Common|121944778|545604317|1|1|1|546159020|0,-0.9885,0,1,0,0,0,1,0,0,0,1
Combat2|Combat II|K|Common|121944778|6932358967|1|1|1|4972196241|0.0416,-1.1409,0.0773,1,0,0,0,1,0,0,0,1
EliteGreen|Green Elite|K|Legendary|121944778|137946316996767|1|1|1|332754554|0,-1.0285,0,1,0,0,0,1,0,0,0,1
Snowy|Snowy|K|Uncommon|121944778|5538538671|1|1|1|332011125|0,-0.9885,0,1,0,0,0,1,0,0,0,1
Tree|Tree|K|Legendary|121944778|5838589224|1|1|1|331745577|0,-1.0285,0,1,0,0,0,1,0,0,0,1
Tree_K_2023|Tree 2023|K|Rare|957726558|121944805|1|1|1|15635563249|K
Infected|Infected|K|Common|121944778|6978645136|1|1|1|200953094|0,0,0,1,0,0,0,1,0,0,0,1
MummyK|Mummy|K|Uncommon|121944778|91472505507923|1|1|1|1133352032|K
ZombifiedK|Zombified|K|Uncommon|121944778|114781782298919|1|1|1|4210928053|K
GreenCamo_K_2022|Zombie Camo|K|Common|121944778|121944805|1|1|1|11254145154|K
GraveK|Grave|K|Common|2514683594|2513648160|1|1|1|2513728474|K
Cane_G_2021|Cane 2021|G|Common|79401392|8275031710|1.5|1.5|1.5|8304768700|G
Cupid_K_2026|Cupid|K|Legendary|121944778|91124699102770|1|1|1|123955324398353|K
Blossom_K_2026|Blossom 2026|K|Uncommon|121944778|139596499078847|1|1|1|110160120309916|K
Hearts_K_2026|Hearts 2026|K|Common|121944778|112048035793774|1|1|1|99939659856909|K
Starry_K_2026|Starry 2026|K|Uncommon|121944778|98911990727243|1|1|1|130537925107449|K
Strawberries_K_2026|Strawberries|K|Common|121944778|75968382870233|1|1|1|73897192147749|K
Sweet_K_2026|Yummy|K|Rare|121944778|139481558107907|1|1|1|113677688954146|K
Snakebite_G_2025|Snakebite|G|Rare|79401392|11255255382|1.6|1.6|1.6|11284147880|G
Wraith_K_2022|Wraith|K|Rare|121944778|11215449757|1|1|1|11254118399|K
Runic_K_2022|Curse|K|Rare|121944778|11246439789|1|1|1|11254123390|K
Bio_K_2023|Bio|K|Rare|6600901997|12926766355|1|1|1|12965298174|K
Spring_K_2024|Spring|K|Rare|957726558|16830850572|1|1|1|0|K
Logcutter_K_2024|Logcutter|K|Rare|6600901997|73375064666195|1|1|1|71088901904009|K
Noodle_K_2023|Pool Noodle|K|Uncommon|6600901997|13895318303|1|1|1|13944133313|K
Popsicle_K_2023|Popsicle|K|Uncommon|6600901997|13884848877|1|1|1|13944131578|K
Toy_K_2023|Toy|K|Common|6600901997|13884851371|1|1|1|13944128440|K
Painted_K_2023|Painted|K|Rare|6600901997|12935208652|1|1|1|12965311567|K
Marble_K_2023|Marble|K|Uncommon|6600901997|12926768989|1|1|1|12965302237|K
Bio_K_2023_Dup|Bio|K|Rare|6600901997|12926766355|1|1|1|12965298174|K
Carrot_K_2023|Carrot 2023|K|Uncommon|6600901997|12928323969|1|1|1|12965307410|K
Fragile_K_2023|Fragile|K|Common|6600901997|12936083164|1|1|1|12965294432|K
Robot_K_2024_Dup|Robot|K|Rare|6600901997|16833551908|1|1|1|0|K
Wavy_K_2024_Dup|Wavy|K|Common|6600901997|16846003250|1|1|1|0|K
Carrot_K_2024|Carrot 2024|K|Uncommon|6600901997|16845528588|1|1|1|0|K
CandyCorn_K_2024|Candy Corn 2024|K|Common|6600901997|76315981363183|1|1|1|0|K
Snowman_K_2024|Snowman 2024|K|Uncommon|6600901997|75066955538535|1|1|1|85751270338066|K
Moons_K_2024|Moons 2024|K|Uncommon|6600901997|87244940102225|1|1|1|0|K
Wreaths_K_2024|Wreaths|K|Uncommon|6600901997|100835235112831|1|1|1|78432760615312|K
Wrapped_K_2024|Wrapped 2024|K|Uncommon|6600901997|73121682334065|1|1|1|72638846676083|K
Reindeer_K_2024|Reindeer|K|Common|6600901997|121109734938655|1|1|1|109101361674956|K
HotChocolate_K_2024|Hot Chocolate|K|Common|6600901997|105940775587606|1|1|1|133307062463653|K
Igloo_K_2024|Igloo|K|Common|6600901997|126697433046307|1|1|1|73203940450745|K
Candles_K_2024|Candles|K|Common|6600901997|137012419503995|1|1|1|0|K
Gifts_K_2024|Gifts 2024|K|Common|6600901997|80884642545249|1|1|1|129290011017110|K
Bats_K_2024|Bats 2024|K|Common|6600901997|134605667915149|1|1|1|0|K
Bones_K_2024_Dup|Bones 2024|K|Uncommon|6600901997|89105172362040|1|1|1|0|K
Monster_K_2024|Monster|K|Uncommon|6600901997|136318121608837|1|1|1|0|K
Cursed_K_2024|Cursed|K|Legendary|6600901997|137589393181339|1|1|1|0|K
Gingerheart_K_2024|Gingerheart|K|Uncommon|6600901997|77403934219171|1|1|1|115273559455814|K
Sleigh_K_2024|Sleigh|K|Rare|6600901997|85646229893233|1|1|1|74917318027165|K
Frostflame_K_2024_Dup|Frostflame|K|Rare|6600901997|121019096457803|1|1|1|104988218477551|K
Constellation_K_2024|Nightstar|K|Legendary|6600901997|125699146017319|1|1|1|113979322866878|K
Snowflakes_K_2020|Snowflakes 2020|K|Rare|121944778|137773102398455|1|1|1|6123338102|K
RbxScary_K_2023|Ghoulish|K|Common|121944778|114660299589667|1|1|1|14967668214|K
Zombie_K_2023|Zombie 2023|K|Uncommon|957726558|11218741536|1|1|1|15091339932|K
Zombified_K_2022|Zombified 2022|K|Rare|121944778|11218741536|1|1|1|11254182560|0,-1.0087,0,1,0,0,0,1,0,0,0,1
Zombie_K_2021|Zombie 2021|K|Uncommon|121944778|7845697152|1|1|1|7800222975|K
Jack_K_2022|Lantern|K|Uncommon|121944778|11245572024|1|1|1|11254093910|K
Spider_K_2023_Dup|Spider 2023|K|Common|957726558|15091217506|1|1|1|15091399982|K
Ritual_K_2024|Ritual|K|Rare|121944778|122499606241450|1|1|1|0|K]]
	-- ================================================================================================
	-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   END OF SKIN DATA   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	-- ================================================================================================

	local function trim(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	local function parseSkins()
		Skin.list, Skin.byKey = {}, {}
		for line in string.gmatch(SKIN_DATA, "[^\r\n]+") do
			if not line:match("^%s*%-%-") then
				local f = {}
				for p in string.gmatch(line, "[^|]+") do f[#f + 1] = trim(p) end
				if #f >= 11 then
					local grip
					local g = f[11]
					if g == "K" then
						grip = CFrame.new(0, -1, -0.1, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					elseif g == "G" then
						grip = CFrame.new(0, -0.7, -0.3, 1, 0, 0, 0, 0, -1, 0, 1, 0)
					else
						local n = {}
						for v in string.gmatch(g, "[^,]+") do n[#n + 1] = tonumber(v) end
						if #n >= 12 then
							grip = CFrame.new(table.unpack(n))
						else
							grip = CFrame.new(0, -1, -0.1)
						end
					end
					local s = {
						key = f[1], name = f[2],
						type = f[3] == "K" and "Knife" or "Gun",
						rarity = f[4],
						mesh = "rbxassetid://" .. f[5],
						tex = (tonumber(f[6]) or 0) ~= 0 and ("rbxassetid://" .. f[6]) or "",
						scale = Vector3.new(tonumber(f[7]) or 1, tonumber(f[8]) or 1, tonumber(f[9]) or 1),
						img = tonumber(f[10]) or 0,
						grip = grip,
					}
					if not Skin.byKey[s.key] then
						Skin.list[#Skin.list + 1] = s
						Skin.byKey[s.key] = s
					end
				end
			end
		end
		local rarityOrder = {Ancient = 1, Godly = 2, Unique = 3, Legendary = 4, Vintage = 5,
			Classic = 6, Rare = 7, Uncommon = 8, Common = 9}
		table.sort(Skin.list, function(a, b)
			local ra, rb = rarityOrder[a.rarity] or 10, rarityOrder[b.rarity] or 10
			if ra ~= rb then return ra < rb end
			return a.name < b.name
		end)
	end
	parseSkins()

	-- ===================== applying the skins =====================
	local function chosen(weapon)
		return Skin.byKey[weapon == "Knife" and Skin.knife or Skin.gun]
	end

	local function restoreSkin(part)
		local a = Skin.applied[part]
		if not a then return end
		pcall(function()
			if a.conn then a.conn:Disconnect() end
			if a.overlay then a.overlay:Destroy() end
			part.LocalTransparencyModifier = 0
		end)
		Skin.applied[part] = nil
	end
	local function restoreAll()
		for part in pairs(Skin.applied) do restoreSkin(part) end
	end

	local function findTool(weapon)
		local bp = player:FindFirstChildOfClass("Backpack")
		for _, container in ipairs({player.Character, bp}) do
			if container then
				local t = container:FindFirstChild(weapon)
				if t and t:IsA("Tool") then return t end
			end
		end
	end

	-- Gingerscope / Icepiercer / Harvester (every variant of each): fixed body position from adjustPresets
	local FAMILIES = {"gingerscope", "icepiercer", "harvester"}
	local function familyOf(key)
		local k = string.lower(key or "")
		for _, f in ipairs(FAMILIES) do
			if string.find(k, f, 1, true) then return f end
		end
	end
	Skin.familyOf = familyOf
	Skin.adj = {}   -- family -> fixed rotation-only CFrame from adjustPresets (all variants of a family share it)
	for fam, str in pairs(Skin.adjustPresets) do
		local n = {}
		for v in string.gmatch(tostring(str), "[^,%s]+") do n[#n + 1] = tonumber(v) end
		if #n == 9 then Skin.adj[string.lower(fam)] = CFrame.new(0, 0, 0, table.unpack(n)) end
	end

	-- default grip offset (as it was) turned by the pad rotation around the mesh origin, in the holster part's axes
	local function withAdjust(base, key)
		local adj = Skin.adj[key]
		if not adj then return base end
		return CFrame.new(base.Position) * adj * base.Rotation
	end

	-- puts the skin mesh on `part` (the original part is hidden locally)
	local function applySkin(part, weapon, isDisplay)
		local s = chosen(weapon)
		if not s then restoreSkin(part) return end
		local a = Skin.applied[part]
		if a and a.key == s.key then
			if a.overlay and a.overlay.Parent then
				part.LocalTransparencyModifier = 1
				return
			end
		end
		if a and a.conn then a.conn:Disconnect() a.conn = nil end
		if a and a.overlay then a.overlay:Destroy() end
		if not a then
			a = {}
			Skin.applied[part] = a
		end
		a.key = s.key
		a.display = isDisplay == true
		a.weld, a.adjKey, a.base = nil, nil, nil
		local offset = CFrame.identity
		local tool = isDisplay and findTool(weapon) or part.Parent
		if s.grip and tool and tool:IsA("Tool") then
			offset = tool.Grip * s.grip:Inverse()
		end
		local final = offset
		local fam = isDisplay and familyOf(s.key)
		if fam then
			a.adjKey, a.base = fam, offset
			final = withAdjust(offset, fam)
		end
		local p = Instance.new("Part")
		p.Name = "MellowynSkin"
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.Transparency = isDisplay and part.Transparency or 0
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.Anchored = false
		p.CFrame = part.CFrame * final
		p.Parent = part
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.FileMesh
		m.MeshId = s.mesh
		m.TextureId = s.tex
		m.Scale = s.scale
		m.Parent = p
		if a.adjKey then
			-- a Weld (not WeldConstraint) so the pads can turn the weapon live through C0
			local w = Instance.new("Weld")
			w.Part0 = part
			w.Part1 = p
			w.C0 = final
			w.C1 = CFrame.identity
			w.Parent = p
			a.weld = w
		else
			local w = Instance.new("WeldConstraint")
			w.Part0 = part
			w.Part1 = p
			w.Parent = p
		end
		a.overlay = p
		if isDisplay then
			a.conn = part:GetPropertyChangedSignal("Transparency"):Connect(function()
				if p.Parent then p.Transparency = part.Transparency end
			end)
		end
		part.LocalTransparencyModifier = 1
	end

	-- live update of the weapons that use the pads (no rebuild, no flicker)
	function Skin.refreshAdjust()
		for _, a in pairs(Skin.applied) do
			if a.weld and a.adjKey and a.base and a.weld.Parent then
				a.weld.C0 = withAdjust(a.base, a.adjKey)
			end
		end
	end

	-- any name with knife / gun in it counts (knife on the back, gun on the leg, holsters, sheaths, displays ...)
	local function weaponKind(name)
		local n = string.lower(name)
		if string.find(n, "knife", 1, true) or string.find(n, "dagger", 1, true) then return "Knife" end
		if string.find(n, "gun", 1, true) or string.find(n, "pistol", 1, true) or string.find(n, "revolver", 1, true) then
			return "Gun"
		end
	end

	-- ===== search around the body: holstered knife / gun that live outside the character model =====
	local Near = {}

	-- mesh id as a bare number string ("rbxassetid://123", "http://www.roblox.com/asset/?id=123" -> "123")
	local function meshNum(id)
		return id and tostring(id):match("%d+") or ""
	end
	local function partMeshId(p)
		local id = p:IsA("MeshPart") and p.MeshId or ""
		if id == "" then
			local sm = p:FindFirstChildOfClass("SpecialMesh")
			id = sm and sm.MeshId or ""
		end
		return meshNum(id)
	end

	-- mesh ids of the real knife / gun that you own: a holstered copy uses the same mesh, whatever its name is
	function Near.meshKinds()
		local ids = {}
		for _, sk in ipairs(Skin.list) do
			local n = meshNum(sk.mesh)
			if n ~= "" then ids[n] = sk.type end
		end
		local bp = player:FindFirstChildOfClass("Backpack")
		for _, container in ipairs({player.Character, bp}) do
			if container then
				for _, tool in ipairs(container:GetChildren()) do
					local kind = tool:IsA("Tool") and weaponKind(tool.Name)
					local h = kind and tool:FindFirstChild("Handle")
					if h and h:IsA("BasePart") then
						local id = partMeshId(h)
						if id ~= "" then ids[id] = kind end
					end
				end
			end
		end
		return ids
	end

	function Near.parts(root)
		if Skin.deepScan then
			local out, pos = {}, root.Position
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("BasePart") and (d.Position - pos).Magnitude <= Skin.radius + d.Size.Magnitude / 2 then
					out[#out + 1] = d
				end
			end
			return out
		end
		local op = OverlapParams.new()
		op.MaxParts = 500
		local res = workspace:GetPartBoundsInRadius(root.Position, Skin.radius, op)
		return res
	end

	local function sizeOk(inst)
		if inst:IsA("Model") then return inst:GetExtentsSize().Magnitude <= 8 end
		if inst:IsA("BasePart") then return inst.Size.Magnitude <= 8 end
		return true
	end

	-- appends the weapons found within Skin.radius studs of the body to `list` (same format as the character scan)
	function Near.collect(list, matched)
		local c = player.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local others = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and pl.Character then others[#others + 1] = pl.Character end
		end
		-- your own holstered weapons: the game stores them in ObjectValues DisplayRefKnife / DisplayRefGun
		for nm, k in pairs({DisplayRefKnife = "Knife", DisplayRefGun = "Gun"}) do
			local ov = c:FindFirstChild(nm)
			local v = ov and ov:IsA("ObjectValue") and ov.Value
			if v and v.Parent and not matched[v] then
				matched[v] = true
				list[#list + 1] = {v, k}
				if Skin.debug and not Skin.seen[v] then
					Skin.seen[v] = true
					print(("[Mellowyn skin] %s display via %s: %s"):format(k, nm, v:GetFullName()))
				end
			end
		end
		if not Skin.nearScan then return end
		local meshKinds = Near.meshKinds()
		for _, p in ipairs(Near.parts(root)) do
			if p.Name ~= "MellowynSkin" and not p:FindFirstAncestorOfClass("Tool")
				and not p:FindFirstAncestor("WeaponDisplays") then
				local foreign = false
				for _, o in ipairs(others) do
					if p:IsDescendantOf(o) then foreign = true break end
				end
				if not foreign then
					-- 1) by name: the highest knife / gun named ancestor that is still weapon-sized
					local inst, kind
					local anc = p
					while anc and anc ~= workspace and anc ~= c do
						if not anc:IsA("Folder") then
							local k = weaponKind(anc.Name)
							if k and sizeOk(anc) then inst, kind = anc, k end
						end
						anc = anc.Parent
					end
					-- 2) by mesh: same mesh as the knife / gun you own
					if not inst then
						local k = meshKinds[partMeshId(p)]
						if k then inst, kind = p, k end
					end
					if inst and not matched[inst] then
						local skip = false
						local a2 = inst.Parent
						while a2 and a2 ~= workspace do
							if matched[a2] then skip = true break end
							a2 = a2.Parent
						end
						if not skip then
							matched[inst] = true
							list[#list + 1] = {inst, kind}
							if Skin.debug and not Skin.seen[inst] then
								Skin.seen[inst] = true
								print(("[Mellowyn skin] %s found near body: %s (%s)"):format(kind, inst:GetFullName(), inst.ClassName))
							end
						end
					end
				end
			end
		end
	end


	-- everything knife / gun hanging on the character (NOT the tools themselves - those are handled separately)
	local function getDisplayParts()
		local list = {}
		local c = player.Character
		if not c then return list end
		local matched = {}
		for _, d in ipairs(c:GetDescendants()) do
			if (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Folder") or d:IsA("Accessory"))
				and d.Name ~= "MellowynSkin" and not d:FindFirstAncestorOfClass("Tool") then
				local kind = weaponKind(d.Name)
				if kind then
					local skip = false
					local anc = d.Parent
					while anc and anc ~= c do
						if matched[anc] then skip = true break end
						anc = anc.Parent
					end
					if not skip then
						matched[d] = true
						list[#list + 1] = {d, kind}
					end
				end
			end
		end
		local ok, err = pcall(Near.collect, list, matched)
		if not ok and Skin.debug and not Skin.errShown then
			Skin.errShown = true
			warn("[Mellowyn skin] nearby scan failed: " .. tostring(err))
		end
		return list
	end

	local function applyDisplaySkin(inst, weapon)
		local s = chosen(weapon)
		local parts = {}
		if inst:IsA("BasePart") then parts[1] = inst end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "MellowynSkin" then parts[#parts + 1] = d end
		end
		if #parts == 0 then return end
		-- the biggest part (or "Handle") carries the skin mesh, the other parts just get hidden
		local main, bestVol = nil, -1
		for _, d in ipairs(parts) do
			local vol = d.Size.X * d.Size.Y * d.Size.Z
			if d.Name == "Handle" then main = d break end
			if vol > bestVol then main, bestVol = d, vol end
		end
		for _, d in ipairs(parts) do
			if d ~= main then
				if s then
					if not Skin.applied[d] then Skin.applied[d] = {display = true, key = s.key} end
					d.LocalTransparencyModifier = 1
				else
					restoreSkin(d)
				end
			end
		end
		if not s then restoreSkin(main) return end
		applySkin(main, weapon, true)
	end

	-- the weapons that are in the hands / in the backpack
	local function getHandles()
		local list = {}
		local bp = player:FindFirstChildOfClass("Backpack")
		for _, container in ipairs({player.Character, bp}) do
			if container then
				for _, tool in ipairs(container:GetChildren()) do
					if tool:IsA("Tool") then
						local kind = weaponKind(tool.Name)
						local h = tool:FindFirstChild("Handle")
						if kind and h and h:IsA("BasePart") then list[#list + 1] = {h, kind} end
					end
				end
			end
		end
		return list
	end

	local function invalidate()
		for _, a in pairs(Skin.applied) do a.key = nil end
		Skin.lastScan = 0
	end

	task.spawn(function()
		while screenGui.Parent do
			local now = os.clock()
			if Skin.enabled and now - Skin.lastScan > 0.5
				and (Skin.knife ~= "" or Skin.gun ~= "" or next(Skin.applied)) then
				Skin.lastScan = now
				pcall(function()
					for _, t in ipairs(getHandles()) do pcall(applySkin, t[1], t[2]) end
					local keep = {}
					for _, t in ipairs(getDisplayParts()) do
						local inst = t[1]
						if inst:IsA("BasePart") then keep[inst] = true end
						for _, d in ipairs(inst:GetDescendants()) do
							if d:IsA("BasePart") then keep[d] = true end
						end
						pcall(applyDisplaySkin, inst, t[2])
					end
					Skin.keep = keep
					for part, a in pairs(Skin.applied) do
						if not part:IsDescendantOf(game) then
							if a.conn then pcall(function() a.conn:Disconnect() end) end
							Skin.applied[part] = nil
						elseif a.display then
							if not keep[part] and not (player.Character and part:IsDescendantOf(player.Character)) then restoreSkin(part) end
						elseif not (part.Parent and part.Parent:IsA("Tool")) then
							restoreSkin(part)
						end
					end
				end)
			end
			task.wait(0.2)
		end
	end)
	screenGui.Destroying:Connect(restoreAll)

	-- ===================== page: Knife / Gun switch, on/off, search, skin cards =====================
	local PAD = CARD_PAD
	local COLS = 3
	local CW = math.floor((BG_W - PAD * (COLS + 1)) / COLS)
	local CH = 98
	local TOP_Y = 72

	-- Knife / Gun: the chosen one gets a bright white outline
	local typeBtns = {}
	local function markType()
		for name, b in pairs(typeBtns) do
			local on = (name == Skin.type)
			tween(b.stroke, {Transparency = on and 0 or 0.75, Thickness = on and 1.6 or 1}, 0.15)
			tween(b.btn, {TextTransparency = on and 0 or 0.5}, 0.15)
		end
	end
	for i, name in ipairs({"Knife", "Gun"}) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 64, 0, 24)
		b.Position = UDim2.new(0, PAD + (i - 1) * 68, 0, PAD)
		b.BackgroundColor3 = BLACK
		b.BackgroundTransparency = 0.2
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Text = name
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 12
		b.TextColor3 = WHITE
		b.Parent = page
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 5)
		bc.Parent = b
		local bs = Instance.new("UIStroke")
		bs.Color = WHITE
		bs.Thickness = 1
		bs.Transparency = 0.75
		bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bs.Parent = b
		typeBtns[name] = {btn = b, stroke = bs}
	end

	-- on / off
	local onHolder = Instance.new("Frame")
	onHolder.Size = UDim2.new(0, 76, 0, 28)
	onHolder.Position = UDim2.new(1, -PAD - 76, 0, PAD - 2)
	onHolder.BackgroundTransparency = 1
	onHolder.BorderSizePixel = 0
	onHolder.Parent = page
	local onToggle = makeToggleRow(onHolder, 0, "Skins", function(v)
		Skin.enabled = v
		if v then
			invalidate()
		else
			restoreAll()
		end
	end, 4, "skins/enabled")
	onToggle.set(true, true)

	-- search
	local search = Instance.new("TextBox")
	search.Size = UDim2.new(1, -PAD * 2, 0, 24)
	search.Position = UDim2.new(0, PAD, 0, PAD + 32)
	search.BackgroundColor3 = BLACK
	search.BackgroundTransparency = 0.2
	search.BorderSizePixel = 0
	search.Text = ""
	search.PlaceholderText = "Search skins..."
	search.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	search.Font = Enum.Font.GothamMedium
	search.TextSize = 11
	search.TextColor3 = WHITE
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.ClearTextOnFocus = false
	search.Parent = page
	do
		local sc = Instance.new("UICorner")
		sc.CornerRadius = UDim.new(0, 5)
		sc.Parent = search
		local ss = Instance.new("UIStroke")
		ss.Color = WHITE
		ss.Thickness = 1
		ss.Transparency = 0.6
		ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ss.Parent = search
		local sp = Instance.new("UIPadding")
		sp.PaddingLeft = UDim.new(0, 8)
		sp.Parent = search
	end

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Size = UDim2.new(1, -PAD * 2, 0, 24)
	emptyLabel.Position = UDim2.new(0, PAD, 0, TOP_Y + 4)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Font = Enum.Font.GothamMedium
	emptyLabel.TextSize = 11
	emptyLabel.TextColor3 = WHITE
	emptyLabel.TextTransparency = 0.5
	emptyLabel.Text = ""
	emptyLabel.Visible = false
	emptyLabel.Parent = page

	-- one card per skin, built once; searching / switching Knife <-> Gun only shows, hides and re-places them
	local cards = {}
	local function selectedKey(kind)
		return kind == "Knife" and Skin.knife or Skin.gun
	end
	local function paintCard(c, instant)
		local on = selectedKey(c.skin.type) == c.skin.key
		-- chosen skin = bright white outline
		if instant then
			c.stroke.Transparency = on and 0 or 0.55
			c.stroke.Thickness = on and 2 or 0.8
		else
			tween(c.stroke, {Transparency = on and 0 or 0.55, Thickness = on and 2 or 0.8}, 0.15)
		end
	end

	for _, s in ipairs(Skin.list) do
		local card = Instance.new("TextButton")
		card.Name = "Skin_" .. s.key
		card.Size = UDim2.new(0, CW, 0, CH)
		card.BackgroundColor3 = BLACK
		card.BackgroundTransparency = 0.10
		card.BorderSizePixel = 0
		card.AutoButtonColor = false
		card.Text = ""
		card.ClipsDescendants = true
		card.Visible = false
		card.Parent = page
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 6)
		cc.Parent = card
		local cs = Instance.new("UIStroke")
		cs.Color = WHITE
		cs.Thickness = 0.8
		cs.Transparency = 0.55
		cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cs.Parent = card

		local img = Instance.new("ImageLabel")
		img.Size = UDim2.new(0, CW - 16, 0, 58)
		img.Position = UDim2.new(0.5, 0, 0, 6)
		img.AnchorPoint = Vector2.new(0.5, 0)
		img.BackgroundTransparency = 1
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = ""
		img.Parent = card

		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -6, 0, 14)
		nm.Position = UDim2.new(0, 3, 0, 68)
		nm.BackgroundTransparency = 1
		nm.Text = s.name
		nm.Font = Enum.Font.GothamMedium
		nm.TextSize = 10
		nm.TextScaled = true
		nm.TextTruncate = Enum.TextTruncate.AtEnd
		nm.TextColor3 = WHITE
		nm.Parent = card
		local nlim = Instance.new("UITextSizeConstraint")
		nlim.MaxTextSize = 10
		nlim.MinTextSize = 6
		nlim.Parent = nm

		local rl = Instance.new("TextLabel")
		rl.Size = UDim2.new(1, -6, 0, 12)
		rl.Position = UDim2.new(0, 3, 0, 83)
		rl.BackgroundTransparency = 1
		rl.Text = s.rarity or ""
		rl.Font = Enum.Font.GothamMedium
		rl.TextSize = 9
		rl.TextColor3 = WHITE
		rl.TextTransparency = 0.5
		rl.Parent = card

		local c = {frame = card, stroke = cs, img = img, skin = s, loaded = false}
		cards[s.key] = c
		paintCard(c, true)

		card.MouseButton1Click:Connect(function()
			playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
			local cur = selectedKey(s.type)
			local new = (cur == s.key) and "" or s.key
			if s.type == "Knife" then Skin.knife = new else Skin.gun = new end
			invalidate()
			for _, other in pairs(cards) do
				if other.skin.type == s.type then paintCard(other) end
			end
			UI.toast(s.name .. (new == "" and " removed" or " equipped"))
		end)
	end

	local function relayout()
		local q = string.lower(search.Text or "")
		local n = 0
		for _, s in ipairs(Skin.list) do
			local c = cards[s.key]
			local show = (s.type == Skin.type) and (q == "" or string.find(string.lower(s.name), q, 1, true) ~= nil)
			c.frame.Visible = show
			if show then
				local col, row = n % COLS, math.floor(n / COLS)
				c.frame.Position = UDim2.new(0, PAD + col * (CW + PAD), 0, TOP_Y + row * (CH + PAD))
				if not c.loaded then
					-- thumbnails are only requested when the card is shown for the first time
					c.loaded = true
					if s.img ~= 0 then
						c.img.Image = "rbxthumb://type=Asset&id=" .. s.img .. "&w=150&h=150"
					end
				end
				n = n + 1
			end
		end
		emptyLabel.Visible = n == 0
		emptyLabel.Text = (#Skin.list == 0) and "no skins: paste SKIN_DATA in the script" or "nothing found"
		page.CanvasSize = UDim2.new(0, 0, 0, TOP_Y + math.ceil(n / COLS) * (CH + PAD))
	end

	for name, t in pairs(typeBtns) do
		t.btn.MouseButton1Click:Connect(function()
			playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
			Skin.type = name
			markType()
			relayout()
		end)
	end
	search:GetPropertyChangedSignal("Text"):Connect(relayout)
	markType()
	relayout()
end

-- Outline strokes on buttons / text boxes go around the BUTTON (Border), never around its text
do
	local function fixStroke(d)
		if d:IsA("UIStroke") then
			local par = d.Parent
			if par and (par:IsA("TextButton") or par:IsA("TextBox")) then
				d.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			end
		end
	end
	for _, d in ipairs(screenGui:GetDescendants()) do fixStroke(d) end
	table.insert(connections, screenGui.DescendantAdded:Connect(function(d)
		task.defer(fixStroke, d)
	end))
end

selectTab(mainTab)

-- Layer order: there is no separate background layer in this version.
-- Keep the content layer above the menu background.
content.ZIndex = 10
for _, d in ipairs(content:GetDescendants()) do
	if d:IsA("GuiObject") then
		d.ZIndex = 10
	end
end
-- ===================== MENU DRAG =====================
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

menu.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragInput = input
		dragStart = input.Position
		startPos = menu.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
	local isTouch = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
	if not (isMouse or isTouch) then return end

	local delta = input.Position - dragStart
	local vp = screenGui.AbsoluteSize
	local nx = math.clamp(startPos.X.Offset + delta.X, -vp.X / 2 + 60, vp.X / 2 - 60)
	local ny = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y / 2 + 60, vp.Y / 2 - 60)
	menu.Position = UDim2.new(0.5, nx, 0.5, ny)
	updateProfilePosition()
	updateSettingsPosition()
end))

-- ===================== MENU OPEN / CLOSE =====================
local menuOpen = false
local menuToken = 0


local function openMenu()
	if menuOpen then return end
	menuOpen = true
	menuToken = menuToken + 1
	menu.Visible = true
	profileButton.Visible = true
	updateProfilePosition()
	menu.GroupTransparency = 1
	menuScale.Scale = 1
	-- A short, clean fade without the unpleasant zoom effect.
	tween(menu, {GroupTransparency = 0}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local function closeMenu()
	if not menuOpen then return end
	menuOpen = false
	menuToken = menuToken + 1
	local token = menuToken
	closeSettingsPanel()
	-- Close with the same short fade; no zoom.
	local t = tween(menu, {GroupTransparency = 1}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	t.Completed:Wait()
	if token == menuToken then
		menu.Visible = false
		profileButton.Visible = false
	end
end

hud.MouseButton1Click:Connect(function()
	if menuOpen then
		closeMenu()
	else
		openMenu()
	end
end)

-- ===================== INTRO ANIMATION =====================

-- 1. Dark overlay + blur
tween(dark, {BackgroundTransparency = 0.15}, 1.1)
tween(blur, {Size = 24}, 1.3)
task.wait(0.9)

-- 2. "Welcome!" expands from the middle to both sides
welcome.Visible = true
tween(welcome, {Size = UDim2.new(0, welcomeW, 0, welcomeH)}, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
task.wait(2.3)

-- collapses back into the middle
tween(welcome, {Size = UDim2.new(0, 0, 0, welcomeH)}, 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
task.wait(0.8)
welcome.Visible = false

-- 3. Loading appears
loadFrame.Visible = true
tween(loadTitle, {TextTransparency = 0}, 0.5)
tween(percentLabel, {TextTransparency = 0}, 0.5)
tween(barBg, {BackgroundTransparency = 0}, 0.5)
tween(barStroke, {Transparency = 0.35}, 0.5)

-- 4. Progress (15 seconds, with pauses and jumps)
local duration = 15
local progress = 0
local lastUpdate = tick()
-- the bar stops at these percents for this many seconds
local holds = {{0.22, 3}, {0.53, 4}, {0.77, 7}, {0.98, 1}}
local holdIdx = 1

while progress < 1 do
	local now = tick()
	local dt = now - lastUpdate
	lastUpdate = now

	local speed = 1 / duration
	if math.random() < 0.08 then
		speed = speed * 0.15
	elseif math.random() < 0.12 then
		speed = speed * 2.2
	end

	progress = math.clamp(progress + speed * dt, 0, 1)
	local hold = holds[holdIdx]
	if hold and progress >= hold[1] then
		progress = hold[1]
		barFill.Size = UDim2.new(progress, 0, 1, 0)
		percentLabel.Text = math.floor(progress * 100 + 0.5) .. "%"
		task.wait(hold[2])
		holdIdx = holdIdx + 1
		lastUpdate = tick()
	end
	barFill.Size = UDim2.new(progress, 0, 1, 0)
	percentLabel.Text = math.floor(progress * 100) .. "%"
	task.wait()
end

percentLabel.Text = "100%"
task.wait(0.35)

-- Loading fades out
tween(loadTitle, {TextTransparency = 1}, 0.4)
tween(percentLabel, {TextTransparency = 1}, 0.4)
tween(barBg, {BackgroundTransparency = 1}, 0.4)
tween(barFill, {BackgroundTransparency = 1}, 0.4)
tween(barStroke, {Transparency = 1}, 0.4)
task.wait(0.45)
loadFrame.Visible = false

-- 5. Success text expands from the middle to both sides
success.Visible = true
tween(success, {Size = UDim2.new(0, successW, 0, successH)}, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
task.wait(2.5)

-- 6. Everything disappears together
tween(success, {Size = UDim2.new(0, 0, 0, successH)}, 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
tween(dark, {BackgroundTransparency = 1}, 1.2)
tween(blur, {Size = 0}, 1.3)

task.wait(1.4)
success.Visible = false
dark.Visible = false
blur:Destroy()

-- 7. HUD + Telegram rectangle appear
hudText.Text = string.format("mellowyn.ft | free  %s  -- FPS  -- Ping | %s", getClock(), getDevice())
hud.Visible = true
tgBox.Visible = true
tween(hud, {Size = UDim2.new(0, HUD_W, 0, HUD_H)}, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
tween(tgBox, {Size = UDim2.new(0, TG_W, 0, HUD_H)}, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- HUD update: FPS and ping refresh every 0.65 seconds, real clock time
local frames, acc = 0, 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	frames = frames + 1
	acc = acc + dt
	if acc >= 0.65 then
		local fps = math.floor(frames / acc + 0.5)
		frames, acc = 0, 0
		hudText.Text = string.format(
			"mellowyn.ft | free  %s  %d FPS  %d Ping | %s",
			getClock(), fps, getPing(), getDevice()
		)
	end
end))

for _, d in ipairs(screenGui:GetDescendants()) do
	if d:IsA("GuiBase2d") then
		pcall(function() d.AutoLocalize = false end)
	end
end

task.spawn(function()
	while screenGui.Parent do
		for _, d in ipairs(screenGui:GetDescendants()) do
			if d:IsA("GuiBase2d") and d.AutoLocalize then
				pcall(function() d.AutoLocalize = false end)
			end
		end
		task.wait(1)
	end
end)


-- ===================== VOTE DUPER =====================
do
	local page = tabs.Vote and tabs.Vote.page
	if page then
		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(1, -16, 0, 18)
		status.Position = UDim2.new(0, 8, 0, 6)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamMedium
		status.TextSize = 11
		status.TextColor3 = WHITE
		status.TextTransparency = 0.25
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.Text = "Waiting for vote..."
		status.Parent = page

		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1, -12, 0, 160)
		holder.Position = UDim2.new(0, 6, 0, 28)
		holder.BackgroundTransparency = 1
		holder.Parent = page
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.fromOffset(82, 140)
		grid.CellPadding = UDim2.fromOffset(6, 6)
		grid.FillDirectionMaxCells = 3
		grid.Parent = holder

		local active = {i = nil}
		local cards = {}

		local function getLobby()
			return workspace:FindFirstChild("RegularLobby") or workspace:FindFirstChild("Lobby") or workspace
		end
		local function getPad(i)
			local lobby = getLobby()
			return lobby:FindFirstChild("VotePad" .. i, true)
		end
		local function padCF(pad)
			if not pad then return nil end
			if pad:IsA("BasePart") then return pad.CFrame end
			if pad:IsA("Model") then
				local ok, piv = pcall(function() return pad:GetPivot() end)
				if ok then return piv end
			end
			local part = pad:FindFirstChildWhichIsA("BasePart", true)
			return part and part.CFrame
		end
		local function isBadImage(img)
			if not img or img == "" then return true end
			local low = string.lower(img)
			if string.find(low, "rbxasset://textures", 1, true) then return true end
			if string.find(low, "ui/ghost", 1, true) then return true end
			return false
		end
		local function isBadMapName(t)
			local low = string.lower(t or "")
			if low == "" then return true end
			if tonumber(t) then return true end
			if string.find(low, "vote", 1, true) then return true end
			if string.find(low, "freeze", 1, true) then return true end
			if low == "classic" or low == "infection" or low == "assassins" then return true end
			if string.find(low, "mode", 1, true) then return true end
			if #t <= 2 or #t >= 40 then return true end
			return false
		end
		local function readPad(pad)
			local mapName, image = nil, nil
			if not pad then return nil, nil end
			local candidates = {}
			for _, d in ipairs(pad:GetDescendants()) do
				if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and not isBadImage(d.Image) then
					if not image then image = d.Image end
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local t = tostring(d.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
					if not isBadMapName(t) then
						candidates[#candidates + 1] = t
					end
				end
			end
			table.sort(candidates, function(a, b) return #a > #b end)
			mapName = candidates[1]
			return mapName or ("Pad " .. tostring(pad.Name)), image
		end

		for i = 1, 3 do
			local cell = Instance.new("Frame")
			cell.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			cell.BackgroundTransparency = 0.15
			cell.BorderSizePixel = 0
			cell.Parent = holder
			Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 6)
			local st = Instance.new("UIStroke")
			st.Color = WHITE
			st.Thickness = 1
			st.Transparency = 0.55
			st.Parent = cell

			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(1, -8, 0, 70)
			img.Position = UDim2.new(0, 4, 0, 4)
			img.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			img.BorderSizePixel = 0
			img.ScaleType = Enum.ScaleType.Crop
			img.ImageTransparency = 0.3
			img.Parent = cell
			Instance.new("UICorner", img).CornerRadius = UDim.new(0, 4)

			local nameL = Instance.new("TextLabel")
			nameL.Size = UDim2.new(1, -6, 0, 22)
			nameL.Position = UDim2.new(0, 3, 0, 76)
			nameL.BackgroundTransparency = 1
			nameL.Font = Enum.Font.GothamMedium
			nameL.TextSize = 10
			nameL.TextColor3 = WHITE
			nameL.Text = "—"
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			nameL.Parent = cell

			local dupe = Instance.new("TextButton")
			dupe.Size = UDim2.new(1, -8, 0, 24)
			dupe.Position = UDim2.new(0, 4, 0, 104)
			dupe.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			dupe.BorderSizePixel = 0
			dupe.Text = "Dupe"
			dupe.Font = Enum.Font.GothamBold
			dupe.TextSize = 11
			dupe.TextColor3 = WHITE
			dupe.AutoButtonColor = false
			dupe.Parent = cell
			Instance.new("UICorner", dupe).CornerRadius = UDim.new(0, 5)

			cards[i] = {cell = cell, img = img, nameL = nameL, dupe = dupe, pad = nil}

			dupe.MouseButton1Click:Connect(function()
				playUISound(TOGGLE_ON_SOUND, 0.2, 1.1)
				if active.i == i then
					active.i = nil
					dupe.Text = "Dupe"
					dupe.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
					status.Text = "Dupe stopped"
					return
				end
				active.i = i
				dupe.Text = "Stop Dupe"
				dupe.BackgroundColor3 = Color3.fromRGB(0, 90, 80)
				status.Text = "Duping pad " .. i
				task.spawn(function()
					while active.i == i and screenGui.Parent do
						local pad = getPad(i) or cards[i].pad
						local cf = padCF(pad)
						local char = player.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hrp and hum and cf and hum.Health > 0 then
							-- spawn 0.5 studs off the pad point, then die after 0.05s
							hrp.CFrame = cf + Vector3.new(0, 0.5, 0)
							hrp.AssemblyLinearVelocity = Vector3.zero
							if firetouchinterest then
								local part = pad:IsA("BasePart") and pad or pad:FindFirstChildWhichIsA("BasePart", true)
								if part then
									pcall(firetouchinterest, hrp, part, 0)
									pcall(firetouchinterest, hrp, part, 1)
								end
							end
							task.wait(0.05)
							if active.i ~= i then break end
							hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
							if hum then hum.Health = 0 end
						end
						task.wait(0.08)
					end
				end)
			end)
		end

		task.spawn(function()
			while screenGui.Parent do
				pcall(function()
					local any = false
					for i = 1, 3 do
						local pad = getPad(i)
						cards[i].pad = pad
						if pad then
							any = true
							local mapName, image = readPad(pad)
							cards[i].nameL.Text = mapName or ("Pad " .. i)
							if image and image ~= "" then
								cards[i].img.Image = image
								cards[i].img.ImageTransparency = 0
							end
						else
							cards[i].nameL.Text = "—"
							cards[i].img.Image = ""
						end
					end
					if not any then
						status.Text = "Waiting for vote..."
					elseif active.i then
						status.Text = "Duping pad " .. active.i
					else
						status.Text = "Maps ready"
					end
				end)
				task.wait(0.5)
			end
		end)
	end
end

-- ===================== CONFIG (Mellowyn Conf) =====================
do
	local page = tabs.Config and tabs.Config.page
	if page then
		local FOLDER = "Mellowyn Conf"
		if not _G.MellowynConfigStore then _G.MellowynConfigStore = {} end

		local function ensureFolder()
			if makefolder and isfolder and not isfolder(FOLDER) then
				pcall(makefolder, FOLDER)
			end
		end

		local function listConfigs()
			local out = {}
			ensureFolder()
			if isfolder and listfiles and isfolder(FOLDER) then
				for _, n in ipairs(listfiles(FOLDER) or {}) do
					local base = n
					for part in string.gmatch(n, "[^/\\\\]+") do base = part end
					if string.sub(base, -5) == ".json" then base = string.sub(base, 1, #base - 5) end
					if base ~= "" then out[#out + 1] = base end
				end
			end
			for k in pairs(_G.MellowynConfigStore) do
				local found = false
				for _, x in ipairs(out) do if x == k then found = true break end end
				if not found then out[#out + 1] = k end
			end
			table.sort(out)
			return out
		end

		local function encodeJson(t)
			local ok, Http = pcall(function() return game:GetService("HttpService") end)
			if ok and Http then
				local ok2, str = pcall(function() return Http:JSONEncode(t) end)
				if ok2 then return str end
			end
			return nil
		end

		-- v2 format: {v = 2, ui = {[controlKey] = value}} read straight from the menu controls
		local function serializeCfg()
			local ui = {}
			for _, key in ipairs(UI.CFG.order) do
				local c = UI.CFG.reg[key]
				local ok, v = pcall(c.get)
				if ok and v ~= nil then
					if c.kind == "bool" then
						ui[key] = v and true or false
					elseif c.kind == "number" then
						if type(v) == "number" and v == v and math.abs(v) < math.huge then ui[key] = v end
					elseif c.kind == "color" then
						if typeof(v) == "Color3" then ui[key] = {v.R, v.G, v.B} end
					elseif c.kind == "string" then
						if type(v) == "string" then ui[key] = v end
					end
				end
			end
			return encodeJson({v = 2, ui = ui})
		end

		local function applyLegacy(data)
			if type(data) ~= "table" then return end
			-- colours / params first
			if Feat and Feat.P then
				for k, v in pairs(data) do
					if string.sub(k, 1, 2) == "P_" then
						local key = string.sub(k, 3)
						if type(v) == "table" and #v >= 3 then
							Feat.P[key] = Color3.new(tonumber(v[1]) or 1, tonumber(v[2]) or 1, tonumber(v[3]) or 1)
						else
							Feat.P[key] = v
						end
					end
				end
			end
			local st = {}
			for k, v in pairs(data) do
				if string.sub(k, 1, 3) == "ST_" then
					st[string.sub(k, 4)] = v
				end
			end
			local function flag(name)
				return st[name] == true
			end
			-- turn features on/off for real
			pcall(function()
				if Feat.setInvis then Feat.setInvis(flag("invis")) end
				if Feat.setAntiAim then Feat.setAntiAim(flag("antiaim")) end
				if Feat.setChams then Feat.setChams(flag("chams")) end
				if Feat.setSpin then Feat.setSpin(flag("spin")) end
				if Feat.setAntiFling then Feat.setAntiFling(flag("antifling")) end
				if Feat.setWater then Feat.setWater(flag("water")) end
				if Feat.setSpeed then Feat.setSpeed(flag("speed")) end
				if Feat.setBunny then Feat.setBunny(flag("bunny")) end
				if Feat.setInfJump then Feat.setInfJump(flag("infjump")) end
				if Feat.setNoclip then Feat.setNoclip(flag("noclip")) end
				if Feat.setFly then Feat.setFly(flag("fly")) end
				if Feat.setAutoGrab then Feat.setAutoGrab(flag("autograb")) end
				if Feat.setFarm then Feat.setFarm(flag("autofarm")) end
				if Feat.setFov then Feat.setFov(flag("fov")) end
				if Feat.setStretch then Feat.setStretch(flag("stretch")) end
				if Feat.setEsp then Feat.setEsp(flag("esp")) end
				if Feat.setBoxFill then Feat.setBoxFill(flag("boxfill")) end
				if Feat.setEspLine then Feat.setEspLine(flag("espline")) end
				if Feat.setAvatar then Feat.setAvatar(flag("avatar")) end
				if Feat.setChamsFx then Feat.setChamsFx(flag("chamsfx")) end
				if Feat.setTrail then Feat.setTrail(flag("trail")) end
				if Feat.setDoubleTrail then Feat.setDoubleTrail(flag("dtrail")) end
				if Feat.setJumpCircle then Feat.setJumpCircle(flag("jcircle")) end
				if Feat.Aim then
					if st.silent ~= nil then Feat.Aim.on = flag("silent") end
					if st.autoshoot ~= nil then Feat.Aim.autoshoot = flag("autoshoot") end
					if st.wallbang ~= nil then Feat.Aim.wallbang = flag("wallbang") end
				end
				if data.P_predMul ~= nil and Feat.Aim then
					Feat.Aim.predMul = tonumber(data.P_predMul) or Feat.Aim.predMul
				end
			end)
			-- sync main UI toggles (silent so they don't re-fire onChange loops badly)
			pcall(function()
				if ctrls and ctrls.invis and ctrls.invis.set then ctrls.invis.set(flag("invis"), true) end
				if ctrls and ctrls.aa and ctrls.aa.set then ctrls.aa.set(flag("antiaim"), true) end
				if ctrls and ctrls.speed and ctrls.speed.set then ctrls.speed.set(flag("speed"), true) end
				if ctrls and ctrls.fly and ctrls.fly.set then ctrls.fly.set(flag("fly"), true) end
				if ctrls and ctrls.noclip and ctrls.noclip.set then ctrls.noclip.set(flag("noclip"), true) end
				if ctrls and ctrls.jump and ctrls.jump.set then ctrls.jump.set(flag("infjump"), true) end
			end)
		end

		-- v2 loader: every control is set through its own onChange (checkbox + feature + params stay in sync).
		-- Order: values (dropdown presets first) -> toggles OFF -> toggles ON, so mutually exclusive
		-- features (Invisible / Anti Aim / Auto Farm) never block each other.
		-- Each control runs in its own pcall: one broken feature can no longer abort the rest.
		local function applyUi(ui)
			local applied, failed, firstErr = 0, 0, nil
			local function decode(c, v)
				if c.kind == "bool" then
					return v == true
				elseif c.kind == "number" then
					return tonumber(v)
				elseif c.kind == "color" then
					if type(v) == "table" and #v >= 3 then
						return Color3.new(tonumber(v[1]) or 1, tonumber(v[2]) or 1, tonumber(v[3]) or 1)
					end
					return nil
				elseif c.kind == "string" then
					return type(v) == "string" and v or nil
				end
				return nil
			end
			local function pass(pred)
				for _, key in ipairs(UI.CFG.order) do
					local c = UI.CFG.reg[key]
					local raw = ui[key]
					if raw ~= nil and pred(c, raw) then
						local val = decode(c, raw)
						if val ~= nil then
							local ok, err = pcall(c.set, val)
							if ok then
								applied = applied + 1
							else
								failed = failed + 1
								firstErr = firstErr or (key .. ": " .. tostring(err))
							end
						end
					end
				end
			end
			pass(function(c) return c.kind ~= "bool" end)
			pass(function(c, raw) return c.kind == "bool" and raw ~= true end)
			pass(function(c, raw) return c.kind == "bool" and raw == true end)
			if firstErr then warn("[mellowyn.ft] config: " .. firstErr) end
			return applied, failed
		end

		local function applyCfg(data)
			if type(data) ~= "table" then return false, "bad data" end
			if type(data.ui) == "table" then
				local applied, failed = applyUi(data.ui)
				if failed > 0 then
					return true, applied .. " ok, " .. failed .. " failed (see F9)"
				end
				return true, applied .. " settings"
			end
			applyLegacy(data)
			return true, "old format: load, then Save again"
		end

		local function saveConfig(name)
			name = tostring(name or ""):gsub("[^%w_%-%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" then return false, "empty name" end
			local raw = serializeCfg()
			if not raw then return false, "json encode failed" end
			_G.MellowynConfigStore[name] = raw
			ensureFolder()
			local note = nil
			if writefile then
				local ok, err = pcall(writefile, FOLDER .. "/" .. name .. ".json", raw)
				if not ok then note = "memory only: " .. tostring(err) end
			else
				note = "memory only: no writefile"
			end
			return true, note
		end

		local function loadConfig(name)
			local raw = nil
			if readfile and isfile then
				local path = FOLDER .. "/" .. name .. ".json"
				local okExists, exists = pcall(isfile, path)
				if okExists and exists then
					local ok, content = pcall(readfile, path)
					if ok then raw = content end
				end
			end
			raw = raw or _G.MellowynConfigStore[name]
			if not raw then return false, "not found" end
			local data = nil
			local okH, Http = pcall(function() return game:GetService("HttpService") end)
			if okH and Http then
				local ok2, decoded = pcall(function() return Http:JSONDecode(raw) end)
				if ok2 then data = decoded end
			end
			if not data then return false, "bad data" end
			return applyCfg(data)
		end

		local function deleteConfig(name)
			_G.MellowynConfigStore[name] = nil
			if delfile and isfile then
				local path = FOLDER .. "/" .. name .. ".json"
				if isfile(path) then pcall(delfile, path) end
			end
		end

		-- UI
		local listHolder = Instance.new("ScrollingFrame")
		listHolder.Size = UDim2.new(1, -100, 1, -12)
		listHolder.Position = UDim2.new(0, 6, 0, 6)
		listHolder.BackgroundTransparency = 1
		listHolder.BorderSizePixel = 0
		listHolder.ScrollBarThickness = 2
		listHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
		listHolder.Parent = page
		local lay = Instance.new("UIListLayout")
		lay.Padding = UDim.new(0, 4)
		lay.Parent = listHolder

		local right = Instance.new("Frame")
		right.Size = UDim2.new(0, 88, 1, -12)
		right.Position = UDim2.new(1, -94, 0, 6)
		right.BackgroundTransparency = 1
		right.Parent = page

		local saveBtn = Instance.new("TextButton")
		saveBtn.Size = UDim2.new(1, 0, 0, 28)
		saveBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		saveBtn.BorderSizePixel = 0
		saveBtn.Text = "Save Config"
		saveBtn.Font = Enum.Font.GothamBold
		saveBtn.TextSize = 11
		saveBtn.TextColor3 = WHITE
		saveBtn.AutoButtonColor = false
		saveBtn.Parent = right
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 5)

		local selectedName = nil

		local function refreshList()
			for _, ch in ipairs(listHolder:GetChildren()) do
				if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
			end
			local names = listConfigs()
			if #names == 0 then
				local e = Instance.new("TextLabel")
				e.Size = UDim2.new(1, 0, 0, 22)
				e.BackgroundTransparency = 1
				e.Font = Enum.Font.GothamMedium
				e.TextSize = 11
				e.TextColor3 = WHITE
				e.TextTransparency = 0.45
				e.Text = "No configs yet"
				e.Parent = listHolder
			end
			for _, name in ipairs(names) do
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, -4, 0, 54)
				row.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
				row.BackgroundTransparency = 0.15
				row.BorderSizePixel = 0
				row.Parent = listHolder
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

				local nm = Instance.new("TextLabel")
				nm.Size = UDim2.new(1, -8, 0, 18)
				nm.Position = UDim2.new(0, 6, 0, 4)
				nm.BackgroundTransparency = 1
				nm.Font = Enum.Font.GothamBold
				nm.TextSize = 11
				nm.TextColor3 = WHITE
				nm.TextXAlignment = Enum.TextXAlignment.Left
				nm.Text = name
				nm.Parent = row

				local loadB = Instance.new("TextButton")
				loadB.Size = UDim2.new(0.48, -4, 0, 22)
				loadB.Position = UDim2.new(0, 4, 0, 26)
				loadB.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				loadB.BorderSizePixel = 0
				loadB.Text = "Load Config"
				loadB.Font = Enum.Font.GothamMedium
				loadB.TextSize = 10
				loadB.TextColor3 = WHITE
				loadB.AutoButtonColor = false
				loadB.Parent = row
				Instance.new("UICorner", loadB).CornerRadius = UDim.new(0, 4)

				local delB = Instance.new("TextButton")
				delB.Size = UDim2.new(0.48, -4, 0, 22)
				delB.Position = UDim2.new(0.52, 0, 0, 26)
				delB.BackgroundColor3 = Color3.fromRGB(40, 18, 18)
				delB.BorderSizePixel = 0
				delB.Text = "Delete Config"
				delB.Font = Enum.Font.GothamMedium
				delB.TextSize = 10
				delB.TextColor3 = WHITE
				delB.AutoButtonColor = false
				delB.Parent = row
				Instance.new("UICorner", delB).CornerRadius = UDim.new(0, 4)

				loadB.MouseButton1Click:Connect(function()
					local ok, info = loadConfig(name)
					UI.toast(ok and ("Loaded: " .. name .. (info and (" (" .. info .. ")") or "")) or ("Load failed: " .. tostring(info)))
				end)
				delB.MouseButton1Click:Connect(function()
					deleteConfig(name)
					refreshList()
					UI.toast("Deleted: " .. name)
				end)
			end
			listHolder.CanvasSize = UDim2.new(0, 0, 0, math.max(0, #names * 58))
		end

		saveBtn.MouseButton1Click:Connect(function()
			-- modal
			local modal = Instance.new("Frame")
			modal.Size = UDim2.new(0, 220, 0, 110)
			modal.Position = UDim2.new(0.5, 0, 0.5, 0)
			modal.AnchorPoint = Vector2.new(0.5, 0.5)
			modal.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
			modal.BorderSizePixel = 0
			modal.ZIndex = 350
			modal.Parent = screenGui
			Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 8)
			local ms = Instance.new("UIStroke")
			ms.Color = WHITE
			ms.Thickness = 1
			ms.Transparency = 0.4
			ms.Parent = modal

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -16, 0, 20)
			title.Position = UDim2.new(0, 8, 0, 8)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBold
			title.TextSize = 12
			title.TextColor3 = WHITE
			title.Text = "Config name"
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.ZIndex = 351
			title.Parent = modal

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -16, 0, 26)
			box.Position = UDim2.new(0, 8, 0, 32)
			box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			box.BorderSizePixel = 0
			box.Font = Enum.Font.GothamMedium
			box.TextSize = 12
			box.TextColor3 = WHITE
			box.PlaceholderText = "my config"
			box.Text = ""
			box.ClearTextOnFocus = false
			box.ZIndex = 351
			box.Parent = modal
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

			local cancel = Instance.new("TextButton")
			cancel.Size = UDim2.new(0.45, -6, 0, 26)
			cancel.Position = UDim2.new(0, 8, 1, -34)
			cancel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			cancel.BorderSizePixel = 0
			cancel.Text = "Cancel"
			cancel.Font = Enum.Font.GothamMedium
			cancel.TextSize = 11
			cancel.TextColor3 = WHITE
			cancel.ZIndex = 351
			cancel.Parent = modal
			Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 5)

			local save = Instance.new("TextButton")
			save.Size = UDim2.new(0.45, -6, 0, 26)
			save.Position = UDim2.new(0.55, 0, 1, -34)
			save.BackgroundColor3 = Color3.fromRGB(0, 90, 70)
			save.BorderSizePixel = 0
			save.Text = "Save"
			save.Font = Enum.Font.GothamBold
			save.TextSize = 11
			save.TextColor3 = WHITE
			save.ZIndex = 351
			save.Parent = modal
			Instance.new("UICorner", save).CornerRadius = UDim.new(0, 5)

			cancel.MouseButton1Click:Connect(function() modal:Destroy() end)
			save.MouseButton1Click:Connect(function()
				local ok, err = saveConfig(box.Text)
				modal:Destroy()
				if ok then
					refreshList()
					UI.toast(err and ("Saved (" .. tostring(err) .. ")") or ("Saved: " .. box.Text))
				else
					UI.toast("Save failed: " .. tostring(err))
				end
			end)
		end)

		refreshList()
	end
end


print("[mellowyn.ft] GUI loaded successfully")
