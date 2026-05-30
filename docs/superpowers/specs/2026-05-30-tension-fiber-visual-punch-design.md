# Tension Fiber Visual Punch Design

## Goal

Make Slack sag and HARE hardening more visible in v0.6 without adding UGC spectacle, cosmetics, or heavy particle systems.

## Direction

Use the existing server-owned Beam, ball visuals, and shockwave helper. The effect should read clearly on mobile and reinforce the Tension Fiber material rules:

- Slack: the fiber is loose, sagging, and absorbing impact.
- HARE: the fiber hardens, flashes gold, and launches the ball as a shared team payoff.

## Slack Visuals

Slack should look more obviously wrong but still playable.

- Increase beam sag through a larger curve.
- Make the beam narrower and more transparent.
- Keep the color cool blue so players read it as weak/loose.
- On a Slack hit, spawn a small blue ripple at the contact point to show energy getting absorbed.

## HARE Visuals

HARE should feel like the fiber briefly locks into a hard glowing rail.

- Make the HARE beam thicker and more opaque.
- Add a second gold hardening ring on HARE hit, separate from the existing shockwave.
- Make HARE ball glow/trail a little stronger.
- Preserve the current short hit-stop and camera kick.

## Constraints

- Do not add unlocks, cosmetics, themed arenas, or monetization hooks.
- Do not flood the screen with effects.
- Keep the server authoritative for shared visuals.
- Keep changes scoped to config, server visual behavior, source checks, and the implementation plan.

## Acceptance Criteria

- Slack beam visibly sags more than before.
- Slack hit creates a small blue absorbed-impact ripple.
- HARE beam is visibly thicker/harder than normal tension.
- HARE hit creates the existing shockwave plus a distinct hardening ring.
- Normal gameplay still builds and starts in Studio without Lua errors.
