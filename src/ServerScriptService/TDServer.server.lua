-- Tension Doubles: PINTO HARE! / Roblox ver0.5.3
-- Server-authoritative MVP: court generation, teams, Beam nets, pin input state,
-- scripted ball movement, virtual-net hit detection, scoring, match loop, and Onboarding & Feel FX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeamsService = game:GetService("Teams")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("GameConfig"))
local MathUtil = require(ReplicatedStorage:WaitForChild("TDShared"):WaitForChild("MathUtil"))

math.randomseed(os.clock() * 1000000)

local RemotesFolder = ReplicatedStorage:FindFirstChild("TensionDoublesRemotes") or Instance.new("Folder")
RemotesFolder.Name = "TensionDoublesRemotes"
RemotesFolder.Parent = ReplicatedStorage

local function getOrCreateRemote(name)
	local remote = RemotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = RemotesFolder
	end
	return remote
end

local PinInputEvent = getOrCreateRemote("PinInputEvent")
local MatchStateEvent = getOrCreateRemote("MatchStateEvent")
local HitFxEvent = getOrCreateRemote("HitFxEvent")

local CourtFolder = workspace:FindFirstChild("TDCourt") or Instance.new("Folder")
CourtFolder.Name = "TDCourt"
CourtFolder.Parent = workspace

local VisualsFolder = CourtFolder:FindFirstChild("Visuals") or Instance.new("Folder")
VisualsFolder.Name = "Visuals"
VisualsFolder.Parent = CourtFolder

local SpawnFolder = CourtFolder:FindFirstChild("SpawnPoints") or Instance.new("Folder")
SpawnFolder.Name = "SpawnPoints"
SpawnFolder.Parent = CourtFolder

local playerState = {}
local score = { Red = 0, Blue = 0 }
local lastTeamHitTime = { Red = -math.huge, Blue = -math.huge }
local currentState = "WaitingForPlayers"
local matchRunning = false
local roundActive = false
local lastPointLoser = "Blue"
local winningTeam = nil
local rallyHitCount = 0
local hareCombo = { Red = 0, Blue = 0 }
local lastHareTime = { Red = -math.huge, Blue = -math.huge }
local lastGuidanceBroadcast = 0

local teamBeams = {}
local pinIndicators = {}
local ghostPartners = { Red = {}, Blue = {} }
local landingTargetMarker = nil
local lastLandingTargetUpdate = 0

local ball = {
	part = nil,
	position = Vector3.new(0, Config.ServeHeight, 0),
	velocity = Vector3.new(0, 0, 0),
	lastTouchedTeam = nil,
	active = false,
	pausedUntil = 0,
}

local TEAM_COLORS = {
	Red = Color3.fromRGB(255, 80, 80),
	Blue = Color3.fromRGB(80, 150, 255),
}

local BEAM_COLORS = {
	Slack = Color3.fromRGB(80, 170, 255),
	Normal = Color3.fromRGB(245, 245, 255),
	OverTension = Color3.fromRGB(255, 95, 95),
	Broken = Color3.fromRGB(80, 80, 80),
	Hare = Color3.fromRGB(255, 215, 80),
}

local function halfWidth()
	return Config.CourtWidth / 2
end

local function totalHalfDepth()
	return Config.CourtDepth + Config.OutZoneDepth
end

local teamCount
local getNetGuidanceForTeam
local isBallOutsideArena

local function broadcastState(message)
	local netGuidance = nil
	if getNetGuidanceForTeam then
		netGuidance = {
			Red = getNetGuidanceForTeam("Red"),
			Blue = getNetGuidanceForTeam("Blue"),
		}
	end

	MatchStateEvent:FireAllClients({
		state = currentState,
		redScore = score.Red,
		blueScore = score.Blue,
		message = message or "",
		winner = winningTeam,
		redPlayers = teamCount("Red"),
		bluePlayers = teamCount("Blue"),
		playersNeeded = Config.AllowGhostPartners and Config.MinPlayersToAutoStart or 4,
		title = Config.Title,
		netGuidance = netGuidance,
	})
end

local function setState(newState, message)
	currentState = newState
	broadcastState(message)
end

local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or CourtFolder
	return part
end

local function makeNonCollidePart(name, size, position, color, material, parent)
	local part = makePart(name, size, position, color, material, parent)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function addSurfaceText(part, text, color)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TD_Label"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.25
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
end

local function clearGeneratedCourt()
	for _, child in ipairs(CourtFolder:GetChildren()) do
		if child.Name ~= "Visuals" and child.Name ~= "SpawnPoints" then
			child:Destroy()
		end
	end
	for _, child in ipairs(SpawnFolder:GetChildren()) do
		child:Destroy()
	end
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		child:Destroy()
	end
	teamBeams = {}
	pinIndicators = {}
	landingTargetMarker = nil
end

local function createSpawn(name, pos)
	local spawn = Instance.new("Part")
	spawn.Name = name
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(2, 1, 2)
	spawn.Position = pos
	spawn.Parent = SpawnFolder
	return spawn
end

local function createFlag(teamName, x, z)
	local color = TEAM_COLORS[teamName]
	local pole = makeNonCollidePart(teamName .. "FlagPole", Vector3.new(0.28, 8, 0.28), Vector3.new(x, 4, z), Color3.fromRGB(230, 230, 240), Enum.Material.Metal)
	local flag = makeNonCollidePart(teamName .. "Flag", Vector3.new(5.2, 2.6, 0.22), Vector3.new(x + (x < 0 and 2.65 or -2.65), 7.0, z), color, Enum.Material.Neon)
	flag:SetAttribute("BaseColorR", color.R)
	flag:SetAttribute("BaseColorG", color.G)
	flag:SetAttribute("BaseColorB", color.B)
	addSurfaceText(flag, string.upper(teamName), Color3.fromRGB(255, 255, 255))
	return pole, flag
end

local function createCrowdDots()
	local total = totalHalfDepth()
	local w = Config.CourtWidth
	local count = Config.CrowdDotCountPerSide or 12
	for sideIndex, z in ipairs({ total + 5, -total - 5 }) do
		for i = 1, count do
			local t = (i - 0.5) / count
			local x = -w / 2 + t * w
			local dot = Instance.new("Part")
			dot.Name = "CrowdDot"
			dot.Shape = Enum.PartType.Ball
			dot.Anchored = true
			dot.CanCollide = false
			dot.CanQuery = false
			dot.CanTouch = false
			dot.Size = Vector3.new(1.15, 1.15, 1.15)
			dot.Position = Vector3.new(x, 1.1 + ((i % 3) * 0.18), z)
			dot.Material = Enum.Material.Neon
			local mix = (i + sideIndex) % 3
			if mix == 0 then
				dot.Color = TEAM_COLORS.Red
			elseif mix == 1 then
				dot.Color = TEAM_COLORS.Blue
			else
				dot.Color = Color3.fromRGB(255, 220, 95)
			end
			dot:SetAttribute("BaseColorR", dot.Color.R)
			dot:SetAttribute("BaseColorG", dot.Color.G)
			dot:SetAttribute("BaseColorB", dot.Color.B)
			dot:SetAttribute("CrowdOrder", i + (sideIndex - 1) * count)
			dot.Transparency = 0.22
			dot.Parent = VisualsFolder
		end
	end
