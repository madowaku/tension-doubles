-- Tension Doubles: PINTO HARE!
-- Builds compact arena models in ServerStorage/Arenas.
-- Sync/run this as a ServerScriptService Script, or paste into Roblox Studio Command Bar.

local ServerStorage = game:GetService("ServerStorage")

local ARENA_FOLDER_NAME = "Arenas"
local LEGACY_GRASS_MODEL_NAME = "TDArena_TileField64"
local MODEL_NAME = LEGACY_GRASS_MODEL_NAME
local ARENA_SIZE = 88

local COURT_THEMES = {
	{
		Id = "Grass",
		ModelName = "Arena_Grass",
		LegacyModelName = "TDArena_Grass64",
		SourceReference = "assets/ChatGPT Image 2026年6月2日 19_40_15.png",
		Surface = Color3.fromRGB(93, 171, 62),
		Court = Color3.fromRGB(96, 185, 58),
		CourtAlt = Color3.fromRGB(109, 197, 65),
		Path = Color3.fromRGB(205, 172, 103),
		Accent = Color3.fromRGB(34, 118, 180),
		Trim = Color3.fromRGB(245, 245, 230),
		Wood = Color3.fromRGB(116, 70, 32),
		Leaf = Color3.fromRGB(59, 143, 49),
	},
	{
		Id = "Rooftop",
		ModelName = "Arena_Rooftop",
		LegacyModelName = "TDArena_Rooftop64",
		SourceReference = "assets/ChatGPT Image 2026年6月2日 19_40_24.png",
		Surface = Color3.fromRGB(65, 79, 90),
		Court = Color3.fromRGB(76, 96, 112),
		CourtAlt = Color3.fromRGB(88, 112, 132),
		Path = Color3.fromRGB(126, 138, 145),
		Accent = Color3.fromRGB(255, 215, 96),
		Trim = Color3.fromRGB(232, 240, 244),
		Wood = Color3.fromRGB(86, 74, 62),
		Leaf = Color3.fromRGB(82, 130, 118),
	},
	{
		Id = "School",
		ModelName = "Arena_School",
		LegacyModelName = "TDArena_School64",
		SourceReference = "assets/ChatGPT Image 2026年6月2日 19_40_35.png",
		Surface = Color3.fromRGB(188, 133, 72),
		Court = Color3.fromRGB(218, 178, 86),
		CourtAlt = Color3.fromRGB(232, 193, 98),
		Path = Color3.fromRGB(174, 112, 68),
		Accent = Color3.fromRGB(68, 116, 188),
		Trim = Color3.fromRGB(255, 248, 218),
		Wood = Color3.fromRGB(126, 72, 38),
		Leaf = Color3.fromRGB(92, 142, 66),
	},
	{
		Id = "Festival",
		ModelName = "Arena_Festival",
		LegacyModelName = "TDArena_Festival64",
		SourceReference = "assets/ChatGPT Image 2026年6月2日 19_40_43.png",
		Surface = Color3.fromRGB(112, 48, 70),
		Court = Color3.fromRGB(224, 86, 116),
		CourtAlt = Color3.fromRGB(242, 106, 142),
		Path = Color3.fromRGB(236, 184, 112),
		Accent = Color3.fromRGB(255, 226, 88),
		Trim = Color3.fromRGB(255, 248, 230),
		Wood = Color3.fromRGB(124, 56, 46),
		Leaf = Color3.fromRGB(74, 148, 80),
	},
	{
		Id = "Space",
		ModelName = "Arena_Space",
		LegacyModelName = "TDArena_Space64",
		SourceReference = "assets/ChatGPT Image 2026年6月2日 19_40_54.png",
		Surface = Color3.fromRGB(24, 24, 58),
		Court = Color3.fromRGB(72, 62, 152),
		CourtAlt = Color3.fromRGB(90, 78, 178),
		Path = Color3.fromRGB(42, 48, 92),
		Accent = Color3.fromRGB(104, 232, 255),
		Trim = Color3.fromRGB(236, 244, 255),
		Wood = Color3.fromRGB(50, 54, 90),
		Leaf = Color3.fromRGB(84, 190, 184),
	},
}

