$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")

$checks = @(
	@{
		Name = "config defines non-power fiber cosmetic colors"
		Ok = $config.Contains('FiberSkinsEnabled = true') -and
			$config.Contains('FiberSkinDefaultColor') -and
			$config.Contains('FiberSkinHareRookieColor') -and
			$config.Contains('FiberSkinSyncPartnerColor') -and
			$config.Contains('FiberSkinOnePinColor')
	},
	@{
		Name = "server derives fiber cosmetic color from player titles"
		Ok = $server.Contains('local function getPlayerFiberSkinColor(player)') -and
			$server.Contains('Config.ProgressTitleSyncPartner') -and
			$server.Contains('Config.FiberSkinSyncPartnerColor') -and
			$server.Contains('Config.FiberSkinHareRookieColor')
	},
	@{
		Name = "server blends team fiber cosmetic without changing warning states"
		Ok = $server.Contains('local function getTeamFiberSkinColor(teamName)') -and
			$server.Contains('local function applyFiberSkinColor(baseColor, teamName, tensionState, realPinCount)') -and
			$server.Contains('if tensionState == "Slack" or tensionState == "OverTension" or tensionState == "Broken" then') -and
			$server.Contains('return baseColor:Lerp(skinColor, Config.FiberSkinBlend or 0.36)')
	},
	@{
		Name = "team beam and HARE visuals use fiber cosmetic color"
		Ok = $server.Contains('color = applyFiberSkinColor(color, teamName, tensionState, realPinCount)') -and
			$server.Contains('getTeamFiberSkinColor(teamName)') -and
			$server.Contains('spawnShockwave(closest, getTeamFiberSkinColor(teamName):Lerp(BEAM_COLORS.Hare')
	},
	@{
		Name = "docs include fiber skin playtest checks"
		Ok = $readme.Contains('Fiber Skins') -and
			$readme.Contains('Fiber Color') -and
			$readme.Contains('non-power cosmetic') -and
			$checklist.Contains('Fiber Skins') -and
			$checklist.Contains('Sync Partner fiber')
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
