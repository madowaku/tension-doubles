# v0.6 Guided Party Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the v0.6 first-30-seconds Guided Party Slice: partner-net guidance, stronger PIN/HARE feedback, readable score reasons, and mobile visibility improvements.

**Architecture:** Keep the current server-authoritative Roblox/Rojo architecture. `TDServer.server.lua` remains the source of truth for team state, net tension, hit type, ball visuals, and score reasons; clients render guidance and feedback through existing `MatchStateEvent` and `HitFxEvent` payloads. Add small config and verification support without restructuring the prototype.

**Tech Stack:** Roblox Luau, Rojo, Studio MCP playtests, PowerShell, Node.js for source-level verification scripts.

---

## File Structure

- Modify `src/ReplicatedStorage/TDShared/GameConfig.lua`
  - Add v0.6 copy/tuning values for net guidance labels, score reason labels, HARE emphasis, and mobile visibility.
- Modify `src/ServerScriptService/TDServer.server.lua`
  - Add team net guidance state to match-state payloads.
  - Shorten score reason tokens.
  - Ensure HARE/Pin hit payload remains rich enough for UI and camera.
- Modify `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`
  - Add compact net guidance HUD.
  - Improve score reason display.
  - Strengthen PIN/HARE floating callouts.
  - Adjust mobile layout spacing.
- Modify `src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua`
  - Tune HARE camera kick and mobile camera readability.
- Create `scripts/verify-v06-guided-party.mjs`
  - Source-level safety check for required v0.6 fields and strings.
- Modify `README.md`
  - Add v0.6 local workflow notes after implementation.

## Verification Commands

Use these throughout:

```powershell
node scripts\verify-v06-guided-party.mjs
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

For Studio runtime checks, use MCP:

```text
start_stop_play(true)
get_console_output()
execute_luau(...) to inspect PlayerGui labels, ReplicatedStorage config, Workspace ball visibility
start_stop_play(false)
```

---

### Task 1: Add v0.6 Source Verification

**Files:**
- Create: `scripts/verify-v06-guided-party.mjs`
- Modify: none

- [ ] **Step 1: Write the failing verification script**

Create `scripts/verify-v06-guided-party.mjs` with this content:

```javascript
import fs from "node:fs";
import path from "node:path";

const root = process.cwd();

function read(relPath) {
  return fs.readFileSync(path.join(root, relPath), "utf8");
}

function assertIncludes(file, text, reason) {
  const source = read(file);
  if (!source.includes(text)) {
    throw new Error(`${file} is missing ${JSON.stringify(text)}: ${reason}`);
  }
}

function assertRegex(file, regex, reason) {
  const source = read(file);
  if (!regex.test(source)) {
    throw new Error(`${file} failed ${regex}: ${reason}`);
  }
}

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  'Version = "0.6.0"',
  "v0.6 should be explicit in config"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "NetGuideGoodText",
  "net guidance copy should be config-driven"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "netGuidance",
  "match-state payload should expose net guidance"
);

