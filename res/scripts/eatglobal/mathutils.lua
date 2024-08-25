--- mathutils
-- @author Enno Sylvester
-- @copyright 2018, 2020
-- @module eatglobal.mathutils

local verionsData = {
	majorVersion = 1,
	minorVersion = 2,
}

local mathutils = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

function mathutils.calcScale(dist, angle)
	if (angle < .001) then
		return dist
	end
			
	local pi = math.pi
	local pi2 = pi / 2	
	local sqrt2 = math.sqrt(2)
			
	local scale = 1.0
	if (angle >= pi2) then 
		scale = 1.0 + (sqrt2 - 1.0) * ((angle - pi2) / pi2)
	end

	return .5 * dist / math.cos(.5 * pi - .5 * angle) * angle * scale
end

return mathutils