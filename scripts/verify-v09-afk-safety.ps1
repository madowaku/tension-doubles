$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "config defines bounded AFK safety thresholds"
		Ok = $config.Contains('AfkSafetyEnabled = true') -and
			$config.Contains('LobbyReadyAfkSeconds') -and
			$config.Contains('PinHoldAfkReleaseSeconds') -and
			$config.Contains('AfkReadyClearedMessage')
	},
	@{
		Name = "server tracks player activity through existing remotes"
		Ok = $server.Contains('local lastPlayerActivityAt = {}') -and
			$server.Contains('local function markPlayerActivity(player)') -and
			$server.Contains('markPlayerActivity(player)') -and
			$server.Contains('PinInputEvent.OnServerEvent') -and
			$server.Contains('LobbyReadyEvent.OnServerEvent')
	},
	@{
		Name = "server clears stale lobby ready without kicking players"
		Ok = $server.Contains('MatchLoop.updateAfkSafety = function()') -and
			$server.Contains('if lobbyReady[player] == true and now - lastActivity >= (Config.LobbyReadyAfkSeconds or 90) then') -and
			$server.Contains('lobbyReady[player] = false') -and
			$server.Contains('Config.AfkReadyClearedMessage')
	},
	@{
		Name = "server releases stale PIN holds"
		Ok = $server.Contains('if state and state.IsPinning and now - (state.LastPinStartTime or now) >= (Config.PinHoldAfkReleaseSeconds or 12) then') -and
			$server.Contains('state.IsPinning = false') -and
			$server.Contains('state.LastPinStartTime = -math.huge')
	},
	@{
		Name = "heartbeat runs AFK safety"
		Ok = $server.Contains('MatchLoop.updateAfkSafety()') -and
			$server.Contains('RunService.Heartbeat:Connect')
	},
	@{
		Name = "v1.0 checklist covers AFK safety"
		Ok = $checklist.Contains('AFK Safety') -and
			$checklist.Contains('READY is cleared') -and
			$checklist.Contains('stale PIN hold')
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
