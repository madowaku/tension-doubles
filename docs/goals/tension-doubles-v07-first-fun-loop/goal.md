# Tension Doubles v0.7 First Fun Loop

## Objective

Complete the first v0.7 fun-loop slice by adding a first-time-only `FIRST HARE!` celebration while preserving the already implemented Practice Wall, Match Results, and light player records.

## Goal Kind

`specific`

## Current Tranche

Implement and verify a per-player, per-server-session FIRST HARE celebration for real match HAREs, then audit the four First Fun Loop surfaces together without expanding gameplay scope.

## Non-Negotiable Constraints

- Do not change ball physics, scoring, CPU behavior, Tension Fiber timing, or HARE eligibility.
- Practice Wall HARE feedback must not consume the real-match FIRST HARE celebration.
- Each player sees FIRST HARE once per server session and only when their own team earns a real match HARE.
- Other players still see normal HARE feedback.
- Reuse the existing HitFx event and UI effect pipeline; do not add a new remote or DataStore.
- Preserve Practice Wall, Match Results, Progress Lite, titles, and analytics behavior.

## Stop Rule

Stop when the implementation and final audit pass, all safe local work is blocked, or owner input is required.

## Canonical Board

Machine truth lives at:

`docs/goals/tension-doubles-v07-first-fun-loop/state.yaml`

## Run Command

```text
/goal Follow docs/goals/tension-doubles-v07-first-fun-loop/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

## PM Loop

Read the charter and board, work only the active task, record a receipt, activate the next task, and finish only through the final audit.
