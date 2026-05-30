# Tension Fiber Material Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the existing Slack, Normal, OverTension, and HARE states read as the original Tension Fiber material.

**Architecture:** Keep the current server-authoritative rally loop. Tune config, hit behavior, beam presentation, and HUD copy in place so the material is clearer without adding new systems or changing ball ownership.

**Tech Stack:** Roblox Luau, Rojo, existing source-check script `scripts/verify-v06-guided-party.mjs`.

---

## File Structure

- Modify `scripts/verify-v06-guided-party.mjs`: add source checks for Tension Fiber copy, state tuning, and beam material behaviors.
- Modify `src/ReplicatedStorage/TDShared/GameConfig.lua`: add material name/copy and v0.6 tuning values for Slack, Good Tension, Over Tension, and HARE.
- Modify `src/ServerScriptService/TDServer.server.lua`: make beam width/transparency/curve encode sag, stable tension, over-tension, and HARE hardening; make Over Tension risky through stronger wobble while keeping Slack weak but playable.
- Modify `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`: render Tension Fiber terms with short HUD language and distinguish `FIBER HIT!` from `SLACK!`, `TOO TIGHT!`, and `HARE!!`.

### Task 1: Add Tension Fiber Verification

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Write failing checks**

Add these assertions after the existing `NetGuideGoodText` check:

```js
assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  'MaterialName = "Tension Fiber"',
  "the partner net should have a clear original material name"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  'NormalHitText = "FIBER HIT!"',
  "normal good-tension returns should read as Tension Fiber, not generic hits"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "BeamCurveSlack",
  "Slack should have a sagging fiber beam"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "OverTensionWobbleScale",
  "Over Tension should be risky and unstable, not strictly better"
);
```

Add these assertions after the existing `local fxType = "Normal"` check:

```js
assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "BeamCurveSlack",
  "server beam visuals should show Slack fiber sag"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "Config.OverTensionWobbleScale",
  "server should tune Over Tension instability from config"
);
```

Add this assertion near the `return "HIT!"` check:

```js
assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.NormalHitText",
  "normal return callout should use Tension Fiber copy from config"
);
```

- [ ] **Step 2: Run source checks and verify RED**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: FAIL because `MaterialName = "Tension Fiber"` is not present yet.

### Task 2: Add Material Config

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`

- [ ] **Step 1: Add material identity**

Insert after `Subtitle = "Hold PIN. Sync for HARE.",`:

```lua
	MaterialName = "Tension Fiber",
```

- [ ] **Step 2: Add material tuning values**

Insert near the existing beam visual config:

```lua
	BeamCurveSlack = 2.8,
	BeamCurveNormal = 0,
	BeamCurveOverTension = -1.1,
	BeamCurveHare = 0,
	BeamWidthSlack = 1.55,
	BeamWidthOverTension = 1.85,
	BeamWidthHareBonus = 0.82,
	OverTensionWobbleScale = 0.42,
```

- [ ] **Step 3: Add material copy**

Insert near the existing v0.5 onboarding strings:

```lua
	NormalHitText = "FIBER HIT!",
	NetGuideGoodText = "TENSION OK",
	NetGuideTooCloseText = "FIBER SAG",
	NetGuideTooFarText = "TOO TIGHT",
