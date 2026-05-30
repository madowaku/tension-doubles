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
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "NetGuidanceBroadcastInterval",
  "live net guidance should have a throttled broadcast interval"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /GoodDistanceMax\s*=\s*18/,
  "party-sport normal net band should be a little more forgiving"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /HareContactWindow\s*=\s*0\.45/,
  "HARE timing should be forgiving enough for the first 30 seconds"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "HareHoldWindow",
  "holding PIN before contact should still allow HARE"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "HareRequiresFreshPin = false",
  "v0.6 party HARE should reward sustained shared PIN instead of a strict contact-timing test"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "SoloGhostsMirrorPinning",
  "solo party testing should let empty-side ghosts produce HARE moments"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "netGuidance",
  "match-state payload should expose net guidance"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "lastGuidanceBroadcast",
  "server should refresh net guidance during rallies"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "Config.HareHoldWindow",
  "server HARE detection should accept sustained PIN holds"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "Config.HareRequiresFreshPin ~= false",
  "server should make strict HARE contact timing optional for the party slice"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  'local fxType = "Normal"',
  "normal returns should not be mislabeled as PIN"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "SoloGhostsMirrorPinning",
  "server should mirror PIN to empty ghost teams only during solo testing"
);

assertRegex(
  "src/ServerScriptService/TDServer.server.lua",
  /awardPoint\([^\n]+,\s*(Config\.ScoreReasonDropText or )?"DROP!"/,
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
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  'return "HIT!"',
  "normal returns should read as a plain hit, not a PIN"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua",
  "HareCameraKick",
  "camera feedback should use config-driven HARE kick"
);

console.log("v0.6 guided party source checks passed");
