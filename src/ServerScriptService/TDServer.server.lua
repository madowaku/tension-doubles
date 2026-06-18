-- Tension Doubles: PINTO HARE! / Roblox ver0.6.1
-- Server-authoritative MVP: court generation, teams, Beam nets, pin input state,
-- scripted ball movement, virtual-net hit detection, scoring, match loop, and Onboarding & Feel FX.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TeamsService = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))
local MathUtil = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("MathUtil"))

math.randomseed(os.clock() * 1000000)

local RemotesFolder = ReplicatedStorage:FindFirstChild("TensionDoublesRemotes") or Instance.new("Folder")
RemotesFolder.Name = "TensionDoublesRemotes"
RemotesFolder.Parent = ReplicatedStorage

local function getOrCreateRemote(name)
	local remote = RemotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = RemotesFolder
	end
	return remote
end

local PinInputEvent = getOrCreateRemote("PinInputEvent")
local LobbyReadyEvent = getOrCreateRemote("LobbyReadyEvent")
local MatchStateEvent = getOrCreateRemote("MatchStateEvent")
local HitFxEvent = getOrCreateRemote("HitFxEvent")
local MonetizationRequestEvent = getOrCreateRemote("MonetizationRequestEvent")
local MonetizationStateEvent = getOrCreateRemote("MonetizationStateEvent")

local CourtFolder = workspace:FindFirstChild("TDCourt") or Instance.new("Folder")
CourtFolder.Name = "TDCourt"
CourtFolder.Parent = workspace

local VisualsFolder = CourtFolder:FindFirstChild("Visuals") or Instance.new("Folder")
VisualsFolder.Name = "Visuals"
VisualsFolder.Parent = CourtFolder

local SpawnFolder = CourtFolder:FindFirstChild("SpawnPoints") or Instance.new("Folder")
SpawnFolder.Name = "SpawnPoints"
SpawnFolder.Parent = CourtFolder

local LobbyFolder = workspace:FindFirstChild("Lobby") or Instance.new("Folder")
LobbyFolder.Name = "Lobby"
LobbyFolder.Parent = workspace

local CourtsFolder = workspace:FindFirstChild("Courts") or Instance.new("Folder")
CourtsFolder.Name = "Courts"
CourtsFolder.Parent = workspace

local playerState = {}
local selectedCourtByPlayer = {}
local courtSelectionOrder = {}
local courtButtonLabels = {}
local courtButtons = {}
local lobbyParticipantLabel = nil
local activeCourtId = "Grass"
local activeCourtOrigin = Vector3.new(0, 0, 0)
local score = { Red = 0, Blue = 0 }
local matchStats = {
	Hares = 0,
	BestRally = 0,
	TeamSyncs = 0,
	SlackSaves = 0,
}
local lastTeamHitTime = { Red = -math.huge, Blue = -math.huge }
local currentState = "WaitingForPlayers"
local matchRunning = false
local roundActive = false
local lastPointLoser = "Blue"
local winningTeam = nil
local currentServingTeam = nil
local rallyHitCount = 0
local hareCombo = { Red = 0, Blue = 0 }
local lastHareTime = { Red = -math.huge, Blue = -math.huge }
local lastGuidanceBroadcast = 0
local lobbyReady = {}
local queuedNextMatchPlayers = {}
local lastPlayerActivityAt = {}
local monetizationOwnership = {}
local dailyBoostClaimed = {}
local Monetization = {}
local PracticeWall = {}
local Analytics = {}
local Diagnostics = {}
local MatchLoop = {}

local teamBeams = {}
local pinIndicators = {}
local ghostPartners = { Red = {}, Blue = {} }
local cpuPartnerState = { Red = {}, Blue = {} }
local landingTargetMarker = nil
local lastLandingTargetUpdate = 0

local ball = {
	part = nil,
	position = Vector3.new(0, Config.ServeHeight, 0),
	velocity = Vector3.new(0, 0, 0),
	lastTouchedTeam = nil,
	active = false,
	pausedUntil = 0,
}

local function countActiveCpuPartners(teamName)
	local count = 0
	local partners = ghostPartners[teamName]
	if not partners then
		return count
	end
	for _, partner in ipairs(partners) do
		if partner and partner.Parent and partner:GetAttribute("CpuFillActive") == true then
			count += 1
		end
	end
	return count
end

local TEAM_COLORS = {
	Red = Color3.fromRGB(255, 80, 80),
	Blue = Color3.fromRGB(80, 150, 255),
}

local BEAM_COLORS = {
	Slack = Color3.fromRGB(80, 170, 255),
	Normal = Color3.fromRGB(245, 245, 255),
	OverTension = Color3.fromRGB(255, 95, 95),
	Broken = Color3.fromRGB(80, 80, 80),
	Hare = Color3.fromRGB(255, 215, 80),
}

local function halfWidth()
	return Config.CourtWidth / 2
end

local function totalHalfDepth()
	return Config.CourtDepth + Config.OutZoneDepth
end

local function getCourtArenaConfig(courtId)
	local arenas = Config.CourtArenaModels or {}
	local arenaConfig = arenas[courtId]
	if arenaConfig then
		return arenaConfig
	end

	local grassArena = Config.GrassTileArena or {}
	if courtId == (grassArena.CourtId or "Grass") then
		return grassArena
	end
	return nil
end

local function shouldUseCourtArena()
	local arenaConfig = getCourtArenaConfig(activeCourtId)
	return matchRunning and arenaConfig and arenaConfig.Enabled == true
end

local function activeHalfDepth()
	if shouldUseCourtArena() then
		local arenaSize = getCourtArenaConfig(activeCourtId).SizeStuds or 64
		return math.min(totalHalfDepth(), arenaSize / 2)
	end
	return totalHalfDepth()
end

local function courtPosition(x, y, z)
	return Vector3.new(activeCourtOrigin.X + x, y, activeCourtOrigin.Z + z)
end

local teamCount
local getNetGuidanceForTeam
local isBallOutsideArena
local startMatchIfPossible
local getAliveRoot
local setLobbyReady
local getSelectedMatchCourt
local getCourtVoteSummary
local getCourtAvailabilitySummary

local function requiredPlayerCount()
	if Config.AllowGhostPartners then
		return Config.MinPlayersToAutoStart
	end
	return 4
end

local function isLobbyParticipant(player)
	return player.Parent == Players and queuedNextMatchPlayers[player] ~= true
end

local function getLobbyReadyCount()
	local readyCount = 0
	local activeCount = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if isLobbyParticipant(player) then
			activeCount += 1
			if lobbyReady[player] == true then
				readyCount += 1
			end
		end
	end
	return readyCount, activeCount
end

local function getQueuedNextMatchCount()
	local count = 0
	for player in pairs(queuedNextMatchPlayers) do
		if player.Parent == Players then
			count += 1
		end
	end
	return count
end

Diagnostics.folder = nil

Diagnostics.isEnabled = function()
	return Config.StudioDiagnosticsEnabled ~= false and RunService:IsStudio()
end

Diagnostics.ensureFolder = function()
	if not Diagnostics.isEnabled() then
		if Diagnostics.folder and Diagnostics.folder.Parent then
			Diagnostics.folder:Destroy()
		end
		Diagnostics.folder = nil
		return nil
	end

	local folder = Diagnostics.folder
	if not folder or not folder.Parent then
		folder = ReplicatedStorage:FindFirstChild(Config.StudioDiagnosticsFolderName or "TensionDoublesStudioDiagnostics")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Config.StudioDiagnosticsFolderName or "TensionDoublesStudioDiagnostics"
			folder.Parent = ReplicatedStorage
		end
		folder:SetAttribute("StudioOnly", true)
		folder:SetAttribute("DisableWith", "StudioDiagnosticsEnabled")
		Diagnostics.folder = folder
	end
	return folder
end

Diagnostics.ensureSubfolder = function(name)
	local folder = Diagnostics.ensureFolder()
	if not folder then
		return nil
	end

	local subfolder = folder:FindFirstChild(name)
	if subfolder and not subfolder:IsA("Folder") then
		subfolder:Destroy()
		subfolder = nil
	end
	if not subfolder then
		subfolder = Instance.new("Folder")
		subfolder.Name = name
		subfolder.Parent = folder
	end
	return subfolder
end

Diagnostics.ensureValue = function(name, className, parent)
	local container = parent or Diagnostics.ensureFolder()
	if not container then
		return nil
	end

	local value = container:FindFirstChild(name)
	if value and value.ClassName ~= className then
		value:Destroy()
		value = nil
	end
	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = container
	end
	return value
end

Diagnostics.setString = function(name, value)
	local stringValue = Diagnostics.ensureValue(name, "StringValue")
	if stringValue then
		stringValue.Value = tostring(value or "")
	end
end

Diagnostics.setInt = function(name, value)
	local intValue = Diagnostics.ensureValue(name, "IntValue")
	if intValue then
		intValue.Value = math.max(0, math.floor(tonumber(value) or 0))
	end
end

Diagnostics.setBool = function(name, value)
	local boolValue = Diagnostics.ensureValue(name, "BoolValue")
	if boolValue then
		boolValue.Value = value == true
	end
end

Diagnostics.syncAnalyticsCounters = function()
	local countersFolder = Diagnostics.ensureSubfolder("AnalyticsCounters")
	if not countersFolder then
		return
	end

	local analyticsFolder = ReplicatedStorage:FindFirstChild(Config.AnalyticsLiteFolderName or "TensionDoublesAnalytics")
	for eventKey, eventName in pairs(Config.AnalyticsLiteEvents or {}) do
		local counterName = eventName or eventKey
		local sourceCounter = analyticsFolder and analyticsFolder:FindFirstChild(counterName)
		local count = 0
		if sourceCounter and sourceCounter:IsA("IntValue") then
			count = sourceCounter.Value
		end
		local mirrorCounter = Diagnostics.ensureValue(counterName, "IntValue", countersFolder)
		if mirrorCounter then
			mirrorCounter.Value = count
		end
	end
end

Diagnostics.update = function(message, readyCount, neededCount)
	if not Diagnostics.isEnabled() then
		return
	end

	Diagnostics.setString("LivePreset", Config.ActiveLivePreset or Config.LivePreset or "")
	Diagnostics.setString("State", currentState)
	Diagnostics.setString("LastMessage", message or "")
	Diagnostics.setInt("QueuedSpectators", getQueuedNextMatchCount())
	Diagnostics.setInt("LobbyReadyPlayers", readyCount or 0)
	Diagnostics.setInt("LobbyNeededPlayers", neededCount or 0)
	Diagnostics.setBool("MatchRunning", matchRunning)
	Diagnostics.syncAnalyticsCounters()
end

Analytics.folder = nil
Analytics.initialized = false
Analytics.playerFlags = {}

Analytics.eventName = function(eventKey)
	local events = Config.AnalyticsLiteEvents or {}
	return events[eventKey] or eventKey
end

Analytics.ensureCounter = function(folder, eventKey)
	local eventName = Analytics.eventName(eventKey)
	local counter = folder:FindFirstChild(eventName)
	if not counter then
		counter = Instance.new("IntValue")
		counter.Name = eventName
		counter.Parent = folder
	end
	if not Analytics.initialized then
		counter.Value = 0
	end
	return counter
end

Analytics.ensureFolder = function()
	if Config.AnalyticsLiteEnabled == false then
		return nil
	end
	local folder = Analytics.folder
	if not folder or not folder.Parent then
		folder = ReplicatedStorage:FindFirstChild(Config.AnalyticsLiteFolderName or "TensionDoublesAnalytics")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Config.AnalyticsLiteFolderName or "TensionDoublesAnalytics"
			folder.Parent = ReplicatedStorage
		end
		Analytics.folder = folder
	end
	for eventKey in pairs(Config.AnalyticsLiteEvents or {}) do
		Analytics.ensureCounter(folder, eventKey)
	end
	Analytics.initialized = true
	return folder
end

Analytics.record = function(eventKey, amount)
	local folder = Analytics.ensureFolder()
	if not folder then
		return
	end
	local counter = Analytics.ensureCounter(folder, eventKey)
	local increment = amount or 1
	counter.Value += increment
	folder:SetAttribute("LastEvent", counter.Name)
	folder:SetAttribute("LastEventAt", os.clock())
	Diagnostics.syncAnalyticsCounters()
	if Config.AnalyticsLitePrintEnabled == true then
		print(string.format("[TD Analytics] %s=%d", counter.Name, counter.Value))
	end
end

Analytics.recordForPlayer = function(player, eventKey)
	if not player then
		return
	end
	local flags = Analytics.playerFlags[player]
	if not flags then
		flags = {}
		Analytics.playerFlags[player] = flags
	end
	if flags[eventKey] == true then
		return
	end
	flags[eventKey] = true
	Analytics.record(eventKey)
end

Analytics.recordForTeamPlayers = function(teamName, eventKey)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			Analytics.recordForPlayer(player, eventKey)
		end
	end
end

local function markPlayerActivity(player)
	lastPlayerActivityAt[player] = os.clock()
end

local function allLobbyPlayersReady()
	if Config.LobbyReadyEnabled == false then
		return true
	end
	local players = Players:GetPlayers()
	local hasLobbyParticipant = false
	for _, player in ipairs(players) do
		if isLobbyParticipant(player) then
			hasLobbyParticipant = true
		elseif queuedNextMatchPlayers[player] == true then
			lobbyReady[player] = false
		end
		if isLobbyParticipant(player) and lobbyReady[player] ~= true then
			return false
		end
	end
	return hasLobbyParticipant
end

local function isFinalHareActive()
	return Config.FinalHareEnabled ~= false
		and score.Red == Config.ScoreToWin - 1
		and score.Blue == Config.ScoreToWin - 1
end

local function formatServeOwnerMessage(teamName)
	local displayTeam = string.upper(teamName)
	if isFinalHareActive() then
		return string.format(Config.FinalHareServeMessageFormat or "%s FINAL SERVE", displayTeam)
	end
	return string.format(Config.ServeOwnerMessageFormat or "%s SERVES", displayTeam)
end

local function resetMatchStats()
	matchStats.Hares = 0
	matchStats.BestRally = 0
	matchStats.TeamSyncs = 0
	matchStats.SlackSaves = 0
end

local function getMatchResultsPayload()
	if Config.MatchResultsEnabled == false then
		return nil
	end
	return {
		hares = matchStats.Hares,
		bestRally = matchStats.BestRally,
		teamSyncs = matchStats.TeamSyncs,
		slackSaves = matchStats.SlackSaves,
	}
end

local function recordMatchRallyResult(rallyCount)
	matchStats.BestRally = math.max(matchStats.BestRally, rallyCount or 0)
end

local function recordMatchHitResult(fxType)
	if fxType == "Hare" then
		matchStats.Hares += 1
		matchStats.TeamSyncs += 1
	elseif fxType == "Slack" then
		matchStats.SlackSaves += 1
	end
end

local function broadcastState(message)
	local netGuidance = nil
	if getNetGuidanceForTeam then
		netGuidance = {
			Red = getNetGuidanceForTeam("Red"),
			Blue = getNetGuidanceForTeam("Blue"),
		}
	end
	local readyCount, activeCount = getLobbyReadyCount()
	local neededCount = math.max(requiredPlayerCount(), activeCount)
	local selectedCourt, voteCounts, selectedVotes, totalVotes = getCourtVoteSummary()
	local availability = getCourtAvailabilitySummary()
	Diagnostics.update(message, readyCount, neededCount)

	MatchStateEvent:FireAllClients({
		state = currentState,
		redScore = score.Red,
		blueScore = score.Blue,
		message = message or "",
		winner = winningTeam,
		matchResults = getMatchResultsPayload(),
		servingTeam = currentServingTeam,
		finalHare = isFinalHareActive(),
		redPlayers = teamCount("Red"),
		bluePlayers = teamCount("Blue"),
		playersNeeded = Config.AllowGhostPartners and Config.MinPlayersToAutoStart or 4,
		lobbyReadyPlayers = readyCount,
		lobbyNeededPlayers = neededCount,
		queuedNextMatchPlayers = getQueuedNextMatchCount(),
		selectedCourtId = selectedCourt and selectedCourt.Id or activeCourtId,
		selectedCourtLabel = selectedCourt and selectedCourt.Label or activeCourtId,
		courtOriginX = activeCourtOrigin.X,
		courtOriginZ = activeCourtOrigin.Z,
		courtVoteCounts = voteCounts,
		courtAvailability = availability,
		selectedCourtVotes = selectedVotes,
		totalCourtVotes = totalVotes,
		livePreset = Config.ActiveLivePreset or Config.LivePreset,
		cpuPlayers = {
			Red = countActiveCpuPartners("Red"),
			Blue = countActiveCpuPartners("Blue"),
		},
		title = Config.Title,
		netGuidance = netGuidance,
	})
