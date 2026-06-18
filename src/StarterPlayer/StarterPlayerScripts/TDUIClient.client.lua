-- Tension Doubles: PINTO HARE! / UI client v0.5.2
-- Return Balance Patch: safer score placement, rotate hint, shorter touch copy.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes", 5)
local remotesReady = Remotes ~= nil
local MatchStateEvent = remotesReady and Remotes:WaitForChild("MatchStateEvent", 5) or nil
local HitFxEvent = remotesReady and Remotes:WaitForChild("HitFxEvent", 5) or nil
local MonetizationRequestEvent = remotesReady and Remotes:WaitForChild("MonetizationRequestEvent", 5) or nil
local MonetizationStateEvent = remotesReady and Remotes:WaitForChild("MonetizationStateEvent", 5) or nil

local isTouch = UserInputService.TouchEnabled
local isGamepad = UserInputService.GamepadEnabled and not isTouch
local subMessageHoldUntil = 0
local lobbyGuideCompleted = false
local lobbyGuideStarted = false
local selectedModeLabel = Config.LobbyDefaultModeLabel or "Quick 2v2"
local lobbyReadyStatus = { ready = 0, needed = 1 }

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

local lobbyGuidePanel = Instance.new("Frame")
lobbyGuidePanel.Name = "LobbyJoinGuide"
lobbyGuidePanel.AnchorPoint = Vector2.new(0.5, 0.5)
lobbyGuidePanel.Position = UDim2.fromScale(0.5, 0.70)
lobbyGuidePanel.Size = UDim2.fromScale(0.58, 0.14)
lobbyGuidePanel.BackgroundColor3 = Color3.fromRGB(7, 12, 22)
lobbyGuidePanel.BackgroundTransparency = 0.16
lobbyGuidePanel.Visible = false
lobbyGuidePanel.ZIndex = 18
lobbyGuidePanel.Parent = gui

local lobbyGuideCorner = Instance.new("UICorner")
lobbyGuideCorner.CornerRadius = UDim.new(0, 10)
lobbyGuideCorner.Parent = lobbyGuidePanel

local lobbyGuideStroke = Instance.new("UIStroke")
lobbyGuideStroke.Color = Color3.fromRGB(255, 220, 90)
lobbyGuideStroke.Thickness = 2
lobbyGuideStroke.Transparency = 0.18
lobbyGuideStroke.Parent = lobbyGuidePanel

local lobbyActiveStepLabel = Instance.new("TextLabel")
lobbyActiveStepLabel.Name = "ActiveStep"
lobbyActiveStepLabel.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
lobbyActiveStepLabel.BackgroundTransparency = 0.04
lobbyActiveStepLabel.Position = UDim2.fromScale(0.03, 0.08)
lobbyActiveStepLabel.Size = UDim2.fromScale(0.94, 0.48)
lobbyActiveStepLabel.Font = Enum.Font.GothamBlack
lobbyActiveStepLabel.Text = Config.LobbyGuideStepModeText or "1  CHOOSE MODE"
lobbyActiveStepLabel.TextColor3 = Color3.fromRGB(28, 24, 10)
lobbyActiveStepLabel.TextScaled = true
lobbyActiveStepLabel.TextWrapped = true
lobbyActiveStepLabel.ZIndex = 19
lobbyActiveStepLabel.Parent = lobbyGuidePanel

local lobbyActiveStepCorner = Instance.new("UICorner")
lobbyActiveStepCorner.CornerRadius = UDim.new(0, 8)
lobbyActiveStepCorner.Parent = lobbyActiveStepLabel

local lobbyModeSummaryLabel = Instance.new("TextLabel")
lobbyModeSummaryLabel.Name = "ModeSummary"
lobbyModeSummaryLabel.BackgroundTransparency = 1
lobbyModeSummaryLabel.Position = UDim2.fromScale(0.04, 0.62)
lobbyModeSummaryLabel.Size = UDim2.fromScale(0.44, 0.28)
lobbyModeSummaryLabel.Font = Enum.Font.GothamBold
lobbyModeSummaryLabel.TextColor3 = Color3.fromRGB(225, 235, 248)
lobbyModeSummaryLabel.TextScaled = true
lobbyModeSummaryLabel.TextWrapped = true
lobbyModeSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
lobbyModeSummaryLabel.ZIndex = 19
lobbyModeSummaryLabel.Parent = lobbyGuidePanel

