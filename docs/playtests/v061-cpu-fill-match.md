# v0.6.1 CPU Fill Match

Date: 2026-06-01

## Goal

Make the game playable when fewer than four people are present.

## Expected Behavior

- 1 human: one visible CPU teammate and two visible CPU opponents fill the court.
- 2 humans: missing team slots are filled by CPU partners.
- 3 humans: only the final empty slot is filled by CPU.
- 4 humans: CPU partners hide and the match becomes full human doubles.

## Feel Target

- CPU partners should make a readable Tension Fiber, not play perfectly.
- CPU auto PIN should help HARE happen sometimes, especially when a solo human holds PIN.
- CPU partners should be visibly marked with `CPU` labels.

## Recheck Focus

- Confirm the match starts with one player.
- Confirm CPU parts are visible on phone landscape and do not block the ball.
- Confirm human players always replace CPU slots when they join.
- Confirm HARE still feels like a shared payoff, not a guaranteed CPU spam event.
