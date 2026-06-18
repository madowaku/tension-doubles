$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$manual = Get-Content -Raw -LiteralPath (Join-Path $root "MANUAL_IMPORT.md")

$checks = @(
	@{
		Name = "UI does not block forever before creating HUD when remotes are missing"
		Ok = $ui.Contains('ReplicatedStorage:WaitForChild("TensionDoublesRemotes", 5)') -and
			$ui.Contains('local remotesReady = Remotes ~= nil') -and
			-not $ui.Contains('local Remotes = ReplicatedStorage:WaitForChild("TensionDoublesRemotes")')
	},
	@{
		Name = "UI guards optional monetization remote calls"
		Ok = $ui.Contains('if MonetizationRequestEvent then') -and
			$ui.Contains('Monetization UI is waiting for the server.')
	},
	@{
		Name = "UI shows server-missing fallback copy"
		Ok = $ui.Contains('Config.ServerMissingMessage') -and
			$ui.Contains('Config.ServerMissingSubMessage')
	},
	@{
		Name = "Config exposes BGM volume settings"
		Ok = $config.Contains('BgmVolumeControlEnabled = true') -and
			$config.Contains('BgmDefaultVolume = 0.55') -and
			$config.Contains('BgmSoundNames = {') -and
			$config.Contains('BgmVolumeStep = 0.10')
	},
	@{
		Name = "UI renders BGM volume controls and applies Sound volumes"
		Ok = $ui.Contains('SoundService = game:GetService("SoundService")') -and
			$ui.Contains('MusicVolumePanel') -and
			$ui.Contains('applyMusicVolume') -and
			$ui.Contains('findBgmSounds') -and
			$ui.Contains('MUSIC')
	},
	@{
		Name = "BGM finder falls back to non-character Sound instances"
		Ok = $ui.Contains('isCharacterSound') -and
			$ui.Contains('isNamedBgmSound') -and
			$ui.Contains('fallbackSounds') -and
			$ui.Contains('return fallbackSounds')
	},
	@{
		Name = "BGM label visibly changes even before a named sound is found"
		Ok = $ui.Contains('string.format("%s %d%%", title, math.floor(musicVolume * 100 + 0.5))') -and
			-not $ui.Contains('bgmLabel.Text = title .. " --"')
	},
	@{
		Name = "Manual import reminds TDServer is required"
		Ok = $manual.Contains('If the screen is blank') -and
			$manual.Contains('ServerScriptService') -and
			$manual.Contains('TDServer')
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
	throw "UI resilience / BGM verification failed: $($failed -join ', ')"
}

Write-Host "UI resilience and BGM source contract passed."
