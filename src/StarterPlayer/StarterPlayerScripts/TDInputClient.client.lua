-- Tension Doubles: PINTO HARE! / Input client v0.5.2
-- Mobile-first controls with landscape-friendly PIN button placement.
-- PC/Gamepad: hold E / Space / LeftShift / R2 / X to PIN.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes")
local PinInputEvent = Remotes:WaitForChild("PinInputEvent")
local LobbyReadyEvent = Remotes:WaitForChild("LobbyReadyEvent")
local MatchStateEvent = Remotes:WaitForChild("MatchStateEvent")

local ACTION_NAME = "TensionDoubles_Pin"
local READY_ACTION_NAME = "TensionDoubles_LobbyReady"
local isPinning = false
local isLobbyReady = false
local isInLobby = false
local currentLobbyState = "WaitingForPlayers"
local pinButton = nil
local readyButton = nil
local buttonStroke = nil
local buttonGlow = nil
local helperLabel = nil
local controlsGui = nil
local baseButtonScale = Config.MobilePinButtonScaleLandscape or 0.165
local pressedButtonScale = baseButtonScale + 0.026
local currentButtonPosition = UDim2.fromScale(Config.MobilePinButtonXLandscape or 0.885, Config.MobilePinButtonYLandscape or 0.705)

local function getSfxSoundGroup()
	local groupName = Config.SfxSoundGroupName or "TDSFX"
	local soundGroup = SoundService:FindFirstChild(groupName)
	if not soundGroup then
		soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = groupName
		soundGroup.Volume = Config.SfxDefaultVolume or 0.70
		soundGroup.Parent = SoundService
	end
	return soundGroup
end

local function playPinSfx()
	if Config.AudioMixerEnabled == false then
		return
	end
	local ids = Config.AudioSfxSoundIds or {}
	local soundId = ids.Pin
	if not soundId or soundId == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "TD_PinSfx"
	sound.SoundId = soundId
	sound.Volume = 0.8
	sound.PlaybackSpeed = 1.15
	sound.SoundGroup = getSfxSoundGroup()
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 2)
end

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
	if isPinning then
		playPinSfx()
	end
	PinInputEvent:FireServer(isPinning)
end

local function updateReadyButton()
	if not readyButton then
		return
	end
	readyButton.Visible = isInLobby
	if isLobbyReady then
		readyButton.Text = "READY!"
		readyButton.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
		readyButton.TextColor3 = Color3.fromRGB(35, 30, 10)
	else
		readyButton.Text = currentLobbyState == "WaitingForPlayers" and "JOIN MATCH" or "READY"
		readyButton.BackgroundColor3 = Color3.fromRGB(245, 245, 255)
		readyButton.TextColor3 = Color3.fromRGB(20, 24, 34)
	end
end

local function setLobbyReady(value)
	if not isInLobby then
		return
	end
	isLobbyReady = value == true
	updateReadyButton()
	LobbyReadyEvent:FireServer(isLobbyReady)
end

local function toggleLobbyReady()
	setLobbyReady(not isLobbyReady)
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

local function onReadyAction(_, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		toggleLobbyReady()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	READY_ACTION_NAME,
	onReadyAction,
	false,
	Enum.KeyCode.R,
	Enum.KeyCode.ButtonY
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

local function getOrCreateControlsGui()
	if controlsGui then
		return controlsGui
	end

	controlsGui = playerGui:FindFirstChild("TensionDoublesPlayerControls")
	if controlsGui then
		for _, child in ipairs(controlsGui:GetChildren()) do
			child:Destroy()
		end
		return controlsGui
	end

	controlsGui = playerGui:FindFirstChild("TensionDoublesMobileControls")
	if controlsGui then
		controlsGui.Name = "TensionDoublesPlayerControls"
		for _, child in ipairs(controlsGui:GetChildren()) do
			child:Destroy()
		end
		return controlsGui
	end

	preferLandscape()

	local gui = Instance.new("ScreenGui")
	gui.Name = "TensionDoublesPlayerControls"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 35
	gui.Parent = playerGui

	controlsGui = gui
	return gui
end

local function createReadyButton(gui)
	if readyButton then
		return
	end

	local ready = Instance.new("TextButton")
	ready.Name = "ReadyButton"
	ready.AnchorPoint = Vector2.new(0.5, 0.5)
	ready.Position = UDim2.fromScale(0.5, Config.LobbyMainButtonY or 0.545)
	ready.Size = UDim2.fromScale(
		UserInputService.TouchEnabled and (Config.LobbyMainButtonWidthTouch or 0.34) or (Config.LobbyMainButtonWidthDesktop or 0.24),
		UserInputService.TouchEnabled and (Config.LobbyMainButtonHeightTouch or 0.105) or (Config.LobbyMainButtonHeightDesktop or 0.085)
	)
	ready.BackgroundTransparency = 0.02
	ready.TextScaled = true
	ready.Font = Enum.Font.GothamBlack
	ready.AutoButtonColor = false
	ready.Visible = false
	ready.ZIndex = 12
	ready.Parent = gui

	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, 10)
	readyCorner.Parent = ready

	local readyStroke = Instance.new("UIStroke")
	readyStroke.Thickness = 3
	readyStroke.Color = Color3.fromRGB(40, 44, 58)
	readyStroke.Transparency = 0.02
	readyStroke.Parent = ready

	readyButton = ready
	updateReadyButton()

	ready.Activated:Connect(function()
		toggleLobbyReady()
	end)
end

local function createMobilePinButton(gui)
	if pinButton then
		return
	end

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

local function createPlayerControls()
	local gui = getOrCreateControlsGui()
	createReadyButton(gui)
	if UserInputService.TouchEnabled then
		createMobilePinButton(gui)
	end
end

createPlayerControls()

MatchStateEvent.OnClientEvent:Connect(function(data)
	local state = data.state or ""
	local wasInLobby = isInLobby
	currentLobbyState = state
	isInLobby = state == "Lobby" or state == "WaitingForPlayers"
	if not isInLobby and wasInLobby then
		isLobbyReady = false
	end
	updateReadyButton()
end)

localPlayer.CharacterRemoving:Connect(function()
	setPinning(false)
end)

UserInputService.WindowFocusReleased:Connect(function()
	setPinning(false)
end)
