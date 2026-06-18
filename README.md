# Tension Doubles: PINTO HARE! v0.6.0

Roblox prototype for a 2v2 co-op net sport.

## v1.0 Public Beta Candidate

v1.0 is the first public beta candidate for a friendly same-server 2v2 party sport. The beta promise is simple: players can enter a small lobby, choose Practice / Quick 2v2 / Friends, get CPU fill when short, understand RED and BLUE sides, and feel the Tension Fiber cooperation loop quickly.

The public beta keeps progression and cosmetics lightweight:

- local `leaderstats` records for Wins, HAREs, Best Rally, Team Syncs, and Title
- non-power Fiber cosmetics that never change hit strength
- late-join safety so new players wait for the next match instead of disrupting an active rally
- no global ranking, Ordered DataStore, monetization, or pay-to-win mechanics in this candidate

## Roblox Description Copy

Short description:

`A 2v2 co-op net sport. Move. Stretch. Hold PIN together. Sync with your partner for HARE!`

Full description:

`Tension Doubles: PINTO HARE! is a fast same-server 2v2 party sport about making a living Tension Fiber net with your teammate. Choose PRACTICE, QUICK 2v2, or play with friends, then stretch the Fiber, hold PIN together, and hit a HARE when your timing matches. CPU fill keeps empty slots playable while more players join. Track HAREs, Best Rally, Team Syncs, Wins, and lightweight titles. Cosmetics are non-power: they change the Fiber look, not your strength.`

## v0.6 direction

v0.6 focuses on the first 30 seconds:

- add a small lobby with PRACTICE / QUICK 2v2 / PRIVATE entries
- show `Move. Stretch. Hold PIN together.` before players commit
- show current lobby participants, a Practice vs Bots path, and a spectator area
- make the partner-net concept readable
- make PIN and HARE feel exciting
- show a clear landing target during rallies
- shorten score reasons for mobile readability
- keep the game party-sport flavored, not simulation-heavy

UGC spectacle, cosmetics, unlocks, and themed arenas are deferred to v0.7+.

## Player Progress Lite

v0.7 starts with light in-experience records before global rankings or skins. Roblox `leaderstats` now shows Wins, HAREs, Best Rally, Team Syncs, and Title so players can feel improvement through cooperation, not only win rate.

The first focus is HAREs, Best Rally, and Team Syncs. Ordered DataStore global rankings should wait until the local loop is clear and friendly.

Titles stay intentionally small: everyone starts as `Rally Starter`, the first HARE earns `HARE Rookie`, and repeated team syncs earn `Sync Partner`.

## Daily Boost Loop

The public beta now gives players one lightweight session goal in the lobby: hit 1 HARE and reach a 4-hit rally. Completing both awards a `Daily Boosts` leaderstat point for that server session and shows a short celebration. This is intentionally non-power and cooperative: it nudges players toward the signature loop without changing strength, HARE chance, or match balance.

## Fiber Skins

v0.8 starts with Fiber Color as a non-power cosmetic. The Tension Fiber subtly picks up color from lightweight titles: default white for `Rally Starter`, warm gold for `HARE Rookie`, and mint for `Sync Partner`. Warning states such as slack, over-tension, and broken fiber keep their readable gameplay colors.

## v1.1 Monetization Lite

The first monetization slice is deliberately no pay-to-win: Supporter Pass, Fiber Color Pack, and HARE FX Pack. These are Roblox passes, so create them in Creator Dashboard, copy each pass asset ID, then fill `SupporterPassId`, `FiberColorPackPassId`, and `HareFxPackPassId` in `GameConfig.lua`.

The lobby now has a small `COSMETIC SHOP` stand. If pass IDs are still `0`, the shop opens but purchase prompts stay disabled and show a setup message. Keep strength, serve power, CPU help, rally scoring, and HARE chance outside paid products.

## v0.5.3 focus

Serve balance. v0.5.2 fixed strong PIN returns, but the opening serve became too short and landed near the front of the opponent court.
This patch gives the serve its own speed, height, vertical lift, and lateral randomness so it lands deeper without making PIN returns too strong again.

## Manual import

Copy the scripts from `src/` into Roblox Studio using `MANUAL_IMPORT.md`, or use Rojo with `default.project.json`.

## Live preset

`GameConfig.lua` now uses one live preset switch:

```lua
LivePreset = "Solo"
```

Use `Solo`, `TwoPlayer`, or `FourPlayer`. Do not hand-edit `AllowGhostPartners`, `CpuFillEnabled`, or `MinPlayersToAutoStart`; the preset applies those together so live tests do not drift into unsafe mixed settings.

## Solo / 2-player / 4-player RC checks

v0.6 is still tuned for fast iteration, but the player-count expectations should be checked with the live preset before each run:

- **Solo:** use `LivePreset = "Solo"`. Ghost and CPU fill are enabled, and the match can start with one player.
- **2-player:** use `LivePreset = "TwoPlayer"`. Ghost and CPU fill stay enabled while each side learns the loop, and the match starts with two players.
- **4-player:** use `LivePreset = "FourPlayer"`. Ghost partners and CPU fill are disabled, and the match starts only with four humans.

For a real 4-player test:

```lua
LivePreset = "FourPlayer"
```

Before inviting testers, run `.\scripts\verify-live-preset.ps1 -ExpectedPreset FourPlayer` and `node scripts\verify-v06-guided-party.mjs`, then confirm the Studio HUD shows no CPU labels during the 4-player match.

## v0.6 RC checklist

Use [docs/playtests/v06-rc-checklist.md](docs/playtests/v06-rc-checklist.md) before treating v0.6 as a release candidate.

The most important mobile check is now: ball, Tension Fiber, landing target, and point reason must all remain readable at the same time.

## Tuning knobs

If serves are still too short, raise these in `GameConfig.lua`:

```lua
BallServeSpeed
ServeVerticalVelocity
ServeHeight
```

If serves go too deep or OUT, lower these slightly:

```lua
BallServeSpeed
ServeVerticalVelocity
```

PIN return tuning remains separate:

```lua
BallBaseSpeed
PowerBonusBothPin
PinMaxForwardSpeed
ReturnLiftNormal
```
