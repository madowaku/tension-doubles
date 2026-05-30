-- Tension Doubles: PINTO HARE! / UI client v0.5.2
-- Return Balance Patch: safer score placement, rotate hint, shorter touch copy.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes")
local MatchStateEvent = Remotes:WaitForChild("MatchStateEvent")
local HitFxEvent = Remotes:WaitForChild("HitFxEvent")
local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))

local isTouch = UserInputService.TouchEnabled
local isGamepad = UserInputService.GamepadEnabled and not isTouch
local subMessageHoldUntil = 0

local function preferLandscape()
	if not isTouch or Config.PreferLandscape == false then
		return
	end
	pcall(function()
		playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
	pcall(function()
		StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
	end)
end
preferLandscape()

local gui = Instance.new("ScreenGui")
gui.Name = "TensionDoublesHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = playerGui

local function makeLabel(name, size, position, textSize, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.22
	label.Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold
	label.TextScaled = false
	label.TextSize = textSize
	label.TextWrapped = true
	label.Text = ""
	label.Parent = gui
	return label
end

local scoreLabel = makeLabel("ScoreLabel", UDim2.fromScale(0.74, 0.08), UDim2.fromScale(0.5, 0.075), isTouch and 31 or 36, true)
local messageLabel = makeLabel("MessageLabel", UDim2.fromScale(0.90, 0.18), UDim2.fromScale(0.5, 0.21), isTouch and 42 or 48, true)
local subMessageLabel = makeLabel("SubMessageLabel", UDim2.fromScale(0.86, 0.07), UDim2.fromScale(0.5, 0.305), isTouch and 20 or 22, false)
local hintLabel = makeLabel("HintLabel", UDim2.fromScale(0.88, 0.08), UDim2.fromScale(0.5, 0.90), isTouch and 18 or 22, false)
local netGuideLabel = makeLabel("NetGuideLabel", UDim2.fromScale(0.62, 0.07), UDim2.fromScale(0.5, 0.80), isTouch and 19 or 22, true)
netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
netGuideLabel.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
netGuideLabel.BackgroundTransparency = 0.38
netGuideLabel.ZIndex = 12
netGuideLabel.Text = ""

local rotateHint = Instance.new("Frame")
rotateHint.Name = "RotateHint"
rotateHint.AnchorPoint = Vector2.new(0.5, 0.5)
rotateHint.Position = UDim2.fromScale(0.5, 0.405)
rotateHint.Size = UDim2.fromScale(0.62, 0.068)
rotateHint.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
rotateHint.BackgroundTransparency = 0.34
rotateHint.Visible = false
rotateHint.ZIndex = 14
rotateHint.Parent = gui

local rotateCorner = Instance.new("UICorner")
rotateCorner.CornerRadius = UDim.new(0, 18)
rotateCorner.Parent = rotateHint

local rotateStroke = Instance.new("UIStroke")
rotateStroke.Color = Color3.fromRGB(255, 220, 90)
rotateStroke.Thickness = 1.5
rotateStroke.Transparency = 0.30
rotateStroke.Parent = rotateHint

local rotateLabel = Instance.new("TextLabel")
rotateLabel.BackgroundTransparency = 1
rotateLabel.Size = UDim2.fromScale(0.94, 0.86)
rotateLabel.Position = UDim2.fromScale(0.03, 0.07)
rotateLabel.Text = Config.MobileRotateHintText or "Best in landscape"
rotateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rotateLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rotateLabel.TextStrokeTransparency = 0.25
rotateLabel.Font = Enum.Font.GothamBlack
rotateLabel.TextScaled = true
rotateLabel.TextWrapped = true
rotateLabel.ZIndex = 15
rotateLabel.Parent = rotateHint

local function isPortrait()
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	local viewport = camera.ViewportSize
	return viewport.Y > viewport.X
end

local function deviceHintText(portrait)
	if isTouch then
		if portrait then
			return Config.TouchPortraitHint or "Rotate sideways for best play."
		end
		return Config.TouchLandscapeHint or Config.TouchHint or "Hold PIN together!"
	elseif isGamepad then
		return Config.GamepadHint or "Hold R2 / X: PIN"
	end
	return Config.DesktopHint or "Hold E / Space / Shift: PIN"
end

local function applyResponsiveLayout()
	local portrait = isTouch and isPortrait()
	if isTouch then
		scoreLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileScoreYPortrait or 0.095) or (Config.MobileScoreYLandscape or 0.105))
		scoreLabel.TextSize = portrait and 27 or 32
		messageLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileMessageYPortrait or 0.205) or (Config.MobileMessageYLandscape or 0.215))
		messageLabel.TextSize = portrait and 37 or 44
		subMessageLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileSubMessageYPortrait or 0.300) or (Config.MobileSubMessageYLandscape or 0.315))
		subMessageLabel.TextSize = portrait and 18 or 21
		hintLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileHintYPortrait or 0.865) or (Config.MobileHintYLandscape or 0.895))
		hintLabel.Size = UDim2.fromScale(portrait and 0.82 or 0.66, portrait and 0.07 or 0.06)
		hintLabel.TextSize = portrait and 16 or 18
		hintLabel.Text = deviceHintText(portrait)
		netGuideLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileNetGuideYPortrait or 0.815) or (Config.MobileNetGuideYLandscape or 0.805))
		netGuideLabel.Size = UDim2.fromScale(portrait and (Config.MobileNetGuideWidthPortrait or 0.72) or (Config.MobileNetGuideWidthLandscape or 0.60), portrait and 0.060 or 0.064)
		netGuideLabel.TextSize = portrait and 18 or 18
		netGuideLabel.BackgroundTransparency = portrait and 0.42 or (Config.MobileNetGuideBgTransparencyLandscape or 0.56)
		rotateHint.Visible = Config.ShowRotateHint ~= false and portrait
		if Config.MobileRotateHintNonBlocking ~= false then
			rotateHint.Position = UDim2.fromScale(0.5, 0.405)
			rotateHint.Size = UDim2.fromScale(0.62, 0.068)
			rotateHint.BackgroundTransparency = 0.34
			rotateHint.ZIndex = 14
			rotateLabel.ZIndex = 15
		end
	else
		scoreLabel.Position = UDim2.fromScale(0.5, 0.065)
		scoreLabel.TextSize = 36
		messageLabel.Position = UDim2.fromScale(0.5, 0.19)
		messageLabel.TextSize = 48
		subMessageLabel.Position = UDim2.fromScale(0.5, 0.285)
		subMessageLabel.TextSize = 22
		hintLabel.Position = UDim2.fromScale(0.5, 0.93)
		hintLabel.TextSize = 22
		hintLabel.Text = deviceHintText(false)
		netGuideLabel.Position = UDim2.fromScale(0.5, 0.82)
		netGuideLabel.Size = UDim2.fromScale(0.46, 0.062)
		netGuideLabel.TextSize = 22
		netGuideLabel.BackgroundTransparency = 0.38
		rotateHint.Visible = false
	end
