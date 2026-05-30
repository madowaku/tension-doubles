# Tension Doubles: Pinto Hare Roblox ver0.1

## Objective

Build and improve the Roblox ver0.1 MVP for `Tension Doubles: ピンとハレ！`: a 2v2 cooperative net-return sport where the visuals feel like physical sport, while ball, hit, and score judgment remain server-led and stable.

## Goal Kind

`specific`

## Current Tranche

Discover the current Rojo project state, choose the first safe verified implementation slice, implement it, verify it as far as local Roblox Lua tooling allows, and audit the slice against the ver0.1 goal.

The likely first tranche is not a full shipped game; it should make one reviewable improvement toward a playable Roblox Studio MVP while preserving the existing architecture.

## Non-Negotiable Constraints

- Keep the core design: visual net presentation via team attachments/Beam, with server-owned virtual net hit detection.
- Prefer stable server-led ball, score, and hit judgment over client-side physics spectacle.
- Preserve the current Rojo layout unless there is concrete evidence it blocks Roblox Studio import.
- Keep ver0.1 focused on playable core: court, teams, pin input, Beam net, server ball, virtual net hits, scoring, HUD, and fast restarts.
- Do not add ranking, monetization, skins, complex matchmaking, tournament mode, full bots, or cloth simulation in this tranche.
- Favor slow ball speed, generous hit radius, forgiving Hare timing, and clear feedback while tuning the first version.
- Treat `README.md`, `CODEX_NEXT_PROMPT.md`, `MANUAL_IMPORT.md`, `default.project.json`, and `src/` as current project evidence.

## Stop Rule

Stop when the tranche audit passes, all safe local work is blocked, or continuing would require Roblox Studio-only runtime evidence, credentials, destructive operations, or product strategy the board cannot decide.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated with bounded files and local verification.

## Canonical Board

Machine truth lives at:

`docs/goals/tension-doubles-pinto-hare-v01/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/tension-doubles-pinto-hare-v01/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Assign Scout, Judge, Worker, or PM according to the task.
5. Write a compact task receipt.
6. Update the board.
7. If Judge selected a safe Worker task with `allowed_files`, `verify`, and `stop_if`, activate it and continue unless blocked.
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the original Roblox ver0.1 outcome.
