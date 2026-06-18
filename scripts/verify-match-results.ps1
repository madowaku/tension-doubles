$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")

$checks = @(
	@{
		Name = "Config defines match result labels"
		Ok = $config.Contains('MatchResultsEnabled = true') -and
			$config.Contains('MatchResultsHaresLabel = "HAREs"') -and
			$config.Contains('MatchResultsBestRallyLabel = "Best Rally"') -and
			$config.Contains('MatchResultsTeamSyncsLabel = "Team Syncs"') -and
			$config.Contains('MatchResultsSlackSavesLabel = "Slack Saves"')
	},
	@{
		Name = "Server tracks per-match result stats"
		Ok = $server.Contains('local matchStats =') -and
			$server.Contains('resetMatchStats()') -and
			$server.Contains('matchStats.Hares') -and
			$server.Contains('matchStats.BestRally') -and
			$server.Contains('matchStats.TeamSyncs') -and
			$server.Contains('matchStats.SlackSaves')
	},
	@{
		Name = "Server updates result stats from existing rally events"
		Ok = $server.Contains('recordMatchRallyResult(rallyCountAtPoint)') -and
			$server.Contains('recordMatchHitResult(fxType)') -and
			$server.Contains('if fxType == "Hare" then') -and
			$server.Contains('elseif fxType == "Slack" then')
	},
	@{
		Name = "Server broadcasts match results to clients"
		Ok = $server.Contains('matchResults = getMatchResultsPayload()') -and
			$server.Contains('winner = winningTeam')
	},
	@{
		Name = "UI formats and shows match results on GameOver"
		Ok = $ui.Contains('local function formatMatchResults') -and
			$ui.Contains('data.matchResults') -and
			$ui.Contains('Config.MatchResultsHaresLabel') -and
			$ui.Contains('Config.MatchResultsSlackSavesLabel') -and
			$ui.Contains('subMessageLabel.Text = formatMatchResults(data.matchResults)')
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
	throw "Match results verification failed: $($failed -join ', ')"
}

Write-Host "Match results source contract passed."
