$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "config defines late-join spectator copy"
		Ok = $config.Contains('LateJoinSpectatorEnabled = true') -and
			$config.Contains('SpectatorTeamName = "Spectators"') -and
			$config.Contains('LateJoinSpectatorMessage') -and
			$config.Contains('LateJoinSpectatorSubMessage') -and
			$config.Contains('NextMatchQueuedMessage')
	},
	@{
		Name = "server tracks queued next-match players"
		Ok = $server.Contains('local queuedNextMatchPlayers = {}') -and
			$server.Contains('local function getQueuedNextMatchCount()') -and
			$server.Contains('queuedNextMatchPlayers[player] = true')
	},
	@{
		Name = "server creates and uses a spectator team"
		Ok = $server.Contains('Config.SpectatorTeamName or "Spectators"') -and
			$server.Contains('local function assignSpectator(player)') -and
			$server.Contains('player.Team = spectatorTeam') -and
			$server.Contains('player.Neutral = true')
	},
	@{
		Name = "mid-match joins are queued instead of spawned into active play"
		Ok = $server.Contains('if matchRunning and Config.LateJoinSpectatorEnabled ~= false then') -and
			$server.Contains('queuePlayerForNextMatch(player)') -and
			$server.Contains('teleportPlayerToLobby(player)') -and
			-not $server.Contains('if matchRunning then' + [Environment]::NewLine + "`t`t`tteleportToSpawn(player)")
	},
	@{
		Name = "queued players are activated after the match returns to lobby"
		Ok = $server.Contains('local function activateQueuedNextMatchPlayers()') -and
			$server.Contains('queuedNextMatchPlayers[player] = nil') -and
			$server.Contains('assignTeam(player)') -and
			$server.Contains('activateQueuedNextMatchPlayers()')
	},
	@{
		Name = "server broadcasts queued player count to clients"
		Ok = $server.Contains('queuedNextMatchPlayers = getQueuedNextMatchCount()') -and
			$server.Contains('LateJoinSpectatorMessage')
	},
	@{
		Name = "ui shows next-match queue copy"
		Ok = $ui.Contains('data.queuedNextMatchPlayers') -and
			$ui.Contains('Config.LateJoinSpectatorSubMessage') -and
			$ui.Contains('Next match queue')
	},
	@{
		Name = "v1.0 checklist covers late join session safety"
		Ok = $checklist.Contains('Late Join Safety') -and
			$checklist.Contains('joins during an active rally') -and
			$checklist.Contains('next match')
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
