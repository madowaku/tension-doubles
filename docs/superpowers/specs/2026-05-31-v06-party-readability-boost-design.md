# v0.6 Party Readability Boost Design

## Goal

Improve the first playable v0.6 loop by making the next landing target visible, making HARE feel more explosive, and making score reasons easier to read during quick mobile rallies.

## Ordered Scope

1. Add a server-owned landing target marker.
2. Add one more layer of HARE spectacle.
3. Polish score reason readability.
4. Update source checks and playtest notes.

## Landing Target Marker

The marker is a lightweight neon ring on the court floor. The server estimates where the active ball will land or leave the court and moves the ring there during rallies. If the ball is predicted to land in court, the ring uses a friendly yellow/white look. If the ball is predicted to go out, it shifts red and sits near the predicted out edge. This keeps gameplay authority on the server and gives mobile players a clear "move here" target.

## HARE Spectacle

HARE already has shockwaves, a hardening ring, camera shake, and HUD text. This pass adds a short vertical spark column at contact and lets the client use a punchier HARE subtitle. The effect should be exciting without hiding the rally for long.

## Score Readability

Score reasons remain short, but the point message should give a slightly more readable party-sport result. The HUD keeps `DROP!`, `OUT!`, and `HARE POINT!`, while adding a short configurable sub-message after points.

## Non-Goals

- No cosmetics, unlocks, UGC spectacle, themed arenas, ranking, monetization, or matchmaking.
- No client-owned hit, score, or ball authority.
- No broad rewrite of `TDServer.server.lua`.

## Acceptance Criteria

- A named `TD_LandingTargetMarker` exists and updates during active rallies.
- The marker uses a red/out state when predicted landing is outside the playable arena.
- HARE contact spawns a named vertical spark effect.
- Score/HUD copy remains config-driven and mobile-readable.
- Source checks cover the marker, HARE spark, and RC checklist additions.
- `node scripts/verify-v06-guided-party.mjs` passes.
- `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx` passes.
