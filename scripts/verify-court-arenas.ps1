$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$builder = Get-Content -Raw -LiteralPath (Join-Path $root "scripts/roblox/build_tile_field_64_arena.server.lua")
$manifest = Get-Content -Raw -LiteralPath (Join-Path $root "data/arena/tile-field-64-arena.json")

$courtIds = @("Grass", "Rooftop", "School", "Festival", "Space")
$modelNames = @("Arena_Grass", "Arena_Rooftop", "Arena_School", "Arena_Festival", "Arena_Space")
$legacyModelNames = @("TDArena_Grass64", "TDArena_Rooftop64", "TDArena_School64", "TDArena_Festival64", "TDArena_Space64")

$checks = @(
	@{
		Name = "config maps every court to a 3D arena model"
		Ok = $config.Contains("CourtArenaModels") -and
			$config.Contains('ArenaFolderName = "Arenas"') -and
			($courtIds | Where-Object { -not $config.Contains($_ + " = {") }).Count -eq 0 -and
			($modelNames | Where-Object { -not $config.Contains('ModelName = "' + $_ + '"') }).Count -eq 0
	},
	@{
		Name = "config keeps source image paths for every court arena"
		Ok = ($courtIds | Where-Object { -not $config.Contains("SourceImagePath") }).Count -eq 0 -and
			$config.Contains("19_40_15.png") -and
			$config.Contains("19_40_24.png") -and
			$config.Contains("19_40_35.png") -and
			$config.Contains("19_40_43.png") -and
			$config.Contains("19_40_54.png")
	},
	@{
		Name = "server loads arena model based on active court id"
		Ok = $server.Contains("local function getCourtArenaConfig(courtId)") -and
			$server.Contains("local function findArenaTemplate(arenaConfig)") -and
			$server.Contains("Config.CourtArenaModels") -and
			$server.Contains('ServerStorage:FindFirstChild(Config.ArenaFolderName or "Arenas")') -and
			$server.Contains("getCourtArenaConfig(activeCourtId)") -and
			$server.Contains('arena:SetAttribute("RuntimeCourtId", activeCourtId)')
	},
	@{
		Name = "server falls back to generated flat court if arena model is unavailable"
		Ok = $server.Contains("using generated flat court fallback") -and
			$server.Contains("return false")
	},
	@{
		Name = "builder creates five themed ServerStorage/Arenas models"
		Ok = $builder.Contains("COURT_THEMES") -and
			$builder.Contains('ARENA_FOLDER_NAME = "Arenas"') -and
			$builder.Contains("local arenaFolder = ensureArenaFolder()") -and
			($courtIds | Where-Object { -not $builder.Contains('Id = "' + $_ + '"') }).Count -eq 0 -and
			($modelNames | Where-Object { -not $builder.Contains('ModelName = "' + $_ + '"') }).Count -eq 0 -and
			$builder.Contains("for _, theme in ipairs(COURT_THEMES) do")
	},
	@{
		Name = "builder preserves legacy grass model alias"
		Ok = $builder.Contains('LEGACY_GRASS_MODEL_NAME = "TDArena_TileField64"') -and
			($legacyModelNames | Where-Object { -not $builder.Contains('LegacyModelName = "' + $_ + '"') }).Count -eq 0 -and
			$builder.Contains("cloneLegacyGrassAlias")
	},
	@{
		Name = "arena manifest documents five generated 3D models"
		Ok = $manifest.Contains('"generatedModels"') -and
			($modelNames | Where-Object { -not $manifest.Contains($_) }).Count -eq 0
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
