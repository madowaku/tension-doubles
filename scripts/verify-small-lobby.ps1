$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")

$checks = @(
	@{
		Name = "config defines v0.6 small lobby entry pads"
		Ok = $config.Contains('LobbyEntryPads') -and
			$config.Contains('Id = "Practice"') -and
			$config.Contains('Label = "PRACTICE"') -and
			$config.Contains('SubLabel = "1P + CPU"') -and
			$config.Contains('Id = "Quick2v2"') -and
			$config.Contains('Label = "QUICK 2v2"') -and
			$config.Contains('SubLabel = "Players + CPU fill"') -and
			$config.Contains('Id = "PrivateFriends"') -and
			$config.Contains('Label = "PRIVATE / FRIENDS"') -and
			$config.Contains('SubLabel = "Play with friends"')
	},
	@{
		Name = "config contains exact lobby rule board copy"
		Ok = $config.Contains('LobbyRulesText = "Move. Stretch. Hold PIN together."')
	},
	@{
		Name = "config contains participant and spectator lobby copy"
		Ok = $config.Contains('LobbyParticipantCountFormat') -and
			$config.Contains('LobbySpectatorLabel') -and
			$config.Contains('LobbySpectatorHelp') -and
			$config.Contains('PracticeVsBots')
	},
	@{
		Name = "server creates rule board, participant board, and spectator area"
		Ok = $server.Contains('LobbyRulesBoard') -and
			$server.Contains('LobbyParticipantBoard') -and
			$server.Contains('LobbySpectatorArea') -and
			$server.Contains('Config.LobbyRulesText') -and
			$server.Contains('lobbyParticipantLabel')
	},
	@{
		Name = "server creates the three requested entry pads"
		Ok = $server.Contains('PracticeEntryPad') -and
			$server.Contains('Quick2v2EntryPad') -and
			$server.Contains('PrivateFriendsEntryPad') -and
			$server.Contains('LobbyEntryId') -and
			$server.Contains('Config.LobbyEntryPads')
	},
	@{
		Name = "server lets lobby entry pads reuse current ready and CPU fill path"
		Ok = $server.Contains('local function selectLobbyEntry(player, entry)') -and
			$server.Contains('selectedCourtByPlayer[player] = courtId') -and
			$server.Contains('lobbyReady[player] = false') -and
			$server.Contains('updateLobbyParticipantBoardStatus()') -and
			$server.Contains('LobbyEntrySelectedMessageFormat')
	},
	@{
		Name = "server exposes entry pads to mouse and proximity prompt input"
		Ok = $server.Contains('entryPadDetector.MouseClick:Connect') -and
			$server.Contains('entryPadPrompt.Triggered:Connect') -and
			$server.Contains('Config.LobbyEntryPromptActionText')
	},
	@{
		Name = "docs mention small lobby entry and playtest checks"
		Ok = $readme.Contains('PRACTICE / QUICK 2v2 / PRIVATE') -and
			$readme.Contains('Move. Stretch. Hold PIN together.') -and
			$checklist.Contains('Small lobby') -and
			$checklist.Contains('Practice vs Bots')
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
