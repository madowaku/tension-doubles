# Tension Fiber Visual Punch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Slack sag and HARE hardening more visible using existing Tension Fiber visuals.

**Architecture:** Keep shared effects server-owned. Add config values, source checks, beam tuning, one Slack ripple, and one extra HARE hardening ring without introducing new systems.

**Tech Stack:** Roblox Luau, Rojo, existing source-check script `scripts/verify-v06-guided-party.mjs`.

---

## File Structure

- Modify `scripts/verify-v06-guided-party.mjs`: add checks for stronger Slack sag and HARE hardening effects.
- Modify `src/ReplicatedStorage/TDShared/GameConfig.lua`: add visual tuning values.
- Modify `src/ServerScriptService/TDServer.server.lua`: use the new values in beam and hit effects.

### Task 1: Add Visual Punch Checks

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Add failing assertions**

Add checks for these strings:

```js
assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "SlackAbsorbRippleSize",
  "Slack hits should create a visible absorbed-impact ripple"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "HareHardeningRingSize",
  "HARE should add a distinct fiber-hardening ring"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "TD_SlackAbsorbRipple",
  "server should spawn a named Slack absorb ripple"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "TD_HareHardeningRing",
  "server should spawn a named HARE hardening ring"
);
```

- [ ] **Step 2: Run RED check**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: FAIL because `SlackAbsorbRippleSize` is not present yet.

### Task 2: Add Visual Tuning Config

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`

- [ ] **Step 1: Add config values**

Insert near the existing beam/HARE visual config:

```lua
	BeamCurveSlack = 4.6,
	BeamWidthSlack = 1.25,
	BeamSlackTransparency = 0.32,
	BeamWidthHareBonus = 1.18,
	BeamHareTransparency = 0.0,
	SlackAbsorbRippleSize = 9,
	SlackAbsorbRippleDuration = 0.34,
	HareHardeningRingSize = 16,
	HareHardeningRingDuration = 0.30,
	HareGlowBrightness = 4.4,
	HareTrailLifetime = 0.56,
```

Replace existing `BeamCurveSlack`, `BeamWidthSlack`, and `BeamWidthHareBonus` values rather than duplicating keys.

- [ ] **Step 2: Run source checks**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: still FAIL because server effects are not wired yet.

### Task 3: Use Config In Server Visuals

**Files:**
- Modify: `src/ServerScriptService/TDServer.server.lua`

- [ ] **Step 1: Use Slack/HARE transparency config**

In `updateTeamBeam`, change Slack transparency to:

```lua
transparency = Config.BeamSlackTransparency or 0.32
```

Change HARE transparency to:

```lua
transparency = Config.BeamHareTransparency or 0
```

- [ ] **Step 2: Use HARE glow/trail config**

In `setBallVisualForFx`, change HARE light brightness and trail lifetime to use:

```lua
light.Brightness = fxType == "Hare" and (Config.HareGlowBrightness or 4.4) or 2.6
trail.Lifetime = fxType == "Hare" and (Config.HareTrailLifetime or 0.56) or 0.38
```

- [ ] **Step 3: Spawn Slack and HARE extra rings**

In `processNetHit`, after `setBallVisualForFx(fxType)`, add:

```lua
	if fxType == "Slack" then
		spawnShockwave(closest, BEAM_COLORS.Slack, Config.SlackAbsorbRippleSize or 9, Config.SlackAbsorbRippleDuration or 0.34, "TD_SlackAbsorbRipple")
	end
```

Inside the existing `if fxType == "Hare" then` block, after the existing `spawnShockwave` call, add:

```lua
		spawnShockwave(closest, Color3.fromRGB(255, 246, 160), Config.HareHardeningRingSize or 16, Config.HareHardeningRingDuration or 0.30, "TD_HareHardeningRing")
```

- [ ] **Step 4: Run source checks**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: PASS.

### Task 4: Build And Studio Smoke Test

**Files:**
- Build output only: `tension-doubles-pinto-hare.rbxlx`

- [ ] **Step 1: Build**

Run:

```powershell
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

Expected: exit code 0 and `Built project to tension-doubles-pinto-hare.rbxlx`.

- [ ] **Step 2: Studio smoke test**

Start Play through Roblox Studio MCP, wait for one rally, inspect output log.

Expected:

- Game starts.
- No game Lua errors in Studio Output.
- Existing HUD still shows Tension Fiber guidance.

### Task 5: Commit And Push

**Files:**
- Stage all modified source/check files and this plan.

- [ ] **Step 1: Verify**

Run:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare status --short
```

Expected: diff check exit code 0, only planned files modified.

- [ ] **Step 2: Commit and push**

Run:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare add docs/superpowers/plans/2026-05-30-tension-fiber-visual-punch.md scripts/verify-v06-guided-party.mjs src/ReplicatedStorage/TDShared/GameConfig.lua src/ServerScriptService/TDServer.server.lua
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare commit -m "feat: punch up tension fiber visuals"
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare push
```

Expected: commit succeeds and `main -> main`.