```

When adding this, replace the existing `NetGuideGoodText`, `NetGuideTooCloseText`, and `NetGuideTooFarText` entries rather than duplicating keys.

- [ ] **Step 4: Run source checks**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: still FAIL because server and UI are not using the new values yet.

### Task 3: Make Server Express Fiber State

**Files:**
- Modify: `src/ServerScriptService/TDServer.server.lua`

- [ ] **Step 1: Update beam state presentation**

In `updateTeamBeam`, replace the `width/transparency` state block with this behavior:

```lua
	local curve = Config.BeamCurveNormal or 0

	if tensionState == "Slack" then
		width = Config.BeamWidthSlack or (Config.BeamWidth - 0.55)
		transparency = 0.22
		curve = Config.BeamCurveSlack or 2.8
	elseif tensionState == "OverTension" then
		width = Config.BeamWidthOverTension or (Config.BeamWidth - 0.25)
		transparency = 0.08
		curve = Config.BeamCurveOverTension or -1.1
	elseif realPinCount >= 2 and tensionState ~= "Broken" then
		color = BEAM_COLORS.Hare
		width = Config.BeamWidth + (Config.BeamWidthHareBonus or 0.82)
		transparency = 0.02
		curve = Config.BeamCurveHare or 0
	elseif realPinCount == 1 and tensionState ~= "Broken" then
		color = Color3.fromRGB(255, 170, 90)
		width = Config.BeamWidth + 0.25
		transparency = 0.06
	elseif tensionState == "Broken" then
		width = 0.25
		transparency = 0.65
		curve = Config.BeamCurveSlack or 2.8
	end

	beam.CurveSize0 = curve
	beam.CurveSize1 = -curve
```

Keep the existing final `beam.Color`, `beam.Width0`, `beam.Width1`, and `beam.Transparency` assignments.

- [ ] **Step 2: Tune Over Tension wobble from config**

In `processNetHit`, replace:

```lua
		horizontal = MathUtil.safeUnit(horizontal + netDir * wobbleSign * 0.22, returnDir)
```

with:

```lua
		horizontal = MathUtil.safeUnit(horizontal + netDir * wobbleSign * (Config.OverTensionWobbleScale or 0.42), returnDir)
```

- [ ] **Step 3: Run source checks**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: still FAIL until UI uses `Config.NormalHitText`.

### Task 4: Update HUD Callouts

**Files:**
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`

- [ ] **Step 1: Make normal hit use config copy**

In `fxTextForType`, replace:

```lua
	return "HIT!", Color3.fromRGB(245, 245, 255)
```

with:

```lua
	return Config.NormalHitText or "FIBER HIT!", Color3.fromRGB(245, 245, 255)
```

- [ ] **Step 2: Run source checks**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: PASS with `v0.6 guided party source checks passed`.

### Task 5: Build And Studio Smoke Test

**Files:**
- Build output only: `tension-doubles-pinto-hare.rbxlx`

- [ ] **Step 1: Build Rojo project**

Run:

```powershell
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

Expected: exit code 0 and `Built project to tension-doubles-pinto-hare.rbxlx`.

- [ ] **Step 2: Sync or patch Studio if needed**

If Studio has not picked up Rojo changes, use Roblox Studio MCP `multi_edit` to apply the same source edits to:

```text
game.ReplicatedStorage.TDShared.GameConfig
game.ServerScriptService.TDServer
game.StarterPlayer.StarterPlayerScripts.TDUIClient
```

- [ ] **Step 3: Play and inspect HUD**

Start Play in Roblox Studio. Inspect `LocalPlayer.PlayerGui` text labels.

Expected:

- Net guide uses `TENSION OK`, `FIBER SAG`, or `TOO TIGHT`.
- Normal returns show `FIBER HIT!` rather than `HIT!`.
- Studio Output contains no game Lua errors.

### Task 6: Commit And Push

**Files:**
- Stage all modified source/check files and the plan.

- [ ] **Step 1: Check diff**

Run:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare status --short
```

Expected: diff check exit code 0, only planned files modified.

- [ ] **Step 2: Commit**

Run:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare add docs/superpowers/plans/2026-05-30-tension-fiber-material.md scripts/verify-v06-guided-party.mjs src/ReplicatedStorage/TDShared/GameConfig.lua src/ServerScriptService/TDServer.server.lua src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare commit -m "feat: express tension fiber material"
```

Expected: commit succeeds.

- [ ] **Step 3: Push**

Run:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare push
```

Expected: `main -> main`.