local lobbyThemeSummaryLabel = Instance.new("TextLabel")
lobbyThemeSummaryLabel.Name = "ThemeSummary"
lobbyThemeSummaryLabel.BackgroundTransparency = 1
lobbyThemeSummaryLabel.Position = UDim2.fromScale(0.52, 0.62)
lobbyThemeSummaryLabel.Size = UDim2.fromScale(0.44, 0.28)
lobbyThemeSummaryLabel.Font = Enum.Font.GothamBold
lobbyThemeSummaryLabel.TextColor3 = Color3.fromRGB(225, 235, 248)
lobbyThemeSummaryLabel.TextScaled = true
lobbyThemeSummaryLabel.TextWrapped = true
lobbyThemeSummaryLabel.TextXAlignment = Enum.TextXAlignment.Right
lobbyThemeSummaryLabel.ZIndex = 19
lobbyThemeSummaryLabel.Parent = lobbyGuidePanel

if not MatchStateEvent then
	messageLabel.Text = Config.ServerMissingMessage or "SERVER SCRIPT MISSING"
	subMessageLabel.Text = Config.ServerMissingSubMessage or "Import TDServer into ServerScriptService, then Play again."
	netGuideLabel.Text = ""
end

local musicVolume = math.clamp(Config.MusicDefaultVolume or Config.BgmDefaultVolume or 0.55, 0, 1)
local sfxVolume = math.clamp(Config.SfxDefaultVolume or 0.70, 0, 1)
local uiVolume = math.clamp(Config.UiDefaultVolume or 0.65, 0, 1)
local musicSoundGroup = nil
local sfxSoundGroup = nil
local uiSoundGroup = nil

local function getOrCreateSoundGroup(groupName, volume)
	local soundGroup = SoundService:FindFirstChild(groupName)
	if not soundGroup then
		soundGroup = Instance.new("SoundGroup")
		soundGroup.Name = groupName
		soundGroup.Parent = SoundService
	end
	soundGroup.Volume = volume
	return soundGroup
end

local function ensureAudioSoundGroups()
	if Config.AudioMixerEnabled == false then
		return
	end
	musicSoundGroup = getOrCreateSoundGroup(Config.MusicSoundGroupName or "TDMusic", musicVolume)
	sfxSoundGroup = getOrCreateSoundGroup(Config.SfxSoundGroupName or "TDSFX", sfxVolume)
	uiSoundGroup = getOrCreateSoundGroup(Config.UiSoundGroupName or "TDUI", uiVolume)
end

ensureAudioSoundGroups()

local function makeMixerPanel(name, title, y)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.fromScale(Config.AudioMixerTopRightX or 0.985, y)
	panel.Size = UDim2.fromScale(isTouch and 0.27 or 0.18, isTouch and 0.058 or 0.052)
	panel.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
	panel.BackgroundTransparency = 0.22
	panel.Visible = Config.BgmVolumeControlEnabled ~= false and Config.AudioMixerEnabled ~= false
	panel.ZIndex = 52
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.05, 0.10)
	label.Size = UDim2.fromScale(0.46, 0.80)
	label.Font = Enum.Font.GothamBlack
	label.Text = title
	label.TextColor3 = Color3.fromRGB(255, 245, 180)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.35
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 53
	label.Parent = panel

	return panel, label
end

local musicPanel, musicLabel = makeMixerPanel("MusicVolumePanel", Config.BgmPanelTitle or "MUSIC", Config.AudioMixerMusicY or 0.075)
local sfxPanel, sfxLabel = makeMixerPanel("SfxVolumePanel", Config.SfxPanelTitle or "SFX", Config.AudioMixerSfxY or 0.140)

local bgmPanel = musicPanel
local bgmLabel = musicLabel

local function setMixerPanelsVisibleForState(state)
	local visible = Config.BgmVolumeControlEnabled ~= false and Config.AudioMixerEnabled ~= false
	if visible and Config.AudioMixerHideDuringMatch ~= false then
		local visibleStates = Config.AudioMixerVisibleStates or {}
		visible = visibleStates[state] == true
	end
	musicPanel.Visible = visible
	sfxPanel.Visible = visible
end

local function setLobbyPlayerListVisible(state)
	local inLobby = state == "Lobby" or state == "WaitingForPlayers"
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not inLobby)
	end)
