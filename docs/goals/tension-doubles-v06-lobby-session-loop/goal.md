# Tension Doubles v0.6 Lobby & Session Loop

## Objective

Build the v0.6 small-lobby tranche that reduces first-time player anxiety before match depth: clear entrances, readable rules, easy Practice/Quick/Friends participation, CPU fill when short, spectators, and a simple post-match loop.

## Goal Kind

`specific`

## Current Tranche

Discover the current lobby/session code, choose the first safe implementation slice, implement it, verify it locally, and audit whether it gives players a small functional lobby with:

- `PRACTICE`: 1P + CPU.
- `QUICK 2v2`: players + CPU fill.
- `PRIVATE / FRIENDS`: play with friends in the same server.
- Rule board: `Move. Stretch. Hold PIN together.`
- Join pads or equivalent in-world entry points.
- Current participant count.
- Practice vs Bots entry.
- Spectator area.
- End-of-match return to lobby or immediate rematch.

This tranche is not full matchmaking, global ranking, monetization, skins, or persistent progression. It should use the current Roblox server-local session model and existing CPU fill path wherever possible.

## Roadmap Context

v0.7 should prioritize player progress lite before skins:

- Wins
- Total HAREs
- Best Rally
- Team Syncs
- Lightweight titles such as `HARE Rookie`, `Sync Partner`, and `Rally Starter`

v0.8 can add non-power cosmetics, with Tension Fiber identity first:

- Fiber Color
- Ball Trail
- HARE hit text style
- Victory Pose
- Court Theme later

v0.9 should polish real 2v2 operations:

- Mid-session join handling
- AFK handling
- CPU takeover on disconnect
- Team auto-balance
- Spectator UI

v1.0 public beta should cover store-facing and launch-readiness work:

- Thumbnail and icon
- Description
- Finished tutorial
- Analytics review
- Public test

## Non-Negotiable Constraints

- Keep v0.6 focused on small lobby and session clarity, not full matchmaking.
- Same-server play matters more than global queues.
- Players who step onto pads can join; short teams are filled with CPU.
- Four available humans should be able to start a 2v2.
- Mid-match joiners should wait for the next match unless an already-safe local path exists.
- The lobby is a reassurance space: rules, entry choice, current count, practice path, and spectator affordance should be visible.
- Reuse existing `LivePreset`, court selection, lobby ready, CPU fill, and post-match return systems when possible.
- Keep gameplay authority on the server.
- Do not add paid power, pay-to-win skins, heavy assets, or global rankings in this tranche.
- Prefer source-contract scripts, Rojo build, and Studio Play/log observation before claiming completion.

## Stop Rule

Stop when the tranche audit passes, every safe local next action is blocked, or continuing would require owner input, credentials, destructive operations, unavailable Studio runtime control, or product strategy beyond this lobby/session tranche.

Do not stop after planning, discovery, or Judge selection if a safe Worker task can be activated with bounded files and verification.

## Canonical Board

Machine truth lives at:

`docs/goals/tension-doubles-v06-lobby-session-loop/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/tension-doubles-v06-lobby-session-loop/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
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
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the small-lobby/session-loop outcome.
