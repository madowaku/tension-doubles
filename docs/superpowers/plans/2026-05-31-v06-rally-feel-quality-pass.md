# v0.6 Rally Feel Quality Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make v0.6 mobile rallies feel easier to read and sustain while keeping HARE exciting.

**Architecture:** Keep gameplay on the server. Add config knobs in `GameConfig.lua`, extend source checks in `scripts/verify-v06-guided-party.mjs`, update ball visuals and return velocity logic in `TDServer.server.lua`, and document the pass under `docs/playtests`.

**Tech Stack:** Roblox Luau, Rojo, Node.js source verification.

---

### Task 1: RED Checks

- [x] Add source checks for `EarlyRallyAssistHits`, `applyEarlyRallyAssist`, `TD_BallReadabilityHalo`, and `ReturnLiftHare = 0.24`.
- [ ] Run `node scripts\verify-v06-guided-party.mjs` and confirm it fails before implementation. Not repeated after resume because the implementation was already present.

### Task 2: Server Assist And Ball Readability

- [x] Add early rally assist and ball halo config.
- [x] Create `TD_BallReadabilityHalo` as a visual-only part that follows the ball.
- [x] Apply `applyEarlyRallyAssist` to non-HARE returns while rally count is low.
- [x] Lower HARE lift to `0.24`.

### Task 3: Verify And Document

- [x] Add a playtest note explaining the intended feel.
- [x] Run `node scripts\verify-v06-guided-party.mjs`.
- [x] Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- [x] Run `git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check`.
