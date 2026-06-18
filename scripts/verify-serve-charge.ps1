$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")

$checks = @(
	@{
		Name = "config defines fiber charge serve tuning"
		Ok = $config.Contains("ServeChargeEnabled = true") -and
			$config.Contains("ServeHarePinDelta") -and
			$config.Contains("ServeHareSpeed") -and
			$config.Contains("ServeOnePinLateralMax") -and
			$config.Contains("ServeSlackVerticalVelocity") -and
			$config.Contains("ServeOverTensionLateralMax")
	},
	@{
		Name = "config defines serve variant copy"
		Ok = $config.Contains('ServeChargeSubMessage') -and
			$config.Contains('ServeHareMessage') -and
			$config.Contains('ServeOnePinMessage') -and
			$config.Contains('ServeSlackMessage') -and
			$config.Contains('ServeOverTensionMessage')
	},
	@{
		Name = "server computes serve charge from team pin and tension"
		Ok = $server.Contains("local function getServeChargeForTeam(teamName)") -and
			$server.Contains("getNetEndpoints(teamName)") -and
			$server.Contains("getTensionState(a, b)") -and
			$server.Contains("getTeamPinInfo(teamName)") -and
			$server.Contains("pinDelta <= (Config.ServeHarePinDelta")
	},
	@{
		Name = "server applies serve variant velocity and visual feedback"
		Ok = $server.Contains("local serveCharge = getServeChargeForTeam(servingTeam)") -and
			$server.Contains("serveCharge.lateralMax") -and
			$server.Contains("serveCharge.verticalVelocity") -and
			$server.Contains("serveCharge.speed") -and
			$server.Contains("setBallVisualForFx(serveCharge.fxType)") -and
			$server.Contains('fireHitFx(serveCharge.fxType')
	},
	@{
		Name = "server announces charge prompt and resolved serve"
		Ok = $server.Contains("Config.ServeChargeMessage") -and
			$server.Contains("serveCharge.message") -and
			$server.Contains('setState("Serving", serveCharge.message)')
	},
	@{
		Name = "ui keeps serving submessage config driven"
		Ok = $ui.Contains('state == "Serving"') -and
			$ui.Contains("Config.ServingSubMessage") -and
			$ui.Contains("Config.ServeChargeSubMessage")
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
