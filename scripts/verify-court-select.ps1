$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$camera = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua")

$checks = @(
	@{
		Name = "config defines five selectable courts"
		Ok = $config.Contains('CourtSelections') -and
			$config.Contains('Id = "Grass"') -and
			$config.Contains('Id = "Rooftop"') -and
			$config.Contains('Id = "School"') -and
			$config.Contains('Id = "Festival"') -and
			$config.Contains('Id = "Space"')
	},
	@{
		Name = "server creates lobby and court folders"
		Ok = $server.Contains('local LobbyFolder') -and
			$server.Contains('local CourtsFolder') -and
			$server.Contains('CourtSelectBoard')
	},
	@{
		Name = "server creates selectable buttons with CourtId attributes"
		Ok = $server.Contains('button:SetAttribute("CourtId", court.Id)') -and
			$server.Contains('ClickDetector') -and
			$server.Contains('MouseClick:Connect')
	},
	@{
		Name = "server makes court selection discoverable on mobile"
		Ok = $server.Contains('local function addProximityPrompt(parent, actionText, objectText)') -and
			$server.Contains('Instance.new("ProximityPrompt")') -and
			$server.Contains('prompt.ActionText = actionText') -and
			$server.Contains('prompt.Triggered:Connect') -and
			$server.Contains('Config.CourtPromptActionText')
	},
	@{
		Name = "server creates per-court spawn points"
		Ok = $server.Contains('CourtSpawn') -and
			($server.Contains('court.Id .. "Court"') -or $server.Contains('tostring(court.Id) .. "Court"')) -and
			$server.Contains('SpawnPoint')
	},
	@{
		Name = "server lets players return from selected court to lobby"
		Ok = $config.Contains('CourtReturnMessage') -and
			$server.Contains('local function returnPlayerToLobby(player)') -and
			$server.Contains('BackToLobbyPad') -and
			$server.Contains('Config.CourtReturnPromptActionText') -and
			$server.Contains('returnPrompt.Triggered:Connect')
	},
	@{
		Name = "server teleports selected player to court spawn"
		Ok = $server.Contains('local function teleportPlayerToCourt(player, courtId)') -and
			$server.Contains('selectedCourtByPlayer[player] = courtId') -and
			$server.Contains('root.CFrame = targetSpawn.CFrame + Vector3.new(0, 3, 0)')
	},
	@{
		Name = "server returns players to lobby after game"
		Ok = $server.Contains('local function teleportPlayersToLobby()') -and
			$server.Contains('teleportPlayersToLobby()')
	},
	@{
		Name = "server uses selected court as active match origin"
		Ok = $server.Contains('local activeCourtOrigin = Vector3.new(0, 0, 0)') -and
			($server.Contains('local function getSelectedMatchCourt()') -or $server.Contains('getSelectedMatchCourt = function()')) -and
			$server.Contains('activeCourtOrigin = Vector3.new(court.X or 0, 0, 0)') -and
			$server.Contains('createCourt(activeCourtOrigin)')
	},
	@{
		Name = "server offsets match physics to active court origin"
		Ok = $server.Contains('local function courtPosition(x, y, z)') -and
			$server.Contains('math.abs(pos.X - activeCourtOrigin.X)') -and
			$server.Contains('Vector3.new(activeCourtOrigin.X') -and
			$server.Contains('baseX = activeCourtOrigin.X')
	},
	@{
		Name = "camera follows selected match court origin"
		Ok = $server.Contains('courtOriginX = activeCourtOrigin.X') -and
			$server.Contains('courtOriginZ = activeCourtOrigin.Z') -and
			$camera.Contains('local currentCourtOriginX = 0') -and
			$camera.Contains('local currentCourtOriginZ = 0') -and
			$camera.Contains('currentCourtOriginX = data.courtOriginX or currentCourtOriginX') -and
			$camera.Contains('currentCourtOriginZ = data.courtOriginZ or currentCourtOriginZ') -and
			$camera.Contains('local focusX = currentCourtOriginX') -and
			$camera.Contains('local focusZ = currentCourtOriginZ') -and
			$camera.Contains('Vector3.new(focusX, cameraHeight, focusZ + cameraBack * side)') -and
			$camera.Contains('Vector3.new(focusX, focusY, focusZ)')
	},
	@{
		Name = "camera frames the lobby before match start"
		Ok = $config.Contains('LobbyCameraFocusPosition') -and
			$config.Contains('LobbyCameraBack') -and
			$camera.Contains('local currentState = "WaitingForPlayers"') -and
			$camera.Contains('local function isLobbyState(state)') -and
			$camera.Contains('Config.LobbyCameraFocusPosition') -and
			$camera.Contains('Config.LobbyCameraBack') -and
			$camera.Contains('if isLobbyState(currentState) then')
	},
	@{
		Name = "server does not clamp lobby players inside court"
		Ok = $server.Contains('if not matchRunning or currentState == "Lobby" or currentState == "WaitingForPlayers" then') -and
			$server.Contains('local function clampPlayersToCourt()')
	},
	@{
		Name = "server keeps match spawn above generated court"
		Ok = $config.Contains('MatchSpawnHeightOffset') -and
			$server.Contains('local spawnPosition = spawn.Position + Vector3.new(0, Config.MatchSpawnHeightOffset or 2.5, 0)') -and
			$server.Contains('root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)') -and
			$server.Contains('root.CFrame = CFrame.lookAt(spawnPosition, lookAt)')
	},
	@{
		Name = "server hides lobby preview pads during match"
		Ok = $config.Contains('MatchPreviewPadHiddenTransparency') -and
			$server.Contains('local function setCourtPreviewPadsEnabled(enabled)') -and
			$server.Contains('previewPad.CanCollide = enabled == true') -and
			$server.Contains('setCourtPreviewPadsEnabled(false)') -and
			$server.Contains('setCourtPreviewPadsEnabled(true)')
	},
	@{
		Name = "server chooses match court by vote majority"
		Ok = $server.Contains('local courtSelectionOrder = {}') -and
			($server.Contains('local function getCourtVoteSummary()') -or $server.Contains('getCourtVoteSummary = function()')) -and
			$server.Contains('voteCounts[courtId] = (voteCounts[courtId] or 0) + 1') -and
			$server.Contains('if votes > winningVotes then')
	},
	@{
		Name = "server broadcasts selected court vote summary"
		Ok = $server.Contains('courtVoteCounts = voteCounts') -and
			$server.Contains('selectedCourtVotes = selectedVotes')
	},
	@{
		Name = "server updates physical court board vote labels"
		Ok = $server.Contains('local courtButtonLabels = {}') -and
			$server.Contains('local function updateCourtSelectBoardStatus()') -and
			$server.Contains('Votes %d') -and
			$server.Contains('PLAYING') -and
			$server.Contains('updateCourtSelectBoardStatus()')
	},
	@{
		Name = "server shows how to choose and start from lobby"
		Ok = $config.Contains('LobbyHelpMessage') -and
			$config.Contains('CourtSelectBoardTitle') -and
			$config.Contains('CourtSelectedMessageFormat') -and
			$server.Contains('HowToStartSign') -and
			$server.Contains('Config.CourtSelectBoardHelp') -and
			$server.Contains('Config.CourtSelectedMessageFormat')
	},
	@{
		Name = "server keeps court billboard labels from covering HUD"
		Ok = $server.Contains('gui.AlwaysOnTop = alwaysOnTop == true') -and
			$server.Contains('gui.MaxDistance = maxDistance or 80') -and
			$server.Contains('Vector2.new(112, 46)') -and
			$server.Contains('false, 36')
	},
	@{
		Name = "server lets READY start with the default selected theme"
		Ok = $config.Contains('LobbyReadySubMessage = "READY starts match. Mode/theme optional."') -and
			$server.Contains('setLobbyReady = function(player, ready)') -and
			$server.Contains('lobbyReady[player] = ready == true') -and
			-not $server.Contains('if ready == true and not playerHasSelectedCourt(player) then')
	},
	@{
		Name = "server blocks selecting busy active court"
		Ok = $server.Contains('local function isCourtAvailable(courtId)') -and
			$server.Contains('if not isCourtAvailable(courtId) then') -and
			$server.Contains('Config.CourtUnavailableMessage') -and
			$server.Contains('courtAvailability = availability')
	}
)

$failed = @($checks | Where-Object { -not $_.Ok })
$checks | ForEach-Object {
	$status = if ($_.Ok) { "PASS" } else { "FAIL" }
	Write-Output ("{0}: {1}" -f $status, $_.Name)
}

if ($failed.Count -gt 0) {
	exit 1
}
