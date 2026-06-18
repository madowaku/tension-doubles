$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")

$checks = @(
	@{
		Name = "config documents progress-lite stat names"
		Ok = $config.Contains('ProgressLiteEnabled = true') -and
			$config.Contains('ProgressStatWins = "Wins"') -and
			$config.Contains('ProgressStatHares = "HAREs"') -and
			$config.Contains('ProgressStatBestRally = "Best Rally"') -and
			$config.Contains('ProgressStatTeamSyncs = "Team Syncs"')
	},
	@{
		Name = "server creates all leaderstats values"
		Ok = $server.Contains('local function ensureLeaderstat(player, statName, initialValue)') -and
			$server.Contains('Config.ProgressStatWins or "Wins"') -and
			$server.Contains('Config.ProgressStatHares or "HAREs"') -and
			$server.Contains('Config.ProgressStatBestRally or "Best Rally"') -and
			$server.Contains('Config.ProgressStatTeamSyncs or "Team Syncs"')
	},
	@{
		Name = "server updates Best Rally when a point ends"
		Ok = $server.Contains('recordBestRallyForMatchPlayers(rallyCountAtPoint)') -and
			$server.Contains('bestRally.Value = math.max(bestRally.Value, rallyCount)')
	},
	@{
		Name = "server awards HAREs and Team Syncs on human team HARE"
		Ok = $server.Contains('recordTeamSync(teamName, fxType)') -and
			$server.Contains('if fxType ~= "Hare" then') -and
			$server.Contains('hares.Value += 1') -and
			$server.Contains('teamSyncs.Value += 1')
	},
	@{
		Name = "server still awards Wins through progress helper"
		Ok = $server.Contains('recordWinForTeam(winner)') -and
			$server.Contains('wins.Value += 1')
	},
	@{
		Name = "docs include progress-lite playtest checks"
		Ok = $readme.Contains('Player Progress Lite') -and
			$readme.Contains('HAREs, Best Rally, and Team Syncs') -and
			$checklist.Contains('leaderstats') -and
			$checklist.Contains('Best Rally')
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
