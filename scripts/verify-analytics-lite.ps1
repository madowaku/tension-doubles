$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "Config exposes Analytics Lite toggles and event names"
		Ok = $config.Contains('AnalyticsLiteEnabled = true') -and
			$config.Contains('AnalyticsLiteFolderName = "TensionDoublesAnalytics"') -and
			$config.Contains('AnalyticsLitePrintEnabled = false') -and
			$config.Contains('LobbyEntered = "LobbyEntered"') -and
			$config.Contains('PracticeStarted = "PracticeStarted"') -and
			$config.Contains('FirstPin = "FirstPIN"') -and
			$config.Contains('FirstHare = "FirstHARE"') -and
			$config.Contains('MatchCompleted = "MatchCompleted"')
	},
	@{
		Name = "Server creates replicated analytics folder and counters"
		Ok = $server.Contains('local Analytics = {}') -and
			$server.Contains('Analytics.folder = nil') -and
			$server.Contains('Analytics.ensureFolder = function()') -and
			$server.Contains('ReplicatedStorage:FindFirstChild(Config.AnalyticsLiteFolderName or "TensionDoublesAnalytics")') -and
			$server.Contains('Instance.new("IntValue")')
	},
	@{
		Name = "Server records public beta funnel events from existing gameplay events"
		Ok = $server.Contains('Analytics.recordForPlayer(player, "LobbyEntered")') -and
			$server.Contains('Analytics.recordForPlayer(player, "PracticeStarted")') -and
			$server.Contains('Analytics.recordForPlayer(player, "FirstPin")') -and
			$server.Contains('Analytics.recordForTeamPlayers(teamName, "FirstHare")') -and
			$server.Contains('Analytics.record("MatchCompleted")')
	},
	@{
		Name = "Analytics Lite does not add gameplay telemetry or external dependencies"
		Ok = -not $server.Contains('AnalyticsService') -and
			-not $server.Contains('DataStoreService') -and
			-not $server.Contains('HttpService') -and
			-not $server.Contains('PlayerMoved') -and
			-not $server.Contains('HumanoidRootPart.Position')
	},
	@{
		Name = "Public beta checklist includes Analytics Lite Studio inspection"
		Ok = $checklist.Contains('Analytics Lite') -and
			$checklist.Contains('TensionDoublesAnalytics') -and
			$checklist.Contains('LobbyEntered') -and
			$checklist.Contains('FirstPIN') -and
			$checklist.Contains('FirstHARE') -and
			$checklist.Contains('MatchCompleted')
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
	throw "Analytics Lite verification failed: $($failed -join ', ')"
}

Write-Host "Analytics Lite source contract passed."
