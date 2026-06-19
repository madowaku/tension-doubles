# v0.7 First Fun Loop Checklist

Use this checklist for the first v0.7 slice. Keep ball physics, scoring, CPU behavior, and HARE eligibility unchanged.

## Existing Fun Loop Surfaces

- Confirm Practice Wall still produces local PIN/HARE feedback without starting a match.
- Confirm GameOver still shows HAREs, Best Rally, Team Syncs, and Slack Saves.
- Confirm Wins, HAREs, Best Rally, Team Syncs, and Title still update through Progress Lite.

## FIRST HARE Celebration

1. Trigger a Practice Wall HARE, then start a real match. Confirm the Practice Wall HARE does not consume the celebration.
2. Earn the first real HARE for the local player's own team. Confirm `FIRST HARE!` and `YOUR FIRST TEAM SYNC!` appear.
3. Confirm the opposing team and spectators receive normal HARE text rather than the personalized celebration.
4. Earn another real HARE for the same team. Confirm the celebration appears only once per server session and the second real HARE uses normal HARE text.
5. Rejoin in a fresh server session and confirm the first eligible real HARE can celebrate again.

## Acceptance Criteria

- Only the first real-match HARE shows `FIRST HARE!` for an eligible player.
- The same player never sees it on their second or later real HARE in that server session.
- A Practice Wall HARE does not consume the first-HARE right.
- Another team's HARE does not consume the local player's first-HARE right.
- Existing `HARE!!`, combo HARE copy, speed, eligibility, scoring, and analytics remain intact.
- The existing HitFx Remote argument order remains compatible; the personalized flag is appended.
- Studio Play produces no red game-script errors.

## Regression Gate

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-first-hare-celebration.ps1`.
- Run the Practice Wall, Match Results, Progress Lite, Analytics Lite, and full verifier sets.
- Build with Rojo and confirm Studio Output has no red game-script errors.