end

local function createCourt()
	clearGeneratedCourt()

	local w = Config.CourtWidth
	local d = Config.CourtDepth
	local out = Config.OutZoneDepth
	local total = d + out

	makePart("FloatingBase", Vector3.new(w + 13, 1.1, total * 2 + 13), Vector3.new(0, -1.05, 0), Color3.fromRGB(14, 16, 24), Enum.Material.SmoothPlastic)
	makePart("Base", Vector3.new(w + 8, 0.4, total * 2 + 8), Vector3.new(0, -0.25, 0), Color3.fromRGB(28, 32, 42), Enum.Material.SmoothPlastic)
	makePart("RedCourt", Vector3.new(w, 0.24, d), Vector3.new(0, 0, d / 2), Color3.fromRGB(95, 42, 50), Enum.Material.SmoothPlastic)
	makePart("BlueCourt", Vector3.new(w, 0.24, d), Vector3.new(0, 0, -d / 2), Color3.fromRGB(40, 55, 95), Enum.Material.SmoothPlastic)
	makePart("RedOutZone", Vector3.new(w, 0.22, out), Vector3.new(0, 0.03, d + out / 2), Color3.fromRGB(55, 33, 38), Enum.Material.SmoothPlastic)
	makePart("BlueOutZone", Vector3.new(w, 0.22, out), Vector3.new(0, 0.03, -d - out / 2), Color3.fromRGB(28, 36, 58), Enum.Material.SmoothPlastic)
	makePart("CenterLine", Vector3.new(w + 0.5, 0.35, 0.7), Vector3.new(0, 0.12, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	local wallColor = Color3.fromRGB(18, 20, 27)
	makePart("Wall_Left", Vector3.new(0.7, Config.WallHeight, total * 2), Vector3.new(-w / 2 - 0.35, Config.WallHeight / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_Right", Vector3.new(0.7, Config.WallHeight, total * 2), Vector3.new(w / 2 + 0.35, Config.WallHeight / 2, 0), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_RedBack", Vector3.new(w + 1.4, Config.WallHeight, 0.7), Vector3.new(0, Config.WallHeight / 2, total + 0.35), wallColor, Enum.Material.SmoothPlastic)
	makePart("Wall_BlueBack", Vector3.new(w + 1.4, Config.WallHeight, 0.7), Vector3.new(0, Config.WallHeight / 2, -total - 0.35), wallColor, Enum.Material.SmoothPlastic)

	-- Neon arena trim. These pulse gold on HARE.
	local trimColor = Color3.fromRGB(130, 185, 255)
	local borders = {
		{ "JuiceBorder_Left", Vector3.new(0.22, 0.22, total * 2 + 1.0), Vector3.new(-w / 2 - 0.82, 0.28, 0) },
		{ "JuiceBorder_Right", Vector3.new(0.22, 0.22, total * 2 + 1.0), Vector3.new(w / 2 + 0.82, 0.28, 0) },
		{ "JuiceBorder_Red", Vector3.new(w + 1.6, 0.22, 0.22), Vector3.new(0, 0.28, total + 0.82) },
		{ "JuiceBorder_Blue", Vector3.new(w + 1.6, 0.22, 0.22), Vector3.new(0, 0.28, -total - 0.82) },
	}
	for _, info in ipairs(borders) do
		local strip = makeNonCollidePart(info[1], info[2], info[3], trimColor, Enum.Material.Neon, VisualsFolder)
		strip:SetAttribute("BaseColorR", trimColor.R)
		strip:SetAttribute("BaseColorG", trimColor.G)
		strip:SetAttribute("BaseColorB", trimColor.B)
	end

	-- Center emblem: floor-art style so it does not read as a physical obstacle.
	local emblemY = 0.154
	local emblem = makeNonCollidePart("CenterEmblemFloorArt", Vector3.new(Config.CenterEmblemSize, 0.014, Config.CenterEmblemSize), Vector3.new(0, emblemY, 0), Color3.fromRGB(245, 245, 255), Enum.Material.SmoothPlastic, VisualsFolder)
	emblem.Transparency = Config.CenterEmblemTransparency or 0.62
	local ring = makeNonCollidePart("CenterEmblemSoftRing", Vector3.new(Config.CenterEmblemSize * 1.16, 0.010, Config.CenterEmblemSize * 1.16), Vector3.new(0, emblemY + 0.006, 0), Color3.fromRGB(255, 230, 120), Enum.Material.SmoothPlastic, VisualsFolder)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(0, emblemY + 0.012, 0)
	ring.Transparency = 0.86
	ring.CastShadow = false
	local rayColor = Color3.fromRGB(255, 235, 130)
	for i = 1, 8 do
		local angle = (math.pi * 2) * (i - 1) / 8
		local ray = makeNonCollidePart("CenterEmblemRay", Vector3.new(0.12, 0.010, Config.CenterEmblemSize * 0.58), Vector3.new(0, emblemY + 0.012, 0), rayColor, Enum.Material.Neon, VisualsFolder)
		ray.CFrame = CFrame.new(0, emblemY + 0.012, 0) * CFrame.Angles(0, angle, 0)
		ray.Transparency = 0.76
		ray.CastShadow = false
	end

	-- Team banners/flags. Very cheap, very readable.
	createFlag("Red", -w / 2 - 4.5, total - 4)
	createFlag("Red", w / 2 + 4.5, total - 4)
	createFlag("Blue", -w / 2 - 4.5, -total + 4)
	createFlag("Blue", w / 2 + 4.5, -total + 4)
	createCrowdDots()

	createSpawn("RedSpawn1", Vector3.new(-10, 3, 18))
	createSpawn("RedSpawn2", Vector3.new(10, 3, 18))
	createSpawn("BlueSpawn1", Vector3.new(-10, 3, -18))
	createSpawn("BlueSpawn2", Vector3.new(10, 3, -18))
end

local function ensureTeams()
	for teamName, color in pairs(TEAM_COLORS) do
		local team = TeamsService:FindFirstChild(teamName)
		if not team then
			team = Instance.new("Team")
			team.Name = teamName
			team.AutoAssignable = false
			team.Parent = TeamsService
		end
		team.TeamColor = BrickColor.new(color)
	end
end

local function createGhostPart(teamName, index, position)
	local part = Instance.new("Part")
	part.Name = teamName .. "GhostPartner" .. tostring(index)
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	local ghostSize = Config.GhostPartSize or 0.55
	part.Size = Vector3.new(ghostSize, ghostSize, ghostSize)
	part.Material = Enum.Material.Neon
	part.Transparency = (Config.GhostPartnerVisible == true) and 0.55 or (Config.GhostPartTransparency or 1)
	part.CastShadow = false
	part.Color = TEAM_COLORS[teamName]
	part.Position = position
	part.Parent = VisualsFolder

	local attachment = Instance.new("Attachment")
	attachment.Name = "TDNetAttachment"
	attachment.Parent = part
	return part
end

local function ensureGhostPartners()
	for teamName, side in pairs({ Red = 1, Blue = -1 }) do
		ghostPartners[teamName] = ghostPartners[teamName] or {}
		for i = 1, 2 do
			if not ghostPartners[teamName][i] or not ghostPartners[teamName][i].Parent then
				local x = (i == 1) and -8 or 8
				local z = side * 18
				ghostPartners[teamName][i] = createGhostPart(teamName, i, Vector3.new(x, Config.NetVisualHeight, z))
			end
		end
	end
end

local function ensureBallReadabilityHalo(part)
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if not (halo and halo:IsA("BasePart")) then
		halo = Instance.new("Part")
		halo.Name = "TD_BallReadabilityHalo"
		halo.Parent = workspace
	end

	halo.Shape = Enum.PartType.Ball
	halo.Anchored = true
	halo.CanCollide = false
	halo.CanQuery = false
	halo.CanTouch = false
	halo.CastShadow = false
	local haloSize = Config.BallReadabilityHaloSize or 4.4
	halo.Size = Vector3.new(haloSize, haloSize, haloSize)
	halo.Material = Enum.Material.Neon
	halo.Color = Color3.fromRGB(255, 242, 150)
	halo.Transparency = Config.BallReadabilityHaloTransparency or 0.62
	halo.CFrame = part.CFrame
	return halo
end

local function ensureBallPart()
	if ball.part and ball.part.Parent then
		ensureBallReadabilityHalo(ball.part)
		return ball.part
	end

	local part = Instance.new("Part")
	part.Name = "TensionBall"
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(Config.BallRadius * 2, Config.BallRadius * 2, Config.BallRadius * 2)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 245, 180)

	local light = Instance.new("PointLight")
	light.Name = "MobileReadableGlow"
	light.Brightness = Config.BallReadableGlowBrightness or 3.4
	light.Range = Config.BallReadableGlowRange or 22
	light.Color = Color3.fromRGB(255, 240, 160)
	light.Parent = part

	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(0, Config.BallRadius * 0.55, 0)
	a0.Parent = part

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(0, -Config.BallRadius * 0.55, 0)
	a1.Parent = part

	local trail = Instance.new("Trail")
	trail.Name = "BallTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = Config.BallTrailLifetime or 0.50
	trail.MinLength = 0.2
	trail.LightEmission = 0.95
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 245, 180))
	trail.Parent = part

	part.Parent = workspace
	ball.part = part
	ensureBallReadabilityHalo(part)
	return part
