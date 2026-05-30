# Changelog - v0.5.3 Serve Balance Patch

- Fixed weak opening serves after the v0.5.2 return-balance changes.
- Added separate serve-only tuning values in `GameConfig.lua`:
  - `ServeStartZ`
  - `ServeVerticalVelocity`
  - `ServeLateralMax`
- Increased `BallServeSpeed` from 26 to 37.
- Serve now lands closer to opponent mid-court instead of dropping near the front edge.
- PIN/HARE return balance from v0.5.2 is kept separate and unchanged.
