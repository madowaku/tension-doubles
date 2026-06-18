# Tension Doubles v1.0 Public Beta Candidate

## Objective

Bring `Tension Doubles: PINTO HARE!` from the current v0.8-ish prototype state to a verified v1.0 public beta candidate.

The goal is not to make the largest possible game. The goal is to ship a coherent, readable, friendly Roblox experience where first-time players can enter a lobby, understand mode/court/team identity, play solo or same-server 2v2 with CPU fill, see cooperation records, enjoy non-power Fiber cosmetics, and pass a public beta readiness checklist.

## Current Tranche

Discover the remaining work across:

- v0.8 Fiber Skins and effects.
- v0.9 real 2v2 polish.
- v1.0 public beta launch readiness.

Then choose and execute the next safe verified implementation slice. Continue through safe slices until the board audit says the local v1.0 candidate is complete or blocked by unavailable Roblox Studio/runtime/publishing inputs.

## Non-Negotiable Constraints

- No pay-to-win or paid power.
- Keep cosmetics non-power and readability-preserving.
- Same-server play and CPU fill remain more important than full matchmaking.
- Do not add DataStore/global rankings before local leaderstats and loop clarity are stable.
- Avoid broad rewrites of `TDServer.server.lua` unless a smaller verified slice is impossible.
- Prefer source-contract verification, Rojo build, and Roblox Studio MCP observation when available.
- Do not claim public beta completion without a final audit mapping implementation and verification to launch readiness.

## v1.0 Definition Of Done

- v0.8 has at least one visible Fiber cosmetic lane beyond the current title-based Fiber tint, with warning readability preserved.
- v0.9 has safe local handling for mid-match joiners, disconnects, team readiness, and spectator clarity, or a documented blocker if Studio/live runtime is required.
- v1.0 has public beta docs/checklist, Roblox description copy, launch-facing thumbnail/icon prompt specs or placeholders, tutorial/onboarding checklist, and verification commands.
- Source contracts and Rojo build pass.
- The final board audit says complete and lists residual manual Studio checks.

## Canonical Board

Machine truth lives at:

`docs/goals/tension-doubles-v10-public-beta/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins.
