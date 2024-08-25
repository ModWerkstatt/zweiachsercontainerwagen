--- vec2
-- @author Enno Sylvester
-- @copyright 2019
-- @module eatglobal.vec2

local origVec2 = require "vec2"

local vec2 = {
	version = "1.0",
}

local function __copy (source, dest)
	for k, v in pairs(source) do
		dest[k] = v
	end
	setmetatable(dest, getmetatable(source))
end
__copy(origVec2, vec2)
--[[========================================]]

local mt = {
  __add = function (lhs, rhs) -- "add" event handler
		local result = { x = lhs.x + rhs.x, y = lhs.y + rhs.y }
		setmetatable(result, mt)
		return result
  end,
	__sub = function (lhs, rhs) -- "sub" event handler
		local result = { x = lhs.x - rhs.x, y = lhs.y - rhs.y }
		setmetatable(result, mt)
		return result
  end,
	__mul = function (lhs, rhs) -- "mul" event handler
		local result = { x = lhs.x * rhs.x, y = lhs.y * rhs.y }
		setmetatable(result, mt)
		return result
	end,
	__div = function (lhs, rhs) -- "div" event handler
		local result = { x = lhs.x / rhs.x, y = lhs.y / rhs.y }
		setmetatable(result, mt)
		return result
	end,
}

function vec2.new(x, y)
	local result = { x = x, y = y }
	setmetatable(result, mt)
	return result
end

function vec2.copy(vec)
	return vec2.new(vec.x, vec.y)
end

function vec2.mt(vec)
	return vec2.new(vec.x, vec.y)
end

function vec2.mtVecs(vecs)
	local result = {}
	for i = 1, #vecs do
		result[#result + 1] = vec2.mt(vecs[i])
	end
	return result
end

function vec2.add(a, b)
	return vec2.new(a.x + b.x, a.y + b.y)
end

function vec2.sub(a, b)
	return vec2.new(a.x - b.x, a.y - b.y)
end

--- Ex- Importfunktionen
function vec2.fromArray (a)
	return vec2.new(a[1], a[2])
end

function vec2.toArray (vec)
	return vec2.eatglobal.arr2.fromVec(vec)
end

function vec2.toParams(vec)
	return vec.x, vec.y
end

return vec2