end

local function setState(newState, message)
	currentState = newState
	broadcastState(message)
end

local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Position = courtPosition(position.X, position.Y, position.Z)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or CourtFolder
	return part
end

local function makeNonCollidePart(name, size, position, color, material, parent)
	local part = makePart(name, size, position, color, material, parent)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function addSurfaceText(part, text, color, face)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TD_Label"
	gui.Face = face or Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
end

local function clearGeneratedCourt()
	for _, child in ipairs(CourtFolder:GetChildren()) do
		if child.Name ~= "Visuals" and child.Name ~= "SpawnPoints" then
			child:Destroy()
		end
	end
	for _, child in ipairs(SpawnFolder:GetChildren()) do
		child:Destroy()
	end
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		child:Destroy()
	end
	teamBeams = {}
	pinIndicators = {}
	landingTargetMarker = nil
end

local function createSpawn(name, pos)
	local spawn = Instance.new("Part")
	spawn.Name = name
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(2, 1, 2)
	spawn.Position = courtPosition(pos.X, pos.Y, pos.Z)
	spawn.Parent = SpawnFolder
	return spawn
end

local function createFlag(teamName, x, z)
	local color = TEAM_COLORS[teamName]
	local pole = makeNonCollidePart(teamName .. "FlagPole", Vector3.new(0.28, 8, 0.28), Vector3.new(x, 4, z), Color3.fromRGB(230, 230, 240), Enum.Material.Metal)
	local flag = makeNonCollidePart(teamName .. "Flag", Vector3.new(5.2, 2.6, 0.22), Vector3.new(x + (x < 0 and 2.65 or -2.65), 7.0, z), color, Enum.Material.Neon)
	flag:SetAttribute("BaseColorR", color.R)
	flag:SetAttribute("BaseColorG", color.G)
	flag:SetAttribute("BaseColorB", color.B)
	addSurfaceText(flag, string.upper(teamName), Color3.fromRGB(255, 255, 255))
	return pole, flag
end

local function clearFolder(folder)
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
end

local function makeWorldPart(parent, name, size, cframe, color, material, collidable)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = collidable == true
	part.CanTouch = collidable == true
	part.CanQuery = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addBillboardText(parent, text, size, studsOffset, alwaysOnTop, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.AlwaysOnTop = alwaysOnTop == true
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = studsOffset or Vector3.new(0, 3.2, 0)
	gui.MaxDistance = maxDistance or 80
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	label.BackgroundTransparency = 0.18
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui

	return gui, label
end

local function addLobbyTutorialBoard(parent, lobbySpawnPos)
	local boardPosition = lobbySpawnPos + Vector3.new(
		Config.LobbyTutorialBoardXOffset or -27,
		6.2,
		Config.LobbyTutorialBoardZOffset or 6
	)
	local board = makeWorldPart(
		parent,
		"LobbyHowToPlayBoard",
		Vector3.new(28, 12.5, 0.8),
		CFrame.new(boardPosition),
		Color3.fromRGB(10, 18, 34),
		Enum.Material.Metal,
		false
	)
	board.CanCollide = false
	board.CanTouch = false

	local gui = Instance.new("SurfaceGui")
	gui.Name = "HowToPlaySurface"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(1120, 500)
	gui.Parent = board

	local background = Instance.new("Frame")
	background.Name = "BoardLayout"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(8, 17, 34)
	background.BorderSizePixel = 0
	background.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromScale(0.03, 0.025)
	title.Size = UDim2.fromScale(0.94, 0.19)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = Config.LobbyTutorialBoardTitle or "HOW TO PLAY"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = background

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Position = UDim2.fromScale(0.18, 0.205)
	subtitle.Size = UDim2.fromScale(0.64, 0.11)
	subtitle.BackgroundColor3 = Color3.fromRGB(255, 215, 54)
	subtitle.BorderSizePixel = 0
	subtitle.Font = Enum.Font.GothamBlack
	subtitle.Text = Config.LobbyTutorialBoardSubtitle or "TENSION DOUBLES: PINTO HARE!"
	subtitle.TextColor3 = Color3.fromRGB(22, 20, 16)
	subtitle.TextScaled = true
	subtitle.Parent = background

	local steps = {
		{ name = "MoveTogether", text = Config.LobbyTutorialStepMove or "1  MOVE WITH YOUR PARTNER", color = Color3.fromRGB(214, 58, 62) },
		{ name = "StretchFiber", text = Config.LobbyTutorialStepStretch or "2  STRETCH THE FIBER", color = Color3.fromRGB(241, 130, 36) },
		{ name = "HoldPin", text = Config.LobbyTutorialStepPin or "3  HOLD PIN TOGETHER FOR HARE!", color = Color3.fromRGB(52, 115, 225) },
	}
	for index, step in ipairs(steps) do
		local card = Instance.new("TextLabel")
		card.Name = step.name
		card.Position = UDim2.fromScale(0.025 + ((index - 1) * 0.325), 0.36)
		card.Size = UDim2.fromScale(0.30, 0.56)
		card.BackgroundColor3 = Color3.fromRGB(246, 244, 235)
		card.BorderColor3 = step.color
		card.BorderSizePixel = 8
		card.Font = Enum.Font.GothamBlack
		card.Text = step.text
		card.TextColor3 = Color3.fromRGB(24, 27, 34)
		card.TextScaled = true
		card.TextWrapped = true
		card.Parent = background
	end

	return board
end

local function addProximityPrompt(parent, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CourtChoosePrompt"
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function getCourtSpawn(courtId)
	local courtFolder = CourtsFolder:FindFirstChild(tostring(courtId) .. "Court")
	return courtFolder and courtFolder:FindFirstChild("SpawnPoint")
end

local function findCourtConfig(courtId)
	for _, court in ipairs(Config.CourtSelections or {}) do
		if court.Id == courtId then
			return court
		end
	end
	return (Config.CourtSelections and Config.CourtSelections[1]) or { Id = "Grass", X = 0 }
end

local function rememberCourtSelection(courtId)
	for _, existingCourtId in ipairs(courtSelectionOrder) do
		if existingCourtId == courtId then
			return
		end
	end
	table.insert(courtSelectionOrder, courtId)
end

getCourtVoteSummary = function()
	local voteCounts = {}
	local totalVotes = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local courtId = selectedCourtByPlayer[player]
		if courtId then
			voteCounts[courtId] = (voteCounts[courtId] or 0) + 1
			totalVotes += 1
		end
	end

	local winningCourtId = activeCourtId
	local winningVotes = 0
	for _, courtId in ipairs(courtSelectionOrder) do
		local votes = voteCounts[courtId] or 0
		if votes > winningVotes then
			winningCourtId = courtId
			winningVotes = votes
		end
	end

	if winningVotes <= 0 then
		winningCourtId = activeCourtId
	end

	return findCourtConfig(winningCourtId), voteCounts, winningVotes, totalVotes
end

getSelectedMatchCourt = function()
	local court = getCourtVoteSummary()
	return court
end

local function isCourtAvailable(courtId)
	return not (matchRunning and courtId == activeCourtId)
end

getCourtAvailabilitySummary = function()
	local availability = {}
	for _, court in ipairs(Config.CourtSelections or {}) do
		availability[court.Id] = isCourtAvailable(court.Id)
	end
	return availability
end

local function updateLobbyParticipantBoardStatus()
	if not lobbyParticipantLabel then
		return
	end
	local readyCount, activeCount = getLobbyReadyCount()
	local format = Config.LobbyParticipantCountFormat or "Players %d / Ready %d"
	lobbyParticipantLabel.Text = string.format(format, activeCount, readyCount)
end

local function updateCourtSelectBoardStatus()
	local selectedCourt, voteCounts = getCourtVoteSummary()
	local selectedCourtId = selectedCourt and selectedCourt.Id or activeCourtId
	for _, court in ipairs(Config.CourtSelections or {}) do
		local courtId = court.Id
		local label = courtButtonLabels[courtId]
		local button = courtButtons[courtId]
		local votes = voteCounts[courtId] or 0
		if label then
			local status = votes > 0 and string.format("Votes %d", votes) or "OPEN"
			if matchRunning and courtId == activeCourtId then
				status = "PLAYING"
			elseif courtId == selectedCourtId then
				status = "Selected  " .. status
			end
			label.Text = string.format("%s\n%s", court.Label or tostring(courtId), status)
		end
		if button then
			if matchRunning and courtId == activeCourtId then
				button.Color = Color3.fromRGB(255, 220, 90)
			elseif courtId == selectedCourtId then
				button.Color = (court.Color or Color3.fromRGB(120, 180, 120)):Lerp(Color3.fromRGB(255, 255, 255), 0.22)
			else
			button.Color = court.Color or Color3.fromRGB(120, 180, 120)
		end
	end
	updateLobbyParticipantBoardStatus()
end
end

local function teleportPlayerToLobby(player)
	local root = getAliveRoot(player)
	local lobbySpawn = LobbyFolder:FindFirstChild("LobbySpawn")
	if root and lobbySpawn and lobbySpawn:IsA("BasePart") then
		root.CFrame = lobbySpawn.CFrame + Vector3.new(0, 3, 0)
	end
end

local function teleportPlayersToLobby()
	for _, player in ipairs(Players:GetPlayers()) do
		teleportPlayerToLobby(player)
	end
end

local function setCourtPreviewPadsEnabled(enabled)
	for _, courtFolder in ipairs(CourtsFolder:GetChildren()) do
		local previewPad = courtFolder:FindFirstChild("PreviewPad")
		if previewPad and previewPad:IsA("BasePart") then
			previewPad.CanCollide = enabled == true
			previewPad.CanTouch = enabled == true
			previewPad.Transparency = enabled == true and 0 or (Config.MatchPreviewPadHiddenTransparency or 0.82)
		end
	end
end

local function returnPlayerToLobby(player)
	if matchRunning then
		setState("Lobby", Config.CourtUnavailableMessage or "That court is playing!")
		return
	end
	selectedCourtByPlayer[player] = nil
	lobbyReady[player] = false
	setCourtPreviewPadsEnabled(true)
	teleportPlayerToLobby(player)
	updateCourtSelectBoardStatus()
	setState("Lobby", Config.CourtReturnMessage or "Back in lobby. Choose a court, then press READY.")
end

local function teleportPlayerToCourt(player, courtId)
	local targetSpawn = getCourtSpawn(courtId)
	local root = getAliveRoot(player)
	if not (targetSpawn and targetSpawn:IsA("BasePart") and root) then
		return
	end
	if not isCourtAvailable(courtId) then
		setState("Lobby", Config.CourtUnavailableMessage or "That court is playing!")
		updateCourtSelectBoardStatus()
		return
	end
	selectedCourtByPlayer[player] = courtId
	rememberCourtSelection(courtId)
	root.CFrame = targetSpawn.CFrame + Vector3.new(0, 3, 0)
	lobbyReady[player] = false
	updateCourtSelectBoardStatus()
	local court = findCourtConfig(courtId)
	local courtLabel = court.Label or tostring(courtId)
	setState("Lobby", string.format(Config.CourtSelectedMessageFormat or "%s selected. Press READY.", courtLabel))
end

local lobbyEntryTouchAtByPlayer = {}

local function selectLobbyEntry(player, entry)
	if not playerState[player] then
		return
	end
	local courtId = entry.CourtId or activeCourtId
	if not isCourtAvailable(courtId) then
		setState("Lobby", Config.CourtUnavailableMessage or "That court is playing!")
		updateCourtSelectBoardStatus()
		return
	end

	selectedCourtByPlayer[player] = courtId
	rememberCourtSelection(courtId)
	lobbyReady[player] = false
	updateCourtSelectBoardStatus()

	local label = entry.Label or Config.PracticeVsBotsButtonLabel or tostring(entry.Id or "Practice")
	setState("Lobby", string.format(Config.LobbyEntrySelectedMessageFormat or "%s selected. Press READY.", label))
end

local function getLobbyEntryPadName(entry)
	if entry.Id == "Quick2v2" then
		return "Quick2v2EntryPad"
	elseif entry.Id == "PrivateFriends" then
		return "PrivateFriendsEntryPad"
	end
	return "PracticeEntryPad"
end

local function connectLobbyEntryPad(entryPad, entry)
	entryPad:SetAttribute("LobbyEntryId", entry.Id)
	entryPad:SetAttribute("CourtId", entry.CourtId or activeCourtId)
	entryPad.CanTouch = Config.LobbyEntryPadTouchJoinEnabled ~= false

	local entryPadDetector = Instance.new("ClickDetector")
	entryPadDetector.MaxActivationDistance = 24
	entryPadDetector.Parent = entryPad
	entryPadDetector.MouseClick:Connect(function(player)
		selectLobbyEntry(player, entry)
	end)

	local entryPadPrompt = addProximityPrompt(entryPad, Config.LobbyEntryPromptActionText or "Join", entry.Label or tostring(entry.Id))
	entryPadPrompt.Triggered:Connect(function(player)
		selectLobbyEntry(player, entry)
	end)

	if Config.LobbyEntryPadTouchJoinEnabled == false then
		return
	end
	entryPad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local now = os.clock()
		if (lobbyEntryTouchAtByPlayer[player] or 0) + 0.8 > now then
			return
		end
		lobbyEntryTouchAtByPlayer[player] = now
		selectLobbyEntry(player, entry)
	end)
end

Monetization.getProduct = function(productKey)
	for _, product in ipairs(Config.MonetizationProducts or {}) do
		if product.Key == productKey then
			return product
		end
	end
	return nil
end

Monetization.getPassId = function(product)
	if not product then
		return 0
	end
	local passId = Config[product.PassIdKey or ""]
	if typeof(passId) ~= "number" then
		return 0
	end
	return passId
end

Monetization.refreshOwnership = function(player)
	local ownership = {}
	if Config.MonetizationLiteEnabled == false then
		monetizationOwnership[player] = ownership
		return ownership
	end
	for _, product in ipairs(Config.MonetizationProducts or {}) do
		local passId = Monetization.getPassId(product)
		local owned = false
		if passId > 0 then
			local success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			owned = success and result == true
		end
		ownership[product.Key] = owned
	end
	monetizationOwnership[player] = ownership
	return ownership
end

Monetization.buildPayload = function(player, openShop, message)
	local ownership = monetizationOwnership[player] or Monetization.refreshOwnership(player)
	local products = {}
	for _, product in ipairs(Config.MonetizationProducts or {}) do
		local passId = Monetization.getPassId(product)
		table.insert(products, {
			key = product.Key,
			name = product.Name,
			description = product.Description,
			passIdSet = passId > 0,
			owned = ownership[product.Key] == true,
		})
	end
	return {
		enabled = Config.MonetizationLiteEnabled ~= false,
		open = openShop == true,
		message = message or "",
		title = Config.MonetizationShopTitle or "COSMETIC SHOP",
		subtitle = Config.MonetizationShopSubtitle or "Style only. No power boosts.",
		ownedLabel = Config.MonetizationOwnedLabel or "OWNED",
		buyLabel = Config.MonetizationBuyLabel or "BUY",
		products = products,
	}
end

Monetization.sendState = function(player, openShop, message)
	if Config.MonetizationLiteEnabled == false then
		return
	end
	MonetizationStateEvent:FireClient(player, Monetization.buildPayload(player, openShop, message))
end

Monetization.promptPass = function(player, productKey)
	local product = Monetization.getProduct(productKey)
	if not product then
		return
	end
	local passId = Monetization.getPassId(product)
	if passId <= 0 then
		Monetization.sendState(player, true, Config.MonetizationUnavailableMessage or "Pass IDs are not set yet.")
		return
	end
	local ownership = monetizationOwnership[player] or Monetization.refreshOwnership(player)
	if ownership[product.Key] == true then
		Monetization.sendState(player, true, Config.MonetizationOwnedLabel or "OWNED")
		return
	end
	local success, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, passId)
	end)
	if not success then
		warn("[TDServer] Could not prompt game pass purchase: " .. tostring(err))
		Monetization.sendState(player, true, Config.MonetizationUnavailableMessage or "Pass IDs are not set yet.")
	end
end

Monetization.standTouchAtByPlayer = {}

Monetization.openShop = function(player)
	Monetization.refreshOwnership(player)
	Monetization.sendState(player, true, "")
end

