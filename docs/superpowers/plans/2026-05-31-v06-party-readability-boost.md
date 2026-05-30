# v0.6 Party Readability Boost Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a visible landing target, punchier HARE feedback, and clearer point readability for the v0.6 first-30-seconds loop.

**Architecture:** Keep gameplay authority server-side. Add config knobs in `GameConfig.lua`, create/update visual parts in `TDServer.server.lua`, use existing `HitFxEvent` and HUD paths in `TDUIClient.client.lua`, and extend the source verification script.

**Tech Stack:** Roblox Luau, Rojo project layout, Node.js source checks.

---

### Task 1: Source Check RED

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Add assertions for the new strings**

Add checks for `TD_LandingTargetMarker`, `predictBallLanding`, `LandingTargetOutColor`, `TD_HareSparkColumn`, `HareSubtitleText`, and checklist text `landing target`.

- [ ] **Step 2: Run source check and confirm RED**

Run: `node scripts\verify-v06-guided-party.mjs`

Expected: FAIL because production code does not yet contain the new marker and HARE spark strings.

### Task 2: Landing Target Marker

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/ServerScriptService/TDServer.server.lua`

- [ ] **Step 1: Add config knobs**

Add marker color, size, transparency, prediction horizon, and update interval settings.

- [ ] **Step 2: Add server visual helpers**

Create a non-colliding neon cylinder named `TD_LandingTargetMarker`, calculate predicted landing from current ball position and velocity, and update it while `roundActive` is true.

- [ ] **Step 3: Hide the marker outside active rallies**

Move the marker below the world when the ball is inactive, points are scored, or waiting/game over states run.

### Task 3: HARE Spectacle

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/ServerScriptService/TDServer.server.lua`
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`

- [ ] **Step 1: Add HARE spark config**

Add `HareSparkColumnHeight`, `HareSparkColumnWidth`, `HareSparkColumnDuration`, and `HareSubtitleText`.

- [ ] **Step 2: Spawn a named HARE spark**

On HARE contact, spawn a vertical neon cylinder named `TD_HareSparkColumn` and fade it with `TweenService`.

- [ ] **Step 3: Use the subtitle**

When the client receives `Hare`, show the config-driven subtitle briefly.

### Task 4: Score Readability and Docs

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `docs/playtests/v06-rc-checklist.md`
- Modify: `README.md`

- [ ] **Step 1: Keep point copy short**

Ensure score reasons remain short and point sub-message is config-driven.

- [ ] **Step 2: Add checklist coverage**

Add playtest checks for landing target visibility, out-state readability, HARE spark readability, and score reason readability.

### Task 5: Verify

**Files:**
- No production edits unless verification finds an issue.

- [ ] **Step 1: Run source checks**

Run: `node scripts\verify-v06-guided-party.mjs`

Expected: PASS.

- [ ] **Step 2: Build with Rojo**

Run: `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`

Expected: PASS.

- [ ] **Step 3: Check whitespace**

Run: `git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check`

Expected: no whitespace errors.