assertRegex(
  "src/ServerScriptService/TDServer.server.lua",
  /awardPoint\([^\\n]+,\s*"DROP!"/,
  "drop scoring reasons should be short"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "NetGuideLabel",
  "HUD should render net guidance"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "HARE!!",
  "HARE should have a stronger party callout"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua",
  "HareCameraKick",
  "camera feedback should use config-driven HARE kick"
);

console.log("v0.6 guided party source checks passed");
```

- [ ] **Step 2: Run the verification and confirm RED**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: FAIL because `Version = "0.6.0"` and the new v0.6 symbols do not exist yet.

- [ ] **Step 3: Commit only if requested later**

Do not commit yet. This task is the test harness for later tasks and should be committed together with the first passing implementation slice.

---

### Task 2: Server Payload And Score Reason Slice

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Modify: `src/ServerScriptService/TDServer.server.lua`
- Test: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Add v0.6 config fields**

In `GameConfig.lua`, update:

```lua
Version = "0.6.0",
```

Add these fields near the onboarding/mobile copy section:

```lua
NetGuideMakeText = "MAKE A NET",
NetGuideGoodText = "GOOD NET",
NetGuideTooCloseText = "MOVE APART",
NetGuideTooFarText = "TOO FAR",
NetGuidePinText = "HOLD PIN",
NetGuideHareText = "HARE READY!",
ScoreReasonDropText = "DROP!",
ScoreReasonOutText = "OUT!",
ScoreReasonTooFarText = "TOO FAR!",
ScoreReasonHareText = "HARE POINT!",
HareCameraKick = 1.25,
HareComboCameraKick = 1.75,
NormalHitCameraKick = 0.34,
MobileNetGuideYLandscape = 0.805,
MobileNetGuideYPortrait = 0.815,
```

- [ ] **Step 2: Add server guidance helpers**

In `TDServer.server.lua`, add a helper after `getTensionState`:

```lua
local function getNetGuidanceForTeam(teamName)
	local a, b = getNetEndpoints(teamName)
	if not a or not b then
		return {
			state = "Missing",
			text = Config.NetGuideMakeText or "MAKE A NET",
			distance = 0,
			pinCount = 0,
		}
	end

	local tensionState, distance = getTensionState(a, b)
	local pinInfo = getTeamPinInfo(teamName)
	local text = Config.NetGuideGoodText or "GOOD NET"
	if tensionState == "Slack" then
		text = Config.NetGuideTooCloseText or "MOVE APART"
	elseif tensionState == "OverTension" or tensionState == "Broken" then
		text = Config.NetGuideTooFarText or "TOO FAR"
	elseif pinInfo.pinCount > 0 then
		text = Config.NetGuidePinText or "HOLD PIN"
	end
	if pinInfo.pinCount >= 2 and tensionState == "Normal" then
		text = Config.NetGuideHareText or "HARE READY!"
	end

	return {
		state = tensionState,
		text = text,
		distance = math.floor(distance * 10) / 10,
		pinCount = pinInfo.pinCount,
	}
end
```

If this placement causes forward-reference issues because `getTeamPinInfo` is defined later, instead place the helper immediately after `getTeamPinInfo`.

- [ ] **Step 3: Extend match-state payload**

Update `broadcastState(message)` so `MatchStateEvent:FireAllClients` includes:

```lua
netGuidance = {
	Red = getNetGuidanceForTeam("Red"),
	Blue = getNetGuidanceForTeam("Blue"),
},
```

If early boot calls happen before helpers are ready, guard with:

```lua
local netGuidance = nil
if getNetGuidanceForTeam then
	netGuidance = {
		Red = getNetGuidanceForTeam("Red"),
		Blue = getNetGuidanceForTeam("Blue"),
	}
end
```

- [ ] **Step 4: Shorten score reasons**

Change drop scoring calls:

```lua
awardPoint("Blue", Config.ScoreReasonDropText or "DROP!", "Red")
awardPoint("Red", Config.ScoreReasonDropText or "DROP!", "Blue")
```

Change out scoring call:

```lua
awardPoint(MathUtil.opponent(losingTeam), Config.ScoreReasonOutText or "OUT!", losingTeam)
```

- [ ] **Step 5: Run source verification**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: still FAIL because UI and camera symbols are not implemented yet, but no longer failing on config/server items.

- [ ] **Step 6: Run Rojo build**

Run:

```powershell
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

Expected: PASS.

---

### Task 3: HUD Guidance And Party Callouts

**Files:**
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`
- Test: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Add a net guidance label**

After `hintLabel` creation, create:

```lua
local netGuideLabel = makeLabel("NetGuideLabel", UDim2.fromScale(0.62, 0.07), UDim2.fromScale(0.5, 0.80), isTouch and 19 or 22, true)
netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
netGuideLabel.BackgroundTransparency = 0.38
netGuideLabel.Text = ""
```

- [ ] **Step 2: Position it responsively**

In `applyResponsiveLayout()`, add touch layout:

```lua
netGuideLabel.Position = UDim2.fromScale(0.5, portrait and (Config.MobileNetGuideYPortrait or 0.815) or (Config.MobileNetGuideYLandscape or 0.805))
netGuideLabel.TextSize = portrait and 18 or 20
```

Add desktop layout:

```lua
netGuideLabel.Position = UDim2.fromScale(0.5, 0.82)
netGuideLabel.TextSize = 22
```

- [ ] **Step 3: Render guidance from match state**

In `MatchStateEvent.OnClientEvent`, after score text update, add:

```lua
local localTeam = player.Team and player.Team.Name
local guidance = localTeam and data.netGuidance and data.netGuidance[localTeam]
if guidance and guidance.text then
	netGuideLabel.Text = guidance.text
	if guidance.state == "Normal" then
		netGuideLabel.TextColor3 = Color3.fromRGB(150, 255, 205)
	elseif guidance.state == "Slack" then
		netGuideLabel.TextColor3 = Color3.fromRGB(120, 205, 255)
	elseif guidance.state == "OverTension" or guidance.state == "Broken" then
		netGuideLabel.TextColor3 = Color3.fromRGB(255, 135, 125)
	else
		netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
	end
else
	netGuideLabel.Text = Config.NetGuideMakeText or "MAKE A NET"
	netGuideLabel.TextColor3 = Color3.fromRGB(255, 235, 145)
end
```

- [ ] **Step 4: Strengthen HARE and one-pin copy**

Update `fxTextForType(fxType, comboCount)` so:

```lua
if fxType == "Hare" then
	if comboCount and comboCount >= 2 then
		return "HARE!! x" .. tostring(comboCount), Color3.fromRGB(255, 230, 90)
	end
	return "HARE!!", Color3.fromRGB(255, 230, 90)
elseif fxType == "OnePin" then
	return "ONE PIN!", Color3.fromRGB(255, 170, 95)
end
```

Keep existing `Slack`, `OverTension`, `Broken`, and default cases.

- [ ] **Step 5: Make point messages shorter and larger**

In the `PointScored` branch, keep `messageLabel.Text = data.message`, but use a larger display:

```lua
setMessage(data.message or "", 4)
subMessageLabel.Text = "NEXT SERVE!"
```

If `setMessage` already handles size boost differently, preserve its signature and use its existing behavior.

- [ ] **Step 6: Run source verification**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: still FAIL only on `HareCameraKick` if camera is not implemented yet.

- [ ] **Step 7: Run Rojo build**

Run:

```powershell
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

Expected: PASS.

---

### Task 4: Camera And Mobile Visibility Tuning

**Files:**
- Modify: `src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua`
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`
- Test: `scripts/verify-v06-guided-party.mjs`

- [ ] **Step 1: Use config-driven camera kick**

In `TDCameraClient.client.lua`, replace HARE hard-coded values:

```lua
shakePower = comboCount and comboCount >= 2 and (Config.HareComboCameraKick or 1.75) or (Config.HareCameraKick or 1.25)
shakeUntil = os.clock() + 0.28
```

For non-HARE normal hit feedback, use:

```lua
shakePower = Config.NormalHitCameraKick or 0.34
shakeUntil = os.clock() + 0.11
```

Keep broken/point scored camera feedback readable and brief.

- [ ] **Step 2: Tune mobile camera config**

In `GameConfig.lua`, adjust only if Studio playtest shows ball/partner visibility needs it. Start with:

```lua
MobileCameraHeightLandscape = 94,
MobileCameraBackLandscape = 82,
MobileCameraFovLandscape = 68,
MobileCameraHeightPortrait = 106,
MobileCameraBackPortrait = 92,
MobileCameraFovPortrait = 72,
```

- [ ] **Step 3: Run source verification**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: PASS with `v0.6 guided party source checks passed`.

- [ ] **Step 4: Run Rojo build**

Run:

```powershell
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
```

Expected: PASS.

---

### Task 5: Studio Runtime Playtest And Docs

**Files:**
- Modify: `README.md`
- Modify: `CODEX_NEXT_PROMPT.md`

- [ ] **Step 1: Start or verify Rojo**

Run:

```powershell
Get-CimInstance Win32_Process -Filter "Name = 'rojo.exe'" | Select-Object ProcessId,CommandLine
```

Expected: one process with `rojo.exe serve default.project.json`. If not, start:

```powershell
Start-Process -WindowStyle Hidden -FilePath rojo -ArgumentList @('serve','default.project.json') -WorkingDirectory 'C:\Dev\Projects\tension-doubles-pinto-hare'
```

- [ ] **Step 2: Use Studio MCP to verify config**

Run an MCP `execute_luau` call:

```lua
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("TDShared"):WaitForChild("GameConfig"))
return {
	version = Config.Version,
	netGuideGood = Config.NetGuideGoodText,
	hareKick = Config.HareCameraKick,
}
```

Expected:

```lua
{ version = "0.6.0", netGuideGood = "GOOD NET", hareKick = 1.25 }
```

- [ ] **Step 3: Playtest first rally**

Use MCP:

```text
start_stop_play(true)
wait 5 seconds
execute_luau to inspect PlayerGui TextLabels
get_console_output()
start_stop_play(false)
```

Expected:

- No game Lua errors in Output.
- PlayerGui includes `NetGuideLabel`.
- Score reason text is short when a point is scored.
- Ball remains visible during serve and first return.

- [ ] **Step 4: Update README**

Add a `v0.6 direction` section:

```markdown
## v0.6 direction

