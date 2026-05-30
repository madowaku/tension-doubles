# v0.6 Release Candidate Hardening Design

## Goal

Prepare v0.6 as a first playable release candidate by improving the first 30 seconds, checking solo/2-player/4-player behavior, polishing mobile HUD readability, and documenting a repeatable RC verification path.

## Ordered Scope

The work proceeds in the requested order:

1. First 30 seconds playtest pass.
2. Solo, 2-player, and 4-player behavior checks.
3. Mobile HUD polish.
4. v0.6 release candidate documentation and verification.

## First 30 Seconds

The first 30 seconds should teach the core loop without a long tutorial:

- Players make a net with their partner.
- Tension Fiber changes state based on partner spacing.
- PIN is a held input.
- HARE is the team-sync payoff.
- Score reasons are short and readable.

Implementation should strengthen existing onboarding and HUD copy rather than adding a separate tutorial mode. The current lightweight `QuickTutorial`, `NetGuideLabel`, hit callouts, and score reason flow remain the primary teaching surfaces.

## Solo / 2 / 4 Behavior

v0.6 still defaults to solo-friendly testing with ghost partners:

- Solo: ghost partners keep the loop playable and allow local iteration.
- 2-player: each side may still use ghost support depending on config.
- 4-player: ghosts should be disabled for live testing through config.

The RC should not rewrite matchmaking. It should make the intended testing modes explicit and add checks/docs that prevent accidental confusion between solo prototype settings and 4-player live settings.

## Mobile HUD Polish

Mobile players need to see the ball, partner fiber, landing target, score, net guide, and PIN control. HUD polish should be conservative:

- Keep the PIN button clear of score and net guidance.
- Keep net guidance readable in landscape and portrait.
- Avoid hiding the ball with oversized messages.
- Keep HARE big, but not so large that it obscures the rally for too long.

## v0.6 Release Candidate

The RC should include a short manual playtest checklist and update the README so the next pass is reproducible:

- Source checks.
- Rojo build.
- Studio Play smoke test.
- First 30 seconds checklist.
- Solo/2/4 configuration checklist.
- Mobile landscape/portrait sanity checklist.

## Non-Goals

- No UGC spectacle, unlocks, cosmetics, themed arenas, ranking, or monetization.
- No heavy new tutorial mode.
- No matchmaking rewrite.
- No client-owned gameplay authority.
- No broad refactor of the server script.

## Acceptance Criteria

- Onboarding copy directly says players make a Tension Fiber net with a partner.
- HUD guidance and hit callouts still fit on mobile.
- Source checks cover the new RC teaching/verification strings.
- README explains solo, 2-player, and 4-player testing modes.
- A v0.6 RC checklist exists for repeatable manual playtests.
- `node scripts/verify-v06-guided-party.mjs` passes.
- `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx` passes.
- Studio Play starts without game Lua errors.
