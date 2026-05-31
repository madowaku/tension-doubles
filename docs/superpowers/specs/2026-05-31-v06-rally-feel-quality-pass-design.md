# v0.6 Rally Feel Quality Pass Design

## Goal

Improve the moment-to-moment mobile rally feel before public testing by making early rallies easier to sustain, making the ball easier to track, and making HARE feel like a fast low smash rather than a long OUT-prone lob.

## Scope

- Add early-rally assist for the first touch or two of each rally.
- Add stronger ball readability without making the ball itself huge.
- Keep HARE powerful but lower and more court-safe.
- Add lightweight documentation and source checks for the new tuning knobs.

## Design

The server remains authoritative for ball movement, hit detection, scoring, and assists. A new early-rally assist applies only while `rallyHitCount` is below a small threshold. It trims forward speed and adds a small lift floor so first returns do not instantly DROP or fly OUT. HARE keeps its high power bonus but has a lower lift and stricter forward cap.

Ball readability improves through visual-only settings on the existing server-created ball: brighter glow, longer trail, and a small non-colliding ring/halo attached to the ball. This avoids changing hitboxes.

## Non-Goals

- No matchmaking, monetization, cosmetics, or UGC work.
- No client-owned ball physics.
- No broad rewrite of `TDServer.server.lua`.

## Acceptance Criteria

- Config exposes early rally assist knobs.
- Server applies assist before final return velocity is assigned.
- Ball has a named visibility halo or equivalent visual-only readability aid.
- HARE remains configured as a lower smash (`ReturnLiftHare` at or below `0.24`).
- Source checks and Rojo build pass.
