$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")
$checklist = Get-Content -Raw -LiteralPath (Join-Path $root "docs/playtests/v06-rc-checklist.md")

$checks = @(
	@{
		Name = "config defines lightweight title stat and thresholds"
		Ok = $config.Contains('ProgressStatTitle = "Title"') -and
			$config.Contains('ProgressTitleDefault = "Rally Starter"') -and
			$config.Contains('ProgressTitleHareRookie = "HARE Rookie"') -and
			$config.Contains('ProgressTitleSyncPartner = "Sync Partner"') -and
			$config.Contains('ProgressTitleHareRookieAt = 1') -and
			$config.Contains('ProgressTitleSyncPartnerAt = 3')
	},
	@{
		Name = "server creates StringValue title in leaderstats"
		Ok = $server.Contains('local function ensureLeaderTitle(player, statName, initialValue)') -and
			$server.Contains('Instance.new("StringValue")') -and
			$server.Contains('Config.ProgressStatTitle or "Title"') -and
			$server.Contains('Config.ProgressTitleDefault or "Rally Starter"')
	},
	@{
		Name = "server updates title from cooperative records"
		Ok = $server.Contains('local function updateProgressTitle(player)') -and
			$server.Contains('if teamSyncs and teamSyncs.Value >= (Config.ProgressTitleSyncPartnerAt or 3) then') -and
			$server.Contains('elseif hares and hares.Value >= (Config.ProgressTitleHareRookieAt or 1) then') -and
			$server.Contains('title.Value = nextTitle')
	},
	@{
		Name = "server refreshes titles after HAREs, rallies, and wins"
		Ok = $server.Contains('updateProgressTitle(player)') -and
			$server.Contains('recordTeamSync(teamName, fxType)') -and
			$server.Contains('recordBestRallyForMatchPlayers(rallyCountAtPoint)') -and
			$server.Contains('recordWinForTeam(winner)')
	},
	@{
		Name = "docs include title playtest checks"
		Ok = $readme.Contains('Rally Starter') -and
			$readme.Contains('HARE Rookie') -and
			$readme.Contains('Sync Partner') -and
			$checklist.Contains('Title') -and
			$checklist.Contains('Sync Partner')
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
