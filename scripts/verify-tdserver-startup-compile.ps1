$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$serverPath = Join-Path $root "src/ServerScriptService/TDServer.server.lua"
$projectPath = Join-Path $root "default.project.json"
$server = Get-Content -Raw -LiteralPath $serverPath
$project = Get-Content -Raw -LiteralPath $projectPath
$bootstrap = $server.Substring($server.IndexOf("-- Bootstrap existing players"))

function Count-Pattern($text, $pattern) {
	([regex]::Matches($text, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
}

$topLevelLocalFunctionCount = Count-Pattern $server '^\s*local\s+function\s+'
$monetizationLocalHelpers = Count-Pattern $server '^\s*local\s+function\s+(getMonetizationProduct|getMonetizationPassId|refreshMonetizationOwnership|buildMonetizationPayload|sendMonetizationState|promptMonetizationPass|openMonetizationShop|connectMonetizationStand)\b'

$checks = @(
	@{
		Name = "TDServer is mapped into ServerScriptService"
		Ok = $project.Contains('"ServerScriptService"') -and
			$project.Contains('"TDServer"') -and
			$project.Contains('src/ServerScriptService/TDServer.server.lua')
	},
	@{
		Name = "Recently added monetization helpers do not consume top-level local function registers"
		Ok = $monetizationLocalHelpers -eq 0
	},
	@{
		Name = "TDServer top-level local function pressure stays below startup limit"
		Ok = $topLevelLocalFunctionCount -lt 195
	},
	@{
		Name = "Late match-loop helpers do not allocate top-level local registers"
		Ok = $server.Contains('local MatchLoop = {}') -and
			$server.Contains('MatchLoop.updateAfkSafety = function()') -and
			$server.Contains('MatchLoop.hasEnoughPlayers = function()') -and
			$server.Contains('MatchLoop.getLobbyGate = function()') -and
			$server.Contains('MatchLoop.resetLobbyReady = function()') -and
			$server.Contains('MatchLoop.runReadyUp = function()') -and
			$server.Contains('MatchLoop.runCountdown = function()') -and
			$server.Contains('MatchLoop.finishGame = function(winner)') -and
			-not $server.Contains('local function updateAfkSafety()') -and
			-not $server.Contains('local function hasEnoughPlayers()') -and
			-not $server.Contains('local function getLobbyGate()') -and
			-not $server.Contains('local function resetLobbyReady()') -and
			-not $server.Contains('local function runReadyUp()') -and
			-not $server.Contains('local function runCountdown()') -and
			-not $server.Contains('local function finishGame(winner)')
	},
	@{
		Name = "Bootstrap existing-player loop runs outside the top-level register frame"
		Ok = $bootstrap.Contains('task.defer(function()') -and
			$bootstrap.Contains('for _, existingPlayer in ipairs(Players:GetPlayers()) do') -and
			-not $bootstrap.Contains('for existingPlayerIndex = 1, #Players:GetPlayers() do')
	},
	@{
		Name = "Startup still creates required remotes"
		Ok = $server.Contains('getOrCreateRemote("PinInputEvent")') -and
			$server.Contains('getOrCreateRemote("LobbyReadyEvent")') -and
			$server.Contains('getOrCreateRemote("MatchStateEvent")') -and
			$server.Contains('getOrCreateRemote("HitFxEvent")') -and
			$server.Contains('getOrCreateRemote("MonetizationRequestEvent")') -and
			$server.Contains('getOrCreateRemote("MonetizationStateEvent")')
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
	throw "TDServer startup compile verification failed: $($failed -join ', ')"
}

Write-Host "TDServer startup compile source contract passed. top-level local functions: $topLevelLocalFunctionCount"