Monetization.connectStand = function(stand)
	stand:SetAttribute("TD_CosmeticStand", true)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 24
	detector.Parent = stand
	detector.MouseClick:Connect(Monetization.openShop)

	local prompt = addProximityPrompt(stand, Config.MonetizationPromptActionText or "Shop", Config.MonetizationStandTitle or "COSMETIC SHOP")
	prompt.Triggered:Connect(Monetization.openShop)

	stand.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local now = os.clock()
		if (Monetization.standTouchAtByPlayer[player] or 0) + 1.0 > now then
			return
		end
		Monetization.standTouchAtByPlayer[player] = now
		Monetization.openShop(player)
	end)
end

PracticeWall.hitCountByPlayer = {}
PracticeWall.lastHitAtByPlayer = {}

PracticeWall.playForPlayer = function(player)
	if Config.PracticeWallEnabled == false then
		return
	end
	local now = os.clock()
	if (PracticeWall.lastHitAtByPlayer[player] or 0) + (Config.PracticeWallCooldownSeconds or 0.75) > now then
		return
	end
	PracticeWall.lastHitAtByPlayer[player] = now
	Analytics.recordForPlayer(player, "PracticeStarted")
	PracticeWall.hitCountByPlayer[player] = (PracticeWall.hitCountByPlayer[player] or 0) + 1

	local practiceBall = LobbyFolder:FindFirstChild("TD_PracticeWallBall")
	local target = LobbyFolder:FindFirstChild("TD_PracticeWallTarget")
	local pad = LobbyFolder:FindFirstChild("TD_PracticeWallPad")
	if not (practiceBall and practiceBall:IsA("BasePart") and target and target:IsA("BasePart") and pad and pad:IsA("BasePart")) then
		return
	end

	local hitCount = PracticeWall.hitCountByPlayer[player]
	local fxType = "OnePin"
	local comboCount = 1
	if hitCount % (Config.PracticeWallHareEvery or 3) == 0 then
		fxType = "Hare"
		comboCount = math.max(1, math.floor(hitCount / (Config.PracticeWallHareEvery or 3)))
	elseif hitCount % 2 == 0 then
		fxType = "Slack"
	end

	local startCFrame = pad.CFrame + Vector3.new(0, 2.2, 0)
	local targetCFrame = target.CFrame + Vector3.new(0, 0.4, -0.8)
	practiceBall.Transparency = 0
	practiceBall.CFrame = startCFrame
	local tween = TweenService:Create(practiceBall, TweenInfo.new(Config.PracticeWallBallTravelSeconds or 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = targetCFrame,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if practiceBall and practiceBall.Parent then
			practiceBall.CFrame = startCFrame
			practiceBall.Transparency = 0.18
		end
	end)

	HitFxEvent:FireClient(player, fxType, practiceBall.Position, player.Team and player.Team.Name or "Red", hitCount, comboCount)
end

PracticeWall.connectPad = function(practicePad)
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 24
	detector.Parent = practicePad
	detector.MouseClick:Connect(PracticeWall.playForPlayer)

	local practicePrompt = addProximityPrompt(practicePad, Config.PracticeWallPromptActionText or "Practice", Config.PracticeWallPromptObjectText or "Practice Wall")
	practicePrompt.Triggered:Connect(PracticeWall.playForPlayer)

	practicePad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			PracticeWall.playForPlayer(player)
		end
	end)
end

local function createCourtSelectionWorld()
	clearFolder(LobbyFolder)
	clearFolder(CourtsFolder)
	courtButtonLabels = {}
	courtButtons = {}
	lobbyParticipantLabel = nil

	local lobbySpawnPos = Config.LobbySpawnPosition or Vector3.new(0, 3, -88)
	local modePadZ = lobbySpawnPos.Z + (Config.LobbyModePadZOffset or 18)
	local readyBoardZ = lobbySpawnPos.Z + (Config.LobbyReadyBoardZOffset or 32)
	local courtBoardZ = lobbySpawnPos.Z + (Config.LobbyCourtBoardZOffset or 48)
	local lobbyCenterZ = lobbySpawnPos.Z + ((Config.LobbyCourtBoardZOffset or 48) / 2)
	makeWorldPart(LobbyFolder, "LobbyFloor", Vector3.new(86, 0.35, 76), CFrame.new(lobbySpawnPos.X, -0.2, lobbyCenterZ), Color3.fromRGB(38, 72, 58), Enum.Material.Grass, true)
	local lobbySpawn = makeWorldPart(LobbyFolder, "LobbySpawn", Vector3.new(4, 1, 4), CFrame.new(lobbySpawnPos), Color3.fromRGB(255, 230, 120), Enum.Material.Neon, false)
	lobbySpawn.Transparency = 0.35

	local modeBoard = makeWorldPart(LobbyFolder, "LobbyModeBoard", Vector3.new(42, 3.6, 1.0), CFrame.new(lobbySpawnPos.X, 4.8, modePadZ - 8), Color3.fromRGB(12, 18, 28), Enum.Material.SmoothPlastic, true)
	addBillboardText(modeBoard, string.format("%s\n%s", Config.LobbyModeBoardTitle or "1  CHOOSE MODE", Config.LobbyFlowHelpText or "Choose mode, optional court, then READY."), Vector2.new(390, 68), Vector3.new(0, 1.0, 0), false, 54)

	addLobbyTutorialBoard(LobbyFolder, lobbySpawnPos)

	if Config.DailyBoostEnabled ~= false then
		local dailyBoard = makeWorldPart(LobbyFolder, "DailyBoostBoard", Vector3.new(32, 4.0, 1.0), CFrame.new(lobbySpawnPos.X, 4.9, lobbySpawnPos.Z + 14), Color3.fromRGB(42, 32, 64), Enum.Material.SmoothPlastic, true)
		addBillboardText(dailyBoard, string.format("%s\n%s", Config.DailyBoostBoardTitle or "DAILY BOOST", Config.DailyBoostBoardHelp or "Hit 1 HARE + Rally 4 to earn a Boost."), Vector2.new(300, 66), Vector3.new(0, 1.0, 0), false, 46)
	end

	local participantBoard = makeWorldPart(LobbyFolder, "LobbyParticipantBoard", Vector3.new(18, 3.2, 1.0), CFrame.new(lobbySpawnPos.X - 30, 4.2, readyBoardZ), Color3.fromRGB(22, 32, 46), Enum.Material.SmoothPlastic, true)
	local participantGui, participantLabel = addBillboardText(participantBoard, string.format(Config.LobbyParticipantCountFormat or "Players %d / Ready %d", 0, 0), Vector2.new(178, 44), Vector3.new(0, 1.0, 0), false, 46)
	participantGui.Name = "LobbyParticipantLabel"
	lobbyParticipantLabel = participantLabel

	local spectatorArea = makeWorldPart(LobbyFolder, "LobbySpectatorArea", Vector3.new(18, 0.45, 9), CFrame.new(lobbySpawnPos.X + 30, 0.25, readyBoardZ), Color3.fromRGB(118, 132, 150), Enum.Material.SmoothPlastic, true)
	addBillboardText(spectatorArea, string.format("%s\n%s", Config.LobbySpectatorLabel or "SPECTATE", Config.LobbySpectatorHelp or "Watch the next match from here."), Vector2.new(180, 52), Vector3.new(0, 2.0, 0), false, 46)

	if Config.PracticeWallEnabled ~= false then
		local practiceX = lobbySpawnPos.X + (Config.PracticeWallXOffset or 30)
		local practiceZ = lobbySpawnPos.Z + (Config.PracticeWallZOffset or 18)
		local practiceWall = makeWorldPart(LobbyFolder, "TD_PracticeWall", Vector3.new(18, 9, 1.2), CFrame.new(practiceX, 4.4, practiceZ + 8), Color3.fromRGB(32, 44, 62), Enum.Material.SmoothPlastic, true)
		addBillboardText(practiceWall, string.format("%s\n%s", Config.PracticeWallTitle or "PRACTICE WALL", Config.PracticeWallHelp or "Hit PIN!  Try HARE!"), Vector2.new(190, 64), Vector3.new(0, 1.0, 0), false, 48)
		local practiceTarget = makeWorldPart(LobbyFolder, "TD_PracticeWallTarget", Vector3.new(5.5, 5.5, 0.35), CFrame.new(practiceX, 4.3, practiceZ + 7.15), Color3.fromRGB(255, 226, 118), Enum.Material.Neon, false)
		practiceTarget.Transparency = 0.20
		local practicePad = makeWorldPart(LobbyFolder, "TD_PracticeWallPad", Vector3.new(14, 0.55, 7), CFrame.new(practiceX, 0.35, practiceZ), Color3.fromRGB(255, 226, 118), Enum.Material.Neon, true)
		addBillboardText(practicePad, "Practice Wall\nHit PIN!", Vector2.new(160, 48), Vector3.new(0, 2.0, 0), false, 42)
		local practiceBall = makeWorldPart(LobbyFolder, "TD_PracticeWallBall", Vector3.new(2.0, 2.0, 2.0), CFrame.new(practiceX, 2.4, practiceZ), Color3.fromRGB(255, 245, 180), Enum.Material.Neon, false)
		practiceBall.Shape = Enum.PartType.Ball
		practiceBall.CanTouch = false
		practiceBall.Transparency = 0.18
		PracticeWall.connectPad(practicePad)
	end

	if Config.MonetizationLiteEnabled ~= false then
		local shopStand = makeWorldPart(LobbyFolder, "TD_CosmeticStand", Vector3.new(18, 0.55, 8), CFrame.new(lobbySpawnPos.X - 30, 0.35, modePadZ), Color3.fromRGB(255, 174, 98), Enum.Material.Neon, true)
		addBillboardText(shopStand, string.format("%s\n%s", Config.MonetizationStandTitle or "COSMETIC SHOP", Config.MonetizationStandHelp or "Fiber colors and HARE FX. No pay-to-win."), Vector2.new(180, 58), Vector3.new(0, 2.0, 0), false, 44)
		Monetization.connectStand(shopStand)
	end

	for _, entry in ipairs(Config.LobbyEntryPads or {}) do
		local entryPad = makeWorldPart(LobbyFolder, getLobbyEntryPadName(entry), Vector3.new(15, 0.55, 9), CFrame.new(lobbySpawnPos.X + (entry.X or 0), 0.35, modePadZ), entry.Color or Color3.fromRGB(120, 180, 120), Enum.Material.Neon, true)
		addBillboardText(entryPad, string.format("%s\n%s", entry.Label or tostring(entry.Id), entry.SubLabel or ""), Vector2.new(164, 58), Vector3.new(0, 2.0, 0), false, 44)
		connectLobbyEntryPad(entryPad, entry)
	end

	local readyBoard = makeWorldPart(LobbyFolder, "LobbyReadyBoard", Vector3.new(28, 3.6, 1.0), CFrame.new(lobbySpawnPos.X, 4.6, readyBoardZ), Color3.fromRGB(255, 226, 118), Enum.Material.SmoothPlastic, true)
	addBillboardText(readyBoard, string.format("%s\n%s", Config.LobbyReadyBoardTitle or "3  PRESS READY", Config.LobbyReadySubMessage or "Choose a mode pad, then press READY."), Vector2.new(260, 60), Vector3.new(0, 1.0, 0), false, 48)

	local board = Instance.new("Folder")
	board.Name = "CourtSelectBoard"
	board.Parent = LobbyFolder
	makeWorldPart(board, "BoardBack", Vector3.new(42, 8, 1.2), CFrame.new(lobbySpawnPos.X, 4, courtBoardZ), Color3.fromRGB(24, 34, 42), Enum.Material.WoodPlanks, true)
	local title = makeWorldPart(board, "HowToStartSign", Vector3.new(38, 4.5, 0.8), CFrame.new(lobbySpawnPos.X, 8.2, courtBoardZ + 0.3), Color3.fromRGB(12, 18, 28), Enum.Material.SmoothPlastic, false)
	addBillboardText(title, string.format("%s\n%s", Config.LobbyCourtBoardTitle or Config.CourtSelectBoardTitle or "OPTIONAL COURT THEME", Config.CourtSelectBoardHelp or "Pick a look, or keep the selected mode."), Vector2.new(360, 86), Vector3.new(0, 1.0, 0), false, 48)

	local courts = Config.CourtSelections or {}
	for index, court in ipairs(courts) do
		local buttonX = lobbySpawnPos.X - 20 + (index - 1) * 10
		local button = makeWorldPart(board, tostring(court.Id) .. "Button", Vector3.new(8.5, 3.2, 1.4), CFrame.new(buttonX, 3.4, courtBoardZ + 1), court.Color or Color3.fromRGB(120, 180, 120), Enum.Material.SmoothPlastic, true)
		button:SetAttribute("CourtId", court.Id)
		local _, label = addBillboardText(button, court.Label or tostring(court.Id), Vector2.new(112, 46), Vector3.new(0, 2.2, 0), false, 36)
		courtButtonLabels[court.Id] = label
		courtButtons[court.Id] = button
		local detector = Instance.new("ClickDetector")
		detector.MaxActivationDistance = 24
		detector.Parent = button
		detector.MouseClick:Connect(function(player)
			teleportPlayerToCourt(player, button:GetAttribute("CourtId"))
		end)
		local prompt = addProximityPrompt(button, Config.CourtPromptActionText or "Choose", court.Label or tostring(court.Id))
		prompt.Triggered:Connect(function(player)
			teleportPlayerToCourt(player, button:GetAttribute("CourtId"))
		end)

		local courtFolder = Instance.new("Folder")
		courtFolder.Name = tostring(court.Id) .. "Court"
		courtFolder.Parent = CourtsFolder
		local x = court.X or ((index - 1) * 300)
		makeWorldPart(courtFolder, "PreviewPad", Vector3.new(64, 0.35, 64), CFrame.new(x, -0.2, 0), court.Color or Color3.fromRGB(96, 185, 58), Enum.Material.SmoothPlastic, true)
		makeWorldPart(courtFolder, "CourtSpawn", Vector3.new(4, 1, 4), CFrame.new(x, 1, -36), Color3.fromRGB(255, 230, 120), Enum.Material.Neon, false)
		local spawn = makeWorldPart(courtFolder, "SpawnPoint", Vector3.new(4, 1, 4), CFrame.new(x, 3, -40), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, false)
		spawn.Transparency = 0.4
		addBillboardText(spawn, court.Label or tostring(court.Id), Vector2.new(118, 32), Vector3.new(0, 2.0, 0), false, 42)
		local returnPad = makeWorldPart(courtFolder, "BackToLobbyPad", Vector3.new(8, 0.45, 5), CFrame.new(x, 0.2, -47), Color3.fromRGB(255, 235, 110), Enum.Material.Neon, false)
		addBillboardText(returnPad, Config.CourtReturnPromptObjectText or "Back to Lobby", Vector2.new(132, 34), Vector3.new(0, 1.8, 0), false, 42)
		local returnPrompt = addProximityPrompt(returnPad, Config.CourtReturnPromptActionText or "Lobby", Config.CourtReturnPromptObjectText or "Back to Lobby")
		returnPrompt.Triggered:Connect(function(player)
			returnPlayerToLobby(player)
		end)
	end
	updateCourtSelectBoardStatus()
end

local function createCrowdDots()
	local total = totalHalfDepth()
	local w = Config.CourtWidth
	local count = Config.CrowdDotCountPerSide or 12
	for sideIndex, z in ipairs({ total + 5, -total - 5 }) do
		for i = 1, count do
			local t = (i - 0.5) / count
			local x = -w / 2 + t * w
			local dot = Instance.new("Part")
			dot.Name = "CrowdDot"
			dot.Shape = Enum.PartType.Ball
			dot.Anchored = true
			dot.CanCollide = false
			dot.CanQuery = false
			dot.CanTouch = false
			dot.Size = Vector3.new(1.15, 1.15, 1.15)
			dot.Position = courtPosition(x, 1.1 + ((i % 3) * 0.18), z)
			dot.Material = Enum.Material.Neon
			local mix = (i + sideIndex) % 3
			if mix == 0 then
				dot.Color = TEAM_COLORS.Red
			elseif mix == 1 then
				dot.Color = TEAM_COLORS.Blue
			else
				dot.Color = Color3.fromRGB(255, 220, 95)
			end
			dot:SetAttribute("BaseColorR", dot.Color.R)
			dot:SetAttribute("BaseColorG", dot.Color.G)
			dot:SetAttribute("BaseColorB", dot.Color.B)
			dot:SetAttribute("CrowdOrder", i + (sideIndex - 1) * count)
			dot.Transparency = 0.22
			dot.Parent = VisualsFolder
		end
	end
end

