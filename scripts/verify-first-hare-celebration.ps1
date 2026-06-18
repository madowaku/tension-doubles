$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$checklistPath = Join-Path $root "docs/playtests/v07-first-fun-loop-checklist.md"
$checklist = if (Test-Path -LiteralPath $checklistPath) { Get-Content -Raw -LiteralPath $checklistPath } else { "" }

$checks = @(
	@{
		Name = "config defines first HARE celebration copy"
		Ok = $config.Contains('FirstHareCelebrationEnabled = true') -and
			$config.Contains('FirstHareMessage = "FIRST HARE!"') -and
			$config.Contains('FirstHareSubtitle = "YOUR FIRST TEAM SYNC!"')
	},
	@{
		Name = "server tracks celebration per player session"
		Ok = $server.Contains('FirstHareCelebrated = false') -and
			$server.Contains('state.FirstHareCelebrated ~= true') -and
			$server.Contains('state.FirstHareCelebrated = true')
	},
	@{
		Name = "existing HitFx remote personalizes only real match HARE"
		Ok = $server.Contains('HitFxEvent:FireClient(player, fxType, position, teamName, rallyHitCount, combo, isFirstHare)') -and
			$server.Contains('HitFxEvent:FireAllClients(fxType, position, teamName, rallyHitCount, combo, false)') -and
			-not $server.Contains('getOrCreateRemote("FirstHare')
	},
	@{
		Name = "Practice Wall does not consume first HARE"
		Ok = $server.Contains('HitFxEvent:FireClient(player, fxType, practiceBall.Position, player.Team and player.Team.Name or "Red", hitCount, comboCount)') -and
			-not $server.Contains('PracticeWall.FirstHare')
	},
	@{
		Name = "UI renders personalized first HARE and preserves normal HARE"
		Ok = $ui.Contains('local function fxTextForType(fxType, comboCount, isFirstHare)') -and
			$ui.Contains('Config.FirstHareMessage or "FIRST HARE!"') -and
			$ui.Contains('Config.FirstHareSubtitle or "YOUR FIRST TEAM SYNC!"') -and
			$ui.Contains('showFloatingFx(fxType, teamName, rallyCount, comboCount, isFirstHare)') -and
			$ui.Contains('return getHareHitText(comboCount)')
	},
	@{
		Name = "v0.7 checklist covers first and repeat behavior"
		Ok = $checklist.Contains('## FIRST HARE Celebration') -and
			$checklist.Contains('own team') -and
			$checklist.Contains('only once per server session') -and
			$checklist.Contains('Practice Wall HARE does not consume') -and
			$checklist.Contains('second real HARE uses normal HARE text')
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
	throw "FIRST HARE verification failed: $($failed -join ', ')"
}

Write-Host "FIRST HARE celebration source contract passed."
