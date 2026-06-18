# v1.0 Public Beta Checklist

Use this checklist before treating v1.0 as a public beta candidate.

## Source And Build

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-v10-public-beta.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-v09-session-safety.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-fiber-skins.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-progress-lite.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-lobby-ready.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-studio-diagnostics.ps1`.
- Run `node scripts\verify-v06-guided-party.mjs`.
- Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- Start Roblox Studio Play and confirm Output has no game Lua errors.

## Launch Metadata

- Confirm README has Roblox Description Copy.
- Short description: `A 2v2 co-op net sport. Move. Stretch. Hold PIN together. Sync with your partner for HARE!`
- Confirm the full description mentions Practice, Quick 2v2, friends, CPU fill, HAREs, Best Rally, Team Syncs, and non-power cosmetics.
- Confirm public-facing copy does not imply paid power, global matchmaking, or persistent global ranking.

## Thumbnail And Icon Specs

- Thumbnail prompt: `Bright Roblox sports scene on a wide stylized doubles court, two red-side players and two blue-side players stretching a glowing Tension Fiber net, a readable ball arcing high above center court, energetic HARE spark, friendly party-sport mood, clear RED and BLUE team colors, no cluttered text.`
- Icon prompt: `Clean square Roblox game icon for Tension Doubles: PINTO HARE!, glowing crossed Tension Fiber strands around a bright ball, red and blue team accents, bold readable silhouette, no small UI text.`
- Placeholder acceptance: icon and thumbnail may remain prompt specs for this local candidate, but upload-ready art must preserve ball/Fiber/team readability.
- Reject thumbnails that hide the actual court, overuse dark blur, or make PIN/HARE look like a power purchase.

## Tutorial Completion

- First 30 seconds: confirm players can read the lobby mode choice, rule board, participant count, READY step, and optional court theme.
- Confirm the first-run onboarding explains that teammates make a Tension Fiber net together.
- Confirm the native `HOW TO PLAY` lobby board reads: move with your partner, stretch the Fiber, and hold PIN together for HARE; walk through its position to confirm it never blocks the player.
- On mobile landscape, confirm the active three-step guide remains readable above the bottom controls, READY is the dominant action, and MUSIC/SFX stay in the top-right stack.
- Confirm solo Practice starts with CPU fill and teaches PIN/HARE without requiring four humans.
- Confirm 2-player play still makes sense with CPU fill support.
- Confirm 4-player play clearly shows two real players per team with no CPU labels in `FourPlayer` preset.
- Confirm replay after match returns players to lobby or restarts through the READY gate without stale serve labels.

## Late Join Safety

- Confirm a player who joins during an active rally stays in the lobby/spectator state.
- Confirm the late joiner sees that they are queued for the next match.
- Confirm the current rally and teams are not disrupted by the late join.
- Confirm queued players can join normal team play after the match returns to lobby.

## AFK Safety

- Confirm lobby READY is cleared after inactivity instead of starting a match with an absent player.
- Confirm a stale PIN hold is released by the server after the configured timeout.
- Confirm AFK safety does not kick players, punish players, or replace active humans with CPU mid-rally.

## HARE Hit Text Styles

- Confirm the first HARE still reads `HARE!!`.
- Confirm combo HARE feedback can show `DOUBLE HARE!!`.
- Confirm longer combo HARE feedback can show `HARE STREAK!!`.
- Confirm HARE hit text styles do not change scoring, ball speed, or title progression.

## Analytics Review

- In Studio Play, inspect `ReplicatedStorage/TensionDoublesAnalytics` for Analytics Lite counters: `LobbyEntered`, `PracticeStarted`, `FirstREADY`, `FirstPIN`, `FirstHARE`, and `MatchCompleted`.
- Confirm `LobbyEntered` increments when a player joins, `FirstPIN` increments on the first PIN hold per player, `FirstHARE` increments when a player first participates in a HARE, and `MatchCompleted` increments at GameOver.
- Use Roblox Creator Analytics after public testing to review retention, average session length, and match starts.
- Track whether players reach first READY, first rally, first HARE, and first completed match through available Creator Analytics/event proxies.
- Compare HAREs, Best Rally, Team Syncs, and Wins from local `leaderstats` during live tests.
- If retention drops before match starts, prioritize lobby/tutorial clarity before skins.
- If players start matches but rarely score HAREs, tune PIN/HARE instruction and feedback before adding global rankings.

## Studio Diagnostics

- In Studio Play, inspect `ReplicatedStorage/TensionDoublesStudioDiagnostics`; it should exist only when `StudioDiagnosticsEnabled` is true and Studio is running.
- Confirm `LivePreset`, `State`, `QueuedSpectators`, `LobbyReadyPlayers`, and `LobbyNeededPlayers` update during Solo, TwoPlayer, FourPlayer, READY, and late-join tests.
- Confirm `AnalyticsCounters` mirrors the current `ReplicatedStorage/TensionDoublesAnalytics` counters without adding UI, DataStore, HTTP, or gameplay telemetry.
- To disable the surface for non-diagnostic builds, set `StudioDiagnosticsEnabled = false` in `GameConfig.lua` and confirm the diagnostics folder is not recreated.

### Smallest manual Studio test

1. Set `LivePreset = "Solo"`, emulate mobile landscape, and Play with one client. Confirm the native `HOW TO PLAY` board is readable and non-blocking, the guide stays above bottom controls, MUSIC/SFX remain top-right, and READY is the dominant action. Press READY, then inspect `ReplicatedStorage/TensionDoublesStudioDiagnostics`: `LivePreset=Solo`, `State` leaves lobby flow, `LobbyReadyPlayers=1`, `LobbyNeededPlayers=1`, and `AnalyticsCounters.FirstREADY=1`.
2. Set `LivePreset = "TwoPlayer"`, Start Server with two clients, press READY on both, then confirm `LivePreset=TwoPlayer`, `LobbyReadyPlayers=2`, `LobbyNeededPlayers=2`, and `AnalyticsCounters.LobbyEntered=2`.
3. Set `LivePreset = "FourPlayer"`, Start Server with four clients, press READY on all four, then join a fifth client during the match and confirm `LivePreset=FourPlayer`, `QueuedSpectators=1`, `LobbyReadyPlayers=4`, `LobbyNeededPlayers=4`, and `State` stays on the current match flow.

## Public Test Plan

- Test `LivePreset = "Solo"` with one player: Practice starts, CPU fill appears, and first HARE is understandable.
- Test `LivePreset = "TwoPlayer"` with two players: same-server cooperation works with CPU fill.
- Test `LivePreset = "FourPlayer"` with four players: no CPU labels appear and RED/BLUE sides remain obvious.
- Test a late join during an active rally: the new player waits for the next match and the current rally continues.
- Test mobile landscape and portrait for HUD overlap, READY button readability, PIN button readability, and ball/Fiber visibility.

## Known Deferrals

- Ordered DataStore global rankings are deferred until local records and public beta retention are understood.
- Full matchmaking, private invite routing, monetization, and paid cosmetics are deferred.
- Court Theme asset expansion is deferred beyond the existing optional court themes.
- Victory Pose and deeper Ball Trail cosmetics can follow after session stability.
- No pay-to-win mechanics are allowed; cosmetics must stay non-power.