end

applyResponsiveLayout()
local cameraForViewport = workspace.CurrentCamera
if cameraForViewport then
	cameraForViewport:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
end

if isTouch and (Config.MobileHintFadeDelay or 0) > 0 then
	task.delay(Config.MobileHintFadeDelay, function()
		TweenService:Create(hintLabel, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0.32,
			TextStrokeTransparency = 0.55,
		}):Play()
	end)
end

local flash = Instance.new("Frame")
flash.Name = "HareFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
flash.BackgroundTransparency = 1
flash.ZIndex = 40
flash.Parent = gui

local fxLayer = Instance.new("Frame")
fxLayer.Name = "FxLayer"
fxLayer.Size = UDim2.fromScale(1, 1)
fxLayer.BackgroundTransparency = 1
fxLayer.ZIndex = 30
fxLayer.Parent = gui

local tutorialPanel = Instance.new("Frame")
tutorialPanel.Name = "QuickTutorial"
tutorialPanel.AnchorPoint = Vector2.new(0.5, 0.5)
tutorialPanel.Position = UDim2.fromScale(isTouch and 0.42 or 0.18, isTouch and 0.39 or 0.43)
tutorialPanel.Size = UDim2.fromScale(isTouch and 0.54 or 0.28, isTouch and 0.20 or 0.24)
tutorialPanel.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
tutorialPanel.BackgroundTransparency = 1
tutorialPanel.Visible = false
tutorialPanel.ZIndex = 25
tutorialPanel.Parent = gui

local tutorialCorner = Instance.new("UICorner")
tutorialCorner.CornerRadius = UDim.new(0, 18)
tutorialCorner.Parent = tutorialPanel

local tutorialStroke = Instance.new("UIStroke")
tutorialStroke.Color = Color3.fromRGB(255, 220, 90)
tutorialStroke.Thickness = 2
tutorialStroke.Transparency = 1
tutorialStroke.Parent = tutorialPanel

