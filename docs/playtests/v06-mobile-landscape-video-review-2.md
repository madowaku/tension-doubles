# v0.6 Mobile Landscape Video Review 2

Date: 2026-05-31

Source video: `Record_2026-05-31-07-42-26_080032403b0f3d7ce099ec68649d222a.mp4`

## Observed Issues

- The PIN button text and the `Hold` helper overlap in landscape. The helper is redundant because the button already says `PIN`.
- HARE produces a great moment, but the return still tends to become `OUT!`. It reads like a long powered shot instead of a smash.
- The bottom hint text remains visible through rallies and competes with the lower court edge.
- The ball, score, landing target, and net guide are readable. The core camera framing is now much closer than the previous video.

## Tuning Applied

- Hide the `Hold` helper label in landscape while keeping it available in portrait.
- Change HARE toward a lower, faster smash:
  - `PowerBonusHare 5 -> 8`
  - `ReturnLiftHare 0.52 -> 0.30`
  - `HareMaxForwardSpeed 44 -> 40`
- Fade the bottom input hint sooner and more strongly.

## Further Improvement Candidates

- If DROP points still chain too quickly, add a short serve/return assist for the first two rallies of a match.
- If the ball is still hard to read on real phones, add a thin outline ring or stronger ball trail instead of enlarging the ball again.
- If HARE still goes OUT, lower `ReturnLiftHare` to `0.24` before reducing speed further.
