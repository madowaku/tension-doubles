$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")

$checks = @(
	@{
		Name = "Config separates mobile net guidance from PIN control"
		Ok = $config.Contains('MobileNetGuideYLandscape = 0.665') -and
			$config.Contains('MobileNetGuideYPortrait = 0.785') -and
			$config.Contains('MobilePinButtonYLandscape = 0.730')
	},
	@{
		Name = "Config defines match-only HUD declutter settings"
		Ok = $config.Contains('AudioMixerHideDuringMatch = true') -and
			$config.Contains('AudioMixerVisibleStates = {') -and
			$config.Contains('Lobby = true') -and
			$config.Contains('WaitingForPlayers = true') -and
			$config.Contains('GameOver = true')
	},
	@{
		Name = "Config defines safer FX and result layout positions"
		Ok = $config.Contains('HareFxY = 0.365') -and
			$config.Contains('HitFxY = 0.500') -and
			$config.Contains('GameOverResultsHeight = 0.120') -and
			$config.Contains('MatchResultsShortBestRallyLabel = "Rally"') -and
			$config.Contains('MatchResultsShortTeamSyncsLabel = "Syncs"')
	},
	@{
		Name = "UI hides mixer panels outside lobby/result states"
		Ok = $ui.Contains('local function setMixerPanelsVisibleForState(state)') -and
			$ui.Contains('Config.AudioMixerVisibleStates') -and
			$ui.Contains('setMixerPanelsVisibleForState(state)')
	},
	@{
		Name = "UI uses safer FX position config"
		Ok = $ui.Contains('Config.HareFxY') -and
			$ui.Contains('Config.HitFxY') -and
			$ui.Contains('label.Position = UDim2.fromScale(x, fxY)')
	},
	@{
		Name = "UI formats game results as compact multiline copy"
		Ok = $ui.Contains('MatchResultsShortBestRallyLabel') -and
			$ui.Contains('MatchResultsShortTeamSyncsLabel') -and
			$ui.Contains('\n') -and
			$ui.Contains('Config.GameOverResultsHeight')
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
	throw "UI polish layout verification failed: $($failed -join ', ')"
}

Write-Host "UI polish layout source contract passed."
