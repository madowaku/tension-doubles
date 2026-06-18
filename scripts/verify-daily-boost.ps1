$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")

$checks = @(
	@{
		Name = "Config defines Daily Boost copy, targets, and leaderstat"
		Ok = $config.Contains('DailyBoostEnabled = true') -and
			$config.Contains('ProgressStatDailyBoosts = "Daily Boosts"') -and
			$config.Contains('DailyBoostHareTarget = 1') -and
			$config.Contains('DailyBoostRallyTarget = 4') -and
			$config.Contains('DailyBoostBoardTitle = "DAILY BOOST"')
	},
	@{
		Name = "Server creates Daily Boosts leaderstat and one-claim guard"
		Ok = $server.Contains('local dailyBoostClaimed = {}') -and
			$server.Contains('Config.ProgressStatDailyBoosts or "Daily Boosts"') -and
			$server.Contains('local function updateDailyBoostProgress(player)') -and
			$server.Contains('dailyBoostClaimed[player] = true')
	},
	@{
		Name = "Server awards boosts from HARE and Best Rally progress"
		Ok = $server.Contains('Config.DailyBoostHareTarget or 1') -and
			$server.Contains('Config.DailyBoostRallyTarget or 4') -and
			$server.Contains('boosts.Value += 1') -and
			$server.Contains('updateDailyBoostProgress(player)')
	},
	@{
		Name = "Lobby world includes a Daily Boost board"
		Ok = $server.Contains('"DailyBoostBoard"') -and
			$server.Contains('Config.DailyBoostBoardHelp')
	},
	@{
		Name = "UI shows Daily Boost progress and earned feedback"
		Ok = $ui.Contains('local function formatDailyBoostProgress()') -and
			$ui.Contains('data.dailyBoostEarned == true') -and
			$ui.Contains('DailyBoostHudFormat') -and
			$ui.Contains('DailyBoostEarnedSubMessage') -and
			$ui.Contains('formatMatchResults(data.matchResults)')
	},
	@{
		Name = "Docs explain Daily Boost is non-power"
		Ok = $readme.Contains('Daily Boost Loop') -and
			$readme.Contains('non-power and cooperative')
	}
)

$failed = @()
foreach ($check in $checks) {
	if ($check.Ok) {
		Write-Host "[OK] $($check.Name)"
	} else {
		Write-Host "[FAIL] $($check.Name)"
		$failed += $check.Name
	}
}

if ($failed.Count -gt 0) {
	throw "Daily Boost verification failed: $($failed -join ', ')"
}

Write-Host "Daily Boost source contract passed."