local function createJuiceBorders(total)
	local w = Config.CourtWidth
	local trimColor = Color3.fromRGB(130, 185, 255)
	local borders = {
		{ "JuiceBorder_Left", Vector3.new(0.22, 0.22, total * 2 + 1.0), Vector3.new(-w / 2 - 0.82, 0.28, 0) },
		{ "JuiceBorder_Right", Vector3.new(0.22, 0.22, total * 2 + 1.0), Vector3.new(w / 2 + 0.82, 0.28, 0) },
		{ "JuiceBorder_Red", Vector3.new(w + 1.6, 0.22, 0.22), Vector3.new(0, 0.28, total + 0.82) },
		{ "JuiceBorder_Blue", Vector3.new(w + 1.6, 0.22, 0.22), Vector3.new(0, 0.28, -total - 0.82) },
	}
	for _, info in ipairs(borders) do
		local strip = makeNonCollidePart(info[1], info[2], info[3], trimColor, Enum.Material.Neon, VisualsFolder)
		strip:SetAttribute("BaseColorR", trimColor.R)
		strip:SetAttribute("BaseColorG", trimColor.G)
		strip:SetAttribute("BaseColorB", trimColor.B)
	end
end

local function createMatchSpawns()
	createSpawn("RedSpawn1", Vector3.new(-10, 3, 18))
	createSpawn("RedSpawn2", Vector3.new(10, 3, 18))
	createSpawn("BlueSpawn1", Vector3.new(-10, 3, -18))
	createSpawn("BlueSpawn2", Vector3.new(10, 3, -18))
end

local function createTeamSideGuides()
	if Config.TeamSideLabelEnabled == false then
		return
	end

	local labelSize = Config.TeamSideLabelSize or 13
	local ringSize = Config.TeamSpawnRingSize or 7.8
	local redSideLabel = makeNonCollidePart("RedSideFloorLabel", Vector3.new(labelSize * 2.7, 0.016, labelSize), Vector3.new(0, 0.36, Config.CourtDepth * 0.58), TEAM_COLORS.Red, Enum.Material.Neon, VisualsFolder)
	redSideLabel.Transparency = 0.28
	addSurfaceText(redSideLabel, "RED SIDE", Color3.fromRGB(255, 255, 255), Enum.NormalId.Top)

	local blueSideLabel = makeNonCollidePart("BlueSideFloorLabel", Vector3.new(labelSize * 2.7, 0.016, labelSize), Vector3.new(0, 0.36, -Config.CourtDepth * 0.58), TEAM_COLORS.Blue, Enum.Material.Neon, VisualsFolder)
	blueSideLabel.Transparency = 0.28
	addSurfaceText(blueSideLabel, "BLUE SIDE", Color3.fromRGB(255, 255, 255), Enum.NormalId.Top)

	for _, info in ipairs({
		{ "RedSpawnRing1", TEAM_COLORS.Red, Vector3.new(-10, 0.38, 18) },
		{ "RedSpawnRing2", TEAM_COLORS.Red, Vector3.new(10, 0.38, 18) },
		{ "BlueSpawnRing1", TEAM_COLORS.Blue, Vector3.new(-10, 0.38, -18) },
		{ "BlueSpawnRing2", TEAM_COLORS.Blue, Vector3.new(10, 0.38, -18) },
	}) do
		local ring = makeNonCollidePart(info[1], Vector3.new(ringSize, 0.018, ringSize), info[3], info[2], Enum.Material.Neon, VisualsFolder)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(courtPosition(info[3].X, info[3].Y, info[3].Z))
		ring.Transparency = 0.48
	end
end

local function findArenaTemplate(arenaConfig)
	local waitSeconds = arenaConfig.ModelWaitSeconds or 3
	local modelName = arenaConfig.ModelName or "TDArena_TileField64"
	local arenaFolder = ServerStorage:FindFirstChild(Config.ArenaFolderName or "Arenas")
	if not arenaFolder then
		arenaFolder = ServerStorage:WaitForChild(Config.ArenaFolderName or "Arenas", waitSeconds)
	end

	local template = arenaFolder and arenaFolder:FindFirstChild(modelName)
	if not template and arenaFolder then
		template = arenaFolder:WaitForChild(modelName, waitSeconds)
	end
	if template then
		return template
	end

	template = ServerStorage:FindFirstChild(modelName)
	if template then
		return template
	end

	local legacyName = arenaConfig.LegacyModelName
	if legacyName then
		template = ServerStorage:FindFirstChild(legacyName)
		if template then
			return template
		end
	end

	if activeCourtId == "Grass" or arenaConfig.CourtId == "Grass" then
		return ServerStorage:FindFirstChild("TDArena_TileField64")
	end
	return nil
end

local function createConfiguredArenaCourt()
	if not shouldUseCourtArena() then
		return false
	end

	local arenaConfig = getCourtArenaConfig(activeCourtId)
	local modelName = arenaConfig.ModelName or "TDArena_TileField64"
	local template = findArenaTemplate(arenaConfig)
	if not template then
		warn(("[TDServer] %s was not found in ServerStorage/%s or legacy ServerStorage roots; using generated flat court fallback. Run %s first."):format(modelName, Config.ArenaFolderName or "Arenas", arenaConfig.BuilderScriptPath or "the arena builder"))
		return false
	end
	if not template:IsA("Model") then
		warn(("[TDServer] Arena template %s is not a Model; using generated flat court fallback."):format(template:GetFullName()))
		return false
	end

	local arena = template:Clone()
	arena.Name = "Active_" .. modelName
	arena:SetAttribute("RuntimeCourtId", activeCourtId)
	arena:SetAttribute("SourceImagePath", arenaConfig.SourceImagePath or "")
	arena:SetAttribute("SourceDataPath", arenaConfig.SourceDataPath or "data/arena/tile-field-64-arena.json")
	arena:SetAttribute("BuilderScriptPath", arenaConfig.BuilderScriptPath or "scripts/roblox/build_tile_field_64_arena.server.lua")
	arena:PivotTo(CFrame.new(activeCourtOrigin))
	arena.Parent = CourtFolder

	createJuiceBorders(activeHalfDepth())
	createTeamSideGuides()
	createMatchSpawns()
	return true
end

local function createCourt(origin)
	activeCourtOrigin = origin or activeCourtOrigin
	clearGeneratedCourt()

	if createConfiguredArenaCourt() then
		return
	end

	local w = Config.CourtWidth
	local d = Config.CourtDepth
	local out = Config.OutZoneDepth
	local total = d + out

	makePart("FloatingBase", Vector3.new(w + 13, 1.1, total * 2 + 13), Vector3.new(0, -1.05, 0), Color3.fromRGB(14, 16, 24), Enum.Material.SmoothPlastic)
	makePart("Base", Vector3.new(w + 8, 0.4, total * 2 + 8), Vector3.new(0, -0.25, 0), Color3.fromRGB(28, 32, 42), Enum.Material.SmoothPlastic)
	makePart("RedCourt", Vector3.new(w, 0.24, d), Vector3.new(0, 0, d / 2), Color3.fromRGB(95, 42, 50), Enum.Material.SmoothPlastic)
	makePart("BlueCourt", Vector3.new(w, 0.24, d), Vector3.new(0, 0, -d / 2), Color3.fromRGB(40, 55, 95), Enum.Material.SmoothPlastic)
	makePart("RedOutZone", Vector3.new(w, 0.22, out), Vector3.new(0, 0.03, d + out / 2), Color3.fromRGB(55, 33, 38), Enum.Material.SmoothPlastic)
	makePart("BlueOutZone", Vector3.new(w, 0.22, out), Vector3.new(0, 0.03, -d - out / 2), Color3.fromRGB(28, 36, 58), Enum.Material.SmoothPlastic)
	makePart("CenterLine", Vector3.new(w + 0.5, 0.35, 0.7), Vector3.new(0, 0.12, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	local wallColor = Color3.fromRGB(18, 20, 27)
	makePart("Wall_Left", Vector3.new(0.7, Config.WallHeight, total * 2), Vector3.new(-w / 2 - 0.35, Config.WallHeight / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_Right", Vector3.new(0.7, Config.WallHeight, total * 2), Vector3.new(w / 2 + 0.35, Config.WallHeight / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_RedBack", Vector3.new(w + 1.4, Config.WallHeight, 0.7), Vector3.new(0, Config.WallHeight / 2, total + 0.35), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_BlueBack", Vector3.new(w + 1.4, Config.WallHeight, 0.7), Vector3.new(0, Config.WallHeight / 2, -total - 0.35), wallColor, Enum.Material.SmoothPlastic)

	-- Neon arena trim. These pulse gold on HARE.
	createJuiceBorders(total)
	createTeamSideGuides()

	-- Center emblem: floor-art style so it does not read as a physical obstacle.
	local emblemY = 0.154
	local emblem = makeNonCollidePart("CenterEmblemFloorArt", Vector3.new(Config.CenterEmblemSize, 0.014, Config.CenterEmblemSize), Vector3.new(0, emblemY, 0), Color3.fromRGB(245, 245, 255), Enum.Material.SmoothPlastic, VisualsFolder)
	emblem.Transparency = Config.CenterEmblemTransparency or 0.62
	local ring = makeNonCollidePart("CenterEmblemSoftRing", Vector3.new(Config.CenterEmblemSize * 1.16, 0.010, Config.CenterEmblemSize * 1.16), Vector3.new(0, emblemY + 0.006, 0), Color3.fromRGB(255, 230, 120), Enum.Material.SmoothPlastic, VisualsFolder)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(courtPosition(0, emblemY + 0.012, 0))
	ring.Transparency = 0.86
	ring.CastShadow = false
	local rayColor = Color3.fromRGB(255, 235, 130)
	for i = 1, 8 do
		local angle = (math.pi * 2) * (i - 1) / 8
		local ray = makeNonCollidePart("CenterEmblemRay", Vector3.new(0.12, 0.010, Config.CenterEmblemSize * 0.58), Vector3.new(0, emblemY + 0.012, 0), rayColor, Enum.Material.Neon, VisualsFolder)
		ray.CFrame = CFrame.new(courtPosition(0, emblemY + 0.012, 0)) * CFrame.Angles(0, angle, 0)
		ray.Transparency = 0.76
		ray.CastShadow = false
	end

	-- Team banners/flags. Very cheap, very readable.
	createFlag("Red", -w / 2 - 4.5, total - 4)
	createFlag("Red", w / 2 + 4.5, total - 4)
	createFlag("Blue", -w / 2 - 4.5, -total + 4)
	createFlag("Blue", w / 2 + 4.5, -total + 4)
	createCrowdDots()

	createMatchSpawns()
end

local function ensureTeams()
	for teamName, color in pairs(TEAM_COLORS) do
		local team = TeamsService:FindFirstChild(teamName)
		if not team then
			team = Instance.new("Team")
			team.Name = teamName
			team.AutoAssignable = false
			team.Parent = TeamsService
		end
		team.TeamColor = BrickColor.new(color)
	end
end

local function ensureCpuLabel(part)
	local labelGui = part:FindFirstChild("TD_CPU_Label")
	if not labelGui then
		labelGui = Instance.new("BillboardGui")
		labelGui.Name = "TD_CPU_Label"
		labelGui.AlwaysOnTop = true
		labelGui.Size = UDim2.fromOffset(86, 28)
		labelGui.StudsOffset = Vector3.new(0, 2.2, 0)
		labelGui.Parent = part

		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.Text = Config.CpuFillLabelText or "CPU"
		label.TextColor3 = Color3.fromRGB(255, 245, 170)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.15
		label.TextScaled = true
		label.Parent = labelGui
	end
	return labelGui
end

local function ensureCpuPolish(part, teamName)
	local outline = part:FindFirstChild("TD_CPU_Outline")
	if not outline then
		outline = Instance.new("SelectionBox")
		outline.Name = "TD_CPU_Outline"
		outline.LineThickness = 0.06
		outline.SurfaceTransparency = 0.72
		outline.Adornee = part
		outline.Parent = part
	end
	outline.Color3 = TEAM_COLORS[teamName]:Lerp(Color3.fromRGB(255, 255, 255), 0.25)

	local light = part:FindFirstChild("TD_CPU_Glow")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "TD_CPU_Glow"
		light.Brightness = 0.75
		light.Range = 9
		light.Parent = part
	end
	light.Color = TEAM_COLORS[teamName]

	local a0 = part:FindFirstChild("TD_CPU_TrailA")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "TD_CPU_TrailA"
		a0.Position = Vector3.new(0, 0.9, 0)
		a0.Parent = part
	end
	local a1 = part:FindFirstChild("TD_CPU_TrailB")
	if not a1 then
		a1 = Instance.new("Attachment")
		a1.Name = "TD_CPU_TrailB"
		a1.Position = Vector3.new(0, -0.9, 0)
		a1.Parent = part
	end
	local trail = part:FindFirstChild("TD_CPU_Trail")
	if not trail then
		trail = Instance.new("Trail")
		trail.Name = "TD_CPU_Trail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.22
		trail.LightEmission = 0.75
		trail.MinLength = 0.1
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Parent = part
	end
	trail.Color = ColorSequence.new(TEAM_COLORS[teamName]:Lerp(Color3.fromRGB(255, 240, 140), 0.18))
end

local function createGhostPart(teamName, index, position)
	local part = Instance.new("Part")
	part.Name = Config.CpuFillEnabled and (teamName .. "CPUPartner" .. tostring(index)) or (teamName .. "GhostPartner" .. tostring(index))
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	local ghostSize = Config.CpuFillEnabled and (Config.CpuFillPartSize or 2.2) or (Config.GhostPartSize or 0.55)
	part.Size = Vector3.new(ghostSize, ghostSize, ghostSize)
	part.Material = Enum.Material.Neon
	part.Transparency = Config.CpuFillEnabled and 0.18 or ((Config.GhostPartnerVisible == true) and 0.55 or (Config.GhostPartTransparency or 1))
	part.CastShadow = false
	part.Color = TEAM_COLORS[teamName]
	part.Position = position
	part:SetAttribute("CpuFillTeam", teamName)
	part:SetAttribute("CpuFillSlot", index)
	part:SetAttribute("CpuFillActive", Config.CpuFillEnabled == true)
	part:SetAttribute("CpuPinning", false)
	part.Parent = VisualsFolder

	local attachment = Instance.new("Attachment")
	attachment.Name = "TDNetAttachment"
	attachment.Parent = part
	ensureCpuLabel(part).Enabled = Config.CpuFillEnabled == true
	ensureCpuPolish(part, teamName)

	cpuPartnerState[teamName][index] = cpuPartnerState[teamName][index] or {
		IsPinning = false,
		LastPinStartTime = -math.huge,
		NextPinDecisionAt = 0,
		NextTargetUpdateAt = 0,
		TargetPosition = position,
		NextPinAllowedAt = 0,
	}
	return part
end

local function ensureGhostPartners()
	for teamName, side in pairs({ Red = 1, Blue = -1 }) do
		ghostPartners[teamName] = ghostPartners[teamName] or {}
		for i = 1, 2 do
			if not ghostPartners[teamName][i] or not ghostPartners[teamName][i].Parent then
				local x = (i == 1) and -8 or 8
				local z = side * 18
				ghostPartners[teamName][i] = createGhostPart(teamName, i, courtPosition(x, Config.NetVisualHeight, z))
			end
		end
	end
end

local function ensureBallReadabilityHalo(part)
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if not (halo and halo:IsA("BasePart")) then
		halo = Instance.new("Part")
		halo.Name = "TD_BallReadabilityHalo"
		halo.Parent = workspace
	end

	halo.Shape = Enum.PartType.Ball
	halo.Anchored = true
	halo.CanCollide = false
	halo.CanQuery = false
	halo.CanTouch = false
	halo.CastShadow = false
	local haloSize = Config.BallReadabilityHaloSize or 4.4
	halo.Size = Vector3.new(haloSize, haloSize, haloSize)
	halo.Material = Enum.Material.Neon
	halo.Color = Color3.fromRGB(255, 242, 150)
	halo.Transparency = Config.BallReadabilityHaloTransparency or 0.62
	halo.CFrame = part.CFrame
	return halo
end

local function ensureServeBallLabel(part)
	local gui = part:FindFirstChild("TD_ServeLabel")
	if not (gui and gui:IsA("BillboardGui")) then
		gui = Instance.new("BillboardGui")
		gui.Name = "TD_ServeLabel"
		gui.AlwaysOnTop = true
		gui.Size = UDim2.fromOffset(96, 34)
		gui.StudsOffset = Vector3.new(0, 3.4, 0)
		gui.MaxDistance = 160
		gui.Enabled = false
		gui.Parent = part

		local label = Instance.new("TextLabel")
		label.Name = "TD_ServeLabelText"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
		label.BackgroundTransparency = 0.18
		label.Text = Config.ServeBallLabelText or "SERVE"
		label.TextColor3 = Color3.fromRGB(255, 245, 180)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0.20
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.Parent = gui
	end
	return gui
end

local function setServeBallLabelVisible(visible, teamName)
	local part = ball.part
	if not part then
		return
	end
	local gui = ensureServeBallLabel(part)
	local label = gui:FindFirstChild("TD_ServeLabelText")
	if label and label:IsA("TextLabel") then
		label.Text = Config.ServeBallLabelText or "SERVE"
		if teamName == "Red" then
			label.TextColor3 = TEAM_COLORS.Red:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
		elseif teamName == "Blue" then
			label.TextColor3 = TEAM_COLORS.Blue:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
		end
	end
	gui.Enabled = visible == true
end

local function ensureBallPart()
	if ball.part and ball.part.Parent then
		ensureBallReadabilityHalo(ball.part)
		ensureServeBallLabel(ball.part)
		return ball.part
	end

	local part = Instance.new("Part")
	part.Name = "TensionBall"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(Config.BallRadius * 2, Config.BallRadius * 2, Config.BallRadius * 2)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 245, 180)

	local light = Instance.new("PointLight")
	light.Name = "MobileReadableGlow"
	light.Brightness = Config.BallReadableGlowBrightness or 3.4
	light.Range = Config.BallReadableGlowRange or 22
	light.Color = Color3.fromRGB(255, 240, 160)
	light.Parent = part

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(0, Config.BallRadius * 0.55, 0)
	a0.Parent = part

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(0, -Config.BallRadius * 0.55, 0)
	a1.Parent = part

	local trail = Instance.new("Trail")
	trail.Name = "BallTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = Config.BallTrailLifetime or 0.50
	trail.MinLength = 0.2
	trail.LightEmission = 0.95
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 245, 180))
	trail.Parent = part

	part.Parent = workspace
	ball.part = part
	ensureBallReadabilityHalo(part)
	ensureServeBallLabel(part)
	return part
end

local function setBallVisualCFrame(cframe)
	if ball.part then
		ball.part.CFrame = cframe
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.CFrame = cframe
	end
end

local function setBallVisualHidden(hidden)
	local transparency = hidden and 1 or 0
	if ball.part then
		ball.part.Transparency = transparency
	end
	if hidden then
		setServeBallLabelVisible(false)
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.Transparency = hidden and 1 or (Config.BallReadabilityHaloTransparency or 0.62)
	end
end

local function ensureLandingTargetMarker()
	if landingTargetMarker and landingTargetMarker.Parent then
		return landingTargetMarker
	end

	local marker = Instance.new("Part")
	marker.Name = "TD_LandingTargetMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	local size = Config.LandingTargetSize or 5.8
	marker.Size = Vector3.new(Config.LandingTargetThickness or 0.09, size, size)
	marker.Material = Enum.Material.Neon
	marker.Color = Config.LandingTargetInColor or Color3.fromRGB(255, 240, 130)
	marker.Transparency = 1
	marker.CFrame = CFrame.new(0, -1000, 0)
	marker.Parent = VisualsFolder
	landingTargetMarker = marker
	return marker
end

local function hideLandingTargetMarker()
	local marker = landingTargetMarker
	if marker and marker.Parent then
		marker.Transparency = 1
		marker.CFrame = CFrame.new(0, -1000, 0)
	end
end

local function predictBallLanding()
	local maxTime = Config.LandingTargetMaxPredictionTime or 2.4
	local gravity = Config.BallGravity or 42
	local targetY = Config.BallRadius or 1.72
	local y0 = ball.position.Y
	local vy = ball.velocity.Y
	local a = -0.5 * gravity
	local b = vy
	local c = y0 - targetY
	local t = maxTime
	local discriminant = b * b - 4 * a * c

	if discriminant >= 0 and a ~= 0 then
		local sqrtDiscriminant = math.sqrt(discriminant)
		local t1 = (-b + sqrtDiscriminant) / (2 * a)
		local t2 = (-b - sqrtDiscriminant) / (2 * a)
		local best = math.huge
		if t1 > 0 then
			best = math.min(best, t1)
		end
		if t2 > 0 then
			best = math.min(best, t2)
		end
		if best < math.huge then
			t = math.min(best, maxTime)
		end
	end

	local predicted = ball.position + ball.velocity * t + Vector3.new(0, -0.5 * gravity * t * t, 0)
	local out = isBallOutsideArena(predicted)
	local clampedX = math.clamp(predicted.X, activeCourtOrigin.X - halfWidth(), activeCourtOrigin.X + halfWidth())
	local zHalfDepth = activeHalfDepth()
	local clampedZ = math.clamp(predicted.Z, activeCourtOrigin.Z - zHalfDepth, activeCourtOrigin.Z + zHalfDepth)
	return Vector3.new(clampedX, 0.33, clampedZ), out
end

local function updateLandingTargetMarker()
	if Config.LandingTargetEnabled == false then
		hideLandingTargetMarker()
		return
	end
	if not ball.active or not roundActive then
		hideLandingTargetMarker()
		return
	end

	local now = os.clock()
	if now - lastLandingTargetUpdate < (Config.LandingTargetUpdateInterval or 0.08) then
		return
	end
	lastLandingTargetUpdate = now

	local marker = ensureLandingTargetMarker()
	local position, out = predictBallLanding()
	local size = Config.LandingTargetSize or 5.8
	marker.Size = Vector3.new(Config.LandingTargetThickness or 0.09, size, size)
	marker.Color = out and (Config.LandingTargetOutColor or Color3.fromRGB(255, 80, 80)) or (Config.LandingTargetInColor or Color3.fromRGB(255, 240, 130))
	marker.Transparency = out and (Config.LandingTargetOutTransparency or 0.12) or (Config.LandingTargetTransparency or 0.28)
	marker.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

local function ensurePinIndicator(player)
	local key = tostring(player.UserId)
	local ring = pinIndicators[key]
	if ring and ring.Parent then
		return ring
	end

	ring = Instance.new("Part")
	ring.Name = "TD_PinRing_" .. key
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(Config.PinRingRadius, Config.PinRingHeight, Config.PinRingRadius)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 80)
	ring.Transparency = 1
	ring.Parent = VisualsFolder
	pinIndicators[key] = ring
	return ring
