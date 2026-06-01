# v0.6.1 CPU Fill Match Design

## Goal

Let the match start and feel populated even when fewer than four human players are present.

## Direction

v0.6.1 uses server-owned CPU fill partners instead of fake Roblox players. CPU partners are visible court objects that can act as net endpoints, move toward useful tension spacing, and contribute light PIN timing. They are not meant to be strong opponents yet; they exist to protect the first 30 seconds from feeling empty.

## Behavior

- Each team still has two functional net slots.
- Human players always take priority.
- Missing slots are filled by CPU partners when `CpuFillEnabled` is true.
- CPU partners hide below the court when a team already has two human players.
- With one human on a team, the CPU partner moves to the opposite side of that human to create a readable Tension Fiber.
- With zero humans on a team, two CPU partners keep a playable net on that side and track the ball laterally.
- CPU partners show a `CPU` label so players understand they are not real teammates.
- CPU auto PIN is intentionally limited. It turns on near playable ball contact, and a solo human's held PIN can still pull the CPU partner into sync often enough to create HARE moments.

## Match Start

When CPU fill is enabled, `MinPlayersToAutoStart = 1` remains valid. A single player can enter and immediately play with one CPU teammate against two CPU opponents. If four humans join, CPU partners step aside automatically.

## Non-Goals

- No humanoid NPC navigation.
- No cosmetics, unlocks, or themed arenas.
- No skill difficulty system yet.
- No client-side CPU UI beyond world labels and existing match HUD.

## Verification

Source checks should confirm CPU fill config, visible CPU labels, CPU movement, CPU auto PIN, and match start messaging. Rojo build should continue to produce a valid place file.
