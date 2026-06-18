# Lobby UI Hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make READY the obvious lobby action, keep mode/theme/audio secondary, and show a lightweight one-step-at-a-time first-session guide.

**Architecture:** Keep server gameplay and world lobby interactions unchanged. Reshape the existing client-created HUD in `TDUIClient`, enlarge/reposition the existing READY control in `TDInputClient`, and expose layout/copy constants through `GameConfig`. A PowerShell source-contract verifier protects hierarchy, device copy, visibility, and non-gameplay scope.

**Tech Stack:** Roblox Luau, Rojo, PowerShell source-contract tests, Roblox Studio MCP playtest.

---

### Task 1: Add the lobby hierarchy source contract

**Files:**
- Create: `scripts/verify-lobby-ui-hierarchy.ps1`

- [ ] Assert config contains `LobbyGuideStepSeconds`, compact guide text, short mobile/desktop/gamepad hints, and top-right mixer layout flags.
- [ ] Assert `TDUIClient` exposes one active guide label, two secondary mode/theme labels, session-completion state, and hides lobby UI outside lobby states.
- [ ] Assert `TDInputClient` keeps one centered high-contrast `ReadyButton` larger than secondary lobby UI.
- [ ] Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-lobby-ui-hierarchy.ps1`; expect failure before implementation.

### Task 2: Implement the A+C lobby HUD

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua`

- [ ] Add config-driven active-step copy, compact returning-session copy, short device hints, ready button dimensions, guide dimensions, and mixer top-right positions.
- [ ] Replace the dense horizontal `JOIN MATCH | MODE | THEME | READY` guide with one prominent `ActiveStep` label and secondary `ModeSummary` / `ThemeSummary` labels.
- [ ] Advance the first-session guide from mode to theme to READY without blocking input; after one sequence, show only the compact hint for later lobby returns.
- [ ] Move Music/SFX panels to a small top-right stack and keep them hidden during active matches.
- [ ] Reposition and enlarge `ReadyButton` around screen center while preserving the existing `LobbyReadyEvent` behavior and READY/READY! feedback.
- [ ] Use exact device copy: touch `Move. Stretch. Hold PIN.`, desktop `Hold E / Space: PIN`, gamepad `Hold R2: PIN`.
- [ ] Run the new verifier; expect all checks to pass.

### Task 3: Regression and Studio verification

**Files:**
- Modify only if a contract needs to follow the intentional UI structure: `scripts/verify-ui-polish-layout.ps1`, `scripts/verify-lobby-clarity.ps1`
- Build: `tension-doubles-pinto-hare.rbxlx`

- [ ] Run every `scripts/verify-*.ps1` plus `node scripts/verify-v06-guided-party.mjs`; expect zero failures.
- [ ] Run `rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx`; expect exit code 0.
- [ ] Use Studio MCP Play and confirm no red Output errors, READY is dominant, mode/theme are secondary, audio is top-right, and lobby UI disappears when countdown/match begins.
- [ ] Do not alter ball physics, CPU behavior, scoring, Fiber gameplay, arenas, cosmetics, monetization, or rankings.

No commit is included because the user did not request one.
