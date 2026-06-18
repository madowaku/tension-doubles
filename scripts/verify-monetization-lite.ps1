$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $root "src/ReplicatedStorage/TDShared/GameConfig.lua")
$server = Get-Content -Raw -LiteralPath (Join-Path $root "src/ServerScriptService/TDServer.server.lua")
$ui = Get-Content -Raw -LiteralPath (Join-Path $root "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua")
$readme = Get-Content -Raw -LiteralPath (Join-Path $root "README.md")

$checks = @(
	@{
		Name = "Config exposes non-power monetization passes"
		Ok = $config.Contains("MonetizationLiteEnabled = true") -and
			$config.Contains("SupporterPassId = 0") -and
			$config.Contains("FiberColorPackPassId = 0") -and
			$config.Contains("HareFxPackPassId = 0") -and
			$config.Contains("MonetizationProducts = {")
	},
	@{
		Name = "Server creates monetization remotes"
		Ok = $server.Contains('local MonetizationRequestEvent = getOrCreateRemote("MonetizationRequestEvent")') -and
			$server.Contains('local MonetizationStateEvent = getOrCreateRemote("MonetizationStateEvent")')
	},
	@{
		Name = "Server uses MarketplaceService safely for passes"
		Ok = $server.Contains('local MarketplaceService = game:GetService("MarketplaceService")') -and
			$server.Contains("UserOwnsGamePassAsync") -and
			$server.Contains("PromptGamePassPurchase") -and
			$server.Contains("PromptGamePassPurchaseFinished")
	},
	@{
		Name = "Lobby has a cosmetic stand"
		Ok = $server.Contains('TD_CosmeticStand') -and
			$server.Contains('Config.MonetizationStandTitle') -and
			$server.Contains('Monetization.connectStand')
	},
	@{
		Name = "UI renders cosmetic shop panel and purchase actions"
		Ok = $ui.Contains('MonetizationStateEvent.OnClientEvent') -and
			$ui.Contains('MonetizationRequestEvent:FireServer') -and
			$ui.Contains('CosmeticShop') -and
			$ui.Contains('Config.MonetizationShopTitle')
	},
	@{
		Name = "README documents safe monetization direction"
		Ok = $readme.Contains("v1.1 Monetization Lite") -and
			$readme.Contains("no pay-to-win") -and
			$readme.Contains("Creator Dashboard")
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
	throw "Monetization Lite verification failed: $($failed -join ', ')"
}

Write-Host "Monetization Lite source contract passed."
