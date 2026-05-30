# Tension Doubles: PINTO HARE! v0.6.0

Roblox prototype for a 2v2 co-op net sport.

## v0.6 direction

v0.6 focuses on the first 30 seconds:

- make the partner-net concept readable
- make PIN and HARE feel exciting
- shorten score reasons for mobile readability
- keep the game party-sport flavored, not simulation-heavy

UGC spectacle, cosmetics, unlocks, and themed arenas are deferred to v0.7+.

## v0.5.3 focus

Serve balance. v0.5.2 fixed strong PIN returns, but the opening serve became too short and landed near the front of the opponent court.
This patch gives the serve its own speed, height, vertical lift, and lateral randomness so it lands deeper without making PIN returns too strong again.

## Manual import

Copy the scripts from `src/` into Roblox Studio using `MANUAL_IMPORT.md`, or use Rojo with `default.project.json`.

## Solo test

`GameConfig.lua` still defaults to solo-friendly testing:

```lua
AllowGhostPartners = true
MinPlayersToAutoStart = 1
```

For a real 4-player test:

```lua
AllowGhostPartners = false
MinPlayersToAutoStart = 4
```

## Tuning knobs

If serves are still too short, raise these in `GameConfig.lua`:

```lua
BallServeSpeed
ServeVerticalVelocity
ServeHeight
```

If serves go too deep or OUT, lower these slightly:

```lua
BallServeSpeed
ServeVerticalVelocity
```

PIN return tuning remains separate:

```lua
BallBaseSpeed
PowerBonusBothPin
PinMaxForwardSpeed
ReturnLiftNormal
```
