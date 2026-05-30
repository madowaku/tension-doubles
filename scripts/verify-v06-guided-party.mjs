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
  "src/ServerScriptService/TDServer.server.lua",
  "netGuidance",
  "match-state payload should expose net guidance"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "lastGuidanceBroadcast",
  "server should refresh net guidance during rallies"
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
  "src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua",
  "HareCameraKick",
  "camera feedback should use config-driven HARE kick"
);

console.log("v0.6 guided party source checks passed");
