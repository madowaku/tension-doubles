$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$input = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")

$checks = @(
	@{
		Name = "config defines the lightweight one-step lobby guide"
		Ok = $config.Contains('LobbyGuideStepSeconds = 2.25') -and
			$config.Contains('LobbyGuideStepModeText = "1  CHOOSE MODE"') -and
			$config.Contains('LobbyGuideStepThemeText = "2  PICK THEME"') -and
			$config.Contains('LobbyGuideStepReadyText = "3  PRESS READY"') -and
			$config.Contains('LobbyGuideCompactText = "Mode. Theme. READY."')
	},
	@{
		Name = "config keeps device hints short"
		Ok = $config.Contains('TouchLandscapeHint = "Move. Stretch. Hold PIN."') -and
			$config.Contains('TouchHint = "Move. Stretch. Hold PIN."') -and
			$config.Contains('DesktopHint = "Hold E / Space: PIN"') -and
			$config.Contains('GamepadHint = "Hold R2: PIN"')
	},
	@{
		Name = "lobby HUD uses one active step and secondary mode theme summaries"
		Ok = $ui.Contains('lobbyActiveStepLabel.Name = "ActiveStep"') -and
			$ui.Contains('lobbyModeSummaryLabel.Name = "ModeSummary"') -and
			$ui.Contains('lobbyThemeSummaryLabel.Name = "ThemeSummary"') -and
			$ui.Contains('local function setLobbyGuideStage(stage)') -and
			$ui.Contains('local function beginLobbyGuideOnce()') -and
			$ui.Contains('lobbyGuideCompleted = true')
	},
	@{
		Name = "mobile lobby guide stays above the bottom control collision zone"
		Ok = $config.Contains('LobbyGuideYTouchPortrait = 0.690') -and
			$config.Contains('LobbyGuideYTouchLandscape = 0.700') -and
			$ui.Contains('Config.LobbyGuideYTouchPortrait or 0.690') -and
			$ui.Contains('Config.LobbyGuideYTouchLandscape or 0.700')
	},
	@{
		Name = "lobby guide hides during countdown and match states"
		Ok = $ui.Contains('local visible = state == "Lobby" or state == "WaitingForPlayers"') -and
			$ui.Contains('lobbyGuidePanel.Visible = visible') -and
			$ui.Contains('if not visible then')
	},
	@{
		Name = "music and SFX controls use a compact top-right stack"
		Ok = $ui.Contains('panel.AnchorPoint = Vector2.new(1, 0)') -and
			$ui.Contains('Config.AudioMixerTopRightX or 0.985') -and
			$ui.Contains('Config.AudioMixerMusicY or 0.075') -and
			$ui.Contains('Config.AudioMixerSfxY or 0.140')
	},
	@{
		Name = "Roblox player list does not cover lobby hierarchy"
		Ok = $ui.Contains('local function setLobbyPlayerListVisible(state)') -and
			$ui.Contains('StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not inLobby)') -and
			$ui.Contains('setLobbyPlayerListVisible(state)')
	},
	@{
		Name = "READY or JOIN MATCH is the centered dominant lobby action"
		Ok = $input.Contains('currentLobbyState == "WaitingForPlayers" and "JOIN MATCH" or "READY"') -and
			$input.Contains('Config.LobbyMainButtonY or 0.545') -and
			$input.Contains('Config.LobbyMainButtonWidthTouch or 0.34') -and
			$input.Contains('isInLobby = state == "Lobby" or state == "WaitingForPlayers"')
	},
	@{
		Name = "native HOW TO PLAY board matches the public beta loop and cannot block players"
		Ok = $config.Contains('LobbyTutorialBoardTitle = "HOW TO PLAY"') -and
			$config.Contains('LobbyTutorialStepMove = "1  MOVE WITH YOUR PARTNER"') -and
			$config.Contains('LobbyTutorialStepStretch = "2  STRETCH THE FIBER"') -and
			$config.Contains('LobbyTutorialStepPin = "3  HOLD PIN TOGETHER FOR HARE!"') -and
			$server.Contains('local function addLobbyTutorialBoard(parent, lobbySpawnPos)') -and
			$server.Contains('"LobbyHowToPlayBoard"') -and
			$server.Contains('board.CanCollide = false') -and
			$server.Contains('board.CanTouch = false') -and
			$server.Contains('addLobbyTutorialBoard(LobbyFolder, lobbySpawnPos)')
	},
	@{
		Name = "patch does not alter gameplay constants"
		Ok = -not $ui.Contains('BallBaseSpeed =') -and
			-not $input.Contains('ScoreToWin =') -and
			-not $input.Contains('CpuFillEnabled =')
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
	throw "Lobby UI hierarchy verification failed: $($failed -join ', ')"
}

Write-Host "Lobby UI hierarchy source contract passed."
