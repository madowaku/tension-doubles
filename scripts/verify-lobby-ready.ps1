$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$input = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")

$checks = @(
	@{
		Name = "server exposes LobbyReadyEvent"
		Ok = $server.Contains('local LobbyReadyEvent = getOrCreateRemote("LobbyReadyEvent")')
	},
	@{
		Name = "server tracks lobby ready players"
		Ok = $server.Contains('local lobbyReady = {}') -and
			($server.Contains('local function setLobbyReady(player, ready)') -or $server.Contains('setLobbyReady = function(player, ready)'))
	},
	@{
		Name = "server blocks match until all active players are ready"
		Ok = $server.Contains('allLobbyPlayersReady()') -and $server.Contains('Config.LobbyWaitingReadyMessage') -and $server.Contains('return false, "Lobby"')
	},
	@{
		Name = "server broadcasts lobby ready counts"
		Ok = $server.Contains('lobbyReadyPlayers = readyCount') -and $server.Contains('lobbyNeededPlayers = neededCount')
	},
	@{
		Name = "input client binds ready action and mobile ready button"
		Ok = $input.Contains('LobbyReadyEvent:FireServer') -and $input.Contains('TensionDoubles_LobbyReady') -and $input.Contains('ReadyButton')
	},
	@{
		Name = "input client exposes ready button beyond touch devices"
		Ok = $input.Contains('local function createReadyButton(gui)') -and
			$input.Contains('createReadyButton(gui)') -and
			$input.Contains('local function createPlayerControls()') -and
			$input.Contains('if UserInputService.TouchEnabled then')
	},
	@{
		Name = "ui client renders Lobby state"
		Ok = $ui.Contains('state == "Lobby"') -and $ui.Contains('lobbyReadyPlayers') -and $ui.Contains('LobbyGuideStepReadyText')
	},
	@{
		Name = "config contains lobby copy and toggle"
		Ok = $config.Contains('LobbyReadyEnabled = true') -and $config.Contains('LobbyWaitingReadyMessage') -and $config.Contains('LobbyReadySubMessage')
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