end

local function updatePinIndicators()
	for _, player in ipairs(Players:GetPlayers()) do
		local root = getAliveRoot(player)
		local state = playerState[player]
		local ring = ensurePinIndicator(player)
		if root and state and state.IsPinning then
			local teamName = player.Team and player.Team.Name
			local color = teamName and TEAM_COLORS[teamName] or Color3.fromRGB(255, 220, 80)
			ring.Color = color:Lerp(Color3.fromRGB(255, 220, 80), 0.45)
			ring.Transparency = 0.34
			ring.CFrame = CFrame.new(root.Position.X, 0.18, root.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		else
			ring.Transparency = 1
			ring.CFrame = CFrame.new(0, -1000, 0)
		end
	end
end

local function countRealPinning(teamName)
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			local state = playerState[player]
			if state and state.IsPinning and getAliveRoot(player) then
				count += 1
			end
		end
	end
	return count
end

local function countCpuPinning(teamName)
	local count = 0
	local states = cpuPartnerState[teamName]
	if not states then
		return count
	end
	for i = 1, 2 do
		local partner = ghostPartners[teamName] and ghostPartners[teamName][i]
		local state = states[i]
		if partner and partner:GetAttribute("CpuFillActive") == true and state and state.IsPinning then
			count += 1
		end
	end
	return count
end

local function getHumanPinStart(teamName)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			local state = playerState[player]
			if state and state.IsPinning and getAliveRoot(player) then
				return state.LastPinStartTime
			end
		end
	end
	return nil
end

local function getTeamPlayers(teamName)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			table.insert(result, player)
		end
	end
	return result
end

getAliveRoot = function(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function ensureNetAttachment(root)
	local attachment = root:FindFirstChild("TDNetAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "TDNetAttachment"
		attachment.Position = Vector3.new(0, 0, 0)
		attachment.Parent = root
	end
	return attachment
end

local function configureCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if humanoid then
		humanoid.WalkSpeed = Config.WalkSpeed
		pcall(function()
			humanoid.JumpHeight = Config.JumpHeight
		end)
	end
	if root then
		ensureNetAttachment(root)
	end
end

teamCount = function(teamName)
	return #getTeamPlayers(teamName)
end

setLobbyReady = function(player, ready)
	if not playerState[player] then
		return
	end
	if queuedNextMatchPlayers[player] == true then
		lobbyReady[player] = false
		updateCourtSelectBoardStatus()
		broadcastState(Config.LateJoinSpectatorMessage or "NEXT MATCH QUEUE")
		return
	end
	lobbyReady[player] = ready == true
	updateCourtSelectBoardStatus()
	if not matchRunning then
		startMatchIfPossible()
	else
		broadcastState()
	end
end

local function assignTeam(player)
	local redTeam = TeamsService:FindFirstChild("Red")
	local blueTeam = TeamsService:FindFirstChild("Blue")
	if not redTeam or not blueTeam then
		return
	end

	if teamCount("Red") <= teamCount("Blue") then
		player.Team = redTeam
	else
		player.Team = blueTeam
	end
	player.Neutral = false
end

local function assignSpectator(player)
	local spectatorTeam = TeamsService:FindFirstChild(Config.SpectatorTeamName or "Spectators")
	if not spectatorTeam then
		spectatorTeam = Instance.new("Team")
		spectatorTeam.Name = Config.SpectatorTeamName or "Spectators"
		spectatorTeam.AutoAssignable = false
		spectatorTeam.Parent = TeamsService
	end
	spectatorTeam.TeamColor = BrickColor.new(Color3.fromRGB(160, 170, 185))
	player.Team = spectatorTeam
	player.Neutral = true
end

local function queuePlayerForNextMatch(player)
	queuedNextMatchPlayers[player] = true
	lobbyReady[player] = false
	selectedCourtByPlayer[player] = nil
	assignSpectator(player)
	teleportPlayerToLobby(player)
	updateCourtSelectBoardStatus()
	setState("Lobby", Config.LateJoinSpectatorMessage or "NEXT MATCH QUEUE")
end

local function activateQueuedNextMatchPlayers()
	for player in pairs(queuedNextMatchPlayers) do
		if player.Parent == Players then
			queuedNextMatchPlayers[player] = nil
			assignTeam(player)
			lobbyReady[player] = false
			teleportPlayerToLobby(player)
		else
			queuedNextMatchPlayers[player] = nil
		end
	end
	updateCourtSelectBoardStatus()
end

local function teleportToSpawn(player)
	local teamName = player.Team and player.Team.Name or "Red"
	local teamPlayers = getTeamPlayers(teamName)
	local index = 1
	for i, p in ipairs(teamPlayers) do
		if p == player then
			index = math.clamp(i, 1, 2)
			break
		end
	end
	local spawn = SpawnFolder:FindFirstChild(teamName .. "Spawn" .. tostring(index))
	local root = getAliveRoot(player)
	if spawn and root then
		local spawnPosition = spawn.Position + Vector3.new(0, Config.MatchSpawnHeightOffset or 2.5, 0)
		local lookAt = courtPosition(0, spawnPosition.Y, 0)
		root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		root.CFrame = CFrame.lookAt(spawnPosition, lookAt)
	end
end

local function setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local function ensureLeaderstat(player, statName, initialValue)
		local existing = leaderstats:FindFirstChild(statName)
		if existing and existing:IsA("IntValue") then
			return existing
		end
		local stat = Instance.new("IntValue")
		stat.Name = statName
		stat.Value = initialValue or 0
		stat.Parent = leaderstats
		return stat
	end
	local function ensureLeaderTitle(player, statName, initialValue)
		local existing = leaderstats:FindFirstChild(statName)
		if existing and existing:IsA("StringValue") then
			return existing
		end
		local stat = Instance.new("StringValue")
		stat.Name = statName
		stat.Value = initialValue or ""
		stat.Parent = leaderstats
		return stat
	end

	ensureLeaderstat(player, Config.ProgressStatWins or "Wins", 0)
	ensureLeaderstat(player, Config.ProgressStatHares or "HAREs", 0)
	ensureLeaderstat(player, Config.ProgressStatBestRally or "Best Rally", 0)
	ensureLeaderstat(player, Config.ProgressStatTeamSyncs or "Team Syncs", 0)
	ensureLeaderstat(player, Config.ProgressStatDailyBoosts or "Daily Boosts", 0)
	ensureLeaderTitle(player, Config.ProgressStatTitle or "Title", Config.ProgressTitleDefault or "Rally Starter")
end

local function getProgressStat(player, statName)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stat = leaderstats and leaderstats:FindFirstChild(statName)
	if stat and stat:IsA("IntValue") then
		return stat
	end
	return nil
end

local function getProgressTitle(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local title = leaderstats and leaderstats:FindFirstChild(Config.ProgressStatTitle or "Title")
	if title and title:IsA("StringValue") then
		return title
	end
	return nil
end

local function updateProgressTitle(player)
	if Config.ProgressLiteEnabled == false then
		return
	end
	local title = getProgressTitle(player)
	if not title then
		return
	end

	local hares = getProgressStat(player, Config.ProgressStatHares or "HAREs")
	local teamSyncs = getProgressStat(player, Config.ProgressStatTeamSyncs or "Team Syncs")
	local nextTitle = Config.ProgressTitleDefault or "Rally Starter"
	if teamSyncs and teamSyncs.Value >= (Config.ProgressTitleSyncPartnerAt or 3) then
		nextTitle = Config.ProgressTitleSyncPartner or "Sync Partner"
	elseif hares and hares.Value >= (Config.ProgressTitleHareRookieAt or 1) then
		nextTitle = Config.ProgressTitleHareRookie or "HARE Rookie"
	end
	title.Value = nextTitle
end

local function updateDailyBoostProgress(player)
	if Config.DailyBoostEnabled == false or Config.ProgressLiteEnabled == false then
		return
	end
	if dailyBoostClaimed[player] == true then
		return
	end
	local hares = getProgressStat(player, Config.ProgressStatHares or "HAREs")
	local bestRally = getProgressStat(player, Config.ProgressStatBestRally or "Best Rally")
	local boosts = getProgressStat(player, Config.ProgressStatDailyBoosts or "Daily Boosts")
	if not hares or not bestRally or not boosts then
		return
	end
	if hares.Value >= (Config.DailyBoostHareTarget or 1) and bestRally.Value >= (Config.DailyBoostRallyTarget or 4) then
		boosts.Value += 1
		dailyBoostClaimed[player] = true
		MatchStateEvent:FireClient(player, {
			state = currentState,
			redScore = score.Red,
			blueScore = score.Blue,
			message = Config.DailyBoostEarnedMessage or "DAILY BOOST EARNED!",
			title = Config.Title,
			dailyBoostEarned = true,
		})
	end
end

local function getPlayerFiberSkinColor(player)
	if Config.FiberSkinsEnabled == false then
		return Config.FiberSkinDefaultColor or BEAM_COLORS.Normal
	end
	local title = getProgressTitle(player)
	local titleValue = title and title.Value or Config.ProgressTitleDefault
	if titleValue == (Config.ProgressTitleSyncPartner or "Sync Partner") then
		return Config.FiberSkinSyncPartnerColor or Color3.fromRGB(112, 245, 208)
	elseif titleValue == (Config.ProgressTitleHareRookie or "HARE Rookie") then
		return Config.FiberSkinHareRookieColor or Color3.fromRGB(255, 218, 92)
	end
	return Config.FiberSkinDefaultColor or BEAM_COLORS.Normal
end

local function getTeamFiberSkinColor(teamName)
	local players = getTeamPlayers(teamName)
	if #players <= 0 then
		return Config.FiberSkinDefaultColor or BEAM_COLORS.Normal
	end

	local mixed = Color3.new(0, 0, 0)
	for _, player in ipairs(players) do
		local color = getPlayerFiberSkinColor(player)
		mixed = Color3.new(mixed.R + color.R, mixed.G + color.G, mixed.B + color.B)
	end
	return Color3.new(mixed.R / #players, mixed.G / #players, mixed.B / #players)
end

local function applyFiberSkinColor(baseColor, teamName, tensionState, realPinCount)
	if Config.FiberSkinsEnabled == false then
		return baseColor
	end
	if tensionState == "Slack" or tensionState == "OverTension" or tensionState == "Broken" then
		return baseColor
	end
	if realPinCount == 1 then
		return Config.FiberSkinOnePinColor or baseColor
	end
	local skinColor = getTeamFiberSkinColor(teamName)
	return baseColor:Lerp(skinColor, Config.FiberSkinBlend or 0.36)
end

local function recordBestRallyForMatchPlayers(rallyCount)
	if Config.ProgressLiteEnabled == false or rallyCount <= 0 then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local bestRally = getProgressStat(player, Config.ProgressStatBestRally or "Best Rally")
		if bestRally then
			bestRally.Value = math.max(bestRally.Value, rallyCount)
		end
		updateProgressTitle(player)
		updateDailyBoostProgress(player)
	end
end

local function recordTeamSync(teamName, fxType)
	if Config.ProgressLiteEnabled == false then
		return
	end
	if fxType ~= "Hare" then
		return
	end
	for _, player in ipairs(getTeamPlayers(teamName)) do
		local hares = getProgressStat(player, Config.ProgressStatHares or "HAREs")
		local teamSyncs = getProgressStat(player, Config.ProgressStatTeamSyncs or "Team Syncs")
		if hares then
			hares.Value += 1
		end
		if teamSyncs then
			teamSyncs.Value += 1
		end
		updateProgressTitle(player)
		updateDailyBoostProgress(player)
	end
end

local function recordWinForTeam(teamName)
	if Config.ProgressLiteEnabled == false then
		return
	end
	for _, player in ipairs(getTeamPlayers(teamName)) do
		local wins = getProgressStat(player, Config.ProgressStatWins or "Wins")
		if wins then
			wins.Value += 1
		end
		updateProgressTitle(player)
	end
end

local function onPlayerAdded(player)
	setupLeaderstats(player)
	markPlayerActivity(player)
	Analytics.recordForPlayer(player, "LobbyEntered")
	Monetization.refreshOwnership(player)
	playerState[player] = {
		IsPinning = false,
		LastPinStartTime = -math.huge,
		FirstHareCelebrated = false,
	}
	lobbyReady[player] = false
	if matchRunning and Config.LateJoinSpectatorEnabled ~= false then
		queuePlayerForNextMatch(player)
	else
		assignTeam(player)
	end
	updateCourtSelectBoardStatus()

	player.CharacterAdded:Connect(function(character)
		configureCharacter(player, character)
		task.wait(0.1)
		if queuedNextMatchPlayers[player] == true then
			teleportPlayerToLobby(player)
		elseif matchRunning then
			teleportToSpawn(player)
		else
			teleportPlayerToLobby(player)
		end
	end)

	if player.Character then
		configureCharacter(player, player.Character)
		task.wait(0.1)
		if queuedNextMatchPlayers[player] == true then
			teleportPlayerToLobby(player)
		elseif matchRunning then
			teleportToSpawn(player)
		else
			teleportPlayerToLobby(player)
		end
	end

	if queuedNextMatchPlayers[player] == true then
		broadcastState(Config.LateJoinSpectatorMessage or "NEXT MATCH QUEUE")
	else
		broadcastState("Welcome to PINTO HARE!")
	end
end

local function onPlayerRemoving(player)
	playerState[player] = nil
	Analytics.playerFlags[player] = nil
	lobbyReady[player] = nil
	selectedCourtByPlayer[player] = nil
	queuedNextMatchPlayers[player] = nil
	lastPlayerActivityAt[player] = nil
	monetizationOwnership[player] = nil
	dailyBoostClaimed[player] = nil
	updateCourtSelectBoardStatus()
end

local function makeBeam(teamName)
	local beam = Instance.new("Beam")
	beam.Name = teamName .. "TensionBeam"
	beam.FaceCamera = true
	beam.Width0 = Config.BeamWidth
	beam.Width1 = Config.BeamWidth
	beam.TextureSpeed = Config.BeamTextureSpeed
	beam.LightEmission = 0.55
	beam.Transparency = NumberSequence.new(0.15)
	beam.Color = ColorSequence.new(BEAM_COLORS.Normal)
	beam.Parent = VisualsFolder
	return beam
end

local function getNetEndpoints(teamName)
	local endpoints = {}
	local players = getTeamPlayers(teamName)

	for _, player in ipairs(players) do
		local root = getAliveRoot(player)
		if root then
			local attachment = ensureNetAttachment(root)
			table.insert(endpoints, {
				kind = "player",
				player = player,
				part = root,
				attachment = attachment,
				position = attachment.WorldPosition,
			})
		end
	end

	if Config.AllowGhostPartners then
		local ghosts = ghostPartners[teamName]
		local ghostIndex = 1
		while #endpoints < 2 and ghosts and ghosts[ghostIndex] do
			local ghost = ghosts[ghostIndex]
			local attachment = ghost:FindFirstChild("TDNetAttachment")
			if attachment then
				table.insert(endpoints, {
					kind = "ghost",
					part = ghost,
					attachment = attachment,
					position = attachment.WorldPosition,
				})
			end
			ghostIndex += 1
		end
	end

	if #endpoints < 2 then
		return nil, nil
	end
	return endpoints[1], endpoints[2]
end

local function getTensionState(a, b)
	local d = MathUtil.xzDistance(a.position, b.position)
	if d >= Config.BrokenDistance then
		return "Broken", d
	elseif d < Config.SlackDistance then
		return "Slack", d
	elseif d < Config.GoodDistanceMax then
		return "Normal", d
	else
		return "OverTension", d
	end
end

local function setCpuPartnerActive(part, active)
	part:SetAttribute("CpuFillActive", active)
	local label = part:FindFirstChild("TD_CPU_Label")
	if label and label:IsA("BillboardGui") then
		label.Enabled = active and Config.CpuFillEnabled == true
	end
	local outline = part:FindFirstChild("TD_CPU_Outline")
	if outline and outline:IsA("SelectionBox") then
		outline.Visible = active and Config.CpuFillEnabled == true
	end
	local glow = part:FindFirstChild("TD_CPU_Glow")
	if glow and glow:IsA("PointLight") then
		glow.Enabled = active and Config.CpuFillEnabled == true
	end
	local trail = part:FindFirstChild("TD_CPU_Trail")
	if trail and trail:IsA("Trail") then
		trail.Enabled = active and Config.CpuFillEnabled == true
	end
	if active then
		if Config.CpuFillEnabled then
			part.Transparency = (Config.CpuFillPartnerVisible == false) and 1 or 0.18
		else
			part.Transparency = (Config.GhostPartnerVisible == true) and 0.55 or (Config.GhostPartTransparency or 1)
		end
	else
		part.Transparency = 1
		part:SetAttribute("CpuPinning", false)
	end
end

local function teamZClamp(teamName, z)
	local total = activeHalfDepth() - 3
	if teamName == "Red" then
		return math.clamp(z, activeCourtOrigin.Z + 3, activeCourtOrigin.Z + total)
	end
	return math.clamp(z, activeCourtOrigin.Z - total, activeCourtOrigin.Z - 3)
end

local function moveCpuPartner(part, target, dt)
	local delta = target - part.Position
	local distance = delta.Magnitude
	if distance <= 0.05 then
		part.Position = target
		return
	end
	local step = (Config.CpuFillMoveSpeed or 18) * math.max(dt, 1 / 60)
	part.Position = part.Position + delta.Unit * math.min(step, distance)
end

local function cpuTargetWithError(target)
	local errorAmount = Config.CpuFillAimError or 0
	if errorAmount <= 0 then
		return target
	end
	local xSteps = math.max(1, math.floor(errorAmount * 10))
	local zSteps = math.max(1, math.floor(errorAmount * 6))
	return Vector3.new(
		math.clamp(target.X + math.random(-xSteps, xSteps) / 10, activeCourtOrigin.X - halfWidth() + 3, activeCourtOrigin.X + halfWidth() - 3),
		target.Y,
		teamZClamp(target.Z >= activeCourtOrigin.Z and "Red" or "Blue", target.Z + math.random(-zSteps, zSteps) / 10)
	)
end

local function updateCpuTargetState(teamName, index, target)
	local state = cpuPartnerState[teamName] and cpuPartnerState[teamName][index]
	if not state then
		return target
	end
	local now = os.clock()
	if now >= (state.NextTargetUpdateAt or 0) then
		state.NextTargetUpdateAt = now + (Config.CpuFillReactionDelay or 0.22)
		state.TargetPosition = cpuTargetWithError(target)
	end
	return state.TargetPosition or target
end

local function updateCpuFillPartners(dt)
	if not Config.AllowGhostPartners then
		return
	end

	for _, teamName in ipairs({ "Red", "Blue" }) do
		local side = MathUtil.teamSideSign(teamName)
		local players = getTeamPlayers(teamName)
		local realRoots = {}
		for _, player in ipairs(players) do
			local root = getAliveRoot(player)
			if root then
				table.insert(realRoots, root)
			end
		end

		local ghosts = ghostPartners[teamName]
		local trackX = math.clamp(ball.position.X, activeCourtOrigin.X - halfWidth() + 6, activeCourtOrigin.X + halfWidth() - 6)
		local baseZ = activeCourtOrigin.Z + side * (Config.CpuFillCourtZ or 18)
		if ball.active then
			baseZ = teamZClamp(teamName, ball.position.Z + side * (Config.CpuFillBallTrackZOffset or 5))
		end
		local span = Config.CpuFillNetSpan or 14

		if #realRoots == 0 then
			local targets = {
				Vector3.new(math.clamp(trackX - span / 2, activeCourtOrigin.X - halfWidth() + 3, activeCourtOrigin.X + halfWidth() - 3), Config.NetVisualHeight, baseZ),
				Vector3.new(math.clamp(trackX + span / 2, activeCourtOrigin.X - halfWidth() + 3, activeCourtOrigin.X + halfWidth() - 3), Config.NetVisualHeight, baseZ),
			}
			for i = 1, 2 do
				if ghosts[i] then
					setCpuPartnerActive(ghosts[i], true)
					if Config.CpuFillEnabled then
						moveCpuPartner(ghosts[i], updateCpuTargetState(teamName, i, targets[i]), dt)
					else
						ghosts[i].Position = targets[i]
					end
				end
			end
		elseif #realRoots == 1 then
			local root = realRoots[1]
			local offsetX = (root.Position.X < trackX) and span or -span
			local target = Vector3.new(
				math.clamp(root.Position.X + offsetX, activeCourtOrigin.X - halfWidth() + 3, activeCourtOrigin.X + halfWidth() - 3),
				Config.NetVisualHeight,
				teamZClamp(teamName, root.Position.Z)
			)
			if ghosts[1] then
				setCpuPartnerActive(ghosts[1], true)
				if Config.CpuFillEnabled then
					moveCpuPartner(ghosts[1], updateCpuTargetState(teamName, 1, target), dt)
				else
					ghosts[1].Position = target
				end
			end
			if ghosts[2] then
				setCpuPartnerActive(ghosts[2], false)
				ghosts[2].Position = Vector3.new(-1000, -1000, -1000)
			end
		else
			-- Hide ghosts below the floor when the real pair exists.
			for i = 1, 2 do
				if ghosts[i] then
					setCpuPartnerActive(ghosts[i], false)
					ghosts[i].Position = Vector3.new(-1000, -1000, -1000)
				end
			end
		end
	end
end

local function updateTeamBeam(teamName)
	local a, b = getNetEndpoints(teamName)
	local beam = teamBeams[teamName]
	if not beam then
		beam = makeBeam(teamName)
		teamBeams[teamName] = beam
	end

	if not a or not b then
		beam.Enabled = false
		return
	end

	beam.Enabled = true
	beam.Attachment0 = a.attachment
	beam.Attachment1 = b.attachment

	local tensionState = getTensionState(a, b)
	local realPinCount = countRealPinning(teamName) + countCpuPinning(teamName)
	local color = BEAM_COLORS[tensionState] or BEAM_COLORS.Normal
	local width = Config.BeamWidth
	local transparency = 0.12
	local curve = Config.BeamCurveNormal or 0

	if tensionState == "Slack" then
		width = Config.BeamWidthSlack or (Config.BeamWidth - 0.55)
		transparency = Config.BeamSlackTransparency or 0.32
		curve = Config.BeamCurveSlack or 2.8
	elseif tensionState == "OverTension" then
		width = Config.BeamWidthOverTension or (Config.BeamWidth - 0.25)
		transparency = 0.08
		curve = Config.BeamCurveOverTension or -1.1
	elseif realPinCount >= 2 and tensionState ~= "Broken" then
		color = BEAM_COLORS.Hare
		width = Config.BeamWidth + (Config.BeamWidthHareBonus or 0.82)
		transparency = Config.BeamHareTransparency or 0
		curve = Config.BeamCurveHare or 0
	elseif realPinCount == 1 and tensionState ~= "Broken" then
		color = Color3.fromRGB(255, 170, 90)
		width = Config.BeamWidth + 0.25
		transparency = 0.06
	elseif tensionState == "Broken" then
		width = 0.25
		transparency = 0.65
		curve = Config.BeamCurveSlack or 2.8
	end
	color = applyFiberSkinColor(color, teamName, tensionState, realPinCount)

	beam.CurveSize0 = curve
	beam.CurveSize1 = -curve
	beam.Color = ColorSequence.new(color)
	beam.Width0 = width
	beam.Width1 = width
	beam.Transparency = NumberSequence.new(transparency)
end

local function getTeamPinInfo(teamName)
	local pinCount = 0
	local minStart = math.huge
	local maxStart = -math.huge
	local realCount = 0
	local realPinning = false
	local realPinStart = -math.huge

	for _, player in ipairs(getTeamPlayers(teamName)) do
		local root = getAliveRoot(player)
		if root then
			realCount += 1
			local state = playerState[player]
			if state and state.IsPinning then
				pinCount += 1
				realPinning = true
				realPinStart = state.LastPinStartTime
				minStart = math.min(minStart, state.LastPinStartTime)
				maxStart = math.max(maxStart, state.LastPinStartTime)
			end
		end
	end

	if Config.CpuFillEnabled then
		local states = cpuPartnerState[teamName]
		for i = 1, 2 do
			local partner = ghostPartners[teamName] and ghostPartners[teamName][i]
			local state = states and states[i]
			if partner and partner:GetAttribute("CpuFillActive") == true and state and state.IsPinning then
				pinCount += 1
				minStart = math.min(minStart, state.LastPinStartTime)
				maxStart = math.max(maxStart, state.LastPinStartTime)
			end
		end
	end

	if Config.AllowGhostPartners and Config.GhostMirrorsPinning and realCount == 1 and realPinning then
		-- Solo/2-player test helper: the ghost partner copies your pin timing.
		pinCount = 2
		minStart = math.min(minStart, realPinStart)
		maxStart = math.max(maxStart, realPinStart)
	end

	if Config.AllowGhostPartners and Config.SoloGhostsMirrorPinning and realCount == 0 and #Players:GetPlayers() == 1 then
		-- Solo party test helper: empty-side ghosts can still create HARE moments.
		for _, player in ipairs(Players:GetPlayers()) do
			local state = playerState[player]
			if state and state.IsPinning and getAliveRoot(player) then
				pinCount = 2
				minStart = state.LastPinStartTime
				maxStart = state.LastPinStartTime
				break
			end
		end
	end

	if pinCount == 0 then
		minStart = -math.huge
		maxStart = -math.huge
	end

	return {
		pinCount = pinCount,
		minStart = minStart,
		maxStart = maxStart,
	}
end

getNetGuidanceForTeam = function(teamName)
	local a, b = getNetEndpoints(teamName)
	if not a or not b then
		return {
			state = "Missing",
			text = Config.NetGuideMakeText or "MAKE A NET",
			distance = 0,
			pinCount = 0,
		}
	end

	local tensionState, distance = getTensionState(a, b)
	local pinInfo = getTeamPinInfo(teamName)
	local text = Config.NetGuideGoodText or "GOOD NET"
	if tensionState == "Slack" then
		text = Config.NetGuideTooCloseText or "MOVE APART"
	elseif tensionState == "OverTension" or tensionState == "Broken" then
		text = Config.NetGuideTooFarText or "TOO FAR"
	elseif pinInfo.pinCount > 0 then
		text = Config.NetGuidePinText or "HOLD PIN"
	end
	if pinInfo.pinCount >= 2 and tensionState == "Normal" then
		text = Config.NetGuideHareText or "HARE READY!"
	end

	return {
		state = tensionState,
		text = text,
		distance = math.floor(distance * 10) / 10,
		pinCount = pinInfo.pinCount,
	}
end

local function clampPlayersToCourt()
	if not Config.ClampPlayersToCourt then
		return
	end
	if not matchRunning or currentState == "Lobby" or currentState == "WaitingForPlayers" then
		return
	end

	local baseX = activeCourtOrigin.X
	local xMin = baseX - halfWidth() + 1.5
	local xMax = baseX + halfWidth() - 1.5
	local baseZ = activeCourtOrigin.Z
	local zTotal = activeHalfDepth() - 1.5

	for _, player in ipairs(Players:GetPlayers()) do
		local root = getAliveRoot(player)
		local teamName = player.Team and player.Team.Name
		if root and (teamName == "Red" or teamName == "Blue") then
			local pos = root.Position
			local x = math.clamp(pos.X, xMin, xMax)
			local z
			if teamName == "Red" then
				z = math.clamp(pos.Z, baseZ + 1.5, baseZ + zTotal)
			else
				z = math.clamp(pos.Z, baseZ - zTotal, baseZ - 1.5)
			end
			if math.abs(x - pos.X) > 0.05 or math.abs(z - pos.Z) > 0.05 then
				local newPos = Vector3.new(x, pos.Y, z)
				root.CFrame = CFrame.new(newPos, newPos + root.CFrame.LookVector)
			end
		end
	end
end

local function resetPlayersToSpawns()
	for _, player in ipairs(Players:GetPlayers()) do
		teleportToSpawn(player)
		local state = playerState[player]
		if state then
			state.IsPinning = false
			state.LastPinStartTime = -math.huge
		end
	end
end

local fireHitFx
local setBallVisualForFx

local function getServeChargeForTeam(teamName)
	local charge = {
		kind = "NormalServe",
		message = string.upper(teamName) .. " SERVES",
		fxType = "Normal",
		speed = Config.BallServeSpeed,
		verticalVelocity = Config.ServeVerticalVelocity or 5.2,
		lateralMax = Config.ServeLateralMax or 4.5,
	}

	if Config.ServeChargeEnabled == false then
		return charge
	end

	local a, b = getNetEndpoints(teamName)
	if not a or not b then
		return charge
	end

	local tensionState = getTensionState(a, b)
	local pinInfo = getTeamPinInfo(teamName)
	local pinDelta = pinInfo.maxStart - pinInfo.minStart

	if tensionState == "Slack" then
		charge.kind = "SlackServe"
		charge.message = Config.ServeSlackMessage or "SAFE FLOAT SERVE!"
		charge.fxType = "Slack"
		charge.speed = Config.ServeSlackSpeed or 34
		charge.verticalVelocity = Config.ServeSlackVerticalVelocity or 7.4
		charge.lateralMax = Config.ServeSlackLateralMax or 2.4
	elseif tensionState == "OverTension" or tensionState == "Broken" then
		charge.kind = "OverTensionServe"
		charge.message = Config.ServeOverTensionMessage or "WILD SERVE!"
		charge.fxType = "OverTension"
		charge.speed = Config.ServeOverTensionSpeed or 44
		charge.verticalVelocity = Config.ServeOverTensionVerticalVelocity or 3.8
		charge.lateralMax = Config.ServeOverTensionLateralMax or 8.4
	elseif pinInfo.pinCount >= 2 then
		if pinDelta <= (Config.ServeHarePinDelta or 0.38) then
			charge.kind = "HareServe"
			charge.message = Config.ServeHareMessage or "HARE SERVE!"
			charge.fxType = "Hare"
			charge.speed = Config.ServeHareSpeed or 47
			charge.verticalVelocity = Config.ServeHareVerticalVelocity or 3.7
			charge.lateralMax = Config.ServeHareLateralMax or 2.0
		else
			charge.kind = "ChargedServe"
			charge.message = Config.ServeChargedMessage or "SYNC SERVE!"
			charge.fxType = "Normal"
			charge.speed = Config.ServeChargedSpeed or 43
			charge.verticalVelocity = Config.ServeChargedVerticalVelocity or 4.6
			charge.lateralMax = Config.ServeChargedLateralMax or 3.2
		end
	elseif pinInfo.pinCount == 1 then
		charge.kind = "OnePinServe"
		charge.message = Config.ServeOnePinMessage or "SLICE SERVE!"
		charge.fxType = "OnePin"
		charge.speed = Config.ServeOnePinSpeed or 42
		charge.verticalVelocity = Config.ServeOnePinVerticalVelocity or 4.8
		charge.lateralMax = Config.ServeOnePinLateralMax or 7.2
	end

	return charge
end

local function serveBall(servingTeam)
	rallyHitCount = 0
	local side = MathUtil.teamSideSign(servingTeam)
	local part = ensureBallPart()
	local serveCharge = getServeChargeForTeam(servingTeam)

	-- v0.5.3: Serve uses its own speed/arc.
	-- Return balance lowered PIN shots in v0.5.2, but the opening serve also became too short.
	-- Keep serves friendly, but make them land around the opponent mid-court instead of the front edge.
	local startZ = activeCourtOrigin.Z + side * (Config.ServeStartZ or 7.5)
	local lateralMax = serveCharge.lateralMax
	local serveY = serveCharge.verticalVelocity
	ball.position = Vector3.new(activeCourtOrigin.X, Config.ServeHeight, startZ)
	ball.velocity = Vector3.new(math.random(-lateralMax * 10, lateralMax * 10) / 10, serveY, -side * serveCharge.speed)
	ball.lastTouchedTeam = servingTeam
	ball.active = true
	ball.pausedUntil = 0
	local trail = part:FindFirstChild("BallTrail")
	if trail and trail:IsA("Trail") then
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 245, 180))
	end
	part.Color = Color3.fromRGB(255, 245, 180)
	setBallVisualHidden(false)
	setServeBallLabelVisible(true, servingTeam)
	if setBallVisualForFx then
		setBallVisualForFx(serveCharge.fxType)
	end
	setBallVisualCFrame(CFrame.new(ball.position))
	if fireHitFx and serveCharge.fxType ~= "Normal" then
		fireHitFx(serveCharge.fxType, ball.position, servingTeam)
	end
	return serveCharge
end

local function hideBall()
	ball.active = false
	setBallVisualHidden(true)
	setBallVisualCFrame(CFrame.new(0, -100, 0))
	hideLandingTargetMarker()
end

local spawnShockwave

local function awardPoint(scoringTeam, reason, losingTeam)
	if not roundActive then
		return
	end
	score[scoringTeam] += 1
	local rallyCountAtPoint = rallyHitCount
	recordMatchRallyResult(rallyCountAtPoint)
	recordBestRallyForMatchPlayers(rallyCountAtPoint)
	hareCombo.Red = 0
	hareCombo.Blue = 0
	lastPointLoser = losingTeam or MathUtil.opponent(scoringTeam)
	roundActive = false

	if ball.part then
		spawnShockwave(ball.position, TEAM_COLORS[scoringTeam]:Lerp(Color3.fromRGB(255, 255, 255), 0.2), Config.PointBurstSize, Config.PointBurstDuration, "TD_PointBurst")
	end
	hideBall()

	local rallyText = ""
	if rallyCountAtPoint >= Config.ShowRallyOnPointAt then
		rallyText = "  RALLY x" .. tostring(rallyCountAtPoint)
	end
	local text = string.format("%s +1  %s%s", string.upper(scoringTeam), reason or "", rallyText)
	rallyHitCount = 0
	setState("PointScored", text)
end

isBallOutsideArena = function(pos)
	return math.abs(pos.X - activeCourtOrigin.X) > halfWidth() or math.abs(pos.Z - activeCourtOrigin.Z) > activeHalfDepth()
end

local function processGroundOrOut()
	local pos = ball.position

	if isBallOutsideArena(pos) then
		local losingTeam = ball.lastTouchedTeam or ((pos.Z >= 0) and "Red" or "Blue")
		awardPoint(MathUtil.opponent(losingTeam), Config.ScoreReasonOutText or "OUT!", losingTeam)
		return true
	end

	if pos.Y <= Config.BallRadius then
		if pos.Z >= activeCourtOrigin.Z then
			awardPoint("Blue", Config.ScoreReasonDropText or "DROP!", "Red")
		else
			awardPoint("Red", Config.ScoreReasonDropText or "DROP!", "Blue")
		end
		return true
	end

	return false
end

local function getStoredBaseColor(part, fallback)
	local r = part:GetAttribute("BaseColorR")
	local g = part:GetAttribute("BaseColorG")
	local b = part:GetAttribute("BaseColorB")
	if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
		return Color3.new(r, g, b)
	end
	return fallback
end

local function pulseCrowd(teamName)
	if not Config.CourtJuiceEnabled then
		return
	end
	local teamColor = teamName == "Red" and TEAM_COLORS.Red or TEAM_COLORS.Blue
	local pulseColor = teamColor:Lerp(BEAM_COLORS.Hare, 0.52)
	local dots = {}
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "CrowdDot" then
			table.insert(dots, child)
		end
	end
	table.sort(dots, function(a, b)
		return (a:GetAttribute("CrowdOrder") or 0) < (b:GetAttribute("CrowdOrder") or 0)
	end)
	for index, dot in ipairs(dots) do
		task.delay((index - 1) * (Config.CrowdWaveDelayPerDot or 0.028), function()
			if not dot or not dot.Parent then
				return
			end
			local baseColor = getStoredBaseColor(dot, dot.Color)
			dot.Color = pulseColor
			dot.Size = Vector3.new(1.45, 1.45, 1.45)
			dot.Transparency = 0.02
			TweenService:Create(dot, TweenInfo.new(Config.CrowdWaveDuration or 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Color = baseColor,
				Transparency = 0.22,
				Size = Vector3.new(1.15, 1.15, 1.15),
			}):Play()
		end)
	end
end

local function pulseArena(teamName)
	if not Config.CourtJuiceEnabled then
		return
	end
	pulseCrowd(teamName)
	local pulseColor = teamName == "Red" and TEAM_COLORS.Red or TEAM_COLORS.Blue
	pulseColor = pulseColor:Lerp(BEAM_COLORS.Hare, 0.45)
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 11) == "JuiceBorder" then
			local baseColor = getStoredBaseColor(child, Color3.fromRGB(130, 185, 255))
			child.Color = pulseColor
			child.Transparency = 0
			TweenService:Create(child, TweenInfo.new(Config.ArenaGlowPulseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Color = baseColor,
				Transparency = 0.08,
			}):Play()
		end
	end
end

spawnShockwave = function(position, color, size, duration, name)
	local wave = Instance.new("Part")
	wave.Name = name or "TD_Shockwave"
	wave.Shape = Enum.PartType.Cylinder
	wave.Anchored = true
	wave.CanCollide = false
	wave.CanQuery = false
	wave.CanTouch = false
	wave.Material = Enum.Material.Neon
	wave.Color = color
	wave.Transparency = 0.24
	wave.Size = Vector3.new(0.2, 0.08, 0.2)
	wave.CFrame = CFrame.new(position.X, 0.35, position.Z)
	wave.Parent = VisualsFolder

	TweenService:Create(wave, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(size, 0.08, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(wave, duration + 0.1)
end

local function spawnHareSparkColumn(position)
	local duration = Config.HareSparkColumnDuration or 0.34
	local height = Config.HareSparkColumnHeight or 18
	local width = Config.HareSparkColumnWidth or 1.4
	local spark = Instance.new("Part")
	spark.Name = "TD_HareSparkColumn"
	spark.Shape = Enum.PartType.Cylinder
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.CanTouch = false
	spark.CastShadow = false
	spark.Material = Enum.Material.Neon
	spark.Color = Color3.fromRGB(255, 240, 120)
	spark.Transparency = 0.18
	spark.Size = Vector3.new(height, width, width)
	spark.CFrame = CFrame.new(position.X, height / 2, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	spark.Parent = VisualsFolder

	TweenService:Create(spark, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(height * 1.10, width * 2.2, width * 2.2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(spark, duration + 0.1)
end

fireHitFx = function(fxType, position, teamName)
	local combo = hareCombo[teamName] or 0
	if fxType ~= "Hare" or Config.FirstHareCelebrationEnabled == false then
		HitFxEvent:FireAllClients(fxType, position, teamName, rallyHitCount, combo, false)
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local state = playerState[player]
		local isFirstHare = state ~= nil and player.Team ~= nil and player.Team.Name == teamName and state.FirstHareCelebrated ~= true
		if isFirstHare then
			state.FirstHareCelebrated = true
		end
		HitFxEvent:FireClient(player, fxType, position, teamName, rallyHitCount, combo, isFirstHare)
	end
end

setBallVisualForFx = function(fxType)
	local part = ball.part
	if not part then
		return
	end
	local color = Color3.fromRGB(255, 245, 180)
	if fxType == "Hare" then
		color = Color3.fromRGB(255, 220, 80)
	elseif fxType == "OnePin" then
		color = Color3.fromRGB(255, 160, 95)
	elseif fxType == "Slack" then
		color = Color3.fromRGB(95, 190, 255)
	elseif fxType == "OverTension" then
		color = Color3.fromRGB(255, 90, 90)
	end
	part.Color = color
	local light = part:FindFirstChild("MobileReadableGlow")
	if light and light:IsA("PointLight") then
		light.Color = color
		light.Brightness = fxType == "Hare" and (Config.HareGlowBrightness or 4.4) or (Config.BallReadableGlowBrightness or 3.4)
		light.Range = Config.BallReadableGlowRange or 22
	end
	local trail = part:FindFirstChild("BallTrail")
	if trail and trail:IsA("Trail") then
		trail.Color = ColorSequence.new(color)
		trail.Lifetime = fxType == "Hare" and (Config.HareTrailLifetime or 0.56) or (Config.BallTrailLifetime or 0.50)
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
		halo.Transparency = Config.BallReadabilityHaloTransparency or 0.62
	end
end

local function shouldApplyEarlyRallyAssist(fxType)
	return fxType ~= "Hare" and rallyHitCount < (Config.EarlyRallyAssistHits or 0)
end

local function applyEarlyRallyAssist(fxType, lift, power)
	if not shouldApplyEarlyRallyAssist(fxType) then
		return lift, power
	end
	local assistedLift = math.max(lift, Config.EarlyRallyAssistLiftFloor or lift)
	local assistedPower = math.max(Config.BallMinSpeed, power - (Config.EarlyRallyAssistPowerTrim or 0))
	return assistedLift, assistedPower
end

local function processNetHit(teamName)
	if not ball.active then
		return false
	end
	if ball.lastTouchedTeam == teamName then
		return false -- v0.4 keeps one-touch returns for mobile clarity
	end
	if os.clock() - lastTeamHitTime[teamName] < Config.HitCooldown then
		return false
	end

	local side = MathUtil.teamSideSign(teamName)
	if ball.position.Z * side < -1.5 then
		return false
	end
	if ball.position.Y < Config.NetMinHeight or ball.position.Y > Config.NetMaxHeight then
		return false
	end

	local a, b = getNetEndpoints(teamName)
	if not a or not b then
		return false
	end

	local tensionState = getTensionState(a, b)
	if tensionState == "Broken" then
		return false
	end

	local distance, closest, t = MathUtil.distancePointToSegment(ball.position, a.position, b.position)
	if distance > Config.NetHitRadius then
		return false
	end

	local now = os.clock()
	local pinInfo = getTeamPinInfo(teamName)
	local pinCount = pinInfo.pinCount
	local isHare = false
	if pinCount >= 2 and tensionState == "Normal" then
		local pinDelta = pinInfo.maxStart - pinInfo.minStart
		local contactWindow = now - pinInfo.maxStart
		local hareWindow = math.max(Config.HareContactWindow or 0.45, Config.HareHoldWindow or 0)
		if Config.HareRequiresFreshPin ~= false then
			isHare = pinDelta <= Config.HarePinDelta and contactWindow <= hareWindow
		else
			isHare = pinDelta <= Config.HarePinDelta
		end
	end

	local distanceBonus = 0
	if tensionState == "Slack" then
		distanceBonus = Config.PowerBonusSlack or -8
	elseif tensionState == "Normal" then
		distanceBonus = Config.PowerBonusNormal or 2
	elseif tensionState == "OverTension" then
		distanceBonus = Config.PowerBonusOverTension or 6
	end

	local pinBonus = 0
	if pinCount >= 2 then
		pinBonus = Config.PowerBonusBothPin or 7
	elseif pinCount == 1 then
		pinBonus = Config.PowerBonusOnePin or 3
	end

	local hareBonus = isHare and (Config.PowerBonusHare or 6) or 0
	local rallyBonus = math.min(rallyHitCount * Config.RallySpeedBonusPerHit, Config.RallySpeedBonusMax)
	local power = math.clamp(Config.BallBaseSpeed + distanceBonus + pinBonus + hareBonus + rallyBonus, Config.BallMinSpeed, Config.BallMaxSpeed)

	local flatA = Vector3.new(a.position.X, 0, a.position.Z)
	local flatB = Vector3.new(b.position.X, 0, b.position.Z)
	local netDir = MathUtil.safeUnit(flatB - flatA, Vector3.new(1, 0, 0))
	local normalA = Vector3.new(-netDir.Z, 0, netDir.X)
	local normalB = -normalA
	local desiredZSign = (teamName == "Red") and -1 or 1
	local returnDir = (normalA.Z * desiredZSign >= normalB.Z * desiredZSign) and normalA or normalB

	local incomingFlat = MathUtil.safeUnit(Vector3.new(ball.velocity.X, 0, ball.velocity.Z), returnDir)
	local reflectedIncoming = Vector3.new(incomingFlat.X, 0, -incomingFlat.Z)
	local edgeWobble = netDir * ((t - 0.5) * 0.32)
	local horizontal = MathUtil.safeUnit(returnDir * 0.78 + reflectedIncoming * 0.20 + edgeWobble, returnDir)

	local fxType = "Normal"
	local lift = Config.ReturnLiftNormal or Config.ReturnLift

	if tensionState == "Slack" then
		fxType = "Slack"
		lift = Config.ReturnLiftSlack or 0.38
	elseif tensionState == "OverTension" then
		fxType = "OverTension"
		lift = Config.ReturnLiftOverTension or 0.20
		local wobbleSign = (math.random() < 0.5) and -1 or 1
		horizontal = MathUtil.safeUnit(horizontal + netDir * wobbleSign * (Config.OverTensionWobbleScale or 0.42), returnDir)
	elseif pinCount == 1 then
		fxType = "OnePin"
		lift = Config.ReturnLiftOnePin or 0.30
		local spinSign = (math.random() < 0.5) and -1 or 1
		horizontal = MathUtil.safeUnit(horizontal + netDir * spinSign * 0.35, returnDir)
	end

	if isHare then
		fxType = "Hare"
		lift = Config.ReturnLiftHare or 0.22
		if now - lastHareTime[teamName] <= Config.HareComboWindow then
			hareCombo[teamName] += 1
		else
			hareCombo[teamName] = 1
		end
		lastHareTime[teamName] = now
	else
		hareCombo[teamName] = 0
	end

	lift, power = applyEarlyRallyAssist(fxType, lift, power)
	local finalDir = MathUtil.safeUnit(horizontal + Vector3.new(0, lift, 0), returnDir)
	local finalVelocity = finalDir * power

	-- v0.5.2: cap only the forward court direction. This keeps shots lively sideways,
	-- but prevents normal PIN returns from immediately sailing beyond the back line.
	if Config.ForwardSpeedCapEnabled ~= false then
		local forwardCap = Config.ReturnMaxForwardSpeed or 32
		if fxType == "Hare" then
			forwardCap = Config.HareMaxForwardSpeed or forwardCap
		elseif fxType == "Pin" then
			forwardCap = Config.PinMaxForwardSpeed or forwardCap
		elseif fxType == "OnePin" then
			forwardCap = Config.OnePinMaxForwardSpeed or forwardCap
		elseif fxType == "OverTension" then
			forwardCap = Config.OverTensionMaxForwardSpeed or forwardCap
		elseif fxType == "Slack" then
			forwardCap = Config.SlackMaxForwardSpeed or forwardCap
		end
		if shouldApplyEarlyRallyAssist(fxType) then
			forwardCap = math.min(forwardCap, Config.EarlyRallyAssistForwardCap or forwardCap)
		end

		if math.abs(finalVelocity.Z) > forwardCap then
			finalVelocity = Vector3.new(finalVelocity.X, finalVelocity.Y, math.sign(finalVelocity.Z) * forwardCap)
		end
	end

	ball.velocity = finalVelocity
	ball.position = closest + returnDir * (Config.NetHitRadius + 0.45) + Vector3.new(0, 0.3, 0)
	ball.lastTouchedTeam = teamName
	lastTeamHitTime[teamName] = now
	rallyHitCount += 1
	setBallVisualForFx(fxType)
	recordMatchHitResult(fxType)
	if fxType == "Hare" then
		Analytics.recordForTeamPlayers(teamName, "FirstHare")
	end
	recordTeamSync(teamName, fxType)

	if fxType == "Slack" then
		spawnShockwave(closest, BEAM_COLORS.Slack, Config.SlackAbsorbRippleSize or 9, Config.SlackAbsorbRippleDuration or 0.34, "TD_SlackAbsorbRipple")
	end

	if fxType == "Hare" then
		ball.pausedUntil = now + Config.HareFreezeTime
		spawnShockwave(closest, getTeamFiberSkinColor(teamName):Lerp(BEAM_COLORS.Hare, 0.55), Config.HareShockwaveSize, Config.HareShockwaveDuration, "TD_HareShockwave")
		spawnShockwave(closest, Color3.fromRGB(255, 246, 160), Config.HareHardeningRingSize or 16, Config.HareHardeningRingDuration or 0.30, "TD_HareHardeningRing")
		spawnHareSparkColumn(closest)
		pulseArena(teamName)
	end

	if ball.part then
		setBallVisualCFrame(CFrame.new(ball.position))
	end

	fireHitFx(fxType, closest, teamName)
	return true
end

local function updateBall(dt)
	if not ball.active or not roundActive then
		return
	end

	if os.clock() < (ball.pausedUntil or 0) then
		setBallVisualCFrame(CFrame.new(ball.position))
		return
	end

	-- Try hits before moving and after moving to reduce tunneling on faster shots.
	processNetHit("Red")
	processNetHit("Blue")

	ball.velocity += Vector3.new(0, -Config.BallGravity * dt, 0)
	ball.velocity = MathUtil.clampMagnitude(ball.velocity, Config.BallMaxSpeed)
	ball.position += ball.velocity * dt

	processNetHit("Red")
	processNetHit("Blue")

	setBallVisualCFrame(CFrame.new(ball.position))

	processGroundOrOut()
end

local function updateCpuPinning()
	if not Config.CpuFillEnabled then
		for teamName, states in pairs(cpuPartnerState) do
			for i = 1, 2 do
				if states[i] then
					states[i].IsPinning = false
				end
				local partner = ghostPartners[teamName] and ghostPartners[teamName][i]
				if partner then
					partner:SetAttribute("CpuPinning", false)
				end
			end
		end
		return
	end

	local now = os.clock()
	for _, teamName in ipairs({ "Red", "Blue" }) do
		local side = MathUtil.teamSideSign(teamName)
		local humanPinStart = getHumanPinStart(teamName)
		local humanPinning = humanPinStart ~= nil
		local leadTime = Config.CpuFillAutoPinLeadTime or 1.25
		local predictedZ = ball.position.Z + ball.velocity.Z * leadTime
		local ballThreatening = ball.active and roundActive and (
			ball.velocity.Z * side > 0 or predictedZ * side > -4
		)
		local states = cpuPartnerState[teamName]
		for i = 1, 2 do
			local partner = ghostPartners[teamName] and ghostPartners[teamName][i]
			local state = states and states[i]
			if partner and state and partner:GetAttribute("CpuFillActive") == true then
				local nearBall = ball.active and ((partner.Position - ball.position).Magnitude <= (Config.CpuFillReactionDistance or 18))
				if now >= (state.NextPinDecisionAt or 0) then
					state.NextPinDecisionAt = now + (Config.CpuFillPinDecisionInterval or 0.34)
					local shouldPin = (humanPinning or nearBall or ballThreatening) and (math.random() <= (Config.CpuFillAutoPinChance or 0.72))
					if humanPinning then
						shouldPin = true
					end
					if now < (state.NextPinAllowedAt or 0) then
						shouldPin = false
					end
					if shouldPin and not state.IsPinning then
						state.LastPinStartTime = humanPinStart or now
					end
					if not shouldPin and state.IsPinning then
						state.NextPinAllowedAt = now + (Config.CpuFillPinCooldown or 0.72)
					end
					state.IsPinning = shouldPin
				end
				partner:SetAttribute("CpuPinning", state.IsPinning)
				if state.IsPinning then
					partner.Color = TEAM_COLORS[teamName]:Lerp(BEAM_COLORS.Hare, 0.55)
				else
					partner.Color = TEAM_COLORS[teamName]
				end
			elseif state then
				state.IsPinning = false
				if partner then
					partner:SetAttribute("CpuPinning", false)
					partner.Color = TEAM_COLORS[teamName]
				end
			end
		end
	end
end

MatchLoop.updateAfkSafety = function()
	if Config.AfkSafetyEnabled == false then
		return
	end
	local now = os.clock()
	local readyChanged = false
	for _, player in ipairs(Players:GetPlayers()) do
		local lastActivity = lastPlayerActivityAt[player] or now
		local state = playerState[player]
		if lobbyReady[player] == true and now - lastActivity >= (Config.LobbyReadyAfkSeconds or 90) then
			lobbyReady[player] = false
			readyChanged = true
		end
		if state and state.IsPinning and now - (state.LastPinStartTime or now) >= (Config.PinHoldAfkReleaseSeconds or 12) then
			state.IsPinning = false
			state.LastPinStartTime = -math.huge
		end
	end
	if readyChanged then
		updateCourtSelectBoardStatus()
		setState("Lobby", Config.AfkReadyClearedMessage or "READY cleared after inactivity.")
	end
end

MatchLoop.hasEnoughPlayers = function()
	local _, activeCount = getLobbyReadyCount()
	return activeCount >= requiredPlayerCount()
end

MatchLoop.getLobbyGate = function()
	if not MatchLoop.hasEnoughPlayers() then
		return false, "WaitingForPlayers", Config.WaitingMessage .. "  Red " .. tostring(teamCount("Red")) .. "/2 - Blue " .. tostring(teamCount("Blue")) .. "/2"
	end
	if not allLobbyPlayersReady() then
		local readyCount, activeCount = getLobbyReadyCount()
		local neededCount = math.max(requiredPlayerCount(), activeCount)
		return false, "Lobby", string.format("%s  %d/%d", Config.LobbyWaitingReadyMessage or "Ready up!", readyCount, neededCount)
	end
	return true, "Lobby", Config.LobbyAllReadyMessage or "All ready!"
end

MatchLoop.resetLobbyReady = function()
	for _, player in ipairs(Players:GetPlayers()) do
		lobbyReady[player] = false
	end
end

MatchLoop.runReadyUp = function()
	local readyTime = Config.PreMatchReadyTime or 0
	if readyTime <= 0 then
		return
	end
	setState("Ready", Config.MatchReadyMessage or "GET READY")
	task.wait(readyTime)
end

MatchLoop.runCountdown = function()
	setState("Countdown", "3")
	for i = Config.CountdownTime, 1, -1 do
		setState("Countdown", tostring(i))
		task.wait(1)
	end
	setState("Countdown", Config.StartMessage)
	task.wait(0.45)
end

MatchLoop.finishGame = function(winner)
	winningTeam = winner
	Analytics.record("MatchCompleted")
	setState("GameOver", string.upper(winner) .. " WINS!  PLAY AGAIN IN " .. tostring(Config.GameOverDelay))
	recordWinForTeam(winner)

	task.wait(Config.GameOverDelay)
	winningTeam = nil
	setCourtPreviewPadsEnabled(true)
	activateQueuedNextMatchPlayers()
	teleportPlayersToLobby()
	updateCourtSelectBoardStatus()
end

startMatchIfPossible = function()
	if matchRunning then
		return
	end
	local canStart, waitingState, waitingMessage = MatchLoop.getLobbyGate()
	if not canStart then
		setState(waitingState, waitingMessage)
		return
	end

	matchRunning = true
	task.spawn(function()
		while MatchLoop.hasEnoughPlayers() do
			local court = getSelectedMatchCourt()
			activeCourtId = court.Id or activeCourtId
			activeCourtOrigin = Vector3.new(court.X or 0, 0, 0)
			updateCourtSelectBoardStatus()
			setCourtPreviewPadsEnabled(false)
			createCourt(activeCourtOrigin)
			ensureGhostPartners()
			ensureBallPart()
			hideBall()
			score.Red = 0
			score.Blue = 0
			resetMatchStats()
			lastPointLoser = "Blue"
			winningTeam = nil
			resetPlayersToSpawns()
			MatchLoop.runReadyUp()
			MatchLoop.runCountdown()

			while score.Red < Config.ScoreToWin and score.Blue < Config.ScoreToWin and MatchLoop.hasEnoughPlayers() do
				resetPlayersToSpawns()
				local servingTeam = lastPointLoser
				currentServingTeam = servingTeam
				if isFinalHareActive() then
					setState("Serving", Config.FinalHareMessage or "FINAL HARE!")
					task.wait(0.45)
				end
				setState("Serving", formatServeOwnerMessage(servingTeam))
				task.wait(0.45)
				setState("Serving", Config.ServeChargeMessage or string.upper(servingTeam) .. " SERVES")
				task.wait(0.8)
				roundActive = true
				local serveCharge = serveBall(servingTeam)
				setState("Serving", serveCharge.message)
				task.wait(0.28)
				setServeBallLabelVisible(false, servingTeam)
				setState("Rally", "RALLY!")

				repeat
					task.wait(0.05)
				until not roundActive

				task.wait(Config.PointDelay)
			end

			if score.Red >= Config.ScoreToWin then
				MatchLoop.finishGame("Red")
			elseif score.Blue >= Config.ScoreToWin then
				MatchLoop.finishGame("Blue")
			else
				setState("WaitingForPlayers", Config.WaitingMessage .. "  Red " .. tostring(teamCount("Red")) .. "/2 - Blue " .. tostring(teamCount("Blue")) .. "/2")
				hideBall()
				task.wait(1)
			end

			MatchLoop.resetLobbyReady()
			currentServingTeam = nil
			local canRestart, waitingState, waitingMessage = MatchLoop.getLobbyGate()
			if not canRestart then
				setState(waitingState, waitingMessage)
				break
			end
		end

		matchRunning = false
		currentServingTeam = nil
		local _, waitingState, waitingMessage = MatchLoop.getLobbyGate()
		setCourtPreviewPadsEnabled(true)
		updateCourtSelectBoardStatus()
		setState(waitingState, waitingMessage)
	end)
end

PinInputEvent.OnServerEvent:Connect(function(player, isPinning)
	if typeof(isPinning) ~= "boolean" then
		return
	end
	markPlayerActivity(player)
	if isPinning then
		Analytics.recordForPlayer(player, "FirstPin")
	end
	local state = playerState[player]
	if not state then
		return
	end
	state.IsPinning = isPinning
	if isPinning then
		state.LastPinStartTime = os.clock()
	end
end)

LobbyReadyEvent.OnServerEvent:Connect(function(player, ready)
	if typeof(ready) ~= "boolean" then
		return
	end
	markPlayerActivity(player)
	if ready then
		Analytics.recordForPlayer(player, "FirstReady")
	end
	setLobbyReady(player, ready)
end)

MonetizationRequestEvent.OnServerEvent:Connect(function(player, action, productKey)
	if Config.MonetizationLiteEnabled == false then
		return
	end
	if action == "OpenShop" then
		Monetization.openShop(player)
	elseif action == "Purchase" and typeof(productKey) == "string" then
		Monetization.promptPass(player, productKey)
	elseif action == "Refresh" then
		Monetization.refreshOwnership(player)
		Monetization.sendState(player, false, "")
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedPassID, purchaseSuccess)
	if not purchaseSuccess then
		return
	end
	for _, product in ipairs(Config.MonetizationProducts or {}) do
		if purchasedPassID == Monetization.getPassId(product) then
			local ownership = monetizationOwnership[player] or {}
			ownership[product.Key] = true
			monetizationOwnership[player] = ownership
			Monetization.sendState(player, true, Config.MonetizationOwnedLabel or "OWNED")
			return
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	onPlayerAdded(player)
	task.wait(0.5)
	startMatchIfPossible()
end)

Players.PlayerRemoving:Connect(function(player)
	onPlayerRemoving(player)
	task.wait(0.5)
	startMatchIfPossible()
end)

RunService.Heartbeat:Connect(function(dt)
	clampPlayersToCourt()
	updatePinIndicators()
	updateCpuFillPartners(dt)
	updateCpuPinning()
	MatchLoop.updateAfkSafety()
	updateTeamBeam("Red")
	updateTeamBeam("Blue")
	updateBall(dt)
	updateLandingTargetMarker()

	if roundActive and currentState == "Rally" then
		local now = os.clock()
		if now - lastGuidanceBroadcast >= (Config.NetGuidanceBroadcastInterval or 0.18) then
			lastGuidanceBroadcast = now
			broadcastState("")
		end
	end
end)

-- Bootstrap existing players in Studio hot-reload sessions.
ensureTeams()
createCourt(activeCourtOrigin)
createCourtSelectionWorld()
ensureGhostPartners()
ensureBallPart()
hideBall()

setState("WaitingForPlayers", Config.Title)
task.defer(function()
	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		onPlayerAdded(existingPlayer)
	end
	startMatchIfPossible()
end)