end

local function setBallVisualCFrame(cframe)
	if ball.part then
		ball.part.CFrame = cframe
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.CFrame = cframe
	end
end

local function setBallVisualHidden(hidden)
	local transparency = hidden and 1 or 0
	if ball.part then
		ball.part.Transparency = transparency
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.Transparency = hidden and 1 or (Config.BallReadabilityHaloTransparency or 0.62)
	end
end

local function ensureLandingTargetMarker()
	if landingTargetMarker and landingTargetMarker.Parent then
		return landingTargetMarker
	end

	local marker = Instance.new("Part")
	marker.Name = "TD_LandingTargetMarker"
	marker.Shape = Enum.PartType.Cylinder
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	local size = Config.LandingTargetSize or 5.8
	marker.Size = Vector3.new(Config.LandingTargetThickness or 0.09, size, size)
	marker.Material = Enum.Material.Neon
	marker.Color = Config.LandingTargetInColor or Color3.fromRGB(255, 240, 130)
	marker.Transparency = 1
	marker.CFrame = CFrame.new(0, -1000, 0)
	marker.Parent = VisualsFolder
	landingTargetMarker = marker
	return marker
end

local function hideLandingTargetMarker()
	local marker = landingTargetMarker
	if marker and marker.Parent then
		marker.Transparency = 1
		marker.CFrame = CFrame.new(0, -1000, 0)
	end
end

local function predictBallLanding()
	local maxTime = Config.LandingTargetMaxPredictionTime or 2.4
	local gravity = Config.BallGravity or 42
	local targetY = Config.BallRadius or 1.72
	local y0 = ball.position.Y
	local vy = ball.velocity.Y
	local a = -0.5 * gravity
	local b = vy
	local c = y0 - targetY
	local t = maxTime
	local discriminant = b * b - 4 * a * c

	if discriminant >= 0 and a ~= 0 then
		local sqrtDiscriminant = math.sqrt(discriminant)
		local t1 = (-b + sqrtDiscriminant) / (2 * a)
		local t2 = (-b - sqrtDiscriminant) / (2 * a)
		local best = math.huge
		if t1 > 0 then
			best = math.min(best, t1)
		end
		if t2 > 0 then
			best = math.min(best, t2)
		end
		if best < math.huge then
			t = math.min(best, maxTime)
		end
	end

	local predicted = ball.position + ball.velocity * t + Vector3.new(0, -0.5 * gravity * t * t, 0)
	local out = isBallOutsideArena(predicted)
	local clampedX = math.clamp(predicted.X, -halfWidth(), halfWidth())
	local clampedZ = math.clamp(predicted.Z, -totalHalfDepth(), totalHalfDepth())
	return Vector3.new(clampedX, 0.33, clampedZ), out
end

local function updateLandingTargetMarker()
	if Config.LandingTargetEnabled == false then
		hideLandingTargetMarker()
		return
	end
	if not ball.active or not roundActive then
		hideLandingTargetMarker()
		return
	end

	local now = os.clock()
	if now - lastLandingTargetUpdate < (Config.LandingTargetUpdateInterval or 0.08) then
		return
	end
	lastLandingTargetUpdate = now

	local marker = ensureLandingTargetMarker()
	local position, out = predictBallLanding()
	local size = Config.LandingTargetSize or 5.8
	marker.Size = Vector3.new(Config.LandingTargetThickness or 0.09, size, size)
	marker.Color = out and (Config.LandingTargetOutColor or Color3.fromRGB(255, 80, 80)) or (Config.LandingTargetInColor or Color3.fromRGB(255, 240, 130))
	marker.Transparency = out and (Config.LandingTargetOutTransparency or 0.12) or (Config.LandingTargetTransparency or 0.28)
	marker.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

