# Tension Fiber Material Design

## Decision

Tension Doubles uses an original material called **Tension Fiber** for the partner-held net.

Tension Fiber behaves like cloth when loose, like a sport net when properly stretched, and like a glowing reactive fiber when both partners PIN together. This keeps the fantasy readable while giving the game a clear cooperative skill: players must manage partner spacing and PIN timing together.

## Why This Material

Pure cloth/net rules create good positioning gameplay, but can feel punishing if players cannot return the ball while close together. Pure rubber is easy to understand, but it weakens the core idea because distance matters less.

Tension Fiber gives the best game shape:

- Close partners can still touch the ball, but the return is weak and readable as a mistake.
- Proper spacing creates a stable net and a satisfying normal return.
- Proper spacing plus synchronized PIN creates the signature HARE moment.
- The material can look fictional and expressive without needing realistic sports simulation.

## Core States

### Slack

Partners are too close, so the fiber sags and absorbs impact.

Gameplay:

- Ball can be returned, but with lower power and a softer arc.
- The opponent gets an easier next ball.
- This should teach players to move apart without instantly stopping the rally.

Feedback:

- Beam looks wavy or droopy.
- HUD copy: `MOVE APART`
- Hit callout: `SLACK!`

### Good Tension

Partners are at a useful distance, so the fiber becomes a stable playable net.

Gameplay:

- Ball returns clearly and reliably.
- This is the normal target state for first-time players.
- Players should be able to hold this state while tracking the ball.

Feedback:

- Beam is straight, bright, and team-colored.
- HUD copy: `GOOD NET`
- Hit callout: `HIT!`

### Over Tension

Partners are too far apart, so the fiber becomes unstable.

Gameplay:

- Return can still happen, but it becomes harder to control.
- It should feel risky rather than strictly better.
- This prevents players from always maximizing distance.

Feedback:

- Beam jitters or turns warning red.
- HUD copy: `TOO FAR`
- Hit callout: `TOO TIGHT!`

### HARE

Partners have good spacing and synchronize PIN, causing the fiber to briefly harden and flash.

Gameplay:

- HARE is the loudest and most exciting return.
- It should feel like a shared team success, not a solo button press.
- In v0.6, HARE should be forgiving enough that new players can experience it in the first 30 seconds.

Feedback:

- Fiber flashes gold.
- Ball gets stronger trail/glow.
- Brief hit-stop and camera kick.
- HUD callout: `HARE!!`

## Rule Philosophy

For v0.6, Tension Fiber should teach through gradients, not hard failure.

- Too close: weak but playable.
- Good: reliable and readable.
- Too far: risky and unstable.
- Good plus synchronized PIN: party payoff.

This keeps the game welcoming for Roblox players while preserving the unique cooperative depth.

## Implementation Notes

The current `Slack`, `Normal`, `OverTension`, and `Hare` states already map well to Tension Fiber. v0.6 should tune and present those states as material behavior rather than as abstract distance checks.

Likely implementation targets:

- `GameConfig.lua`: copy and tuning for Slack, Good Tension, Over Tension, and HARE.
- `TDServer.server.lua`: return strength and hit type by tension state.
- `TDUIClient.client.lua`: concise material-state HUD copy.
- Future visual pass: make the beam sag/jitter/flash according to Tension Fiber state.

## Out Of Scope

Do not add cosmetics, unlocks, skins, themed arenas, or UGC spectacle for this material yet. Those belong in v0.7+ after the core loop is clearer.

Do not make Slack or Over Tension instant-fail states in v0.6. The first version should let players learn through readable weak/risky returns.

## Acceptance Criteria

- New player can infer that partner distance changes the fiber state.
- Close partners see or feel a weak `SLACK!` return instead of an unexplained failure.
- Proper spacing is rewarded with a stable `GOOD NET` state.
- HARE reads as a special synchronized hardening of the fiber.
- The material fiction supports party-sport readability rather than realistic simulation.
