$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "README declares v1.0 public beta candidate scope"
		Ok = $readme.Contains('## v1.0 Public Beta Candidate') -and
			$readme.Contains('same-server 2v2') -and
			$readme.Contains('CPU fill') -and
			$readme.Contains('non-power Fiber cosmetics')
	},
	@{
		Name = "README includes Roblox description copy"
		Ok = $readme.Contains('## Roblox Description Copy') -and
			$readme.Contains('Short description') -and
			$readme.Contains('Full description') -and
			$readme.Contains('Move. Stretch. Hold PIN together.')
	},
	@{
		Name = "checklist includes launch metadata and asset specs"
		Ok = $checklist.Contains('## Launch Metadata') -and
			$checklist.Contains('Roblox Description Copy') -and
			$checklist.Contains('## Thumbnail And Icon Specs') -and
			$checklist.Contains('Thumbnail prompt') -and
			$checklist.Contains('Icon prompt')
	},
	@{
		Name = "checklist includes tutorial and onboarding completion"
		Ok = $checklist.Contains('## Tutorial Completion') -and
			$checklist.Contains('First 30 seconds') -and
			$checklist.Contains('native `HOW TO PLAY` lobby board') -and
			$checklist.Contains('MUSIC/SFX stay in the top-right stack') -and
			$checklist.Contains('solo') -and
			$checklist.Contains('2-player') -and
			$checklist.Contains('4-player')
	},
	@{
		Name = "checklist includes analytics review"
		Ok = $checklist.Contains('## Analytics Review') -and
			$checklist.Contains('Creator Analytics') -and
			$checklist.Contains('retention') -and
			$checklist.Contains('match starts') -and
			$checklist.Contains('HAREs')
	},
	@{
		Name = "checklist includes public test plan and known deferrals"
		Ok = $checklist.Contains('## Public Test Plan') -and
			$checklist.Contains('Known Deferrals') -and
			$checklist.Contains('Ordered DataStore') -and
			$checklist.Contains('pay-to-win')
	},
	@{
		Name = "checklist keeps v0.9 and existing verification commands"
		Ok = $checklist.Contains('Late Join Safety') -and
			$checklist.Contains('scripts\verify-v09-session-safety.ps1') -and
			$checklist.Contains('scripts\verify-fiber-skins.ps1') -and
			$checklist.Contains('scripts\verify-studio-diagnostics.ps1') -and
			$checklist.Contains('rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx')
	},
	@{
		Name = "checklist includes Studio diagnostics inspection"
		Ok = $checklist.Contains('## Studio Diagnostics') -and
			$checklist.Contains('TensionDoublesStudioDiagnostics') -and
			$checklist.Contains('LivePreset') -and
			$checklist.Contains('State') -and
			$checklist.Contains('QueuedSpectators') -and
			$checklist.Contains('LobbyReadyPlayers') -and
			$checklist.Contains('LobbyNeededPlayers') -and
			$checklist.Contains('AnalyticsCounters') -and
			$checklist.Contains('Smallest manual Studio test') -and
			$checklist.Contains('StudioDiagnosticsEnabled')
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