local tutorialTitle = Instance.new("TextLabel")
tutorialTitle.Name = "Title"
tutorialTitle.BackgroundTransparency = 1
tutorialTitle.Position = UDim2.fromScale(0.06, 0.04)
tutorialTitle.Size = UDim2.fromScale(0.88, 0.24)
tutorialTitle.Font = Enum.Font.GothamBlack
tutorialTitle.Text = "HOW TO PLAY"
tutorialTitle.TextColor3 = Color3.fromRGB(255, 235, 120)
tutorialTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
tutorialTitle.TextStrokeTransparency = 0.35
tutorialTitle.TextScaled = true
tutorialTitle.ZIndex = 26
tutorialTitle.Parent = tutorialPanel

local tutorialStep = Instance.new("TextLabel")
tutorialStep.Name = "Step"
tutorialStep.BackgroundTransparency = 1
tutorialStep.Position = UDim2.fromScale(0.07, 0.30)
tutorialStep.Size = UDim2.fromScale(0.86, 0.60)
tutorialStep.Font = Enum.Font.GothamBlack
tutorialStep.Text = ""
tutorialStep.TextColor3 = Color3.fromRGB(255, 255, 255)
tutorialStep.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
tutorialStep.TextStrokeTransparency = 0.25
tutorialStep.TextWrapped = true
tutorialStep.TextScaled = true
tutorialStep.ZIndex = 26
tutorialStep.Parent = tutorialPanel

local tutorialShown = false
local function tweenTutorial(transparency)
	TweenService:Create(tutorialPanel, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = transparency,
	}):Play()
	TweenService:Create(tutorialStroke, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = transparency,
	}):Play()
	TweenService:Create(tutorialTitle, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = transparency,
		TextStrokeTransparency = math.min(1, transparency + 0.35),
	}):Play()
	TweenService:Create(tutorialStep, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = transparency,
		TextStrokeTransparency = math.min(1, transparency + 0.25),
	}):Play()
end

local function showOnboardingOnce()
	if tutorialShown or Config.OnboardingEnabled == false then
		return
	end
	tutorialShown = true
	tutorialPanel.Visible = true
	tweenTutorial(0.14)

	local steps = Config.First30OnboardingSteps or {
		"Make a Tension Fiber net with your partner.",
		"Move apart until it says TENSION OK.",
		"Hold PIN together to spark HARE!",
	}

	task.spawn(function()
		local stepDuration = Config.OnboardingStepDuration or 1.35
		for _, step in ipairs(steps) do
			tutorialStep.TextTransparency = 1
			tutorialStep.TextStrokeTransparency = 1
			tutorialStep.Text = step
			TweenService:Create(tutorialStep, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
				TextStrokeTransparency = 0.25,
			}):Play()
			task.wait(stepDuration)
		end
		tweenTutorial(1)
		task.wait(0.32)
		tutorialPanel.Visible = false
	end)
end

local function fxTextForType(fxType, comboCount)
	if fxType == "Hare" then
		if comboCount and comboCount >= 2 then
			return "HARE!! x" .. tostring(comboCount), Color3.fromRGB(255, 230, 90)
		end
		return "HARE!!", Color3.fromRGB(255, 230, 90)
	elseif fxType == "OnePin" then
		return "ONE PIN!", Color3.fromRGB(255, 170, 95)
	elseif fxType == "Slack" then
		return "SLACK!", Color3.fromRGB(95, 190, 255)
	elseif fxType == "OverTension" then
		return "TOO TIGHT!", Color3.fromRGB(255, 90, 90)
	elseif fxType == "Broken" then
		return "FRIENDSHIP BREAK!", Color3.fromRGB(210, 210, 210)
	end
	return Config.NormalHitText or "FIBER HIT!", Color3.fromRGB(245, 245, 255)
end

