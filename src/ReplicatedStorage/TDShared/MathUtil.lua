--!strict

local MathUtil = {}

function MathUtil.clampMagnitude(v: Vector3, maxMagnitude: number): Vector3
	local mag = v.Magnitude
	if mag > maxMagnitude and mag > 0 then
		return v.Unit * maxMagnitude
	end
	return v
end

function MathUtil.withY(v: Vector3, y: number): Vector3
	return Vector3.new(v.X, y, v.Z)
end

function MathUtil.xzDistance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

function MathUtil.safeUnit(v: Vector3, fallback: Vector3): Vector3
	if v.Magnitude < 1e-5 then
		return fallback
	end
	return v.Unit
end

function MathUtil.distancePointToSegment(point: Vector3, a: Vector3, b: Vector3): (number, Vector3, number)
	local ab = b - a
	local ap = point - a
	local denom = ab:Dot(ab)
	if denom < 1e-5 then
		local distance = (point - a).Magnitude
		return distance, a, 0
	end

	local t = ap:Dot(ab) / denom
	t = math.clamp(t, 0, 1)

	local closest = a + ab * t
	local distance = (point - closest).Magnitude
	return distance, closest, t
end

function MathUtil.reflect(incoming: Vector3, normal: Vector3): Vector3
	local n = MathUtil.safeUnit(normal, Vector3.new(0, 0, 1))
	return incoming - 2 * incoming:Dot(n) * n
end

function MathUtil.teamSideSign(teamName: string): number
	-- Red lives on +Z and returns toward -Z. Blue lives on -Z and returns toward +Z.
	if teamName == "Red" then
		return 1
	end
	return -1
end

function MathUtil.opponent(teamName: string): string
	if teamName == "Red" then
		return "Blue"
	end
	return "Red"
end

return MathUtil
