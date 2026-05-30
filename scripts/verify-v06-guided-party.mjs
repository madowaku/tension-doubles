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
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "NetGuidanceBroadcastInterval",
  "live net guidance should have a throttled broadcast interval"
);

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
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "PlaytestProfiles",
  "solo, 2-player, and 4-player playtest profiles should be explicit"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "MobileMessageYLandscape",
  "mobile HUD vertical positions should be config-driven for RC polish"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "MobileRotateHintNonBlocking",
  "portrait rotate guidance should not block play"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /MobileCameraHeightLandscape\s*=\s*52/,
  "mobile landscape camera should be close enough that the court fills the screen"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /MobilePinButtonScaleLandscape\s*=\s*0\.145/,
  "mobile landscape PIN button should leave more playfield visible"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "HidePinButtonHintLandscape",
  "landscape PIN button should not overlap with its Hold helper"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /ReturnLiftHare\s*=\s*0\.30/,
  "HARE should behave more like a fast smash than a long lob"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /HareMaxForwardSpeed\s*=\s*40/,
  "HARE forward travel should be capped to reduce OUT results"
);

assertRegex(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  /LandingTargetSize\s*=\s*7\.2/,
  "mobile landing target should be large enough to see in landscape"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "MobileNetGuideBgTransparencyLandscape",
  "mobile landscape net guidance should not read as a heavy blocking bar"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "GameOverSubMessage",
  "game over should have a clear replay loop message"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "WaitingSubMessage",
  "lobby/waiting state should teach the party sport loop"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "FailSubtitleDropText",
  "drop/out failures should have party-readable feedback"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "LandingTargetOutColor",
  "landing target marker should have an explicit OUT color for mobile readability"
);

assertIncludes(
  "src/ReplicatedStorage/TDShared/GameConfig.lua",
  "HareSubtitleText",
  "HARE subtitle should be config-driven"
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
  "BeamCurveSlack",
  "server beam visuals should show Slack fiber sag"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "Config.OverTensionWobbleScale",
  "server should tune Over Tension instability from config"
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

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "SoloGhostsMirrorPinning",
  "server should mirror PIN to empty ghost teams only during solo testing"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "TD_LandingTargetMarker",
  "server should create a visible landing target marker"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "predictBallLanding",
  "server should predict the ball landing target for mobile readability"
);

assertIncludes(
  "src/ServerScriptService/TDServer.server.lua",
  "TD_HareSparkColumn",
  "HARE should spawn a named vertical spark effect"
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
  'return Config.NormalHitText or "FIBER HIT!"',
  "normal returns should read as a Tension Fiber hit, not a PIN"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.NormalHitText",
  "normal return callout should use Tension Fiber copy from config"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.First30OnboardingSteps",
  "HUD should render first-30s onboarding from config"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.MobileMessageYLandscape",
  "HUD should use config-driven mobile message placement"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.HareSubtitleText",
  "HARE subtitle should come from config"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "subMessageHoldUntil",
  "temporary HARE subtitles should survive frequent rally guidance broadcasts"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "MobileRotateHintNonBlocking",
  "portrait rotate guidance should be a non-blocking hint"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.GameOverSubMessage",
  "game over HUD should explain the replay loop"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua",
  "Config.FailSubtitleDropText",
  "failure subtitles should be config-driven"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua",
  "HidePinButtonHintLandscape",
  "mobile landscape should hide the helper label that overlaps the PIN button"
);

assertIncludes(
  "src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua",
  "HareCameraKick",
  "camera feedback should use config-driven HARE kick"
);

assertIncludes(
  "README.md",
  "Solo / 2-player / 4-player RC checks",
  "README should explain the expected player-count checks"
);

assertIncludes(
  "README.md",
  "v0.6 RC checklist",
  "README should point to the v0.6 RC checklist"
);

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
  "docs/playtests/v06-rc-checklist.md",
  "landing target",
  "RC checklist should ask testers to verify the landing target"
);

console.log("v0.6 guided party source checks passed");
