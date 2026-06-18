-- Tension Doubles: PINTO HARE! / Camera client v0.5.2
-- Mobile landscape-friendly fixed camera with portrait fallback and tiny HARE shake.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))

local isTouch = UserInputService.TouchEnabled
local shakeUntil = 0
local shakePower = 0
local currentCourtOriginX = 0
local currentCourtOriginZ = 0
local currentState = "WaitingForPlayers"

local function isLobbyState(state)
	return state == "WaitingForPlayers" or state == "Lobby"
end

local function isPortrait()
	if not camera then
		camera = workspace.CurrentCamera
	end
	if not camera then
		return false
	end
	local viewport = camera.ViewportSize
	return viewport.Y > viewport.X
end

local function getCameraSettings()
	if isTouch then
		if isPortrait() then
			return Config.MobileCameraHeightPortrait or 102, Config.MobileCameraBackPortrait or 88, Config.MobileCameraFovPortrait or 70
		end
		return Config.MobileCameraHeightLandscape or 90, Config.MobileCameraBackLandscape or 76, Config.MobileCameraFovLandscape or 66
	end
	return 80, 63, 59
end

local function bindHitFx()
	local remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes", 10)
	if not remotes then
		return
	end
	local hitFx = remotes:WaitForChild("HitFxEvent", 10)
	local matchState = remotes:WaitForChild("MatchStateEvent", 10)
	if not hitFx then
		return
	end
	hitFx.OnClientEvent:Connect(function(fxType, _position, _teamName, _rallyCount, comboCount)
		if fxType == "Hare" then
			shakePower = comboCount and comboCount >= 2 and (Config.HareComboCameraKick or 1.75) or (Config.HareCameraKick or 1.25)
			shakeUntil = os.clock() + 0.28
		elseif fxType == "OverTension" then
			shakePower = 0.50
			shakeUntil = os.clock() + 0.13
		else
			shakePower = Config.NormalHitCameraKick or 0.34
			shakeUntil = os.clock() + 0.11
		end
	end)

	if matchState then
		matchState.OnClientEvent:Connect(function(data)
			local state = data and data.state or ""
			currentState = state
			currentCourtOriginX = data.courtOriginX or currentCourtOriginX
			currentCourtOriginZ = data.courtOriginZ or currentCourtOriginZ
			if state == "PointScored" then
				shakePower = 0.55
				shakeUntil = os.clock() + 0.16
			elseif state == "GameOver" then
				shakePower = 0.38
				shakeUntil = os.clock() + 0.26
			end
		end)
	end
end

task.spawn(bindHitFx)

local function updateCamera()
	if not camera then
		camera = workspace.CurrentCamera
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable
	local cameraHeight, cameraBack, cameraFov = getCameraSettings()

	local side = 1
	local focusX = currentCourtOriginX
	local focusZ = currentCourtOriginZ
	local focusY = 1.2
	if isLobbyState(currentState) then
		local lobbyFocus = Config.LobbyCameraFocusPosition or Config.LobbySpawnPosition or Vector3.new(0, 1.2, -88)
		focusX = lobbyFocus.X
		focusY = lobbyFocus.Y
		focusZ = lobbyFocus.Z
		cameraHeight = Config.LobbyCameraHeight or cameraHeight
		cameraBack = Config.LobbyCameraBack or cameraBack
		cameraFov = Config.LobbyCameraFov or cameraFov
	elseif localPlayer.Team and localPlayer.Team.Name == "Blue" then
		side = -1
	end
	camera.FieldOfView = cameraFov

	local camPos = Vector3.new(focusX, cameraHeight, focusZ + cameraBack * side)
	local lookAt = Vector3.new(focusX, focusY, focusZ)

	local now = os.clock()
	if now < shakeUntil then
		local remaining = math.max(0, shakeUntil - now) / 0.23
		local amount = shakePower * remaining
		local shake = Vector3.new((math.random() - 0.5) * amount, (math.random() - 0.5) * amount * 0.35, (math.random() - 0.5) * amount)
		camPos += shake
		lookAt += shake * 0.35
	end

	camera.CFrame = CFrame.lookAt(camPos, lookAt)
end

RunService.RenderStepped:Connect(updateCamera)
