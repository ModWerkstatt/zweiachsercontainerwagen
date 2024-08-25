--- arr3
-- @author Enno Sylvester
-- @copyright 2017, 2018, 2019, 2020
-- @module eatglobal.arr3
local historie = [[
	Version 1.7:
	 - Added: arr3.div, arr3.max, arr3.calcSteps, arr3.split
	 - Changed: struct versionsData hinzugefügt
]]

local verionsData = {
	majorVersion = 1,
	minorVersion = 7,
}

local arr3 = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

local function angleArg(arg)
	return math.acos(math.clamp(arg, -1, 1))
end

local mt = {
  __add = function (lhs, rhs) -- "add" event handler
		local result = { lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3] }
		setmetatable(result, mt)
		return result
  end,
	__sub = function (lhs, rhs) -- "sub" event handler
		local result = { lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3] }
		setmetatable(result, mt)
		return result
  end,
	__mul = function (lhs, rhs) -- "mul" event handler
		local result = { lhs[1] * rhs[1], lhs[2] * rhs[2], lhs[3] * rhs[3] }
		setmetatable(result, mt)
		return result
	end,
	__div = function (lhs, rhs) -- "div" event handler
		local result = { lhs[1] / rhs[1], lhs[2] / rhs[2], lhs[3] / rhs[3] }
		setmetatable(result, mt)
		return result
	end,
}

function arr3.new(x, y, z)
	local result = {x, y, z}
	setmetatable(result, mt)
	return result
end

function arr3.copy(pt)
	return arr3.new(pt[1], pt[2], pt[3])
end

function arr3.mt(pt)
	return arr3.copy(pt)
end

function arr3.mtPoints(points)
	local result = {}
	for i = 1, #points do
		result[#result + 1] = arr3.copy(points[i])
	end
	return result
end

function arr3.add(a, b)
	return arr3.new(a[1] + b[1], a[2] + b[2], a[3] + b[3])
end

function arr3.sub(a, b)
	return arr3.new(a[1] - b[1], a[2] - b[2], a[3] - b[3])
end

function arr3.mul(f, pt)
	return arr3.new(f * pt[1], f * pt[2], f * pt[3])
end

function arr3.div(f, pt)
	return arr3.new(pt[1] / f, pt[2] / f, pt[3] / f)
end
function arr3.dot(a, b)
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3];
end

function arr3.cross(a, b)
	return arr3.new(
		a[2] * b[3] - a[3] * b[2],
		a[3] * b[1] - a[1] * b[3],
		a[1] * b[2] - a[2] * b[1])
end

function arr3.length(pt)
	--return math.sqrt(arr3.dot(pt, pt))
	return math.sqrt(pt[1]^2 + pt[2]^2 + pt[3]^2)
end

function arr3.distance(a, b)
	return arr3.length(arr3.sub(a, b))
end

function arr3.max(a)
	local result = 0
	for i, value in ipairs(a) do
		result = math.max(result, math.abs(value))
	end
	return result
end

--[[
function arr3.lengthBetween(a, b)
	return math.sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[2] - b[2])^2)
end
]]

function arr3.lengthBetween(p0, p1, radius)
	local r = radius or 0
	local l = math.abs(arr3.distance(p1, p0))
	if (r == 0) then
		return l
	else
		return 2 * r * math.asin( l / (2 * r) )
	end
end

function arr3.getMiddle(p0, p1)
	local pt0 = arr3.copy(p0)
	return pt0 + ((arr3.copy(p1) - pt0) / arr3.new(2, 2, 2))
end

function arr3.calcSteps(p0, p1, range)
	return math.round(math.max(arr3.max(arr3.sub(p1, p0)), range) / range)
end

function arr3.split(p0, p1, steps, insertLast)
	local result = { arr3.copy(p0), }
	local addP = arr3.div(steps, arr3.sub(p1, p0))
	local currentPoint = arr3.copy(p0)
	for i = 1, steps - 1 do
		local nextPoint = currentPoint + addP
		table.insert(result, nextPoint)
		currentPoint = nextPoint
	end
	insertLast = (insertLast == nil) and true or insertLast
	if insertLast then
		table.insert(result, arr3.copy(p1))
	end
	
	return result
end