v0.6 focuses on the first 30 seconds:

- make the partner-net concept readable
- make PIN and HARE feel exciting
- shorten score reasons for mobile readability
- keep the game party-sport flavored, not simulation-heavy

UGC spectacle, cosmetics, unlocks, and themed arenas are deferred to v0.7+.
```

- [ ] **Step 5: Update CODEX_NEXT_PROMPT**

Replace the old serve-only prompt with:

```markdown
# Next Codex Prompt

We have Roblox project `Tension Doubles: PINTO HARE!` v0.6.

Continue polishing the first 30 seconds:

1. Confirm players can infer they are making a net with their partner.
2. Confirm PIN and HARE feedback are readable and exciting.
3. Confirm score reasons are short and readable on mobile.
4. Do not start UGC, cosmetics, unlocks, themed arenas, ranking, monetization, or matchmaking yet.
5. Keep ball, hit, and score authority on the server.
```

- [ ] **Step 6: Run final verification**

Run:

```powershell
node scripts\verify-v06-guided-party.mjs
rojo build default.project.json --output tension-doubles-pinto-hare.rbxlx
git status --short
```

Expected:

- Node verification passes.
- Rojo build passes.
- Git status shows only intentional modified/created files.

- [ ] **Step 7: Commit**

Run:

```powershell
git add scripts/verify-v06-guided-party.mjs src/ReplicatedStorage/TDShared/GameConfig.lua src/ServerScriptService/TDServer.server.lua src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua README.md CODEX_NEXT_PROMPT.md docs/superpowers/plans/2026-05-30-v06-guided-party-slice.md
git commit -m "feat: add v0.6 guided party slice"
```

Expected: commit succeeds.

---

## Self-Review

Spec coverage:

- Partner-net guidance: Task 2 and Task 3.
- PIN charge feedback: Task 3.
- HARE moment upgrade: Task 3 and Task 4.
- Readable score reasons: Task 2 and Task 3.
- Mobile visibility: Task 3 and Task 4.
- Runtime verification: Task 5.
- v0.7+ exclusions: README and next prompt in Task 5.

The plan contains concrete file paths, commands, and expected outcomes. Any implementation that needs broader architecture changes should stop and report the blocker rather than expanding the scope.
