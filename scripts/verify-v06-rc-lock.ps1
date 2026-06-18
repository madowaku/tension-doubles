$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")
$presetVerifier = Get-Content -Raw -LiteralPath (Join-Path $root "scripts/verify-live-preset.ps1")

$checks = @(
	@{
		Name = "checklist has one compact RC Lock owner run"
		Ok = $checklist.Contains('## v0.6 RC Lock: Smallest Owner Run') -and
			$checklist.Contains('Do not mark v0.6 RC locked until every item below has owner evidence.')
	},
	@{
		Name = "real-phone landscape covers lobby hierarchy and safe area"
		Ok = $checklist.Contains('real phone in landscape') -and
			$checklist.Contains('READY is immediately tappable') -and
			$checklist.Contains('MODE/THEME stay secondary') -and
			$checklist.Contains('MUSIC/SFX remain readable') -and
			$checklist.Contains('PIN hint fits inside the safe area')
	},
	@{
		Name = "owner run covers all three live presets"
		Ok = $checklist.Contains('Solo: one client, CPU fill, practice rally') -and
			$checklist.Contains('TwoPlayer: two clients, CPU fill completes both sides') -and
			$checklist.Contains('FourPlayer: four clients, no CPU labels or ghost support') -and
			$presetVerifier.Contains('[ValidateSet("Solo", "TwoPlayer", "FourPlayer")]')
	},
	@{
		Name = "session audio independence and retention are explicit"
		Ok = $checklist.Contains('change MUSIC without changing SFX') -and
			$checklist.Contains('change SFX without changing MUSIC') -and
			$checklist.Contains('values are retained when the player returns to the lobby in the same session')
	},
	@{
		Name = "results-to-rematch is one continuous acceptance flow"
		Ok = $checklist.Contains('finish one match') -and
			$checklist.Contains('HAREs, Best Rally, Team Syncs, and Slack Saves') -and
			$checklist.Contains('return to the lobby') -and
			$checklist.Contains('press READY again') -and
			$checklist.Contains('next match reaches FIBER CHARGE')
	},
	@{
		Name = "clean Output is a lock gate"
		Ok = $checklist.Contains('Output has no red game-script errors') -and
			$checklist.Contains('External Roblox HTTP or plugin warnings are recorded separately')
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
	throw "v0.6 RC Lock verification failed: $($failed -join ', ')"
}

Write-Host "v0.6 RC Lock source contract passed."