local getAliveRoot

local function ensurePinIndicator(player)
	local key = tostring(player.UserId)
	local ring = pinIndicators[key]
	if ring and ring.Parent then
		return ring
	end

	ring = Instance.new("Part")
	ring.Name = "TD_PinRing_" .. key
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Size = Vector3.new(Config.PinRingRadius, Config.PinRingHeight, Config.PinRingRadius)
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 80)
	ring.Transparency = 1
	ring.Parent = VisualsFolder
	pinIndicators[key] = ring
	return ring
end

local function updatePinIndicators()
	for _, player in ipairs(Players:GetPlayers()) do
		local root = getAliveRoot(player)
		local state = playerState[player]
		local ring = ensurePinIndicator(player)
		if root and state and state.IsPinning then
			local teamName = player.Team and player.Team.Name
			local color = teamName and TEAM_COLORS[teamName] or Color3.fromRGB(255, 220, 80)
			ring.Color = color:Lerp(Color3.fromRGB(255, 220, 80), 0.45)
			ring.Transparency = 0.34
			ring.CFrame = CFrame.new(root.Position.X, 0.18, root.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		else
			ring.Transparency = 1
			ring.CFrame = CFrame.new(0, -1000, 0)
		end
	end
end

local function countRealPinning(teamName)
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			local state = playerState[player]
			if state and state.IsPinning and getAliveRoot(player) then
				count += 1
			end
		end
	end
	return count
end

local function getTeamPlayers(teamName)
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == teamName then
			table.insert(result, player)
		end
	end
	return result
end

getAliveRoot = function(player)
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function ensureNetAttachment(root)
	local attachment = root:FindFirstChild("TDNetAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "TDNetAttachment"
		attachment.Position = Vector3.new(0, 0, 0)
		attachment.Parent = root
	end
	return attachment
end

local function configureCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 8)
	local root = character:WaitForChild("HumanoidRootPart", 8)
	if humanoid then
		humanoid.WalkSpeed = Config.WalkSpeed
		pcall(function()
			humanoid.JumpHeight = Config.JumpHeight
		end)
	end
	if root then
		ensureNetAttachment(root)
	end
end

teamCount = function(teamName)
	return #getTeamPlayers(teamName)
end

local function assignTeam(player)
	local redTeam = TeamsService:FindFirstChild("Red")
	local blueTeam = TeamsService:FindFirstChild("Blue")
	if not redTeam or not blueTeam then
		return
	end

	if teamCount("Red") <= teamCount("Blue") then
		player.Team = redTeam
	else
		player.Team = blueTeam
	end
	player.Neutral = false
end

local function teleportToSpawn(player)
	local teamName = player.Team and player.Team.Name or "Red"
	local teamPlayers = getTeamPlayers(teamName)
	local index = 1
	for i, p in ipairs(teamPlayers) do
		if p == player then
			index = math.clamp(i, 1, 2)
			break
		end
	end
	local spawn = SpawnFolder:FindFirstChild(teamName .. "Spawn" .. tostring(index))
	local root = getAliveRoot(player)
	if spawn and root then
		root.CFrame = CFrame.new(spawn.Position)
	end
end

local function setupLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	if not leaderstats:FindFirstChild("Wins") then
		local wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Value = 0
		wins.Parent = leaderstats
	end
end

local function onPlayerAdded(player)
	setupLeaderstats(player)
	playerState[player] = {
		IsPinning = false,
		LastPinStartTime = -math.huge,
	}
	assignTeam(player)

	player.CharacterAdded:Connect(function(character)
		configureCharacter(player, character)
		task.wait(0.1)
		teleportToSpawn(player)
	end)

	if player.Character then
		configureCharacter(player, player.Character)
		task.wait(0.1)
		teleportToSpawn(player)
	end

	broadcastState("Welcome to PINTO HARE!")
end

local function onPlayerRemoving(player)
	playerState[player] = nil
end

local function makeBeam(teamName)
	local beam = Instance.new("Beam")
	beam.Name = teamName .. "TensionBeam"
	beam.FaceCamera = true
	beam.Width0 = Config.BeamWidth
	beam.Width1 = Config.BeamWidth
	beam.TextureSpeed = Config.BeamTextureSpeed
	beam.LightEmission = 0.55
	beam.Transparency = NumberSequence.new(0.15)
	beam.Color = ColorSequence.new(BEAM_COLORS.Normal)
	beam.Parent = VisualsFolder
	return beam
end

local function getNetEndpoints(teamName)
	local endpoints = {}
	local players = getTeamPlayers(teamName)

	for _, player in ipairs(players) do
		local root = getAliveRoot(player)
		if root then
			local attachment = ensureNetAttachment(root)
			table.insert(endpoints, {
				kind = "player",
				player = player,
				part = root,
				attachment = attachment,
				position = attachment.WorldPosition,
			})
		end
	end

	if Config.AllowGhostPartners then
		local ghosts = ghostPartners[teamName]
		local ghostIndex = 1
		while #endpoints < 2 and ghosts and ghosts[ghostIndex] do
			local ghost = ghosts[ghostIndex]
			local attachment = ghost:FindFirstChild("TDNetAttachment")
			if attachment then
				table.insert(endpoints, {
					kind = "ghost",
					part = ghost,
					attachment = attachment,
					position = attachment.WorldPosition,
				})
			end
			ghostIndex += 1
		end
	end

	if #endpoints < 2 then
		return nil, nil
	end
	return endpoints[1], endpoints[2]
end

local function getTensionState(a, b)
	local d = MathUtil.xzDistance(a.position, b.position)
	if d >= Config.BrokenDistance then
		return "Broken", d
	elseif d < Config.SlackDistance then
		return "Slack", d
	elseif d < Config.GoodDistanceMax then
		return "Normal", d
	else
		return "OverTension", d
	end
end

local function updateGhostPartners()
	if not Config.AllowGhostPartners then
		return
	end

	for _, teamName in ipairs({ "Red", "Blue" }) do
		local side = MathUtil.teamSideSign(teamName)
		local players = getTeamPlayers(teamName)
		local realRoots = {}
		for _, player in ipairs(players) do
			local root = getAliveRoot(player)
			if root then
				table.insert(realRoots, root)
			end
		end

		local ghosts = ghostPartners[teamName]
		if #realRoots == 0 then
			if ghosts[1] then ghosts[1].Position = Vector3.new(-8, Config.NetVisualHeight, side * 18) end
			if ghosts[2] then ghosts[2].Position = Vector3.new(8, Config.NetVisualHeight, side * 18) end
		elseif #realRoots == 1 then
			local root = realRoots[1]
			local offsetX = (root.Position.X < 0) and 14 or -14
			local target = Vector3.new(
				math.clamp(root.Position.X + offsetX, -halfWidth() + 3, halfWidth() - 3),
				Config.NetVisualHeight,
				math.clamp(root.Position.Z, side == 1 and 3 or -totalHalfDepth() + 3, side == 1 and totalHalfDepth() - 3 or -3)
			)
			if ghosts[1] then ghosts[1].Position = target end
		else
			-- Hide ghosts below the floor when the real pair exists.
			if ghosts[1] then ghosts[1].Position = Vector3.new(-1000, -1000, -1000) end
			if ghosts[2] then ghosts[2].Position = Vector3.new(-1000, -1000, -1000) end
		end
	end
end

local function updateTeamBeam(teamName)
	local a, b = getNetEndpoints(teamName)
	local beam = teamBeams[teamName]
	if not beam then
		beam = makeBeam(teamName)
		teamBeams[teamName] = beam
	end

	if not a or not b then
		beam.Enabled = false
		return
	end

	beam.Enabled = true
	beam.Attachment0 = a.attachment
	beam.Attachment1 = b.attachment

	local tensionState = getTensionState(a, b)
	local realPinCount = countRealPinning(teamName)
	local color = BEAM_COLORS[tensionState] or BEAM_COLORS.Normal
	local width = Config.BeamWidth
	local transparency = 0.12
	local curve = Config.BeamCurveNormal or 0

	if tensionState == "Slack" then
		width = Config.BeamWidthSlack or (Config.BeamWidth - 0.55)
		transparency = Config.BeamSlackTransparency or 0.32
		curve = Config.BeamCurveSlack or 2.8
	elseif tensionState == "OverTension" then
		width = Config.BeamWidthOverTension or (Config.BeamWidth - 0.25)
		transparency = 0.08
		curve = Config.BeamCurveOverTension or -1.1
	elseif realPinCount >= 2 and tensionState ~= "Broken" then
		color = BEAM_COLORS.Hare
		width = Config.BeamWidth + (Config.BeamWidthHareBonus or 0.82)
		transparency = Config.BeamHareTransparency or 0
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
	beam.Color = ColorSequence.new(color)
	beam.Width0 = width
	beam.Width1 = width
	beam.Transparency = NumberSequence.new(transparency)
end

local function getTeamPinInfo(teamName)
	local pinCount = 0
	local minStart = math.huge
	local maxStart = -math.huge
	local realCount = 0
	local realPinning = false
	local realPinStart = -math.huge

	for _, player in ipairs(getTeamPlayers(teamName)) do
		local root = getAliveRoot(player)
		if root then
			realCount += 1
			local state = playerState[player]
			if state and state.IsPinning then
				pinCount += 1
				realPinning = true
				realPinStart = state.LastPinStartTime
				minStart = math.min(minStart, state.LastPinStartTime)
				maxStart = math.max(maxStart, state.LastPinStartTime)
			end
		end
	end

	if Config.AllowGhostPartners and Config.GhostMirrorsPinning and realCount == 1 and realPinning then
		-- Solo/2-player test helper: the ghost partner copies your pin timing.
		pinCount = 2
		minStart = math.min(minStart, realPinStart)
		maxStart = math.max(maxStart, realPinStart)
	end

	if Config.AllowGhostPartners and Config.SoloGhostsMirrorPinning and realCount == 0 and #Players:GetPlayers() == 1 then
		-- Solo party test helper: empty-side ghosts can still create HARE moments.
		for _, player in ipairs(Players:GetPlayers()) do
			local state = playerState[player]
			if state and state.IsPinning and getAliveRoot(player) then
				pinCount = 2
				minStart = state.LastPinStartTime
				maxStart = state.LastPinStartTime
				break
			end
		end
	end

	if pinCount == 0 then
		minStart = -math.huge
		maxStart = -math.huge
	end

	return {
		pinCount = pinCount,
		minStart = minStart,
		maxStart = maxStart,
	}
end

getNetGuidanceForTeam = function(teamName)
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

local function clampPlayersToCourt()
	if not Config.ClampPlayersToCourt then
		return
	end

	local xMin = -halfWidth() + 1.5
	local xMax = halfWidth() - 1.5
	local zTotal = totalHalfDepth() - 1.5

	for _, player in ipairs(Players:GetPlayers()) do
		local root = getAliveRoot(player)
		local teamName = player.Team and player.Team.Name
		if root and (teamName == "Red" or teamName == "Blue") then
			local pos = root.Position
			local x = math.clamp(pos.X, xMin, xMax)
			local z
			if teamName == "Red" then
				z = math.clamp(pos.Z, 1.5, zTotal)
			else
				z = math.clamp(pos.Z, -zTotal, -1.5)
			end
			if math.abs(x - pos.X) > 0.05 or math.abs(z - pos.Z) > 0.05 then
				local newPos = Vector3.new(x, pos.Y, z)
				root.CFrame = CFrame.new(newPos, newPos + root.CFrame.LookVector)
			end
		end
	end
end

local function resetPlayersToSpawns()
	for _, player in ipairs(Players:GetPlayers()) do
		teleportToSpawn(player)
		local state = playerState[player]
		if state then
			state.IsPinning = false
			state.LastPinStartTime = -math.huge
		end
	end
end

local function serveBall(servingTeam)
	rallyHitCount = 0
	local side = MathUtil.teamSideSign(servingTeam)
	local part = ensureBallPart()

	-- v0.5.3: Serve uses its own speed/arc.
	-- Return balance lowered PIN shots in v0.5.2, but the opening serve also became too short.
	-- Keep serves friendly, but make them land around the opponent mid-court instead of the front edge.
	local startZ = side * (Config.ServeStartZ or 7.5)
	local lateralMax = Config.ServeLateralMax or 4.5
	local serveY = Config.ServeVerticalVelocity or 5.2
	ball.position = Vector3.new(0, Config.ServeHeight, startZ)
	ball.velocity = Vector3.new(math.random(-lateralMax * 10, lateralMax * 10) / 10, serveY, -side * Config.BallServeSpeed)
	ball.lastTouchedTeam = servingTeam
	ball.active = true
	ball.pausedUntil = 0
	local trail = part:FindFirstChild("BallTrail")
	if trail and trail:IsA("Trail") then
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 245, 180))
	end
	part.Color = Color3.fromRGB(255, 245, 180)
	setBallVisualHidden(false)
	setBallVisualCFrame(CFrame.new(ball.position))