local function playHareFlash(comboCount)
	flash.BackgroundTransparency = comboCount and comboCount >= 2 and 0.50 or 0.62
	TweenService:Create(flash, TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
end

local function showFloatingFx(fxType, teamName, rallyCount, comboCount)
	local text, color = fxTextForType(fxType, comboCount)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.13
	label.Font = Enum.Font.GothamBlack
	label.TextSize = fxType == "Hare" and (isTouch and 60 or 76) or (isTouch and 36 or 46)
	label.TextScaled = false
	label.TextWrapped = true
	label.Size = fxType == "Hare" and UDim2.fromScale(0.86, 0.17) or (fxType == "Broken" and UDim2.fromScale(0.78, 0.15) or UDim2.fromScale(0.56, 0.14))

	local x = teamName == "Red" and 0.42 or 0.58
	if fxType == "Hare" then
		x = 0.5
	end
	label.Position = UDim2.fromScale(x, fxType == "Hare" and 0.46 or 0.50)
	label.Parent = fxLayer

	if fxType == "Hare" then
		playHareFlash(comboCount)
		local hareSubtitle = Config.HareSubtitleText or "TEAM SYNC!"
		if comboCount and comboCount >= 2 then
			hareSubtitle = hareSubtitle .. " x" .. tostring(comboCount)
		end
		subMessageLabel.Text = hareSubtitle
		subMessageHoldUntil = os.clock() + 1.05
		task.delay(0.95, function()
			if subMessageLabel.Text == hareSubtitle then
				subMessageLabel.Text = ""
			end
		end)
	end

	local tween = TweenService:Create(label, TweenInfo.new(fxType == "Hare" and 1.10 or 0.82, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = label.Position - UDim2.fromScale(0, 0.09),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)

	if rallyCount and rallyCount >= 6 then
		subMessageLabel.Text = "RALLY x" .. tostring(rallyCount)
		task.delay(1.0, function()
			if subMessageLabel.Text == "RALLY x" .. tostring(rallyCount) then
				subMessageLabel.Text = ""
			end
		end)
	end
end

local function normalizeMessage(message)
	if message == "" or message == nil then
		return ""
	end
	return tostring(message)
end

local function setMessage(text, sizeBoost)
	local portrait = isTouch and isPortrait()
	messageLabel.Text = text
	messageLabel.TextSize = ((isTouch and (portrait and 37 or 44)) or 48) + (sizeBoost or 0)
end

local function updateNetGuidance(data)
	local localTeam = localPlayer.Team and localPlayer.Team.Name
	local guidance = localTeam and data.netGuidance and data.netGuidance[localTeam]
	if guidance and guidance.text then
		netGuideLabel.Text = guidance.text
		if guidance.state == "Normal" then
			netGuideLabel.TextColor3 = Color3.fromRGB(150, 255, 205)
		elseif guidance.state == "Slack" then
			netGuideLabel.TextColor3 = Color3.fromRGB(120, 205, 255)
		elseif guidance.state == "OverTension" or guidance.state == "Broken" then
			netGuideLabel.TextColor3 = Color3.fromRGB(255, 135, 125)
		else
			netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
		end
	else
		netGuideLabel.Text = Config.NetGuideMakeText or "MAKE A NET"
		netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
	end
end

MatchStateEvent.OnClientEvent:Connect(function(data)
	applyResponsiveLayout()
	local redScore = data.redScore or 0
	local blueScore = data.blueScore or 0
	scoreLabel.Text = string.format("RED  %d  -  %d  BLUE", redScore, blueScore)
	updateNetGuidance(data)

	local state = data.state or ""
	local message = normalizeMessage(data.message)

	if state == "WaitingForPlayers" then
		showOnboardingOnce()
		setMessage("WAITING", 0)
		if message ~= "" then
			subMessageLabel.Text = Config.WaitingSubMessage or message
		else
			subMessageLabel.Text = Config.WaitingSubMessage or string.format("Red %d/2 - Blue %d/2", data.redPlayers or 0, data.bluePlayers or 0)
		end
	elseif state == "Countdown" then
		showOnboardingOnce()
		setMessage(message ~= "" and message or "3", 20)
		subMessageLabel.Text = ""
	elseif state == "Serving" then
		setMessage(message, 0)
		subMessageLabel.Text = Config.ServingSubMessage or "Track the ball!"
	elseif state == "Rally" then
		messageLabel.Text = ""
		if os.clock() >= subMessageHoldUntil then
			subMessageLabel.Text = Config.RallySubMessage or ""
		end
	elseif state == "PointScored" then
		setMessage(message, 4)
		subMessageHoldUntil = 0
		if string.find(message, "DROP!", 1, true) then
			subMessageLabel.Text = Config.FailSubtitleDropText or Config.PointSubMessage or "NEXT SERVE!"
		elseif string.find(message, "OUT!", 1, true) then
			subMessageLabel.Text = Config.FailSubtitleOutText or Config.PointSubMessage or "NEXT SERVE!"
		else
			subMessageLabel.Text = Config.PointSubMessage or "NEXT SERVE!"
		end
	elseif state == "GameOver" then
		setMessage(message ~= "" and message or "GAME SET!", 4)
		subMessageLabel.Text = Config.GameOverSubMessage or "NEXT MATCH INCOMING!"
	else
		setMessage(message ~= "" and message or state, 0)
		subMessageLabel.Text = ""
	end
end)

HitFxEvent.OnClientEvent:Connect(function(fxType, _position, teamName, rallyCount, comboCount)
	showFloatingFx(fxType, teamName, rallyCount, comboCount)
end)
