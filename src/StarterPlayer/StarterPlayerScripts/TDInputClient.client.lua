-- Tension Doubles: PINTO HARE! / Input client v0.5.2
-- Mobile-first controls with landscape-friendly PIN button placement.
-- PC/Gamepad: hold E / Space / LeftShift / R2 / X to PIN.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes")
local PinInputEvent = Remotes:WaitForChild("PinInputEvent")

local ACTION_NAME = "TensionDoubles_Pin"
local isPinning = false
local pinButton = nil
local buttonStroke = nil
local buttonGlow = nil
local helperLabel = nil
local baseButtonScale = Config.MobilePinButtonScaleLandscape or 0.165
local pressedButtonScale = baseButtonScale + 0.026
local currentButtonPosition = UDim2.fromScale(Config.MobilePinButtonXLandscape or 0.885, Config.MobilePinButtonYLandscape or 0.705)

local function preferLandscape()
	if not UserInputService.TouchEnabled or Config.PreferLandscape == false then
		return
	end
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
	pcall(function()
		StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
end

local function isPortrait()
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	local viewport = camera.ViewportSize
	return viewport.Y > viewport.X
end

local function tweenButton(sizeScale, bg, textColor, glowTransparency)
	if not pinButton then
		return
	end
	TweenService:Create(pinButton, TweenInfo.new(0.075, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(sizeScale, sizeScale),
		BackgroundColor3 = bg,
		TextColor3 = textColor,
	}):Play()
	if buttonGlow then
		TweenService:Create(buttonGlow, TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(sizeScale + 0.045, sizeScale + 0.045),
			Position = currentButtonPosition,
			Transparency = glowTransparency or 0.78,
		}):Play()
	end
end

local function updateButtonVisual()
	if not pinButton then
		return
	end

	local portrait = isPortrait()
	local showHelper = Config.ShowPinButtonHelper == true and (portrait or not (Config.HidePinButtonHintLandscape == true))
	if isPinning then
		pinButton.Text = "PIN!"
		if helperLabel then
			helperLabel.Text = "Hold!"
			helperLabel.Visible = showHelper
		end
		if buttonStroke then
			buttonStroke.Color = Color3.fromRGB(255, 225, 90)
			buttonStroke.Thickness = 7
		end
		tweenButton(pressedButtonScale, Color3.fromRGB(255, 216, 84), Color3.fromRGB(35, 30, 10), 0.25)
	else
		pinButton.Text = "PIN"
		if helperLabel then
			helperLabel.Text = "Hold"
			helperLabel.Visible = showHelper
		end
		if buttonStroke then
			buttonStroke.Color = Color3.fromRGB(40, 44, 58)
			buttonStroke.Thickness = 4
		end
		tweenButton(baseButtonScale, Color3.fromRGB(245, 245, 255), Color3.fromRGB(20, 24, 34), 0.82)
	end
end

local function setPinning(value)
	if isPinning == value then
		return
	end
	isPinning = value
	updateButtonVisual()
	PinInputEvent:FireServer(isPinning)
end

local function onPinAction(_, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		setPinning(true)
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		setPinning(false)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	ACTION_NAME,
	onPinAction,
	false,
	Enum.KeyCode.E,
	Enum.KeyCode.Space,
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonX
)

local function applyMobileButtonLayout()
	if not pinButton then
		return
	end

	local portrait = isPortrait()
	baseButtonScale = portrait and (Config.MobilePinButtonScalePortrait or 0.205) or (Config.MobilePinButtonScaleLandscape or 0.165)
	pressedButtonScale = baseButtonScale + (portrait and 0.026 or 0.024)
	local x = portrait and (Config.MobilePinButtonXPortrait or 0.835) or (Config.MobilePinButtonXLandscape or 0.885)
	local y = portrait and (Config.MobilePinButtonYPortrait or 0.745) or (Config.MobilePinButtonYLandscape or 0.705)
	currentButtonPosition = UDim2.fromScale(x, y)

	pinButton.Position = currentButtonPosition
	pinButton.Size = UDim2.fromScale(isPinning and pressedButtonScale or baseButtonScale, isPinning and pressedButtonScale or baseButtonScale)
	if buttonGlow then
		buttonGlow.Position = currentButtonPosition
		buttonGlow.Size = UDim2.fromScale(baseButtonScale + 0.045, baseButtonScale + 0.045)
	end
	if helperLabel then
		helperLabel.Visible = Config.ShowPinButtonHelper == true and (portrait or not (Config.HidePinButtonHintLandscape == true))
		helperLabel.Position = UDim2.fromScale(x, math.min(0.94, y + (portrait and 0.145 or 0.155)))
		helperLabel.Size = UDim2.fromScale(portrait and 0.30 or 0.16, portrait and 0.050 or 0.044)
	end
end

local function createMobilePinButton()
	if not UserInputService.TouchEnabled then
		return
	end
	if playerGui:FindFirstChild("TensionDoublesMobileControls") then
		return
	end

	preferLandscape()

	local gui = Instance.new("ScreenGui")
	gui.Name = "TensionDoublesMobileControls"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 35
	gui.Parent = playerGui

	local glow = Instance.new("Frame")
	glow.Name = "PinGlow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = currentButtonPosition
	glow.Size = UDim2.fromScale(baseButtonScale + 0.045, baseButtonScale + 0.045)
	glow.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
	glow.BackgroundTransparency = 0.82
	glow.ZIndex = 9
	glow.Parent = gui

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glow

	local button = Instance.new("TextButton")
	button.Name = "PinButton"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = currentButtonPosition
	button.Size = UDim2.fromScale(baseButtonScale, baseButtonScale)
	button.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
	button.BackgroundTransparency = 0.02
	button.Text = "PIN"
	button.TextColor3 = Color3.fromRGB(20, 24, 34)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBlack
	button.AutoButtonColor = false
	button.ZIndex = 10
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(40, 44, 58)
	stroke.Transparency = 0.02
	stroke.Parent = button

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = button

	local helper = Instance.new("TextLabel")
	helper.Name = "PinButtonHint"
	helper.AnchorPoint = Vector2.new(0.5, 0.5)
	helper.BackgroundTransparency = 1
	helper.Text = "Hold"
	helper.TextColor3 = Color3.fromRGB(255, 255, 255)
	helper.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	helper.TextStrokeTransparency = 0.35
	helper.Font = Enum.Font.GothamBold
	helper.TextScaled = true
	helper.Parent = gui

	pinButton = button
	buttonStroke = stroke
	buttonGlow = glow
	helperLabel = helper
	applyMobileButtonLayout()
	updateButtonVisual()

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setPinning(true)
		end
	end)

	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setPinning(false)
		end
	end)

	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyMobileButtonLayout()
		end)
	end
end

createMobilePinButton()

localPlayer.CharacterRemoving:Connect(function()
	setPinning(false)
end)

UserInputService.WindowFocusReleased:Connect(function()
	setPinning(false)
end)
