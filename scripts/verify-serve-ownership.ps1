$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")

$checks = @(
	@{
		Name = "config defines serve ownership and final hare copy"
		Ok = $config.Contains("ServeOwnerMessageFormat") -and
			$config.Contains("ServeOwnerSubMessageFormat") -and
			$config.Contains("ServeBallLabelText") -and
			$config.Contains("FinalHareEnabled = true") -and
			$config.Contains("FinalHareMessage") -and
			$config.Contains("FinalHareSubMessage")
	},
	@{
		Name = "server tracks and broadcasts current serving team"
		Ok = $server.Contains("local currentServingTeam = nil") -and
			$server.Contains("servingTeam = currentServingTeam") -and
			$server.Contains("currentServingTeam = servingTeam") -and
			$server.Contains("currentServingTeam = nil")
	},
	@{
		Name = "server detects final hare at deuce point"
		Ok = $server.Contains("local function isFinalHareActive()") -and
			$server.Contains("Config.FinalHareEnabled ~= false") -and
			$server.Contains("score.Red == Config.ScoreToWin - 1") -and
			$server.Contains("score.Blue == Config.ScoreToWin - 1") -and
			$server.Contains("finalHare = isFinalHareActive()")
	},
	@{
		Name = "server formats serve owner messages"
		Ok = $server.Contains("local function formatServeOwnerMessage(teamName)") -and
			$server.Contains("Config.ServeOwnerMessageFormat") -and
			$server.Contains("Config.FinalHareServeMessageFormat") -and
			$server.Contains('setState("Serving", formatServeOwnerMessage(servingTeam))')
	},
	@{
		Name = "server creates visible serve label on ball"
		Ok = $server.Contains("local function ensureServeBallLabel(part)") -and
			$server.Contains('label.Name = "TD_ServeLabelText"') -and
			$server.Contains("setServeBallLabelVisible(true, servingTeam)") -and
			$server.Contains("setServeBallLabelVisible(false)")
	},
	@{
		Name = "server hides serve label before rally starts"
		Ok = $server.Contains("setServeBallLabelVisible(false, servingTeam)") -and
			$server.Contains('setState("Rally", "RALLY!")')
	},
	@{
		Name = "ui renders serve ownership and final hare submessages"
		Ok = $ui.Contains("data.servingTeam") -and
			$ui.Contains("Config.ServeOwnerSubMessageFormat") -and
			$ui.Contains("data.finalHare") -and
			$ui.Contains("Config.FinalHareSubMessage")
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
