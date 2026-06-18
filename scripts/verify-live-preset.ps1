param(
	[ValidateSet("Solo", "TwoPlayer", "FourPlayer")]
	[string]$ExpectedPreset
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configPath = Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua"
$config = Get-Content -Raw -LiteralPath $configPath

function Assert-Match {
	param(
		[string]$Name,
		[bool]$Ok
	)

	$status = if ($Ok) { "PASS" } else { "FAIL" }
	Write-Output ("{0}: {1}" -f $status, $Name)
	if (-not $Ok) {
		throw $Name
	}
}

if ($config -notmatch 'LivePreset\s*=\s*"(?<preset>Solo|TwoPlayer|FourPlayer)"') {
	throw "GameConfig.lua must set LivePreset to Solo, TwoPlayer, or FourPlayer."
}

$activePreset = $Matches.preset
Write-Output ("Active LivePreset: {0}" -f $activePreset)

if ($ExpectedPreset) {
	Assert-Match "active preset matches expected $ExpectedPreset" ($activePreset -eq $ExpectedPreset)
}

$presetExpectations = @{
	Solo = @{
		AllowGhostPartners = "true"
		GhostMirrorsPinning = "true"
		SoloGhostsMirrorPinning = "true"
		CpuFillEnabled = "true"
		MinPlayersToAutoStart = "1"
	}
	TwoPlayer = @{
		AllowGhostPartners = "true"
		GhostMirrorsPinning = "true"
		SoloGhostsMirrorPinning = "false"
		CpuFillEnabled = "true"
		MinPlayersToAutoStart = "2"
	}
	FourPlayer = @{
		AllowGhostPartners = "false"
		GhostMirrorsPinning = "false"
		SoloGhostsMirrorPinning = "false"
		CpuFillEnabled = "false"
		MinPlayersToAutoStart = "4"
	}
}

foreach ($presetName in @("Solo", "TwoPlayer", "FourPlayer")) {
	$blockPattern = "(?s)$presetName\s*=\s*\{(?<block>.*?)\n\t\t\}"
	if ($config -notmatch $blockPattern) {
		throw ("LivePresets.{0} is missing." -f $presetName)
	}
	$block = $Matches.block
	foreach ($key in $presetExpectations[$presetName].Keys) {
		$value = $presetExpectations[$presetName][$key]
		Assert-Match "$presetName sets $key = $value" ($block -match ("\b{0}\s*=\s*{1}\b" -f $key, $value))
	}
}

Write-Output "live preset checks passed"
