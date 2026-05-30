# v0.6 Release Candidate Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden v0.6 in the requested order: first 30 seconds, solo/2/4 checks, mobile HUD polish, and RC documentation.

**Architecture:** Keep the existing server-authoritative game loop. Use config-driven copy and small HUD layout changes, add source checks, and document manual RC verification without adding new gameplay systems.

**Tech Stack:** Roblox Luau, Rojo, Node source verification script.

---

## File Structure

- Modify `scripts/verify-v06-guided-party.mjs`: add checks for RC onboarding copy, mode profiles, mobile HUD config, README, and RC checklist.
- Modify `src/ReplicatedStorage/TDShared/GameConfig.lua`: add config-driven onboarding steps, first-30s copy, testing profile labels, and mobile HUD sizing knobs.
- Modify `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`: render onboarding steps from config and use config-driven mobile HUD dimensions.
- Modify `README.md`: document v0.6 RC focus and solo/2/4 playtest profiles.
- Create `docs/playtests/v06-rc-checklist.md`: repeatable manual playtest checklist.

### Task 1: First 30 Seconds Source Checks

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`

- [ ] Add checks for:

```js
assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "First30OnboardingSteps",
  "first 30 seconds should use config-driven onboarding copy"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "Make a Tension Fiber net",
  "onboarding should directly teach the partner-net concept"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.First30OnboardingSteps",
  "HUD should render first-30s onboarding from config"
);
```

- [ ] Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: FAIL because the config-driven onboarding values are not present yet.

### Task 2: Implement First 30 Seconds Copy

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`

- [ ] Add to `GameConfig.lua` near onboarding settings:

```lua
	First30OnboardingSteps = {
		"Make a Tension Fiber net with your partner.",
		"Move apart until it says TENSION OK.",
		"Hold PIN together to spark HARE!",
	},
	ServingSubMessage = "Track the ball!",
	RallySubMessage = "",
	PointSubMessage = "NEXT SERVE!",
```

- [ ] Replace the hard-coded `steps` table in `showOnboardingOnce` with:

```lua
	local steps = Config.First30OnboardingSteps or {
		"Make a Tension Fiber net with your partner.",
		"Move apart until it says TENSION OK.",
		"Hold PIN together to spark HARE!",
	}
```

- [ ] Replace serving and point submessages:

```lua
subMessageLabel.Text = Config.ServingSubMessage or "Track the ball!"
subMessageLabel.Text = Config.PointSubMessage or "NEXT SERVE!"
```

- [ ] Run source checks. Expected: PASS for Task 1 checks.

### Task 3: Solo / 2 / 4 Behavior Checks

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `README.md`

- [ ] Add source checks:

```js
assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "PlaytestProfiles",
  "solo, 2-player, and 4-player playtest profiles should be explicit"
);

assertIncludes(
  "README.md",
  "Solo / 2-player / 4-player RC checks",
  "README should explain the expected player-count checks"
);
```

- [ ] Add config table:

```lua
	PlaytestProfiles = {
		Solo = "AllowGhostPartners=true, MinPlayersToAutoStart=1",
		TwoPlayer = "Ghost support allowed while each side learns the loop",
		FourPlayer = "Set AllowGhostPartners=false and MinPlayersToAutoStart=4",
	},
```

- [ ] Update README with a short `Solo / 2-player / 4-player RC checks` section.

- [ ] Run source checks.

### Task 4: Mobile HUD Polish

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`

- [ ] Add source checks:

```js
assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "MobileMessageYLandscape",
  "mobile HUD vertical positions should be config-driven for RC polish"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.MobileMessageYLandscape",
  "HUD should use config-driven mobile message placement"
);
```

- [ ] Add config values:

```lua
	MobileMessageYLandscape = 0.215,
	MobileMessageYPortrait = 0.205,
	MobileSubMessageYLandscape = 0.315,
	MobileSubMessageYPortrait = 0.300,
	MobileNetGuideWidthLandscape = 0.60,
	MobileNetGuideWidthPortrait = 0.72,
```

- [ ] In `applyResponsiveLayout`, replace hard-coded mobile message/submessage/net guide widths with config lookups.

- [ ] Run source checks.

### Task 5: v0.6 RC Checklist

**Files:**
- Modify: `scripts/verify-v06-guided-party.mjs`
- Modify: `README.md`
- Create: `docs/playtests/v06-rc-checklist.md`

- [ ] Add source checks:

```js
assertIncludes(
  "docs/playtests/v06-rc-checklist.md",
  "First 30 seconds",
  "RC checklist should include first 30 seconds playtest"
);

assertIncludes(
  "docs/playtests/v06-rc-checklist.md",
  "Mobile landscape",
  "RC checklist should include mobile landscape sanity"
);

assertIncludes(
  "README.md",
  "v0.6 RC checklist",
  "README should point to the v0.6 RC checklist"
);
```

- [ ] Create the checklist with sections for source checks, build, Studio smoke, first 30 seconds, solo/2/4, and mobile.

- [ ] Update README to link the checklist.

### Task 6: Verification, Studio Smoke, Commit

**Files:**
- Verify all changed files.

- [ ] Run:

```powershell
node scripts\verify-v06-guided-party.mjs
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare diff --check
```

- [ ] If Roblox Studio MCP is connected, Play and inspect HUD texts and output log.

- [ ] Commit and push:

```powershell
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare add docs/superpowers/plans/2026-05-31-v06-release-candidate-hardening.md docs/playtests/v06-rc-checklist.md scripts/verify-v06-guided-party.mjs src/ReplicatedStorage/TDShared/GameConfig.lua src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua README.md
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare commit -m "feat: harden v06 release candidate"
git -c safe.directory=C:/Dev/Projects/tension-doubles-pinto-hare push
```
