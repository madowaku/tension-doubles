# Tension Doubles: PINTO HARE! v0.6 Guided Party Slice Design

## Goal

v0.6 improves the first 30 seconds of play so Roblox players quickly understand the core fantasy:

- players make a net with their partner
- PIN and HARE feel exciting and readable
- scoring reasons are clear at a glance
- mobile players can see the ball, partner, and play direction
- the match feels like a party sport, not a serious simulator

The direction is 60% first-time clarity and 40% party energy. v0.6 does not include UGC spectacle work such as unlocks, cosmetics, themed arenas, ranking, or monetization.

## Product Direction

The main v0.6 approach is **Guided Party Slice**. It keeps the existing server-authoritative match loop and adds guidance and feedback around it.

The intended first 30 seconds:

1. **0-5s: Find Your Partner**  
   Players spawn with team color, a partner cue, and short copy that implies "you and your partner make the net."

2. **5-12s: Make A Net**  
   The team Beam is visually emphasized. The game communicates whether partner spacing is usable with short states: `SLACK`, `GOOD`, or `TOO FAR`.

3. **12-20s: Hold PIN**  
   PIN input gives immediate visual feedback through rings, beam charge, HUD text, and partner-sync framing.

4. **20-26s: HARE Moment**  
   HARE is the biggest party payoff: stronger trail/color, brief hit-stop, a short camera kick, a large callout, and rally/combo feedback.

5. **26-30s: Read The Point**  
   The score moment shows a short reason such as `DROP!`, `OUT!`, `TOO FAR!`, or `HARE POINT!`, then clears quickly for the next serve.

Design rule: every loud moment should teach something: where the partner is, where the ball is going, why PIN mattered, or why the point happened.

## Existing Architecture

Keep the current Rojo layout and script ownership:

- `src/ServerScriptService/TDServer.server.lua` owns teams, court setup, server ball simulation, virtual-net hit detection, hit type, scoring, and match state broadcast.
- `src/ReplicatedStorage/TDShared/GameConfig.lua` owns tuning values and user-facing short copy.
- `src/ReplicatedStorage/TDShared/MathUtil.lua` stays as shared math support.
- `src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua` owns input mapping and mobile PIN button.
- `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua` owns HUD, onboarding text, score, hit callouts, and mobile layout.
- `src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua` owns camera framing and hit camera feedback.

Do not move ball authority or scoring to clients. Client changes should be display-only or input-only.

## Feature Design

### Partner Net Guidance

Add concise guidance so players understand the partner-net idea without a full tutorial.

Server responsibilities:

- Continue computing team net endpoints and tension state.
- Include enough team/tension information in match state payloads for HUD display.
- Send guidance through the existing match-state payload unless implementation shows a separate event would be simpler. The HUD needs the player's team net state as `Slack`, `Normal`, `OverTension`, or `Broken`.

Client responsibilities:

- Show a compact status near the main HUD: `MAKE A NET`, `GOOD NET`, `TOO FAR`, or `MOVE APART`.
- Keep copy short and mobile-readable.
- Avoid persistent instruction walls.

### PIN Charge Feedback

PIN should feel like charging the shared net.

Server responsibilities:

- Keep current `PinInputEvent` flow.
- Preserve `GhostMirrorsPinning` for solo testing.
- Ensure hit FX distinguishes normal PIN, one PIN, and HARE.

Client responsibilities:

- Make PIN state visually obvious through button/ring styling.
- Use stronger HUD callouts for `ONE PIN`, `PIN`, and `HARE`.
- Keep desktop and mobile inputs aligned with existing controls.

### HARE Moment Upgrade

HARE should be the signature party moment.

Server responsibilities:

- Continue firing `HitFxEvent` with `fxType = "Hare"`, team, rally count, and combo count.
- Keep HARE timing generous enough for mobile and solo tests.
- Keep HARE powerful but not an automatic OUT.

Client responsibilities:

- Add/strengthen HARE callout text.
- Use brief camera kick and screen emphasis through `TDCameraClient`.
- Make ball feedback visibly stronger through color/trail that already comes from server-owned ball visuals.
- Keep hit-stop short so the match still feels fast.

### Readable Scoring Reasons

Point reasons must be understandable in one glance.

Server responsibilities:

- Replace verbose scoring strings with short reason tokens where possible.
- Preserve enough information for debugging and future analytics through code-side reason names.

Client responsibilities:

- Display score reason in a large short message.
- Avoid long phrases that wrap poorly on mobile.

Suggested display vocabulary:

- `DROP!`
- `OUT!`
- `TOO FAR!`
- `HARE POINT!`
- `RALLY xN`

### Mobile Visibility Pass

Mobile should show the ball, partner, net, and point reason without clutter.

Server responsibilities:

- Keep ball size and trail tuning configurable.
- Keep match state payload compact.

Client responsibilities:

- Adjust HUD positions and text sizes for portrait and landscape.
- Keep PIN button away from score and point reason.
- Prefer shorter hints on small screens.
- Tune camera height, distance, and FOV so the partner/net line and ball path are visible.

## Out Of Scope For v0.6

- Unlocks
- Cosmetics
- Themed arenas
- UGC reward loops
- Ranking or matchmaking
- Monetization
- Full tutorial mode
- Complex bots
- Rewriting the physics or networking model

These are v0.7+ candidates after the core loop is clearer and more fun.

## Data Flow

1. Player input goes through `TDInputClient` to `PinInputEvent`.
2. `TDServer` updates pin state, team beam state, ball hits, HARE detection, scoring, and match state.
3. `MatchStateEvent` updates HUD score, phase, and guidance copy.
4. `HitFxEvent` drives client-side callouts and camera feedback.
5. Server-owned ball visuals provide shared ball readability in Studio and live play.

## Testing And Verification

Minimum verification for v0.6:

- Rojo project builds successfully with `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- Roblox Studio play starts without Lua errors.
- First rally produces visible serve, return, score reason, and next serve.
- Mobile layout sanity is checked in portrait and landscape Studio/device emulation if available.
- HARE/OnePin/normal hit feedback remains distinguishable.
- Scoring reasons are readable and do not overlap score or PIN controls.

Runtime playtest checklist:

- First-time player can infer "stand with partner to make the net."
- PIN has immediate visible feedback.
- HARE is the loudest moment.
- Ball remains visible during serve and first return.
- Score reason is understandable within one second.
- No new errors appear in Studio Output.

## Implementation Shape

Prefer small slices:

1. Add server state/reason payload improvements.
2. Update HUD guidance and scoring reason display.
3. Strengthen PIN/HARE feedback.
4. Tune mobile HUD/camera visibility.
5. Run Studio playtest and adjust config values.

Each slice should keep files bounded and avoid unrelated refactors.