end

local function makeBgmButton(parent, name, text, x)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.Position = UDim2.fromScale(x, 0.50)
	button.Size = UDim2.fromScale(0.17, 0.70)
	button.BackgroundColor3 = Color3.fromRGB(255, 220, 110)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(8, 12, 22)
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.ZIndex = 54
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local bgmDownButton = makeBgmButton(musicPanel, "Down", "-", 0.58)
local bgmUpButton = makeBgmButton(musicPanel, "Up", "+", 0.78)
local sfxDownButton = makeBgmButton(sfxPanel, "Down", "-", 0.58)
local sfxUpButton = makeBgmButton(sfxPanel, "Up", "+", 0.78)

local function findBgmSounds()
	local found = {}
	local fallbackSounds = {}
	local names = Config.BgmSoundNames or { "BGM", "Music", "BackgroundMusic", "TD_BGM" }
	local function isNamedBgmSound(soundName)
		for _, name in ipairs(names) do
			if string.lower(soundName) == string.lower(tostring(name)) then
				return true
			end
		end
		return false
	end
	local function isCharacterSound(sound)
		local ancestor = sound.Parent
		while ancestor do
			if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
				return true
			end
			ancestor = ancestor.Parent
		end
		return false
	end
	for _, container in ipairs({ SoundService, workspace }) do
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("Sound") and not isCharacterSound(descendant) then
				if isNamedBgmSound(descendant.Name) then
					table.insert(found, descendant)
				else
					table.insert(fallbackSounds, descendant)
				end
			end
		end
	end
	if #found == 0 then
		return fallbackSounds
	end
	return found
end

local function updateBgmLabel(foundCount)
	local title = Config.BgmPanelTitle or "BGM"
	bgmLabel.Text = string.format("%s %d%%", title, math.floor(musicVolume * 100 + 0.5))
end

local function updateSfxLabel()
	local title = Config.SfxPanelTitle or "SFX"
	sfxLabel.Text = string.format("%s %d%%", title, math.floor(sfxVolume * 100 + 0.5))
end

local function applyMusicVolume()
	ensureAudioSoundGroups()
	local sounds = findBgmSounds()
	for _, sound in ipairs(sounds) do
		sound.SoundGroup = musicSoundGroup
		sound.Volume = musicVolume
	end
	updateBgmLabel(#sounds)
end

local function applyBgmVolume()
	applyMusicVolume()
end

local function applySfxVolume()
	ensureAudioSoundGroups()
	if sfxSoundGroup then
		sfxSoundGroup.Volume = sfxVolume
	end
	if uiSoundGroup then
		uiSoundGroup.Volume = uiVolume
	end
	updateSfxLabel()
end

local function playOneShot(soundId, soundGroup, volumeScale, playbackSpeed)
	if Config.AudioMixerEnabled == false or not soundId or soundId == "" then
		return
	end
	ensureAudioSoundGroups()
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volumeScale or 1
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.SoundGroup = soundGroup
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function playGameSfx(key)
	local ids = Config.AudioSfxSoundIds or {}
	local soundId = ids[key] or ids.Normal
	local speed = 1
	if key == "Hare" then
		speed = 0.86
	elseif key == "OnePin" then
		speed = 1.18
	elseif key == "Slack" then
		speed = 0.72
	elseif key == "Countdown" then
		speed = 1.0
	elseif key == "Start" then
		speed = 1.24
	end
	playOneShot(soundId, sfxSoundGroup, 1, speed)
end

local function playUiSfx(key)
	local ids = Config.AudioSfxSoundIds or {}
	playOneShot(ids[key or "UiClick"] or ids.UiClick, uiSoundGroup, 0.65, 1.18)
end

bgmDownButton.Activated:Connect(function()
	musicVolume = math.clamp(musicVolume - (Config.AudioVolumeStep or Config.BgmVolumeStep or 0.10), 0, 1)
	applyMusicVolume()
	playUiSfx("UiClick")
end)

bgmUpButton.Activated:Connect(function()
	musicVolume = math.clamp(musicVolume + (Config.AudioVolumeStep or Config.BgmVolumeStep or 0.10), 0, 1)
	applyMusicVolume()
	playUiSfx("UiClick")
end)

sfxDownButton.Activated:Connect(function()
	sfxVolume = math.clamp(sfxVolume - (Config.AudioVolumeStep or 0.10), 0, 1)
	applySfxVolume()
	playUiSfx("UiClick")
end)

sfxUpButton.Activated:Connect(function()
	sfxVolume = math.clamp(sfxVolume + (Config.AudioVolumeStep or 0.10), 0, 1)
	applySfxVolume()
	playUiSfx("UiClick")
end)

task.defer(applyMusicVolume)
task.defer(applySfxVolume)
SoundService.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Sound") then
		task.defer(applyMusicVolume)
	end
end)
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Sound") then
		task.defer(applyMusicVolume)
	end
