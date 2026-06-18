$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$builder = Get-Content -Raw -LiteralPath (Join-Path $root "scripts/roblox/build_tile_field_64_arena.server.lua")

$checks = @(
	@{
		Name = "config widens playable court"
		Ok = $config.Contains("CourtWidth = 56") -and
			$config.Contains("CourtDepth = 34") -and
			$config.Contains("OutZoneDepth = 8")
	},
	@{
		Name = "arena models have enough floor size for wider court"
		Ok = $config.Contains("SizeStuds = 88") -and
			$builder.Contains("local ARENA_SIZE = 88") -and
			$builder.Contains('Vector3.new(88, 0.35, 88)')
	},
	@{
		Name = "normal returns are slower and higher"
		Ok = $config.Contains("BallBaseSpeed = 29") -and
			$config.Contains("PowerBonusNormal = 1") -and
			$config.Contains("ReturnLiftNormal = 0.68") -and
			$config.Contains("ReturnMaxForwardSpeed = 34")
	},
	@{
		Name = "pin and hare still read faster and lower than normal"
		Ok = $config.Contains("PowerBonusBothPin = 7") -and
			$config.Contains("PowerBonusHare = 8") -and
			$config.Contains("ReturnLiftHare = 0.24") -and
			$config.Contains("PinMaxForwardSpeed = 42") -and
			$config.Contains("HareMaxForwardSpeed = 40")
	},
	@{
		Name = "landing target stays readable on wider court"
		Ok = $config.Contains("LandingTargetSize = 8.0")
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
