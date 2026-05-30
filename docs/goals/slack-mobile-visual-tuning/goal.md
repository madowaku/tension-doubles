# Slack Mobile Visual Tuning

## Objective

Observe the current Slack state in Roblox Studio, judge whether the blue absorb ripple and sagging Tension Fiber are readable enough for mobile players, then complete the first safe verified tuning slice if needed.

## Goal Kind

`specific`

## Current Tranche

Create a safe observation-first loop for the current Slack/HARE visual punch work: inspect current source and Studio runtime behavior, decide whether `SlackAbsorbRippleSize`, `BeamCurveSlack`, or nearby mobile readability settings need adjustment, implement the smallest safe tuning slice, verify it locally and in Studio as far as MCP allows, and audit whether mobile readability improved.

This tranche is not a full mobile redesign. It is focused on Slack readability and immediate Tension Fiber feedback.

## Non-Negotiable Constraints

- Keep the project direction: party sport first, competitive clarity second.
- Preserve the Tension Fiber material model: Slack is weak but playable; HARE is hardened and exciting.
- Prioritize mobile readability: the ball, partner net, landing target, score reason, and PIN/HARE feedback should remain visible.
- Keep shared gameplay and visual authority on the server where the current code already owns it.
- Do not add UGC spectacle, cosmetics, themed arenas, monetization, or unlock systems.
- Do not introduce heavy particle systems, large assets, or visual clutter that hides the ball.
- Prefer config-only tuning when that is enough.
- Use Rojo build and Studio Play/log observation before claiming the slice is done.

## Stop Rule

Stop when a final audit says this tranche is complete, every safe local next action is blocked, or continuing would require human-only mobile device testing, product direction beyond this tranche, credentials, destructive operations, or unavailable Studio runtime control.

Do not stop after planning if a safe Worker task can be activated with bounded files and verification.

## Canonical Board

Machine truth lives at:

`docs/goals/slack-mobile-visual-tuning/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/slack-mobile-visual-tuning/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
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
8. Finish only with a Judge/PM audit receipt that maps receipts and verification back to the Slack/mobile readability outcome.
