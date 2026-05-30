--!strict
-- Tension Doubles: PINTO HARE! / Roblox ver0.5.3
-- Serve Balance Patch: serves now have their own tuned speed/arc so they reach the opponent court.

local Config = {
	Version = "0.5.3",
	Title = "Tension Doubles: PINTO HARE!",
	Subtitle = "Hold PIN. Sync for HARE.",
	ScoreToWin = 7,

	-- Court dimensions in studs.
	CourtWidth = 48,
	CourtDepth = 28, -- per side, from center line to back court line
	OutZoneDepth = 8,
	WallHeight = 3,

	-- Player movement. Slightly faster so touch players can recover.
	WalkSpeed = 20,
	JumpHeight = 4.5,
	ClampPlayersToCourt = true,

	-- Dev/testing. Solo/2-player testing gets ghost partners so the rally loop works.
	AllowGhostPartners = true,
	GhostMirrorsPinning = true,
	MinPlayersToAutoStart = 1, -- set to 4 for a stricter live game

	-- Ball. v0.5.2 lowers PIN/HARE arcs so strong returns land in court more often.
	BallRadius = 1.72,
	BallMinSpeed = 18,
	BallBaseSpeed = 33,
	BallServeSpeed = 40,
	ServeStartZ = 7.5,
	ServeVerticalVelocity = 5.2,
	ServeLateralMax = 4.5,
	BallMaxSpeed = 58,
	BallGravity = 42,
	ServeHeight = 8,
	ReturnLift = 0.52,

	-- Net hit detection. Larger hit radius for touch/mobile readability.
	NetVisualHeight = 3.2,
	NetHitRadius = 3.75,
	NetMinHeight = 1.3,
	NetMaxHeight = 9.8,

	-- Tension distance bands. Distance is between the two net endpoints.
	SlackDistance = 8,
	GoodDistanceMin = 8,
	GoodDistanceMax = 16,
	OverDistanceMin = 16,
	BrokenDistance = 23,

	-- Hit windows. A little kinder on mobile.
	HitCooldown = 0.25,
	HarePinDelta = 0.24,
	HareContactWindow = 0.31,

	-- v0.5.2 Return Balance Patch. Keep PIN fun without making every good hit fly OUT.
	PowerBonusSlack = -8,
	PowerBonusNormal = 3,
	PowerBonusOverTension = 6,
	PowerBonusBothPin = 7,
	PowerBonusOnePin = 3,
	PowerBonusHare = 6,
	ReturnLiftSlack = 0.38,
	ReturnLiftNormal = 0.52,
	ReturnLiftOnePin = 0.56,
	ReturnLiftOverTension = 0.20,
	ReturnLiftHare = 0.52,
	ForwardSpeedCapEnabled = true,
	ReturnMaxForwardSpeed = 38,
	PinMaxForwardSpeed = 42,
	HareMaxForwardSpeed = 46,
	OnePinMaxForwardSpeed = 43,
	OverTensionMaxForwardSpeed = 40,
	SlackMaxForwardSpeed = 28,

	-- Match pacing.
	PointDelay = 1.45,
	CountdownTime = 3,
	GameOverDelay = 5,

	-- Visuals. Thicker Beam and clearer ball for phone screens.
	BeamWidth = 2.2,
	BeamTextureSpeed = 1.8,
	HudMessageDuration = 1.25,
	MobilePinButtonScale = 0.20,

	-- v0.3 party polish.
	RallySpeedBonusPerHit = 0.65,
	RallySpeedBonusMax = 5,
	HareScreenShakePower = 1,
	PinRingRadius = 4.2,
	PinRingHeight = 0.12,
	WaitingMessage = "Waiting for players...",
	StartMessage = "PINTO HARE!",

	-- v0.4 Court & Juice Patch.
	CourtJuiceEnabled = true,
	HareFreezeTime = 0.105, -- tiny hit-stop after a HARE return
	HareComboWindow = 7.0,
	HareShockwaveSize = 22,
	HareShockwaveDuration = 0.52,
	PointBurstSize = 15,
	PointBurstDuration = 0.42,
	ArenaGlowPulseDuration = 0.55,
	CrowdDotCountPerSide = 14,
	CenterEmblemSize = 8.4,
	CenterEmblemTransparency = 0.82,
	CrowdWaveDelayPerDot = 0.028,
	CrowdWaveDuration = 0.42,
	ShowRallyOnPointAt = 4,

	-- v0.5 Onboarding & Feel Patch.
	OnboardingEnabled = true,
	OnboardingStepDuration = 1.35,
	TouchHint = "Hold PIN together!",
	TouchLandscapeHint = "Hold PIN. Sync for HARE!",
	TouchPortraitHint = "Rotate sideways for best play.",
	DesktopHint = "Hold E / Space / Shift: PIN",
	GamepadHint = "Hold R2 / X: PIN",

	-- v0.5.1 Mobile Landscape & UI Fix.
	PreferLandscape = true,
	ShowRotateHint = true,
	MobileHintFadeDelay = 7.0,
	MobileScoreYLandscape = 0.105,
	MobileScoreYPortrait = 0.095,
	MobileHintYLandscape = 0.895,
	MobileHintYPortrait = 0.865,
	MobilePinButtonScaleLandscape = 0.165,
	MobilePinButtonScalePortrait = 0.205,
	MobilePinButtonXLandscape = 0.885,
	MobilePinButtonYLandscape = 0.705,
	MobilePinButtonXPortrait = 0.835,
	MobilePinButtonYPortrait = 0.745,
	GhostPartnerVisible = false,
	GhostPartTransparency = 1,
	GhostPartSize = 0.55,
	MobileCameraHeightLandscape = 90,
	MobileCameraBackLandscape = 76,
	MobileCameraFovLandscape = 66,
	MobileCameraHeightPortrait = 102,
	MobileCameraBackPortrait = 88,
	MobileCameraFovPortrait = 70,
}

return Config
