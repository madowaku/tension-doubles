$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "config defines HARE hit text style variants"
		Ok = $config.Contains('HareHitTextStyles') -and
			$config.Contains('Text = "HARE!!"') -and
			$config.Contains('Text = "DOUBLE HARE!!"') -and
			$config.Contains('Text = "HARE STREAK!!"') -and
			$config.Contains('HareHitTextComboSuffixFormat = " x%d"')
	},
	@{
		Name = "ui selects HARE text from config without server payload changes"
		Ok = $ui.Contains('local function getHareHitText(comboCount)') -and
			$ui.Contains('Config.HareHitTextStyles') -and
			$ui.Contains('if count >= (style.AtCombo or 1) then') -and
			$ui.Contains('Config.HareHitTextComboSuffixFormat or " x%d"')
	},
	@{
		Name = "ui preserves existing HARE text with an appended compatibility flag"
		Ok = $ui.Contains('local function fxTextForType(fxType, comboCount, isFirstHare)') -and
			$ui.Contains('return getHareHitText(comboCount), Color3.fromRGB(255, 230, 90)') -and
			$ui.Contains('HitFxEvent.OnClientEvent:Connect(function(fxType, _position, teamName, rallyCount, comboCount, isFirstHare)')
	},
	@{
		Name = "v1.0 checklist covers HARE hit text styles"
		Ok = $checklist.Contains('HARE Hit Text Styles') -and
			$checklist.Contains('DOUBLE HARE!!') -and
			$checklist.Contains('HARE STREAK!!')
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
