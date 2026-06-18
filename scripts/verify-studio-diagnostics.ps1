$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v10-public-beta-checklist.md")

$checks = @(
	@{
		Name = "Config exposes disableable Studio diagnostics toggles"
		Ok = $config.Contains('StudioDiagnosticsEnabled = true') -and
			$config.Contains('StudioDiagnosticsFolderName = "TensionDoublesStudioDiagnostics"')
	},
	@{
		Name = "Server gates diagnostics to Studio and ReplicatedStorage"
		Ok = $server.Contains('local Diagnostics = {}') -and
			$server.Contains('RunService:IsStudio()') -and
			$server.Contains('Config.StudioDiagnosticsEnabled ~= false') -and
			$server.Contains('Config.StudioDiagnosticsFolderName or "TensionDoublesStudioDiagnostics"') -and
			$server.Contains('ReplicatedStorage:FindFirstChild(Config.StudioDiagnosticsFolderName or "TensionDoublesStudioDiagnostics")')
	},
	@{
		Name = "Diagnostics mirror LivePreset, queue, READY, and state"
		Ok = $server.Contains('Diagnostics.setString("LivePreset"') -and
			$server.Contains('Diagnostics.setString("State"') -and
			$server.Contains('Diagnostics.setInt("QueuedSpectators"') -and
			$server.Contains('Diagnostics.setInt("LobbyReadyPlayers"') -and
			$server.Contains('Diagnostics.setInt("LobbyNeededPlayers"')
	},
	@{
		Name = "READY diagnostics exclude queued spectators from lobby participant counts"
		Ok = $server.Contains('local function isLobbyParticipant(player)') -and
			$server.Contains('queuedNextMatchPlayers[player] ~= true') -and
			$server.Contains('if isLobbyParticipant(player) then') -and
			$server.Contains('if queuedNextMatchPlayers[player] == true then') -and
			$server.Contains('return')
	},
	@{
		Name = "Diagnostics mirror Analytics Lite counters without external telemetry"
		Ok = $server.Contains('Diagnostics.syncAnalyticsCounters = function()') -and
			$server.Contains('local countersFolder = Diagnostics.ensureSubfolder("AnalyticsCounters")') -and
			$server.Contains('Config.AnalyticsLiteFolderName or "TensionDoublesAnalytics"') -and
			$server.Contains('Diagnostics.syncAnalyticsCounters()') -and
			-not $server.Contains('AnalyticsService') -and
			-not $server.Contains('DataStoreService') -and
			-not $server.Contains('HttpService')
	},
	@{
		Name = "Diagnostics are not player-facing UI"
		Ok = -not $ui.Contains('TensionDoublesStudioDiagnostics') -and
			-not $ui.Contains('StudioDiagnosticsEnabled') -and
			-not $ui.Contains('QueuedSpectators')
	},
	@{
		Name = "v1.0 checklist covers Studio diagnostics inspection"
		Ok = $checklist.Contains('Studio Diagnostics') -and
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