end)

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
		subMessageLabel.Size = UDim2.fromScale(0.86, 0.07)
		subMessageLabel.TextSize = portrait and 18 or 21
		hintLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileHintYPortrait or 0.865) or (Config.MobileHintYLandscape or 0.895))
		hintLabel.Size = UDim2.fromScale(portrait and 0.82 or 0.66, portrait and 0.07 or 0.06)
		hintLabel.TextSize = portrait and 16 or 18
		hintLabel.Text = deviceHintText(portrait)
		netGuideLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileNetGuideYPortrait or 0.815) or (Config.MobileNetGuideYLandscape or 0.805))
		netGuideLabel.Size = UDim2.fromScale(portrait and (Config.MobileNetGuideWidthPortrait or 0.72) or (Config.MobileNetGuideWidthLandscape or 0.60), portrait and 0.060 or 0.064)
		netGuideLabel.TextSize = portrait and 18 or 18
		netGuideLabel.BackgroundTransparency = portrait and 0.42 or (Config.MobileNetGuideBgTransparencyLandscape or 0.56)
		lobbyGuidePanel.Position = UDim2.fromScale(0.5, portrait and (Config.LobbyGuideYTouchPortrait or 0.690) or (Config.LobbyGuideYTouchLandscape or 0.700))
		lobbyGuidePanel.Size = UDim2.fromScale(
			portrait and (Config.LobbyGuideWidthTouchPortrait or 0.84) or (Config.LobbyGuideWidthTouchLandscape or 0.62),
			portrait and 0.145 or 0.130
		)
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
		subMessageLabel.Size = UDim2.fromScale(0.86, 0.07)
		subMessageLabel.TextSize = 22
		hintLabel.Position = UDim2.fromScale(0.5, 0.93)
		hintLabel.TextSize = 22
		hintLabel.Text = deviceHintText(false)
		netGuideLabel.Position = UDim2.fromScale(0.5, 0.82)
		netGuideLabel.Size = UDim2.fromScale(0.46, 0.062)
		netGuideLabel.TextSize = 22
		netGuideLabel.BackgroundTransparency = 0.38
		lobbyGuidePanel.Position = UDim2.fromScale(0.5, Config.LobbyGuideYDesktop or 0.700)
		lobbyGuidePanel.Size = UDim2.fromScale(0.56, 0.130)
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
			TextTransparency = 0.62,
			TextStrokeTransparency = 0.78,
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

local shopPanel = Instance.new("Frame")
shopPanel.Name = "CosmeticShop"
shopPanel.AnchorPoint = Vector2.new(1, 0.5)
shopPanel.Position = UDim2.fromScale(0.985, 0.52)
shopPanel.Size = UDim2.fromScale(isTouch and 0.44 or 0.30, isTouch and 0.44 or 0.42)
shopPanel.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
shopPanel.BackgroundTransparency = 0.10
shopPanel.Visible = false
shopPanel.ZIndex = 60
shopPanel.Parent = gui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopPanel

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(255, 190, 105)
shopStroke.Thickness = 2
shopStroke.Transparency = 0.12
shopStroke.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.BackgroundTransparency = 1
shopTitle.Position = UDim2.fromScale(0.06, 0.04)
shopTitle.Size = UDim2.fromScale(0.76, 0.12)
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Text = Config.MonetizationShopTitle or "COSMETIC SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 226, 118)
shopTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
shopTitle.TextStrokeTransparency = 0.25
shopTitle.TextScaled = true
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.ZIndex = 61
shopTitle.Parent = shopPanel

