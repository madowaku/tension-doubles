# v0.6 RC Playtest Checklist

Use this checklist before treating v0.6 as a release candidate.

## Source And Build

- Run `node scripts\verify-v06-guided-party.mjs`.
- Run `.\scripts\verify-live-preset.ps1 -ExpectedPreset FourPlayer` before 4-player live tests.
- Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- Start Roblox Studio Play and confirm the Output window has no game Lua errors.

## First 30 seconds

- Small lobby: confirm the PRACTICE, QUICK 2v2, and PRIVATE / FRIENDS pads are visible from spawn.
- Confirm spawn starts behind the mode pads and does not auto-select QUICK 2v2.
- Confirm the rule board says `Move. Stretch. Hold PIN together.`
- Confirm Practice vs Bots can be selected from the PRACTICE pad, then READY starts the existing CPU-fill loop.
- Confirm the participant count board updates as players join, leave, and ready up.
- Confirm the lobby spectator area is readable and does not block join pads.
- Confirm court selection reads as `OPTIONAL COURT THEME`, not as the required first action.
- Confirm the match court shows large `RED SIDE` and `BLUE SIDE` labels plus colored spawn rings.
- Confirm the onboarding says players make a Tension Fiber net with their partner.
- Confirm `FIBER SAG`, `TENSION OK`, and `HARE READY!` are readable without opening a long tutorial.
- Confirm the player can see the ball, the partner fiber, and the landing target during the first rally.
- Confirm the landing target turns urgent/red when the predicted ball path is OUT.
- Confirm score reasons use short copy such as `DROP!` and `OUT!`.

## Solo

- Use `LivePreset = "Solo"`.
- Confirm the match starts without waiting for four players.
- Confirm ghost and CPU fill support give useful net guidance.

## 2-player

- Use `LivePreset = "TwoPlayer"`.
- Confirm a real player plus ghost support can rally on each side as players join.
- Confirm `FIBER SAG`, `TENSION OK`, and `TOO TIGHT` still make sense when only some slots are real players.

## 4-player

- Use `LivePreset = "FourPlayer"`.
- Confirm two real players per team create the fiber.
- Confirm no CPU labels appear on the court or HUD.
- Confirm PIN/HARE requires team cooperation and does not rely on solo ghost behavior.

## Progress Lite

- Confirm Roblox leaderstats shows `Wins`, `HAREs`, `Best Rally`, and `Team Syncs`.
- Confirm leaderstats also shows `Title`, starting at `Rally Starter`.
- Confirm a HARE return increments `HAREs` and `Team Syncs` for the real players on that team.
- Confirm the first HARE changes `Title` to `HARE Rookie`, and repeated syncs can reach `Sync Partner`.
- Confirm `Best Rally` updates after a point ends and keeps the highest rally count.
- Confirm the winning team's real players gain `Wins` after match end.

## Fiber Skins

- Confirm the default Tension Fiber remains readable and white-forward.
- Confirm `HARE Rookie` gives the team's Fiber a subtle gold tint.
- Confirm `Sync Partner fiber` reads as a mint cosmetic tint without changing hit strength.
- Confirm slack, over-tension, and broken Fiber warning colors stay more readable than cosmetics.

## Mobile landscape

- Confirm the PIN button does not cover score, net guidance, or point reason.
- Confirm the ball, Tension Fiber, and landing target remain visible during serve and first return.
- Confirm `HARE!!`, the spark column, and the subtitle are exciting but do not hide the rally for too long.

## Mobile portrait

- Confirm the rotate hint appears when portrait play is detected.
- Confirm score, message, net guidance, and PIN button do not overlap.
- Confirm text fits inside its HUD areas.

## Release Candidate Notes

- Defer UGC spectacle, unlocks, cosmetics, themed arenas, ranking, and monetization to v0.7+.
- Keep v0.6 focused on clarity, party-sport feel, and the Tension Fiber core loop.

## v0.6 RC Lock: Smallest Owner Run

Do not mark v0.6 RC locked until every item below has owner evidence. Automated source contracts reduce setup mistakes, but Studio emulation does not replace the real-phone pass.

1. On a real phone in landscape, join with `LivePreset = "Solo"`. Confirm READY is immediately tappable, MODE/THEME stay secondary, MUSIC/SFX remain readable, the PIN hint fits inside the safe area, and no lobby control overlaps the PIN area.
2. In the same session, change MUSIC without changing SFX, then change SFX without changing MUSIC. Start and finish a match; confirm the values are retained when the player returns to the lobby in the same session.
3. Run the preset matrix and inspect `TensionDoublesStudioDiagnostics` while READY starts each match:
   - Solo: one client, CPU fill, practice rally.
   - TwoPlayer: two clients, CPU fill completes both sides.
   - FourPlayer: four clients, no CPU labels or ghost support.
4. In any preset, finish one match. Confirm results show HAREs, Best Rally, Team Syncs, and Slack Saves; return to the lobby; press READY again; and confirm the next match reaches FIBER CHARGE.
5. Confirm Output has no red game-script errors. External Roblox HTTP or plugin warnings are recorded separately and do not hide game-script failures.

Record the phone model, OS, orientation, preset, and pass/fail beside this checklist. A failed item is an RC blocker until reproduced or explicitly deferred.
