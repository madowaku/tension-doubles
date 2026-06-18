$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")

$checks = @(
	@{
		Name = "Config defines Practice Wall lobby copy and tuning"
		Ok = $config.Contains('PracticeWallEnabled = true') -and
			$config.Contains('PracticeWallTitle = "PRACTICE WALL"') -and
			$config.Contains('PracticeWallHelp = "Hit PIN!  Try HARE!"') -and
			$config.Contains('PracticeWallPromptActionText = "Practice"') -and
			$config.Contains('PracticeWallCooldownSeconds = 0.75')
	},
	@{
		Name = "Server tracks practice wall state without touching match ball"
		Ok = $server.Contains('local PracticeWall = {}') -and
			$server.Contains('PracticeWall.hitCountByPlayer = {}') -and
			$server.Contains('PracticeWall.lastHitAtByPlayer = {}')
	},
	@{
		Name = "Server creates Practice Wall lobby parts"
		Ok = $server.Contains('"TD_PracticeWall"') -and
			$server.Contains('"TD_PracticeWallPad"') -and
			$server.Contains('"TD_PracticeWallBall"') -and
			$server.Contains('Config.PracticeWallTitle')
	},
	@{
		Name = "Practice Wall can be triggered by touch click or prompt"
		Ok = $server.Contains('PracticeWall.connectPad') -and
			$server.Contains('ClickDetector') -and
			$server.Contains('practicePrompt.Triggered') -and
			$server.Contains('practicePad.Touched')
	},
	@{
		Name = "Practice Wall sends safe local feedback only"
		Ok = $server.Contains('PracticeWall.playForPlayer') -and
			$server.Contains('TweenService:Create(practiceBall') -and
			$server.Contains('HitFxEvent:FireClient(player') -and
			-not $server.Contains('serveBall("Practice")')
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
	throw "Practice Wall verification failed: $($failed -join ', ')"
}

Write-Host "Practice Wall source contract passed."
