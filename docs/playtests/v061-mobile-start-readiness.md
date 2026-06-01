# v0.6.1 Mobile Start Readiness

Date: 2026-06-01

## Observation

- The mobile PIN control still showed `PIN` and `Hold` close enough to read as overlapping.
- CPU-filled matches started too quickly, leaving little time to understand the court before the serve.

## Changes

- Disabled the mobile PIN helper label by default with `ShowPinButtonHelper = false`.
- Added a short `Ready` state before the countdown using `PreMatchReadyTime`.
- Added ready-state HUD copy so players can find their spot before the serve.

## Recheck Focus

- Confirm the mobile PIN button shows only `PIN`.
- Confirm the match flow reads as `GET READY` -> `3, 2, 1` -> serve.
- Confirm the added pause feels like preparation, not waiting.
