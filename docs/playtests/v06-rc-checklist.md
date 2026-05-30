# v0.6 RC Playtest Checklist

Use this checklist before treating v0.6 as a release candidate.

## Source And Build

- Run `node scripts\verify-v06-guided-party.mjs`.
- Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- Start Roblox Studio Play and confirm the Output window has no game Lua errors.

## First 30 seconds

- Confirm the onboarding says players make a Tension Fiber net with their partner.
- Confirm `FIBER SAG`, `TENSION OK`, and `HARE READY!` are readable without opening a long tutorial.
- Confirm the player can see the ball, the partner fiber, and the landing target during the first rally.
- Confirm the landing target turns urgent/red when the predicted ball path is OUT.
- Confirm score reasons use short copy such as `DROP!` and `OUT!`.

## Solo

- Use `AllowGhostPartners = true`.
- Use `MinPlayersToAutoStart = 1`.
- Confirm the match starts without waiting for four players.
- Confirm the ghost-supported fiber gives useful net guidance.

## 2-player

- Keep ghost support enabled for learning.
- Confirm a real player plus ghost support can rally on each side as players join.
- Confirm `FIBER SAG`, `TENSION OK`, and `TOO TIGHT` still make sense when only some slots are real players.

## 4-player

- Set `AllowGhostPartners = false`.
- Set `MinPlayersToAutoStart = 4`.
- Confirm two real players per team create the fiber.
- Confirm PIN/HARE requires team cooperation and does not rely on solo ghost behavior.

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
