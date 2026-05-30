# v0.6 Party Readability Observation

Date: 2026-05-31

## Studio Play Smoke

- Studio instance: `緊張がピントハレを2倍にする`
- Local player count: 1
- Config: solo-friendly ghost partners enabled

## Observations

- `TD_LandingTargetMarker` appears during active rallies with transparency around `0.28`.
- The marker hides below the world when the ball is inactive, during point messages, and during serve setup.
- HUD simultaneously showed score, point reason, `Track the ball!`, and `TENSION OK`.
- Holding PIN before serve produced `HARE READY!`.
- HARE contact spawned `TD_HareSparkColumn`, `TD_HareHardeningRing`, and `TD_HareShockwave`.

## Tuning Applied

- Added a short client-side hold window for `HareSubtitleText` so frequent rally guidance broadcasts do not erase `TEAM SYNC!` immediately.
- Reduced HARE forward power slightly (`PowerBonusHare` and `HareMaxForwardSpeed`) after the first observed HARE return scored as `OUT!`.

## Recheck

- Re-ran Studio Play with PIN held before serve.
- Confirmed `TEAM SYNC!` remained visible across multiple rally guidance broadcasts during the HARE moment.
- Confirmed `TD_HareSparkColumn` and `TD_HareHardeningRing` were visible during the same moment.
- Confirmed the landing target stayed visible during active rallies and hid during point/serve transitions.

## Follow-Up

- Run one real mobile landscape session before final v0.6 release tagging.
