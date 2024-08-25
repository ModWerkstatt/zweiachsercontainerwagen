--- transf
-- @author Enno Sylvester
-- @copyright 2018, 2019
-- @module eatglobal.transf

local origTransf = require "transf"

local transf = {
	version = "1.3",
}

local function __copy (source, dest)
	for k, v in pairs(source) do
		dest[k] = v
	end
	setmetatable(dest, getmetatable(source))
end
__copy(origTransf, transf)
--[[========================================]]

local function pToVec (pt)
	return { x = pt[1], y = pt[2], z = pt[3] }
end

function transf.copy (_transf)
	local result = {}
	for i = 1, #_transf do
		result[i] = _transf[i]
	end
	
	return result
end

function transf.create(position, rotation, scale, rotationIsRad)
	local rot = rotation or {0, 0, 0}
	rotationIsRad = (type(rotationIsRad) == "boolean") and rotationIsRad or false
	if rotationIsRad then
		return transf.scaleRotZYXTransl(pToVec(scale or {1, 1, 1}),
			{x = rot[3], y = rot[2], z = rot[1]},
				pToVec(position))
	else
		return transf.scaleRotZYXTransl(pToVec(scale or {1, 1, 1}),
			transf.degToRad(rot[3], rot[2], rot[1]),
				pToVec(position))
	end
end

function transf.getPos (_transf, pos)
	return {
		_transf[13],
		_transf[14],
		_transf[15],
	}
end

function transf.setPos (_transf, pos)
	local result = transf.copy(_transf)
	result[13] = pos[1]
	result[14] = pos[2]
	result[15] = pos[3]
	
	return result
end

function transf.incrementPos (_transf, increment)
	local result = transf.copy(_transf)
	result[13] = result[13] + increment[1]
	result[14] = result[14] + increment[2]
	result[15] = result[15] + increment[3]
	
	return result
end

function transf.setRotation (_transf, rotation, origin, rotationIsRad)
local vec3 = transf.eatglobal.vec3
	--[[
		Rotationen immer um den Nullpunkt, sonst landet das Objekt irgendwo.
		Daher:
			1. Position merken
			2. Position auf 0
			3. rotieren
			4. gemerkte Position wieder herstellen
	]]
	local pos = transf.getPos(_transf)
	origin = origin or {0, 0, 0}
	rotationIsRad = (type(rotationIsRad) == "boolean") and rotationIsRad or false
	if rotationIsRad then
		return transf.setPos(transf.mul(transf.rotZYXTransl({x = rotation[3], y = rotation[2], z = rotation[1]},
			vec3.new(0, 0, 0)), transf.setPos(_transf, origin)), pos)
	else
		return transf.setPos(transf.mul(transf.rotZYXTransl(transf.degToRad(rotation[3], rotation[2], rotation[1]),
			vec3.new(0, 0, 0)), transf.setPos(_transf, origin)), pos)
	end
end

---	Skaliert _transf
--	@eatglobal_intern.transfScaleTo
--	@param _transf: die zu skalierende Matrix
--	@param scale: Skalierwerte {x, y, z}
--	@return eine skalierte Kopie von _transf
function transf.setScale (_transf, scale)
	return transf.mul(_transf, transf.scale(pToVec(scale)))
end

function transf.transVec (vec0, vec1, vec2, vec3)
	return transf.new(
		{ x = vec0.x, y = vec0.y , z = vec0.z, w = 0 },
		{	x = vec1.x, y = vec1.y , z = vec1.z, w = 0 },
		{	x = vec2.x, y = vec2.y , z = vec2.z, w = 0 },
		{	x = vec3.x, y = vec3.y , z = vec3.z, w = 1 }
	)
end


function transf.rotXYZTransl(rot, transl)
	return transf.rotZYXTransl({ x = rot.z, y = rot.y, z = rot.x}, transl)
end

function transf.scaleRotXYZTransl(scale, rot, transl)
	return transf.mul(transf.rotXYZTransl(rot, transl), transf.scale(scale))
end

function transf.getTransformFromUnitXVec(p0, p1)
	local vec3 = transf.eatglobal.vec3
	
	local a = vec3.new(1, 0, 0)
	local b = vec3.new(0, 1, 0)
	
	local v = p1 - p0
	
	local lenV = vec3.distance(p0, p1)
	assert(lenV > .0)
	
	local transl = transf.transl(p0)
	
	local c1 = vec3.normalize(v)
	local c2 = vec3.cross(a, v)
	c2 = (vec3.length(c2) > .0) and vec3.normalize(c2) or vec3.normalize(vec3.cross(b, v))
	
	local c3 = vec3.normalize(vec3.cross(c2, a))
	
	local rot = transf.transVec(c1, c2, c3, vec3.new({0, 0, 0}))
	--local rot = { c1.x, c1.y, c1.z, 0, c2.x, c2.y, c2.z, 0, c3.x, c3.y, c3.z, 0, 0, 0, 0, 1 }
	
	local scale = transf.scale(vec3.new(lenV, 1, 1))
	
	return transf.mul(transf.mul(transl, rot), scale)
end

function transf.getTransformFromUnitXPt(p0, p1)
	local arr3 = transf.eatglobal.arr3
	return transf.getTransformFromUnitXVec(arr3.toVec(p0), arr3.toVec(p1))
end

return transf