local shopClose = Instance.new("TextButton")
shopClose.Name = "Close"
shopClose.AnchorPoint = Vector2.new(1, 0)
shopClose.Position = UDim2.fromScale(0.96, 0.045)
shopClose.Size = UDim2.fromScale(0.12, 0.12)
shopClose.BackgroundColor3 = Color3.fromRGB(36, 44, 58)
shopClose.Text = "X"
shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
shopClose.Font = Enum.Font.GothamBlack
shopClose.TextScaled = true
shopClose.ZIndex = 62
shopClose.Parent = shopPanel

local shopCloseCorner = Instance.new("UICorner")
shopCloseCorner.CornerRadius = UDim.new(0, 7)
shopCloseCorner.Parent = shopClose

local shopSubtitle = Instance.new("TextLabel")
shopSubtitle.BackgroundTransparency = 1
shopSubtitle.Position = UDim2.fromScale(0.06, 0.17)
shopSubtitle.Size = UDim2.fromScale(0.88, 0.10)
shopSubtitle.Font = Enum.Font.GothamBold
shopSubtitle.Text = Config.MonetizationShopSubtitle or "Style only. No power boosts."
shopSubtitle.TextColor3 = Color3.fromRGB(230, 240, 255)
shopSubtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
shopSubtitle.TextStrokeTransparency = 0.45
shopSubtitle.TextScaled = true
shopSubtitle.TextWrapped = true
shopSubtitle.TextXAlignment = Enum.TextXAlignment.Left
shopSubtitle.ZIndex = 61
shopSubtitle.Parent = shopPanel

local shopMessage = Instance.new("TextLabel")
shopMessage.BackgroundTransparency = 1
shopMessage.Position = UDim2.fromScale(0.06, 0.83)
shopMessage.Size = UDim2.fromScale(0.88, 0.12)
shopMessage.Font = Enum.Font.GothamBlack
shopMessage.Text = ""
shopMessage.TextColor3 = Color3.fromRGB(255, 210, 115)
shopMessage.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
shopMessage.TextStrokeTransparency = 0.35
shopMessage.TextScaled = true
shopMessage.TextWrapped = true
shopMessage.ZIndex = 61
shopMessage.Parent = shopPanel

local shopList = Instance.new("Frame")
shopList.Name = "ProductList"
shopList.BackgroundTransparency = 1
shopList.Position = UDim2.fromScale(0.06, 0.30)
shopList.Size = UDim2.fromScale(0.88, 0.50)
shopList.ZIndex = 61
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

shopClose.Activated:Connect(function()
	shopPanel.Visible = false
	playUiSfx("UiClick")
end)

local function clearShopRows()
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function addShopRow(product, labels)
	local row = Instance.new("Frame")
	row.Name = tostring(product.key or "Product")
	row.Size = UDim2.fromScale(1, 0.30)
	row.BackgroundColor3 = Color3.fromRGB(22, 30, 44)
	row.BackgroundTransparency = 0.05
	row.ZIndex = 62
	row.Parent = shopList

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromScale(0.04, 0.07)
	name.Size = UDim2.fromScale(0.60, 0.34)
	name.Font = Enum.Font.GothamBlack
	name.Text = tostring(product.name or product.key or "Pass")
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 63
	name.Parent = row

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.fromScale(0.04, 0.45)
	description.Size = UDim2.fromScale(0.60, 0.42)
	description.Font = Enum.Font.GothamBold
	description.Text = tostring(product.description or "")
	description.TextColor3 = Color3.fromRGB(210, 224, 240)
	description.TextScaled = true
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.ZIndex = 63
	description.Parent = row

	local button = Instance.new("TextButton")
	button.Name = "Buy"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.fromScale(0.96, 0.50)
	button.Size = UDim2.fromScale(0.28, 0.58)
	button.BackgroundColor3 = product.owned and Color3.fromRGB(88, 146, 120) or Color3.fromRGB(255, 178, 82)
	button.Text = product.owned and (labels.ownedLabel or "OWNED") or (labels.buyLabel or "BUY")
	button.TextColor3 = Color3.fromRGB(10, 14, 24)
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.ZIndex = 64
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 7)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		if product.owned then
			shopMessage.Text = labels.ownedLabel or "OWNED"
			playUiSfx("UiClick")
			return
		end
		playUiSfx("UiClick")
		if MonetizationRequestEvent then
			MonetizationRequestEvent:FireServer("Purchase", product.key)
		else
			shopMessage.Text = "Monetization UI is waiting for the server."
		end
	end)
end

