# Tension Doubles v0.6 RC Lock

## Objective

Lock v0.6 as a release candidate by proving the A+C lobby UI, Solo/TwoPlayer/FourPlayer presets, lobby-to-match-to-results-to-rematch loop, session audio controls, and clean Studio startup are stable enough for a focused mobile-device acceptance pass.

## Goal Kind

`audit`

## Current Tranche

Map existing RC evidence and gaps, choose and implement the first safe local hardening slice, run the complete automated and Studio verification set, produce the smallest owner-run mobile/preset/rematch script, and audit whether v0.6 can be marked RC or which exact evidence still blocks the lock.

## Non-Negotiable Constraints

- Do not add new gameplay features while locking v0.6.
- Do not change ball physics, CPU behavior, scoring, Tension Fiber behavior, arena themes, monetization, cosmetics, or rankings unless a verified RC blocker requires owner approval.
- Preserve all unrelated dirty-worktree changes and never revert user work.
- Treat real-phone layout evidence as owner-run evidence; do not claim device coverage from Studio emulation alone.
- Verify `LivePreset` behavior for Solo, TwoPlayer, and FourPlayer without weakening their existing contracts.
- Verify results, lobby return, READY gate, and next-match start as one replay loop.
- Session-only Music/SFX persistence is sufficient for v0.6; cross-session persistence is deferred unless the audit finds a blocker.
- Practice Wall, Match Results, and current local records are existing surfaces to verify, not expansion scope.
- First HARE celebration and any larger First Fun Loop work belong to v0.7 unless required to fix a release-blocking regression.

## Stop Rule

Stop when the tranche audit passes, every safe local RC hardening action is complete and only owner-run real-device evidence remains, all safe local work is blocked, or continuing would require credentials, destructive operations, or product strategy outside this board.

Do not stop after planning, discovery, or Judge selection when a bounded Worker task can still improve RC confidence.

## Canonical Board

Machine truth lives at:

`docs/goals/tension-doubles-v06-rc-lock/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/tension-doubles-v06-rc-lock/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

On every `/goal` continuation:

1. Read this charter.
2. Read `state.yaml`.
3. Work only on the active board task.
4. Assign Scout, Judge, Worker, or PM according to the task.
5. Write a compact task receipt.
6. Update the board.
7. If Judge selects a safe Worker task with `allowed_files`, `verify`, and `stop_if`, activate it and continue unless blocked.
8. Finish only with a Judge/PM audit receipt that maps preset, replay-loop, audio, mobile, Output, and build evidence to the RC outcome.