local COLORS = {
	grass = Color3.fromRGB(93, 171, 62),
	grassDark = Color3.fromRGB(73, 144, 53),
	court = Color3.fromRGB(96, 185, 58),
	courtAlt = Color3.fromRGB(109, 197, 65),
	path = Color3.fromRGB(205, 172, 103),
	pathLight = Color3.fromRGB(226, 204, 139),
	line = Color3.fromRGB(245, 245, 230),
	wood = Color3.fromRGB(116, 70, 32),
	rope = Color3.fromRGB(218, 188, 116),
	leaf = Color3.fromRGB(59, 143, 49),
	leafLight = Color3.fromRGB(97, 190, 52),
	trunk = Color3.fromRGB(96, 55, 30),
	blue = Color3.fromRGB(34, 118, 180),
	dark = Color3.fromRGB(34, 44, 39),
	stone = Color3.fromRGB(221, 213, 175),
	sign = Color3.fromRGB(232, 220, 165),
}

local old = ServerStorage:FindFirstChild(MODEL_NAME)
if old then
	old:Destroy()
end

local model = Instance.new("Model")
model.Name = MODEL_NAME
model:SetAttribute("SourceWorkflow", "agent-sprite-forge generate2dmap")
model:SetAttribute("SourceReference", "assets/ChatGPT Image 2026年6月2日 19_40_15.png")
model:SetAttribute("ArenaWidthStuds", ARENA_SIZE)
model:SetAttribute("ArenaDepthStuds", ARENA_SIZE)
model:SetAttribute("MobilePartBudget", 120)
model:SetAttribute("CollisionPolicy", "Only broad floor/path/court surfaces collide; decor/fence/net/platforms are non-collide.")
model.Parent = ServerStorage

local folders = {}
local function folder(path)
	local current = model
	for name in string.gmatch(path, "[^/]+") do
		local child = current:FindFirstChild(name)
		if not child then
			child = Instance.new("Folder")
			child.Name = name
			child.Parent = current
		end
		current = child
	end
	folders[path] = current
	return current
end

folder("Foundation")
folder("Court")
folder("Court/CourtLines")
folder("Court/Net")
folder("Fences")
folder("SpectatorPlatforms")
folder("Props")
folder("Decor")
folder("Collision")

local function prepPart(part, collidable)
	part.Anchored = true
	part.CanCollide = collidable == true
	part.CanTouch = collidable == true
	part.CanQuery = collidable == true
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function block(parent, name, size, cframe, color, material, collidable)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	prepPart(part, collidable)
	part.Parent = parent
	return part
end