local function updateShop(payload)
	if payload.enabled == false then
		shopPanel.Visible = false
		return
	end
	shopTitle.Text = payload.title or Config.MonetizationShopTitle or "COSMETIC SHOP"
	shopSubtitle.Text = payload.subtitle or Config.MonetizationShopSubtitle or "Style only. No power boosts."
	shopMessage.Text = payload.message or ""
	clearShopRows()
	for _, product in ipairs(payload.products or {}) do
		addShopRow(product, payload)
	end
	if payload.open == true then
		shopPanel.Visible = true
	end
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

local function getHareHitText(comboCount)
	local count = comboCount or 1
	local selectedText = "HARE!!"
	for _, style in ipairs(Config.HareHitTextStyles or {}) do
		if count >= (style.AtCombo or 1) then
			selectedText = style.Text or selectedText
		end
	end
	if count >= 2 then
		selectedText = selectedText .. string.format(Config.HareHitTextComboSuffixFormat or " x%d", count)
	end
	return selectedText
end

local function fxTextForType(fxType, comboCount, isFirstHare)
	if fxType == "Hare" then
		if isFirstHare and Config.FirstHareCelebrationEnabled ~= false then
			return Config.FirstHareMessage or "FIRST HARE!", Color3.fromRGB(255, 240, 120)
		end
		return getHareHitText(comboCount), Color3.fromRGB(255, 230, 90)
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

local function showFloatingFx(fxType, teamName, rallyCount, comboCount, isFirstHare)
	local text, color = fxTextForType(fxType, comboCount, isFirstHare)
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
	local fxY = fxType == "Hare" and (Config.HareFxY or 0.365) or (Config.HitFxY or 0.500)
	label.Position = UDim2.fromScale(x, fxY)
	label.Parent = fxLayer

	if fxType == "Hare" then
		playHareFlash(comboCount)
		local hareSubtitle = isFirstHare and (Config.FirstHareSubtitle or "YOUR FIRST TEAM SYNC!") or (Config.HareSubtitleText or "TEAM SYNC!")
		if not isFirstHare and comboCount and comboCount >= 2 then
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

local function cpuFillCount(data)
	local cpuPlayers = data.cpuPlayers
	if typeof(cpuPlayers) ~= "table" then
		return 0
	end
	return (cpuPlayers.Red or 0) + (cpuPlayers.Blue or 0)
end

local function getLocalIntStat(statName)
	local leaderstats = localPlayer:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	if stat and stat:IsA("IntValue") then
		return stat.Value
	end
	return 0
end

local function formatDailyBoostProgress()
	if Config.DailyBoostEnabled == false then
		return ""
	end
	local hares = getLocalIntStat(Config.ProgressStatHares or "HAREs")
	local bestRally = getLocalIntStat(Config.ProgressStatBestRally or "Best Rally")
	local hareTarget = Config.DailyBoostHareTarget or 1
	local rallyTarget = Config.DailyBoostRallyTarget or 4
	if hares >= hareTarget and bestRally >= rallyTarget then
		return Config.DailyBoostCompleteText or "Daily Boost ready!"
	end
	return string.format(
		Config.DailyBoostHudFormat or "Daily: HARE %d/%d  Rally %d/%d",
		math.min(hares, hareTarget),
		hareTarget,
		math.min(bestRally, rallyTarget),
		rallyTarget
	)
end

local function formatMatchResults(results)
	if Config.MatchResultsEnabled == false or typeof(results) ~= "table" then
		return Config.GameOverSubMessage or "NEXT MATCH INCOMING!"
	end
	local dailyText = formatDailyBoostProgress()
	local suffix = dailyText ~= "" and ("\n" .. dailyText) or ""
	return string.format(
		"%s: %d   %s: %d\n%s: %d   %s: %d%s",
		Config.MatchResultsHaresLabel or "HAREs",
		results.hares or 0,
		Config.MatchResultsShortBestRallyLabel or Config.MatchResultsBestRallyLabel or "Rally",
		results.bestRally or 0,
		Config.MatchResultsShortTeamSyncsLabel or Config.MatchResultsTeamSyncsLabel or "Syncs",
		results.teamSyncs or 0,
		Config.MatchResultsSlackSavesLabel or "Slack Saves",
		results.slackSaves or 0,
		suffix
	)
end