function arr3.calcNSectors(p0, p1, countSectors)
	local pt0 = arr3.copy(p0)
	local pt1 = arr3.copy(p1)
	local pSector = (pt1 - pt0) / arr3.new(countSectors, countSectors, countSectors)
	local result = { pt0 }
	for i = 1, countSectors - 1 do
		result[#result + 1] = arr3.copy(pt0 + (pSector * arr3.new(i, i, i)))
	end
	result[#result + 1] = pt1
	
	return result
end

function arr3.getZAngel(pStart, pEnd)
	local function calcTotalLength(yLength, z)
		local fac = (yLength < 0) and -1 or 1
		return math.sqrt((yLength * yLength) + (z * z)) * fac
	end
	
	local sx, sy, sz = arr3.toParams(pStart)
	local ex, ey, ez = arr3.toParams(pEnd)
	local z = (sz < ez) and ez - sz or sz - ez
	local yLength = ey - sy
	return z / calcTotalLength(yLength, z)
end

function arr3.projectZPoint(p, angel, yLength)
	return arr3.new(p[1], p[2] + yLength, p[3] + (math.tan(angel) * yLength))
end

function arr3.normalize(pt)
	return arr3.mul(1.0 / arr3.length(pt), pt)
end

function arr3.mormize(points)
	local result = {}
	if (#points > 0) then
		local min = {
			points[1][1],
			points[2][2],
			points[3][3],
		}
		local max = {
			points[1][1],
			points[2][2],
			points[3][3],
		}
		for i = 1, #points do
			min[1] = math.min(points[i][1], min[1])
			min[2] = math.min(points[i][2], min[2])
			min[3] = math.min(points[i][3], min[3])
			
			max[1] = math.max(points[i][1], max[1])
			max[2] = math.max(points[i][2], max[2])
			max[3] = math.max(points[i][3], max[3])
		end
		for i = 1, #points do
			local temp = {}
			if ((max[1] - min[1]) == 0) then
				temp[1] = 0
			else
				temp[1] = (points[i][1] - min[1]) / (max[1] - min[1])
			end
			if ((max[2] - min[2]) == 0) then
				temp[2] = 0
			else
				temp[2] = (points[i][2] - min[2]) / (max[2] - min[2])
			end
			if ((max[3] - min[3]) == 0) then
				temp[3] = 0
			else
				temp[3] = (points[i][3] - min[3]) / (max[3] - min[3])
			end
			result[#result + 1] = temp
		end
	end
	
	return result
end

function arr3.angleUnit(a, b)
	return angleArg(arr3.dot(a, b))
end

function arr3.xyAngle(pt)
	return math.atan2(pt[2], pt[1])
end

--- alle rotate...-Funktionen mit rot in RAD
-- Umrechnung: aRAD = math.rad(aDEG)
function arr3.rotateX(pt, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return arr3.new(
		pt[1],
		(pt[2] * c - pt[3] * s),
		(pt[2] * s + pt[3] * c)
	)
end

function arr3.rotateY(pt, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return arr3.new(
		(pt[1] * c + pt[3] * s),
		pt[2],
		(pt[1] * -s + pt[3] * c)
	)
end

function arr3.rotateZ(pt, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return arr3.new(
		(pt[1] * c - pt[2] * s),
		(pt[2] * s + pt[2] * c),
		pt[3]
	)
end

----------------------

function arr3.degToRad(pt)
	return arr3.new(math.rad(pt[1]), math.rad(pt[2]), math.rad(pt[3]))
end

function arr3.getZData(p0, p1, radius)
	local arg = p1[3] - p0[3]
	return arg, angleArg(arg), arr3.lengthBetween(p0, p1, radius)
end

function arr3.calcZArgAndAngel(p0, p1, radius)
	local arg = p1[3] - p0[3]
	
	return arg, angleArg(arg) * arr3.lengthBetween(p0, p1, radius)
end

-- Ex- Importfunktionen
function arr3.toVec (pt)
	return arr3.eatglobal.vec3.fromArray(pt)
end

function arr3.fromVec (vec)
	return arr3.new(vec.x, vec.y, vec.z)
end

function arr3.toParams (pt)
	return pt[1], pt[2], pt[3]
end

return arr3

