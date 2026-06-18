$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")

$checks = @(
	@{
		Name = "spawn is behind and clear of the mode pads"
		Ok = $config.Contains('LobbySpawnPosition = Vector3.new(0, 3, -116)') -and
			$config.Contains('LobbyModePadZOffset = 12') -and
			$config.Contains('LobbyEntryPadTouchJoinEnabled = true')
	},
	@{
		Name = "lobby uses a readable step sequence"
		Ok = $config.Contains('LobbyModeBoardTitle = "1  CHOOSE MODE"') -and
			$config.Contains('LobbyReadyBoardTitle = "3  PRESS READY"') -and
			$config.Contains('LobbyCourtBoardTitle = "2  OPTIONAL COURT THEME"') -and
			$config.Contains('LobbyFlowHelpText')
	},
	@{
		Name = "court selection copy is optional rather than mandatory"
		Ok = $config.Contains('CourtSelectBoardTitle = "OPTIONAL COURT THEME"') -and
			$config.Contains('CourtSelectBoardHelp = "Theme only. Skip it and press READY."') -and
			$config.Contains('LobbyReadySubMessage = "READY starts match. Mode/theme optional."')
	},
	@{
		Name = "HUD keeps join steps visible without walking to far boards"
		Ok = $config.Contains('LobbyGuideStepModeText = "1  CHOOSE MODE"') -and
			$config.Contains('LobbyGuideStepThemeText = "2  PICK THEME"') -and
			$config.Contains('LobbyGuideStepReadyText = "3  PRESS READY"') -and
			$ui.Contains('LobbyJoinGuide') -and
			$ui.Contains('local function updateLobbyGuide(state, data)') -and
			$ui.Contains('lobbyActiveStepLabel.Name = "ActiveStep"') -and
			$ui.Contains('lobbyThemeSummaryLabel.Name = "ThemeSummary"')
	},
	@{
		Name = "server positions lobby as a clear path from spawn to mode pads to optional court themes"
		Ok = $server.Contains('local modeBoard = makeWorldPart(LobbyFolder, "LobbyModeBoard"') -and
			$server.Contains('LobbyModePadZOffset') -and
			$server.Contains('LobbyCourtBoardZOffset') -and
			$server.Contains('LobbyReadyBoard') -and
			$server.Contains('LobbyFlowHelpText')
	},
	@{
		Name = "server keeps intentional stand-on-pad joining while spawn starts clear"
		Ok = $server.Contains('entryPad.Touched:Connect') -and
			$server.Contains('entryPad.CanTouch = Config.LobbyEntryPadTouchJoinEnabled ~= false')
	},
	@{
		Name = "court has oversized team side labels and spawn rings"
		Ok = $server.Contains('addSurfaceText(redSideLabel, "RED SIDE"') -and
			$server.Contains('addSurfaceText(blueSideLabel, "BLUE SIDE"') -and
			$server.Contains('RedSpawnRing') -and
			$server.Contains('BlueSpawnRing') -and
			$server.Contains('Config.TeamSideLabelEnabled')
	},
	@{
		Name = "docs include the lobby clarity playtest pass"
		Ok = $checklist.Contains('Confirm spawn starts behind the mode pads') -and
			$checklist.Contains('OPTIONAL COURT THEME') -and
			$checklist.Contains('RED SIDE') -and
			$checklist.Contains('BLUE SIDE')
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