end

local function hideBall()
	ball.active = false
	setBallVisualHidden(true)
	setBallVisualCFrame(CFrame.new(0, -100, 0))
	hideLandingTargetMarker()
end

local spawnShockwave

local function awardPoint(scoringTeam, reason, losingTeam)
	if not roundActive then
		return
	end
	score[scoringTeam] += 1
	local rallyCountAtPoint = rallyHitCount
	hareCombo.Red = 0
	hareCombo.Blue = 0
	lastPointLoser = losingTeam or MathUtil.opponent(scoringTeam)
	roundActive = false

	if ball.part then
		spawnShockwave(ball.position, TEAM_COLORS[scoringTeam]:Lerp(Color3.fromRGB(255, 255, 255), 0.2), Config.PointBurstSize, Config.PointBurstDuration, "TD_PointBurst")
	end
	hideBall()

	local rallyText = ""
	if rallyCountAtPoint >= Config.ShowRallyOnPointAt then
		rallyText = "  RALLY x" .. tostring(rallyCountAtPoint)
	end
	local text = string.format("%s +1  %s%s", string.upper(scoringTeam), reason or "", rallyText)
	rallyHitCount = 0
	setState("PointScored", text)
end

isBallOutsideArena = function(pos)
	return math.abs(pos.X) > halfWidth() or math.abs(pos.Z) > totalHalfDepth()
