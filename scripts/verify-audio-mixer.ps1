$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$input = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua")

$checks = @(
	@{
		Name = "Config defines audio mixer groups and default volumes"
		Ok = $config.Contains('AudioMixerEnabled = true') -and
			$config.Contains('MusicSoundGroupName = "TDMusic"') -and
			$config.Contains('SfxSoundGroupName = "TDSFX"') -and
			$config.Contains('UiSoundGroupName = "TDUI"') -and
			$config.Contains('MusicDefaultVolume = 0.55') -and
			$config.Contains('SfxDefaultVolume = 0.70') -and
			$config.Contains('UiDefaultVolume = 0.65')
	},
	@{
		Name = "Config defines replaceable SFX asset ids"
		Ok = $config.Contains('AudioSfxSoundIds = {') -and
			$config.Contains('Pin = "rbxassetid://12221990"') -and
			$config.Contains('Hare = "rbxassetid://12221831"') -and
			$config.Contains('Out = "rbxassetid://12222216"') -and
			$config.Contains('Countdown = "rbxassetid://12221944"')
	},
	@{
		Name = "UI creates Music SFX and UI SoundGroups"
		Ok = $ui.Contains('ensureAudioSoundGroups') -and
			$ui.Contains('Instance.new("SoundGroup")') -and
			$ui.Contains('Config.MusicSoundGroupName') -and
			$ui.Contains('Config.SfxSoundGroupName') -and
			$ui.Contains('Config.UiSoundGroupName')
	},
	@{
		Name = "UI mixer exposes Music and SFX controls"
		Ok = $ui.Contains('MusicVolumePanel') -and
			$ui.Contains('SfxVolumePanel') -and
			$ui.Contains('applyMusicVolume') -and
			$ui.Contains('applySfxVolume')
	},
	@{
		Name = "UI plays SFX from existing match events"
		Ok = $ui.Contains('playGameSfx') -and
			$ui.Contains('playGameSfx("Countdown")') -and
			$ui.Contains('playGameSfx("Score")') -and
			$ui.Contains('playGameSfx(fxType)')
	},
	@{
		Name = "Input client plays local PIN SFX without server behavior changes"
		Ok = $input.Contains('local function playPinSfx()') -and
			$input.Contains('local ids = Config.AudioSfxSoundIds or {}') -and
			$input.Contains('local soundId = ids.Pin') -and
			$input.Contains('setPinning(true)') -and
			$input.Contains('playPinSfx()')
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
	throw "Audio mixer verification failed: $($failed -join ', ')"
}

Write-Host "Audio mixer source contract passed."
