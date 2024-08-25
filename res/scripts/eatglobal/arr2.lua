--- arr2
-- @author Enno Sylvester
-- @copyright 2019
-- @module eatglobal.arr2

local arr2 = {
	version = "1.0",
}

local mt = {
  __add = function (lhs, rhs) -- "add" event handler
		local result = { lhs[1] + rhs[1], lhs[2] + rhs[2] }
		setmetatable(result, mt)
		return result
  end,
	__sub = function (lhs, rhs) -- "sub" event handler
		local result = { lhs[1] - rhs[1], lhs[2] - rhs[2] }
		setmetatable(result, mt)
		return result
  end,
	__mul = function (lhs, rhs) -- "mul" event handler
		local result = { lhs[1] * rhs[1], lhs[2] * rhs[2] }
		setmetatable(result, mt)
		return result
	end,
	__div = function (lhs, rhs) -- "div" event handler
		local result = { lhs[1] / rhs[1], lhs[2] / rhs[2] }
		setmetatable(result, mt)
		return result
	end,
}

function arr2.new(x, y)
	local result = {x, y}
	setmetatable(result, mt)
	return result
end

local function calcPointData(p, radius)
	if (radius == 0) then
		-- Daten
		return {
			aRad = 0,
			yLength = p[2],
			tangent = arr2.new(0, 1),
		}
	else
		local r = radius + p[1]
		local aRad = p[2] / radius
		local yLength = aRad * r
		-- Daten
		return {
			aRad = aRad,
			yLength = yLength,
			tangent = arr2.new(-math.sin(aRad), math.cos(aRad), 0),
		}
	end
end

function arr2.copy(p)
	return arr2.new(p[1], p[2])
end

function arr2.mt(p)
	return arr2.copy(p)
end

function arr2.mtPoints(points)
	local result = {}
	for i = 1, #points do
		result[#result + 1] = arr2.copy(points[i])
	end
	return result
end

function arr2.length(p)
	return math.sqrt(p[1]^2 + p[2]^2)
end

function arr2.distance(p0, p1)
	return arr2.length(arr2.copy(p1) - arr2.copy(p0))
end

function arr2.lengthBetween(p0, p1, radius)
	local r = radius or 0
	if (r == 0) then
		return arr2.distance(p0, p1)
	else
		local d0 = calcPointData(p0, radius)
		local d1 = calcPointData(p1, radius)
		return d1.yLength - d0.yLength
	end
end

-- Ex- Importfunktionen
function arr2.toVec (p)
	return arr2.eatglobal.vec2.fromArray(p)
end

function arr2.fromVec (vec)
	return arr2.new(vec.x, vec.y)
end

function arr2.toParams (p)
	return p[1], p[2]
end

return arr2