end

local function processGroundOrOut()
	local pos = ball.position

	if isBallOutsideArena(pos) then
		local losingTeam = ball.lastTouchedTeam or ((pos.Z >= 0) and "Red" or "Blue")
		awardPoint(MathUtil.opponent(losingTeam), Config.ScoreReasonOutText or "OUT!", losingTeam)
		return true
	end

	if pos.Y <= Config.BallRadius then
		if pos.Z >= 0 then
			awardPoint("Blue", Config.ScoreReasonDropText or "DROP!", "Red")
		else
			awardPoint("Red", Config.ScoreReasonDropText or "DROP!", "Blue")
		end
		return true
	end

	return false
end

local function getStoredBaseColor(part, fallback)
	local r = part:GetAttribute("BaseColorR")
	local g = part:GetAttribute("BaseColorG")
	local b = part:GetAttribute("BaseColorB")
	if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
		return Color3.new(r, g, b)
	end
	return fallback
end

local function pulseCrowd(teamName)
	if not Config.CourtJuiceEnabled then
		return
	end
	local teamColor = teamName == "Red" and TEAM_COLORS.Red or TEAM_COLORS.Blue
	local pulseColor = teamColor:Lerp(BEAM_COLORS.Hare, 0.52)
	local dots = {}
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "CrowdDot" then
			table.insert(dots, child)
		end
	end
	table.sort(dots, function(a, b)
		return (a:GetAttribute("CrowdOrder") or 0) < (b:GetAttribute("CrowdOrder") or 0)
	end)
	for index, dot in ipairs(dots) do
		task.delay((index - 1) * (Config.CrowdWaveDelayPerDot or 0.028), function()
			if not dot or not dot.Parent then
				return
			end
			local baseColor = getStoredBaseColor(dot, dot.Color)
			dot.Color = pulseColor
			dot.Size = Vector3.new(1.45, 1.45, 1.45)
			dot.Transparency = 0.02
			TweenService:Create(dot, TweenInfo.new(Config.CrowdWaveDuration or 0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Color = baseColor,
				Transparency = 0.22,
				Size = Vector3.new(1.15, 1.15, 1.15),
			}):Play()
		end)
	end
end

local function pulseArena(teamName)
	if not Config.CourtJuiceEnabled then
		return
	end
	pulseCrowd(teamName)
	local pulseColor = teamName == "Red" and TEAM_COLORS.Red or TEAM_COLORS.Blue
	pulseColor = pulseColor:Lerp(BEAM_COLORS.Hare, 0.45)
	for _, child in ipairs(VisualsFolder:GetChildren()) do
		if child:IsA("BasePart") and string.sub(child.Name, 1, 11) == "JuiceBorder" then
			local baseColor = getStoredBaseColor(child, Color3.fromRGB(130, 185, 255))
			child.Color = pulseColor
			child.Transparency = 0
			TweenService:Create(child, TweenInfo.new(Config.ArenaGlowPulseDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Color = baseColor,
				Transparency = 0.08,
			}):Play()
		end
	end
end

spawnShockwave = function(position, color, size, duration, name)
	local wave = Instance.new("Part")
	wave.Name = name or "TD_Shockwave"
	wave.Shape = Enum.PartType.Cylinder
	wave.Anchored = true
	wave.CanCollide = false
	wave.CanQuery = false
	wave.CanTouch = false
	wave.Material = Enum.Material.Neon
	wave.Color = color
	wave.Transparency = 0.24
	wave.Size = Vector3.new(0.2, 0.08, 0.2)
	wave.CFrame = CFrame.new(position.X, 0.35, position.Z)
	wave.Parent = VisualsFolder

	TweenService:Create(wave, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(size, 0.08, size),
		Transparency = 1,
	}):Play()
	Debris:AddItem(wave, duration + 0.1)
end

