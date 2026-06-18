# Lobby Polish And Tutorial Board

## Objective

Finish direction A of the approved lobby-polish brief and translate the v1.0 launch-art HOW TO PLAY signboard into a native Roblox lobby board.

## Current Tranche

Keep the three-step lobby flow readable on mobile, keep READY visually dominant, keep audio/status UI out of the bottom control collision zone, add a non-player-blocking tutorial board, update source contracts and public-beta documentation, then run the smallest useful verification pass and push the result.

## Non-Negotiable Constraints

- `.superpowers/brainstorm/lobby-polish-20260618` direction A, as preserved in `tention.md`, is the HUD source of truth.
- `assets/launch-art/v10-lobby-how-to-play-signboard-1920x1080.png` is the tutorial-board visual/copy direction.
- Preserve the existing READY remote and match flow.
- Do not change ball physics, CPU behavior, scoring, Fiber gameplay, arenas, cosmetics, monetization, or rankings.
- The tutorial board must not block player movement.
- Verification should be the smallest source-contract plus Rojo build pass, leaving one concise Studio smoke check.

## Definition Of Done

- Direction-A HUD hierarchy is covered by a passing source contract.
- READY remains the dominant centered lobby action.
- The three-step guide stays above mobile controls and the audio stack stays top-right.
- A native HOW TO PLAY lobby board teaches move together, stretch the Fiber, and hold PIN together for HARE.
- The board is non-collidable/non-touching and public-beta docs name the smoke check.
- The Rojo build succeeds and the final audit passes.

## Canonical Board

Machine truth lives at `docs/goals/lobby-polish-tutorial-board/state.yaml`.
