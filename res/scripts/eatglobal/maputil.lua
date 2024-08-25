--- maputil
-- @author Enno Sylvester
-- @copyright 2018, 2019
-- @module eatglobal.maputil

local maputil = {
	version = "1.0",
}

function maputil.createMapping(radius)
	local transf = maputil.eatglobal.transf
	local arr3 = maputil.eatglobal.arr3
	local logFn = maputil.eatglobal.utils.createLogFn ("[maputil]")
	local mapping = {
			radius = radius,
		}
	
	--[[
		################################################################
	]]
	mapping.pointData = function(p)
		local function calcData(pt)
			local x, y, z = arr3.toParams(pt)
			if (radius == 0) then
				return {
					origPoint = arr3.copy(pt),
					mappedPoint = arr3.copy(pt),
					radius = 0,
					radiusAtXPosition = 0,
					aRad = 0,
					yLength = y,
					heigth = z,
					tangent = arr3.new(0, 1, 0),
					scaleFactor = 1,
					meshScale = arr3.new(1, 1, 1),
				}
			else
				local r = radius + x
				local aRad = y / radius
				local scaleFactor = r / radius
				local yLength = aRad * r
				-- Daten
				return {
					origPoint = arr3.copy(pt),
					mappedPoint = arr3.new(math.cos(aRad) * r - radius, math.sin(aRad) * r, z),
					radius = radius,
					radiusAtXPosition = r,
					aRad = aRad,
					yLength = yLength,
					heigth = z,
					tangent = arr3.new(-math.sin(aRad), math.cos(aRad), 0),
					scaleFactor = scaleFactor,
					meshScale = arr3.new(1, scaleFactor, 1),
				}
			end
		end
		local result = {
			data = calcData(p)
		}

		-- Hilfsfunktionen
		local function angleArg(arg)
			if (arg < -1) then
				arg = -1
			elseif (arg > 1) then
				arg = 1
			end
				
			return math.acos(arg)
		end

		local function checkBoolArray(v)
			if (type(v) == "table") then
				local result = {}

				for i = 1, 3 do
					result[#result + 1] = ((#v >= i) and (v[i] == true)) and true or false
				end

				return result
			else
				return {false, false, false}
			end
		end
	
		-- Funktionen
		result.applyRotation = function (rotation)
				return arr3.new(rotation[1], rotation[2], rotation[3] + result.data.aRad)
			end

		result.getLengthTo = function (p1)
				local function calcTotalLength(yLength, z)
					local fac = (yLength < 0) and -1 or 1
					return math.sqrt((yLength * yLength) + (z * z)) * fac
				end
				local p1Data = calcData(p1)
				return calcTotalLength(p1Data.yLength - result.data.yLength, p1Data.heigth - result.data.heigth)
			end
			
		result.getYLengthTo = function (p1)
				local p1Data = calcData(p1)
				return p1Data.yLength - result.data.yLength
			end

		result.calcZData = function(p1, slopes)
				local p1Data = calcData(p1)
				local _slopes = checkBoolArray(slopes)
				local height = p1Data.heigth - result.data.heigth
				local angle = angleArg(height)
				
				local slopeCorrection = 0.625
				local fac = (_slopes[1] == true) and math.addPercent(1, slopeCorrection) or 1
				fac = (_slopes[2] == true) and math.addPercent(fac, slopeCorrection) or fac
				
				return {
					angle = angle,
					length = result.getLengthTo(p1) * fac,
					height = height,
					argAndAngel = angle * length,
					slopes = _slopes,
				}
			end
			
		result.calcDirectionVectors = function (p1, slopes)
				local t0, t1
				local zData = result.calcZData(p1, slopes)
				if (radius == 0) then
					t0 = arr3.copy(p1) - result.data.origPoint
					t1 = arr3.copy(t0)
				else
					local p1Data = calcData(p1)
					t0 = arr3.mul(zData.length, result.data.tangent)
					t1 = arr3.mul(zData.length, p1Data.tangent)
				end
				if (zData.height ~= 0) then
					t0[3] = (zData.slopes[1] == true) and zData.argAndAngel or zData.height
					t1[3] = (zData.slopes[2] == true) and zData.argAndAngel or zData.height
				end
				return t0, t1
			end

		result.calcCompleteMapping = function(p1, slopes)
				local p1Data = calcData(p1)
				local t0, t1 = result.calcDirectionVectors(p1, slopes)
				return result.data.mappedPoint, t0, p1Data.mappedPoint, t1
			end
			
		result.getMeshTransf = function (doYScale, additionalScale, additionalRotate, forceXScale)
				local _doYScale = (doYScale ~= nil) and doYScale or true
				local scale = (_doYScale == true) and result.data.meshScale or {1, 1, 1}
				if (forceXScale == true) then
					scale = arr3.new(scale[2], scale[1], scale[3])
				end
				_additionalRotate = (type(additionalRotate) == 'table') and additionalRotate or {0, 0, 0}
				local _result = transf.scaleRotXYZTransl(
					arr3.toVec(scale),
					arr3.toVec(result.applyRotation(_additionalRotate)),
					arr3.toVec(result.data.mappedPoint)
				)
				if (type(additionalScale) == 'table') then
					_result = transf.setScale(_result, additionalScale)
				end
				return _result
			end
			
		return result
	end
	
	mapping.mapPoint = function (p)
			local pointData = mapping.pointData(p)
			return pointData.data.mappedPoint
		end
	
	mapping.mapPoints = function (points)
			local result = {}
			for i = 1, #points do
				result[#result + 1] = mapping.mapPoint(points[i])
			end
			return result
		end
		
	return mapping
end

return maputil