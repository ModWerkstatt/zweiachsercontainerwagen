--- vec3
-- @author Enno Sylvester
-- @copyright 2018
-- @module eatglobal.vec3

local origVec3 = require "vec3"

local vec3 = {
	version = "1.1",
}

local function __copy (source, dest)
	for k, v in pairs(source) do
		dest[k] = v
	end
	setmetatable(dest, getmetatable(source))
end
__copy(origVec3, vec3)
--[[========================================]]

local mt = {
  __add = function (lhs, rhs) -- "add" event handler
		local result = { x = lhs.x + rhs.x, y = lhs.y + rhs.y, z = lhs.z + rhs.z }
		setmetatable(result, mt)
		return result
  end,
	__sub = function (lhs, rhs) -- "sub" event handler
		local result = { x = lhs.x - rhs.x, y = lhs.y - rhs.y, z = lhs.z - rhs.z }
		setmetatable(result, mt)
		return result
  end,
	__mul = function (lhs, rhs) -- "mul" event handler
		local result = { x = lhs.x * rhs.x, y = lhs.y * rhs.y, z = lhs.z * rhs.z }
		setmetatable(result, mt)
		return result
	end,
	__div = function (lhs, rhs) -- "div" event handler
		local result = { x = lhs.x / rhs.x, y = lhs.y / rhs.y, z = lhs.z / rhs.z }
		setmetatable(result, mt)
		return result
	end,
}

function vec3.new(x, y, z)
	local result = { x = x, y = y, z = z }
	setmetatable(result, mt)
	return result
end

function vec3.copy(vec)
	return vec3.new(vec.x, vec.y, vec.z)
end

function vec3.mt(vec)
	return vec3.new(vec.x, vec.y, vec.z)
end

function vec3.mtVecs(vecs)
	local result = {}
	for i = 1, #vecs do
		result[#result + 1] = vec3.mt(vecs[i])
	end
	return result
end

function vec3.add(a, b)
	return vec3.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

function vec3.sub(a, b)
	return vec3.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

function vec3.mul(f, vec)
	return vec3.new(f * vec.x, f * vec.y, f * vec.z)
end

function vec3.cross(a, b)
	return vec3.new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
		)
end

function vec3.length(vec)
	return math.sqrt(vec.x^2 + vec.y^2 + vec.z^2)
end

function vec3.lengthBetween(a, b)
	return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end

--- alle rotate...-Funktionen mit rot in RAD
-- Umrechnung: aRAD = math.rad(aDEG)
function vec3.rotateX(vec, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return vec3.new(
		vec.x,
		(vec.y * c - vec.z * s),
		(vec.y * s + vec.z * c) 
	)
end

function vec3.rotateY(vec, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return vec3.new(
		(vec.x * c + vec.z * s),
		y,
		(vec.x * -s + vec.z * c)
	)
end

function vec3.rotateZ(vec, rot)
	local s = math.sin(rot)
	local c = math.cos(rot)

	return vec3.new(
		(vec.x * c - vec.y * s),
		(vec.x * s + vec.y * c),
		vec.z
	)
end

----

function vec3.degToRad(vec)
	return vec3.new(math.rad(vec.x), math.rad(vec.y), math.rad(vec.z))
end

function vec3.fromArray (a)
	return vec3.new(a[1], a[2], a[3])
end

-- vec3.new2 identisch mit vec3.fromArray
-- bleibt aus Kompatibilitätsgründen erhalten
function vec3.new2 (a)
	return vec3.fromArray (a)
end

function vec3.toArray (vec)
	return vec3.eatglobal.arr3.fromVec(vec)
end

function vec3.toParams(vec)
	return vec.x, vec.y, vec.z
end

return vec3