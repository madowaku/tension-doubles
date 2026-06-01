# v0.6.1 CPU Fill Match Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visible CPU fill partners so matches can start and feel populated with one to three human players.

**Architecture:** Keep the server authoritative. Reuse the existing ghost partner table as CPU-capable net endpoints, add config-driven CPU visibility/movement/PIN behavior, and keep client UI changes minimal by relying on world labels and existing match-state payloads.

**Tech Stack:** Roblox Luau, Rojo, Node.js source verification.

---

### Task 1: RED Source Checks

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`

- [x] Add checks for `CpuFillEnabled`, `CpuFillLabelText`, `updateCpuFillPartners`, `updateCpuPinning`, and `TD_CPU_Label`.
- [x] Run `node scripts\verify-v06-guided-party.mjs`.
- [x] Confirm the command fails because the CPU fill symbols do not exist yet.

### Task 2: Config

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`

- [x] Add CPU fill knobs near the existing dev/testing ghost config.
- [x] Keep `MinPlayersToAutoStart = 1` while CPU fill is enabled.
- [x] Add copy for `CpuFillMatchSubMessage`.

### Task 3: Server CPU Fill

**Files:**
- Modify: `src/ServerScriptService/TDServer.server.lua`

- [x] Convert ghost partner creation into visible CPU fill parts when `CpuFillEnabled` is true.
- [x] Add `TD_CPU_Label` BillboardGui labels.
- [x] Replace `updateGhostPartners` with `updateCpuFillPartners` while preserving ghost fallback behavior.
- [x] Add `updateCpuPinning` and count CPU PIN in `getTeamPinInfo`.
- [x] Include CPU counts in match-state payloads for future HUD use.

### Task 4: Documentation And Verification

**Files:**
- Create: `docs/playtests/v061-cpu-fill-match.md`

- [x] Document expected solo, two-player, three-player, and four-player behavior.
- [x] Run `node scripts\verify-v06-guided-party.mjs`.
- [x] Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`.
- [x] Run `git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check`.