local function cylinder(parent, name, size, cframe, color, material, collidable)
	local part = block(parent, name, size, cframe, color, material, collidable)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function sphere(parent, name, size, position, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Ball
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	prepPart(part, false)
	part.Parent = parent
	return part
end

local function addLabel(part, text)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 28
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(32, 48, 38)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Parent = gui
end

local foundation = folder("Foundation")
local court = folder("Court")
local lines = folder("Court/CourtLines")
local net = folder("Court/Net")
local fences = folder("Fences")
local platforms = folder("SpectatorPlatforms")
local props = folder("Props")
local decor = folder("Decor")
local collision = folder("Collision")

-- Foundation and paths: a few broad smooth surfaces instead of per-tile parts.
local baseGrass = block(foundation, "BaseGrass", Vector3.new(88, 0.35, 88), CFrame.new(0, -0.18, 0), COLORS.grass, Enum.Material.Grass, true)
model.PrimaryPart = baseGrass
block(foundation, "NorthPath", Vector3.new(72, 0.08, 5), CFrame.new(0, 0.05, -38), COLORS.path, Enum.Material.Ground, true)
block(foundation, "SouthPath", Vector3.new(72, 0.08, 5), CFrame.new(0, 0.05, 38), COLORS.path, Enum.Material.Ground, true)
block(foundation, "WestPath", Vector3.new(5, 0.08, 72), CFrame.new(-38, 0.05, 0), COLORS.path, Enum.Material.Ground, true)
block(foundation, "EastPath", Vector3.new(5, 0.08, 72), CFrame.new(38, 0.05, 0), COLORS.path, Enum.Material.Ground, true)
block(foundation, "NorthSteps", Vector3.new(9, 0.12, 5.5), CFrame.new(0, 0.12, -43), COLORS.pathLight, Enum.Material.Slate, true)
block(foundation, "SouthSteps", Vector3.new(9, 0.12, 5.5), CFrame.new(0, 0.12, 43), COLORS.pathLight, Enum.Material.Slate, true)

-- 2v2 tennis-like court, compressed to fit inside the 64x64 field.
block(court, "CourtGrass", Vector3.new(52, 0.12, 62), CFrame.new(0, 0.12, 0), COLORS.court, Enum.Material.Grass, true)
for x = -18, 18, 12 do
	for z = -24, 24, 12 do
		local color = ((x + z) / 6) % 2 == 0 and COLORS.courtAlt or COLORS.court
		block(decor, "SubtleCourtTile", Vector3.new(5.8, 0.02, 5.8), CFrame.new(x, 0.21, z), color, Enum.Material.Grass, false)
	end
end

block(lines, "OuterLineNorth", Vector3.new(52, 0.08, 0.45), CFrame.new(0, 0.28, -30.5), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "OuterLineSouth", Vector3.new(52, 0.08, 0.45), CFrame.new(0, 0.28, 30.5), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "OuterLineWest", Vector3.new(0.45, 0.08, 61), CFrame.new(-25.5, 0.28, 0), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "OuterLineEast", Vector3.new(0.45, 0.08, 61), CFrame.new(25.5, 0.28, 0), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "CenterServiceLine", Vector3.new(0.45, 0.08, 61), CFrame.new(0, 0.29, 0), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "NetLine", Vector3.new(52, 0.08, 0.36), CFrame.new(0, 0.3, 0), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "NorthServiceLine", Vector3.new(35, 0.08, 0.38), CFrame.new(0, 0.3, -14), COLORS.line, Enum.Material.SmoothPlastic, false)
block(lines, "SouthServiceLine", Vector3.new(35, 0.08, 0.38), CFrame.new(0, 0.3, 14), COLORS.line, Enum.Material.SmoothPlastic, false)

-- Net is visual-only so players cannot snag on it. Gameplay uses the existing virtual net.
block(net, "NetLeftPost", Vector3.new(0.65, 4.2, 0.65), CFrame.new(-27, 2.1, 0), COLORS.blue, Enum.Material.SmoothPlastic, false)
block(net, "NetRightPost", Vector3.new(0.65, 4.2, 0.65), CFrame.new(27, 2.1, 0), COLORS.blue, Enum.Material.SmoothPlastic, false)
block(net, "NetTopRail", Vector3.new(54, 0.35, 0.35), CFrame.new(0, 3.35, 0), COLORS.line, Enum.Material.SmoothPlastic, false)
block(net, "NetMesh", Vector3.new(53, 2.3, 0.18), CFrame.new(0, 2.1, 0), Color3.fromRGB(210, 230, 230), Enum.Material.Glass, false).Transparency = 0.45

-- Low rope fence around the outside. All decorative pieces are non-collide.
for _, z in ipairs({ -32, 32 }) do
	block(fences, "FenceRailLong", Vector3.new(58, 0.35, 0.35), CFrame.new(0, 1.55, z), COLORS.rope, Enum.Material.Wood, false)
	for x = -24, 24, 8 do
		block(fences, "FencePost", Vector3.new(0.75, 2.6, 0.75), CFrame.new(x, 1.3, z), COLORS.wood, Enum.Material.Wood, false)
	end
end
for _, x in ipairs({ -32, 32 }) do
	block(fences, "FenceRailShort", Vector3.new(0.35, 0.35, 58), CFrame.new(x, 1.55, 0), COLORS.rope, Enum.Material.Wood, false)
	for z = -24, 24, 8 do
		block(fences, "FencePost", Vector3.new(0.75, 2.6, 0.75), CFrame.new(x, 1.3, z), COLORS.wood, Enum.Material.Wood, false)
	end
end

local function makePlatform(name, x, z)
	local sign = z < 0 and -1 or 1
	block(platforms, name .. "_Deck", Vector3.new(8, 0.8, 5), CFrame.new(x, 0.42, z), COLORS.pathLight, Enum.Material.WoodPlanks, false)
	block(platforms, name .. "_BackRail", Vector3.new(8.4, 1.2, 0.45), CFrame.new(x, 1.1, z + sign * 2.7), COLORS.wood, Enum.Material.Wood, false)
	block(platforms, name .. "_Bench", Vector3.new(5.8, 0.65, 1.1), CFrame.new(x, 1.05, z), COLORS.wood, Enum.Material.WoodPlanks, false)
end

makePlatform("NW_SpectatorPlatform", -22, -22)
makePlatform("NE_SpectatorPlatform", 22, -22)
makePlatform("SW_SpectatorPlatform", -22, 22)
makePlatform("SE_SpectatorPlatform", 22, 22)

local function makeTree(name, x, z, scale)
	scale = scale or 1
	block(props, name .. "_Trunk", Vector3.new(1.1 * scale, 3 * scale, 1.1 * scale), CFrame.new(x, 1.5 * scale, z), COLORS.trunk, Enum.Material.Wood, false)
	sphere(props, name .. "_CanopyA", Vector3.new(4.2 * scale, 4.2 * scale, 4.2 * scale), Vector3.new(x, 3.7 * scale, z), COLORS.leaf)
	sphere(props, name .. "_CanopyB", Vector3.new(3.2 * scale, 3.2 * scale, 3.2 * scale), Vector3.new(x - 1.1 * scale, 4.2 * scale, z + 0.7 * scale), COLORS.leafLight)
end

for i, p in ipairs({
	{ -28, -28, 0.9 }, { 28, -28, 0.9 }, { -28, 28, 0.9 }, { 28, 28, 0.9 },
	{ -30, 0, 0.72 }, { 30, 0, 0.72 },
}) do
	makeTree("Tree" .. i, p[1], p[2], p[3])
end

local function makeSign(name, x, z, yaw)
	local cf = CFrame.new(x, 1.8, z) * CFrame.Angles(0, math.rad(yaw), 0)
	block(props, name .. "_PostL", Vector3.new(0.35, 2.8, 0.35), cf * CFrame.new(-1.5, -0.45, 0), COLORS.wood, Enum.Material.Wood, false)
	block(props, name .. "_PostR", Vector3.new(0.35, 2.8, 0.35), cf * CFrame.new(1.5, -0.45, 0), COLORS.wood, Enum.Material.Wood, false)
	local face = block(props, name .. "_Board", Vector3.new(3.8, 2.2, 0.35), cf, COLORS.sign, Enum.Material.WoodPlanks, false)
	addLabel(face, "PINTO")
	block(props, name .. "_Roof", Vector3.new(4.4, 0.45, 0.8), cf * CFrame.new(0, 1.35, 0), COLORS.blue, Enum.Material.SmoothPlastic, false)
end

makeSign("WestSignNorth", -30, -20, 90)
makeSign("EastSignSouth", 30, 20, -90)

local function shrub(name, x, z, color)
	sphere(decor, name, Vector3.new(2.1, 1.4, 2.1), Vector3.new(x, 0.75, z), color or COLORS.leafLight)
end
for i, p in ipairs({
	{ -14, -27 }, { 14, -27 }, { -14, 27 }, { 14, 27 },
	{ -27, -14 }, { 27, -14 }, { -27, 14 }, { 27, 14 },
}) do
	shrub("FlowerShrub" .. i, p[1], p[2], i % 2 == 0 and Color3.fromRGB(75, 168, 74) or Color3.fromRGB(96, 180, 58))
end

local function lamp(name, x, z)
	block(decor, name .. "_Post", Vector3.new(0.35, 3.1, 0.35), CFrame.new(x, 1.55, z), COLORS.dark, Enum.Material.Metal, false)
	local light = block(decor, name .. "_Glow", Vector3.new(0.85, 0.85, 0.85), CFrame.new(x, 3.25, z), Color3.fromRGB(255, 221, 126), Enum.Material.Neon, false)
	light.Shape = Enum.PartType.Ball
end

lamp("LampNW", -15, -27)
lamp("LampNE", 15, -27)
lamp("LampSW", -15, 27)
lamp("LampSE", 15, 27)

-- Collision folder intentionally contains only notes/markers; the broad surfaces above are the real colliders.
local note = Instance.new("StringValue")
note.Name = "CollisionNotes"
note.Value = "Decor, fence, net, signs, trees, and spectator platforms are non-collide/non-query. Broad grass/path/court surfaces are smooth colliders."
note.Parent = collision

local partCount = 0
for _, child in ipairs(model:GetDescendants()) do
	if child:IsA("BasePart") then
		partCount += 1
	end
end
model:SetAttribute("BasePartCount", partCount)
print(("[TDArena] Built %s in ServerStorage with %d BaseParts."):format(MODEL_NAME, partCount))

local function contains(text, pattern)
	return string.find(text, pattern, 1, true) ~= nil
end

local function applyTheme(arenaModel, theme)
	arenaModel:SetAttribute("CourtId", theme.Id)
	arenaModel:SetAttribute("LegacyModelName", theme.LegacyModelName or "")
	arenaModel:SetAttribute("SourceWorkflow", "agent-sprite-forge generate2dmap")
	arenaModel:SetAttribute("SourceReference", theme.SourceReference)
	arenaModel:SetAttribute("ArenaWidthStuds", ARENA_SIZE)
	arenaModel:SetAttribute("ArenaDepthStuds", ARENA_SIZE)
	arenaModel:SetAttribute("MobilePartBudget", 120)
	arenaModel:SetAttribute("CollisionPolicy", "Only broad floor/path/court surfaces collide; decor/fence/net/platforms are non-collide.")

	for _, descendant in ipairs(arenaModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local name = descendant.Name
			local parentName = descendant.Parent and descendant.Parent.Name or ""
			if contains(name, "BaseGrass") then
				descendant.Color = theme.Surface
				descendant.Material = theme.Id == "Space" and Enum.Material.Slate or Enum.Material.Grass
			elseif contains(name, "CourtGrass") then
				descendant.Color = theme.Court
				descendant.Material = theme.Id == "Rooftop" and Enum.Material.SmoothPlastic or Enum.Material.Grass
			elseif contains(name, "SubtleCourtTile") then
				descendant.Color = theme.CourtAlt
				descendant.Material = theme.Id == "Space" and Enum.Material.Neon or Enum.Material.Grass
				descendant.Transparency = theme.Id == "Space" and 0.34 or descendant.Transparency
			elseif contains(name, "Path") or contains(name, "Steps") or parentName == "Foundation" then
				descendant.Color = contains(name, "BaseGrass") and theme.Surface or theme.Path
			elseif contains(name, "Line") or parentName == "CourtLines" or contains(name, "NetTopRail") then
				descendant.Color = theme.Trim
				descendant.Material = Enum.Material.Neon
			elseif contains(name, "Net") then
				descendant.Color = theme.Accent
			elseif contains(name, "Fence") or contains(name, "Deck") or contains(name, "Bench") or contains(name, "Rail") or contains(name, "Post") or contains(name, "Board") then
				descendant.Color = theme.Wood
			elseif contains(name, "Canopy") or contains(name, "Shrub") then
				descendant.Color = theme.Leaf
			elseif contains(name, "Lamp") or contains(name, "Roof") then
				descendant.Color = theme.Accent
				descendant.Material = Enum.Material.Neon
			end
		end
	end

	local labelText = theme.Id:upper()
	for _, descendant in ipairs(arenaModel:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Text == "PINTO" then
			descendant.Text = labelText
		end
	end
end

local function ensureArenaFolder()
	local arenaFolder = ServerStorage:FindFirstChild(ARENA_FOLDER_NAME)
	if not arenaFolder then
		arenaFolder = Instance.new("Folder")
		arenaFolder.Name = ARENA_FOLDER_NAME
		arenaFolder.Parent = ServerStorage
	end
	return arenaFolder
end

local function cloneThemeArena(theme, arenaFolder)
	local old = arenaFolder:FindFirstChild(theme.ModelName)
	if old then
		old:Destroy()
	end
	local oldRoot = ServerStorage:FindFirstChild(theme.ModelName)
	if oldRoot then
		oldRoot:Destroy()
	end
	if theme.LegacyModelName then
		local oldLegacyRoot = ServerStorage:FindFirstChild(theme.LegacyModelName)
		if oldLegacyRoot then
			oldLegacyRoot:Destroy()
		end
	end

	local themedModel = model:Clone()
	themedModel.Name = theme.ModelName
	applyTheme(themedModel, theme)
	themedModel.Parent = arenaFolder
	print(("[TDArena] Built ServerStorage/%s/%s for %s from %s."):format(ARENA_FOLDER_NAME, theme.ModelName, theme.Id, theme.SourceReference))
	return themedModel
end

local function cloneLegacyGrassAlias(grassModel)
	local old = ServerStorage:FindFirstChild(LEGACY_GRASS_MODEL_NAME)
	if old and old ~= model then
		old:Destroy()
	end
	model:SetAttribute("LegacyAliasFor", grassModel.Name)
end

local grassModel = nil
local arenaFolder = ensureArenaFolder()
for _, theme in ipairs(COURT_THEMES) do
	local themedModel = cloneThemeArena(theme, arenaFolder)
	if theme.Id == "Grass" then
		grassModel = themedModel
	end
end

if grassModel then
	cloneLegacyGrassAlias(grassModel)
end