local function spawnHareSparkColumn(position)
	local duration = Config.HareSparkColumnDuration or 0.34
	local height = Config.HareSparkColumnHeight or 18
	local width = Config.HareSparkColumnWidth or 1.4
	local spark = Instance.new("Part")
	spark.Name = "TD_HareSparkColumn"
	spark.Shape = Enum.PartType.Cylinder
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.CanTouch = false
	spark.CastShadow = false
	spark.Material = Enum.Material.Neon
	spark.Color = Color3.fromRGB(255, 240, 120)
	spark.Transparency = 0.18
	spark.Size = Vector3.new(height, width, width)
	spark.CFrame = CFrame.new(position.X, height / 2, position.Z) * CFrame.Angles(0, 0, math.rad(90))
	spark.Parent = VisualsFolder

	TweenService:Create(spark, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(height * 1.10, width * 2.2, width * 2.2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(spark, duration + 0.1)
end

local function fireHitFx(fxType, position, teamName)
	local combo = hareCombo[teamName] or 0
	HitFxEvent:FireAllClients(fxType, position, teamName, rallyHitCount, combo)
end

local function setBallVisualForFx(fxType)
	local part = ball.part
	if not part then
		return
	end
	local color = Color3.fromRGB(255, 245, 180)
	if fxType == "Hare" then
		color = Color3.fromRGB(255, 220, 80)
	elseif fxType == "OnePin" then
		color = Color3.fromRGB(255, 160, 95)
	elseif fxType == "Slack" then
		color = Color3.fromRGB(95, 190, 255)
	elseif fxType == "OverTension" then
		color = Color3.fromRGB(255, 90, 90)
	end
	part.Color = color
	local light = part:FindFirstChild("MobileReadableGlow")
	if light and light:IsA("PointLight") then
		light.Color = color
		light.Brightness = fxType == "Hare" and (Config.HareGlowBrightness or 4.4) or (Config.BallReadableGlowBrightness or 3.4)
		light.Range = Config.BallReadableGlowRange or 22
	end
	local trail = part:FindFirstChild("BallTrail")
	if trail and trail:IsA("Trail") then
		trail.Color = ColorSequence.new(color)
		trail.Lifetime = fxType == "Hare" and (Config.HareTrailLifetime or 0.56) or (Config.BallTrailLifetime or 0.50)
	end
	local halo = workspace:FindFirstChild("TD_BallReadabilityHalo")
	if halo and halo:IsA("BasePart") then
		halo.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
		halo.Transparency = Config.BallReadabilityHaloTransparency or 0.62
	end
end

local function shouldApplyEarlyRallyAssist(fxType)
	return fxType ~= "Hare" and rallyHitCount < (Config.EarlyRallyAssistHits or 0)
end

local function applyEarlyRallyAssist(fxType, lift, power)
	if not shouldApplyEarlyRallyAssist(fxType) then
		return lift, power
	end
	local assistedLift = math.max(lift, Config.EarlyRallyAssistLiftFloor or lift)
	local assistedPower = math.max(Config.BallMinSpeed, power - (Config.EarlyRallyAssistPowerTrim or 0))
	return assistedLift, assistedPower
end

local function processNetHit(teamName)
	if not ball.active then
		return false
	end
	if ball.lastTouchedTeam == teamName then
		return false -- v0.4 keeps one-touch returns for mobile clarity
	end
	if os.clock() - lastTeamHitTime[teamName] < Config.HitCooldown then
		return false
	end

	local side = MathUtil.teamSideSign(teamName)
	if ball.position.Z * side < -1.5 then
		return false
	end
	if ball.position.Y < Config.NetMinHeight or ball.position.Y > Config.NetMaxHeight then
		return false
	end

	local a, b = getNetEndpoints(teamName)
	if not a or not b then
		return false
	end

	local tensionState = getTensionState(a, b)
	if tensionState == "Broken" then
		return false
	end

	local distance, closest, t = MathUtil.distancePointToSegment(ball.position, a.position, b.position)
	if distance > Config.NetHitRadius then
		return false
	end

	local now = os.clock()
	local pinInfo = getTeamPinInfo(teamName)
	local pinCount = pinInfo.pinCount
	local isHare = false
	if pinCount >= 2 and tensionState == "Normal" then
		local pinDelta = pinInfo.maxStart - pinInfo.minStart
		local contactWindow = now - pinInfo.maxStart
		local hareWindow = math.max(Config.HareContactWindow or 0.45, Config.HareHoldWindow or 0)
		if Config.HareRequiresFreshPin ~= false then
			isHare = pinDelta <= Config.HarePinDelta and contactWindow <= hareWindow
		else
			isHare = pinDelta <= Config.HarePinDelta
		end
	end

	local distanceBonus = 0
	if tensionState == "Slack" then
		distanceBonus = Config.PowerBonusSlack or -8
	elseif tensionState == "Normal" then
		distanceBonus = Config.PowerBonusNormal or 2
	elseif tensionState == "OverTension" then
		distanceBonus = Config.PowerBonusOverTension or 6
	end

	local pinBonus = 0
	if pinCount >= 2 then
		pinBonus = Config.PowerBonusBothPin or 7
	elseif pinCount == 1 then
		pinBonus = Config.PowerBonusOnePin or 3
	end

	local hareBonus = isHare and (Config.PowerBonusHare or 6) or 0
	local rallyBonus = math.min(rallyHitCount * Config.RallySpeedBonusPerHit, Config.RallySpeedBonusMax)
	local power = math.clamp(Config.BallBaseSpeed + distanceBonus + pinBonus + hareBonus + rallyBonus, Config.BallMinSpeed, Config.BallMaxSpeed)

	local flatA = Vector3.new(a.position.X, 0, a.position.Z)
	local flatB = Vector3.new(b.position.X, 0, b.position.Z)
	local netDir = MathUtil.safeUnit(flatB - flatA, Vector3.new(1, 0, 0))
	local normalA = Vector3.new(-netDir.Z, 0, netDir.X)
	local normalB = -normalA
	local desiredZSign = (teamName == "Red") and -1 or 1
	local returnDir = (normalA.Z * desiredZSign >= normalB.Z * desiredZSign) and normalA or normalB

	local incomingFlat = MathUtil.safeUnit(Vector3.new(ball.velocity.X, 0, ball.velocity.Z), returnDir)
	local reflectedIncoming = Vector3.new(incomingFlat.X, 0, -incomingFlat.Z)
	local edgeWobble = netDir * ((t - 0.5) * 0.32)
	local horizontal = MathUtil.safeUnit(returnDir * 0.78 + reflectedIncoming * 0.20 + edgeWobble, returnDir)

	local fxType = "Normal"
	local lift = Config.ReturnLiftNormal or Config.ReturnLift

	if tensionState == "Slack" then
		fxType = "Slack"
		lift = Config.ReturnLiftSlack or 0.38
	elseif tensionState == "OverTension" then
		fxType = "OverTension"
		lift = Config.ReturnLiftOverTension or 0.20
		local wobbleSign = (math.random() < 0.5) and -1 or 1
		horizontal = MathUtil.safeUnit(horizontal + netDir * wobbleSign * (Config.OverTensionWobbleScale or 0.42), returnDir)
	elseif pinCount == 1 then
		fxType = "OnePin"
		lift = Config.ReturnLiftOnePin or 0.30
		local spinSign = (math.random() < 0.5) and -1 or 1
		horizontal = MathUtil.safeUnit(horizontal + netDir * spinSign * 0.35, returnDir)
	end

	if isHare then
		fxType = "Hare"
		lift = Config.ReturnLiftHare or 0.22
		if now - lastHareTime[teamName] <= Config.HareComboWindow then
			hareCombo[teamName] += 1
		else
			hareCombo[teamName] = 1
		end
		lastHareTime[teamName] = now
	else
		hareCombo[teamName] = 0
	end

	lift, power = applyEarlyRallyAssist(fxType, lift, power)
	local finalDir = MathUtil.safeUnit(horizontal + Vector3.new(0, lift, 0), returnDir)
	local finalVelocity = finalDir * power

	-- v0.5.2: cap only the forward court direction. This keeps shots lively sideways,
	-- but prevents normal PIN returns from immediately sailing beyond the back line.
	if Config.ForwardSpeedCapEnabled ~= false then
		local forwardCap = Config.ReturnMaxForwardSpeed or 32
		if fxType == "Hare" then
			forwardCap = Config.HareMaxForwardSpeed or forwardCap
		elseif fxType == "Pin" then
			forwardCap = Config.PinMaxForwardSpeed or forwardCap
		elseif fxType == "OnePin" then
			forwardCap = Config.OnePinMaxForwardSpeed or forwardCap
		elseif fxType == "OverTension" then
			forwardCap = Config.OverTensionMaxForwardSpeed or forwardCap
		elseif fxType == "Slack" then
			forwardCap = Config.SlackMaxForwardSpeed or forwardCap
		end
		if shouldApplyEarlyRallyAssist(fxType) then
			forwardCap = math.min(forwardCap, Config.EarlyRallyAssistForwardCap or forwardCap)
		end

		if math.abs(finalVelocity.Z) > forwardCap then
			finalVelocity = Vector3.new(finalVelocity.X, finalVelocity.Y, math.sign(finalVelocity.Z) * forwardCap)
		end
	end

	ball.velocity = finalVelocity
	ball.position = closest + returnDir * (Config.NetHitRadius + 0.45) + Vector3.new(0, 0.3, 0)
	ball.lastTouchedTeam = teamName
	lastTeamHitTime[teamName] = now
	rallyHitCount += 1
	setBallVisualForFx(fxType)

	if fxType == "Slack" then
		spawnShockwave(closest, BEAM_COLORS.Slack, Config.SlackAbsorbRippleSize or 9, Config.SlackAbsorbRippleDuration or 0.34, "TD_SlackAbsorbRipple")
	end

	if fxType == "Hare" then
		ball.pausedUntil = now + Config.HareFreezeTime
		spawnShockwave(closest, BEAM_COLORS.Hare, Config.HareShockwaveSize, Config.HareShockwaveDuration, "TD_HareShockwave")
		spawnShockwave(closest, Color3.fromRGB(255, 246, 160), Config.HareHardeningRingSize or 16, Config.HareHardeningRingDuration or 0.30, "TD_HareHardeningRing")
		spawnHareSparkColumn(closest)
		pulseArena(teamName)
	end

	if ball.part then
		setBallVisualCFrame(CFrame.new(ball.position))
	end

	fireHitFx(fxType, closest, teamName)
	return true
end

local function updateBall(dt)
	if not ball.active or not roundActive then
		return
	end

	if os.clock() < (ball.pausedUntil or 0) then
		setBallVisualCFrame(CFrame.new(ball.position))
		return
	end

	-- Try hits before moving and after moving to reduce tunneling on faster shots.
	processNetHit("Red")
	processNetHit("Blue")

	ball.velocity += Vector3.new(0, -Config.BallGravity * dt, 0)
	ball.velocity = MathUtil.clampMagnitude(ball.velocity, Config.BallMaxSpeed)
	ball.position += ball.velocity * dt

	processNetHit("Red")
	processNetHit("Blue")

	setBallVisualCFrame(CFrame.new(ball.position))

	processGroundOrOut()
end

local function canStartMatch()
	local count = #Players:GetPlayers()
	if Config.AllowGhostPartners then
		return count >= Config.MinPlayersToAutoStart
	end
	return count >= 4
end

local function runCountdown()
	setState("Countdown", "3")
	for i = Config.CountdownTime, 1, -1 do
		setState("Countdown", tostring(i))
		task.wait(1)
	end
	setState("Countdown", Config.StartMessage)
	task.wait(0.45)
end

local function finishGame(winner)
	winningTeam = winner
	setState("GameOver", string.upper(winner) .. " WINS!  PLAY AGAIN IN " .. tostring(Config.GameOverDelay))

	for _, player in ipairs(getTeamPlayers(winner)) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local wins = leaderstats and leaderstats:FindFirstChild("Wins")
		if wins and wins:IsA("IntValue") then
			wins.Value += 1
		end
	end

	task.wait(Config.GameOverDelay)
	winningTeam = nil
end

local function startMatchIfPossible()
	if matchRunning then
		return
	end
	if not canStartMatch() then
		setState("WaitingForPlayers", Config.WaitingMessage .. "  Red " .. tostring(teamCount("Red")) .. "/2 - Blue " .. tostring(teamCount("Blue")) .. "/2")
		return
	end

	matchRunning = true
	task.spawn(function()
		while canStartMatch() do
			score.Red = 0
			score.Blue = 0
			lastPointLoser = "Blue"
			winningTeam = nil
			resetPlayersToSpawns()
			runCountdown()

			while score.Red < Config.ScoreToWin and score.Blue < Config.ScoreToWin and canStartMatch() do
				resetPlayersToSpawns()
				local servingTeam = lastPointLoser
				setState("Serving", string.upper(servingTeam) .. " SERVES")
				task.wait(0.8)
				roundActive = true
				serveBall(servingTeam)
				setState("Rally", "RALLY!")

				repeat
					task.wait(0.05)
				until not roundActive

				task.wait(Config.PointDelay)
			end

			if score.Red >= Config.ScoreToWin then
				finishGame("Red")
			elseif score.Blue >= Config.ScoreToWin then
				finishGame("Blue")
			else
				setState("WaitingForPlayers", Config.WaitingMessage .. "  Red " .. tostring(teamCount("Red")) .. "/2 - Blue " .. tostring(teamCount("Blue")) .. "/2")
				hideBall()
				task.wait(1)
			end
		end

		matchRunning = false
		setState("WaitingForPlayers", Config.WaitingMessage .. "  Red " .. tostring(teamCount("Red")) .. "/2 - Blue " .. tostring(teamCount("Blue")) .. "/2")
	end)
end

PinInputEvent.OnServerEvent:Connect(function(player, isPinning)
	if typeof(isPinning) ~= "boolean" then
		return
	end
	local state = playerState[player]
	if not state then
		return
	end
	state.IsPinning = isPinning
	if isPinning then
		state.LastPinStartTime = os.clock()
	end
end)

Players.PlayerAdded:Connect(function(player)
	onPlayerAdded(player)
	task.wait(0.5)
	startMatchIfPossible()
end)

Players.PlayerRemoving:Connect(function(player)
	onPlayerRemoving(player)
	task.wait(0.5)
	startMatchIfPossible()
end)

RunService.Heartbeat:Connect(function(dt)
	clampPlayersToCourt()
	updatePinIndicators()
	updateGhostPartners()
	updateTeamBeam("Red")
	updateTeamBeam("Blue")
	updateBall(dt)
	updateLandingTargetMarker()

	if roundActive and currentState == "Rally" then
		local now = os.clock()
		if now - lastGuidanceBroadcast >= (Config.NetGuidanceBroadcastInterval or 0.18) then
			lastGuidanceBroadcast = now
			broadcastState("")
		end
	end
end)

-- Bootstrap existing players in Studio hot-reload sessions.
ensureTeams()
createCourt()
ensureGhostPartners()
ensureBallPart()
hideBall()

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

setState("WaitingForPlayers", Config.Title)
startMatchIfPossible()