local function setLobbyGuideStage(stage)
	if lobbyReadyStatus.ready > 0 then
		lobbyActiveStepLabel.Text = string.format("READY!  WAITING %d/%d", lobbyReadyStatus.ready, lobbyReadyStatus.needed)
	elseif stage == 1 then
		lobbyActiveStepLabel.Text = Config.LobbyGuideStepModeText or "1  CHOOSE MODE"
	elseif stage == 2 then
		lobbyActiveStepLabel.Text = Config.LobbyGuideStepThemeText or "2  PICK THEME"
	elseif stage == 3 then
		lobbyActiveStepLabel.Text = Config.LobbyGuideStepReadyText or "3  PRESS READY"
	else
		lobbyActiveStepLabel.Text = Config.LobbyGuideCompactText or "Mode. Theme. READY."
	end
end

local function beginLobbyGuideOnce()
	if lobbyGuideStarted then
		return
	end
	lobbyGuideStarted = true
	setLobbyGuideStage(1)
	local stepSeconds = Config.LobbyGuideStepSeconds or 2.25
	task.delay(stepSeconds, function()
		setLobbyGuideStage(2)
		task.delay(stepSeconds, function()
			setLobbyGuideStage(3)
			task.delay(stepSeconds, function()
				lobbyGuideCompleted = true
				setLobbyGuideStage(4)
			end)
		end)
	end)
end

local function updateLobbyGuide(state, data)
	local visible = state == "Lobby" or state == "WaitingForPlayers"
	lobbyGuidePanel.Visible = visible
	netGuideLabel.Visible = not visible
	if not visible then
		return
	end

	local message = tostring(data.message or "")
	for _, entry in ipairs(Config.LobbyEntryPads or {}) do
		local label = tostring(entry.Label or entry.Id or "")
		if label ~= "" and string.find(message, label, 1, true) and string.find(message, "selected", 1, true) then
			selectedModeLabel = label
			break
		end
	end
	local courtLabel = data.selectedCourtLabel or data.selectedCourtId or "Grass Court"
	lobbyReadyStatus.ready = data.lobbyReadyPlayers or 0
	lobbyReadyStatus.needed = data.lobbyNeededPlayers or data.playersNeeded or 1
	lobbyModeSummaryLabel.Text = string.format(Config.LobbyModeSummaryFormat or "MODE: %s", selectedModeLabel)
	lobbyThemeSummaryLabel.Text = string.format(Config.LobbyThemeSummaryFormat or "THEME: %s", tostring(courtLabel))
	if lobbyGuideCompleted then
		setLobbyGuideStage(4)
	else
		beginLobbyGuideOnce()
	end
end

