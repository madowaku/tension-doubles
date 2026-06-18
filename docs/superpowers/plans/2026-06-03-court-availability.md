# Court Availability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make court selection clearer by marking the active match court as unavailable, preventing new votes for it while a match is running, and keeping lobby/HUD/board status consistent.

**Architecture:** Keep the current single-match server loop. Add a small availability layer around the existing court vote data: `activeCourtId` remains the current match court, `matchRunning` marks it busy, and button clicks are ignored for the active court during play. The physical board and HUD continue to read from server-owned state through `MatchStateEvent`.

**Tech Stack:** Roblox Luau server scripts, Roblox client LocalScripts, PowerShell source-contract checks, Rojo build.

---

## File Structure

- Modify `src/ServerScriptService/TDServer.server.lua`
  - Add `isCourtAvailable(courtId)` and `getCourtAvailabilitySummary()`.
  - Reject selection clicks on the active court while `matchRunning == true`.
  - Broadcast `courtAvailability` to clients.
  - Update board labels with `OPEN`, `SELECTED`, and `PLAYING`.
- Modify `src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua`
  - Keep the lobby HUD concise, using the selected court, votes, and any server message.
- Modify `scripts/verify-court-select.ps1`
  - Add source checks for availability, selection rejection, broadcast payload, and board labels.

---

### Task 1: Add Failing Availability Contract

**Files:**
- Modify: `scripts/verify-court-select.ps1`

- [ ] **Step 1: Add failing checks**

Add this check object near the end of `$checks`:

```powershell
@{
	Name = "server blocks selecting busy active court"
	Ok = $server.Contains('local function isCourtAvailable(courtId)') -and
		$server.Contains('if not isCourtAvailable(courtId) then') -and
		$server.Contains('Config.CourtUnavailableMessage') -and
		$server.Contains('courtAvailability = availability')
}
```

- [ ] **Step 2: Run test to verify RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-court-select.ps1
```

Expected: existing checks pass and `server blocks selecting busy active court` fails.

---

### Task 2: Add Config Copy

**Files:**
- Modify: `src/ReplicatedStorage/TDShared/GameConfig.lua`

- [ ] **Step 1: Add court unavailable message**

Add near the lobby messages:

```lua
CourtUnavailableMessage = "That court is playing!",
```

- [ ] **Step 2: Run existing contract**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-court-select.ps1
```

Expected: still fails only because server availability logic is missing.

---

### Task 3: Implement Server Availability

**Files:**
- Modify: `src/ServerScriptService/TDServer.server.lua`

- [ ] **Step 1: Add availability helpers after `getSelectedMatchCourt`**

```lua
local function isCourtAvailable(courtId)
	return not (matchRunning and courtId == activeCourtId)
end

local function getCourtAvailabilitySummary()
	local availability = {}
	for _, court in ipairs(Config.CourtSelections or {}) do
		availability[court.Id] = isCourtAvailable(court.Id)
	end
	return availability
end
```

- [ ] **Step 2: Broadcast availability in `broadcastState`**

Add before `MatchStateEvent:FireAllClients`:

```lua
local availability = getCourtAvailabilitySummary()
```

Add inside the payload:

```lua
courtAvailability = availability,
```

- [ ] **Step 3: Reject busy court clicks in `teleportPlayerToCourt`**

Insert after the `targetSpawn/root` guard:

```lua
if not isCourtAvailable(courtId) then
	setState("Lobby", Config.CourtUnavailableMessage or "That court is playing!")
	updateCourtSelectBoardStatus()
	return
end
```

- [ ] **Step 4: Update board status wording**

In `updateCourtSelectBoardStatus`, use these status values:

```lua
local status = votes > 0 and string.format("Votes %d", votes) or "OPEN"
if matchRunning and courtId == activeCourtId then
	status = "PLAYING"
elseif courtId == selectedCourtId then
	status = "Selected  " .. status
end
```

- [ ] **Step 5: Run contract**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-court-select.ps1
```

Expected: all checks pass.

---

### Task 4: Verify Full Project

**Files:**
- No source edits expected.

- [ ] **Step 1: Run lobby contract**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-lobby-ready.ps1
```

Expected: all checks pass.

- [ ] **Step 2: Run existing v0.6 source checks**

```powershell
node scripts\verify-v06-guided-party.mjs
```

Expected: `v0.6 guided party source checks passed`.

- [ ] **Step 3: Build Roblox file**

```powershell
rojo build -o tension-doubles-pinto-hare-court-availability.rbxlx
```

Expected: `Built project to tension-doubles-pinto-hare-court-availability.rbxlx`.

- [ ] **Step 4: Inspect generated rbxlx**

```powershell
Select-String -LiteralPath tension-doubles-pinto-hare-court-availability.rbxlx -Pattern 'isCourtAvailable','CourtUnavailableMessage','courtAvailability','PLAYING' -SimpleMatch
```

Expected: all four strings appear.

---

## Self-Review

- Spec coverage: The plan covers busy-court rejection, board status, HUD state payload, and verification.
- Placeholder scan: No `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: Uses existing `activeCourtId`, `matchRunning`, `Config.CourtSelections`, `MatchStateEvent`, and `updateCourtSelectBoardStatus`.