if MatchStateEvent then
MatchStateEvent.OnClientEvent:Connect(function(data)
	applyResponsiveLayout()
	local redScore = data.redScore or 0
	local blueScore = data.blueScore or 0
	scoreLabel.Text = string.format("RED  %d  -  %d  BLUE", redScore, blueScore)
	updateNetGuidance(data)

	local state = data.state or ""
	local message = normalizeMessage(data.message)
	setLobbyPlayerListVisible(state)
	setMixerPanelsVisibleForState(state)
	local dailyText = formatDailyBoostProgress()
	updateLobbyGuide(state, data)

	if data.dailyBoostEarned == true then
		setMessage(message ~= "" and message or (Config.DailyBoostEarnedMessage or "DAILY BOOST EARNED!"), 8)
		subMessageHoldUntil = os.clock() + (Config.HudMessageDuration or 1.25)
		subMessageLabel.Text = Config.DailyBoostEarnedSubMessage or "Nice teamwork. Queue another round!"
		playGameSfx("Score")
		return
	end

	if state == "Lobby" then
		setMessage("LOBBY", 0)
		netGuideLabel.Text = ""
		local queued = data.queuedNextMatchPlayers or 0
		if message == (Config.LateJoinSpectatorMessage or "NEXT MATCH QUEUE") then
			subMessageLabel.Text = Config.LateJoinSpectatorSubMessage or "Queued for next match."
		elseif queued > 0 then
			subMessageLabel.Text = string.format("Next match queue: %d", queued)
		else
			subMessageLabel.Text = ""
		end
	elseif state == "WaitingForPlayers" then
		setMessage("WAITING", 0)
		netGuideLabel.Text = ""
		local queued = data.queuedNextMatchPlayers or 0
		if queued > 0 then
			subMessageLabel.Text = string.format("%s  Next match queue %d", Config.LateJoinSpectatorSubMessage or "Queued for next match.", queued)
		elseif Config.CpuFillEnabled and cpuFillCount(data) > 0 then
			subMessageLabel.Text = Config.CpuFillMatchSubMessage or Config.WaitingSubMessage or message
		elseif message ~= "" then
			subMessageLabel.Text = Config.WaitingSubMessage or message
		else
			subMessageLabel.Text = Config.WaitingSubMessage or string.format("Red %d/2 - Blue %d/2", data.redPlayers or 0, data.bluePlayers or 0)
		end
		if dailyText ~= "" then
			subMessageLabel.Text = subMessageLabel.Text .. "  " .. dailyText
		end
	elseif state == "Countdown" then
		showOnboardingOnce()
		setMessage(message ~= "" and message or "3", 20)
		if message == (Config.StartMessage or "PINTO HARE!") then
			playGameSfx("Start")
		else
			playGameSfx("Countdown")
		end
		if Config.CpuFillEnabled and cpuFillCount(data) > 0 then
			subMessageLabel.Text = Config.CpuFillIntroText or Config.CpuFillMatchSubMessage or ""
		else
			subMessageLabel.Text = ""
		end
	elseif state == "Ready" then
		showOnboardingOnce()
		setMessage(message ~= "" and message or (Config.MatchReadyMessage or "GET READY"), 4)
		if Config.CpuFillEnabled and cpuFillCount(data) > 0 then
			subMessageLabel.Text = Config.CpuFillIntroText or Config.MatchReadySubMessage or ""
		else
			subMessageLabel.Text = Config.MatchReadySubMessage or ""
		end
		if dailyText ~= "" then
			subMessageLabel.Text = subMessageLabel.Text .. "  " .. dailyText
		end
	elseif state == "Serving" then
		setMessage(message, 0)
		local servingTeam = data.servingTeam
		if data.finalHare then
			subMessageLabel.Text = Config.FinalHareSubMessage or "Next point wins."
		elseif message == (Config.ServeChargeMessage or "FIBER CHARGE!") then
			subMessageLabel.Text = Config.ServeChargeSubMessage or Config.ServingSubMessage or "Track the ball!"
		elseif servingTeam then
			subMessageLabel.Text = string.format(Config.ServeOwnerSubMessageFormat or "%s has serve. Hold PIN to charge.", tostring(servingTeam))
		else
			subMessageLabel.Text = Config.ServingSubMessage or "Track the ball!"
		end
	elseif state == "Rally" then
		messageLabel.Text = ""
		if os.clock() >= subMessageHoldUntil then
			subMessageLabel.Text = Config.RallySubMessage or ""
		end
	elseif state == "PointScored" then
		setMessage(message, 4)
		subMessageHoldUntil = 0
		if string.find(message, "DROP!", 1, true) then
			playGameSfx("Out")
			subMessageLabel.Text = Config.FailSubtitleDropText or Config.PointSubMessage or "NEXT SERVE!"
		elseif string.find(message, "OUT!", 1, true) then
			playGameSfx("Out")
			subMessageLabel.Text = Config.FailSubtitleOutText or Config.PointSubMessage or "NEXT SERVE!"
		else
			playGameSfx("Score")
			subMessageLabel.Text = Config.PointSubMessage or "NEXT SERVE!"
		end
	elseif state == "GameOver" then
		setMessage(message ~= "" and message or "GAME SET!", 4)
		subMessageLabel.Size = UDim2.fromScale(0.90, Config.GameOverResultsHeight or 0.120)
		subMessageLabel.TextSize = isTouch and (Config.GameOverResultsTextSizeTouch or 16) or (Config.GameOverResultsTextSizeDesktop or 19)
		subMessageLabel.Text = formatMatchResults(data.matchResults)
	else
		setMessage(message ~= "" and message or state, 0)
		subMessageLabel.Text = ""
	end
end)
end

if MonetizationStateEvent then
	MonetizationStateEvent.OnClientEvent:Connect(function(payload)
		updateShop(payload or {})
	end)
end

if HitFxEvent then
	HitFxEvent.OnClientEvent:Connect(function(fxType, _position, teamName, rallyCount, comboCount, isFirstHare)
		showFloatingFx(fxType, teamName, rallyCount, comboCount, isFirstHare)
		playGameSfx(fxType)
	end)
end
