--- conutils
-- @author Enno Sylvester
-- @copyright 2018, 2019
-- @module eatglobal.conutils

local constructionutil = require "constructionutil"

local conutils = {
	version = "1.5",
}

function conutils.makeFence(points, modelId, length, loop, result, scale, rotationModel)
local transf = conutils.eatglobal.transf
local vec3 = conutils.eatglobal.vec3

	local num1 = #points + 1
	local num = loop and num1 or #points
	
	for i = 2, num do
		
		-- get start and end coordinates
		coordStart = points[i - 1]
		xStart = coordStart[1]
		yStart = coordStart[2]
		zStart = coordStart[3]
		
		coordEnd = points[i == num1 and 1 or i]
		xEnd = coordEnd[1]
		yEnd = coordEnd[2]
		zEnd = coordEnd[3]
		
		-- calculate the fence vector
		fenceVector = vec3.new(xEnd-xStart, yEnd-yStart, zEnd-zStart)
		fenceVectorLength = vec3.length(fenceVector)
		
		-- calculate segments
		segments = fenceVectorLength / length
		fenceVectorSegment = vec3.new((xEnd-xStart) / segments, (yEnd-yStart) / segments, (zEnd-zStart) / segments)

		-- place along vector and rotate z axis with xyAngle, offset with half segment length
		for build_fence = 1, math.floor(segments) do
		
			fence_point = vec3.sub(vec3.add(vec3.new(xStart, yStart, zStart), vec3.mul(build_fence, fenceVectorSegment)), vec3.mul(0.5, fenceVectorSegment))
			
			if (type(scale) == "table") then
				if (type(rotationModel) == "table") then
					result[#result + 1] = {
						id = modelId,
						transf = transf.setRotation(transf.setScale(transf.rotZTransl(vec3.xyAngle(fenceVector), fence_point), scale), rotationModel),
					}
				else
					result[#result + 1] = {
						id = modelId,
						transf = transf.setScale(transf.rotZTransl(vec3.xyAngle(fenceVector), fence_point), scale),
					}
				end
			else
				if (type(rotationModel) == "table") then
					result[#result + 1] = {
						id = modelId,
						transf = transf.setRotation(transf.rotZTransl(vec3.xyAngle(fenceVector), fence_point), rotationModel),
					}
				else
					result[#result + 1] = {
						id = modelId,
						transf = transf.rotZTransl(vec3.xyAngle(fenceVector), fence_point),
					}
				end
			end
		
		end
		
	end	
			
end

function conutils.makeFences (data, result, scale, rotationModel)
	local transf = conutils.eatglobal.transf
	local vec3 = conutils.eatglobal.vec3
	--[[
		data ist ein array von folgenden Werten:
			[1] - points: Array von Punkten für den Zaun (mindestens 2 Punkte erforderlich)
			[2] - modelFile: Das Zaunobjekt
			[3] - length: Länge des Objektes in modelFile
			[4] - modelFile für zusätzliches Gebäude (optional)
			[5] - true: Gebäude am ersten Punkt; false: Gebäude am letzten Punkt; default true
	]]
	if (type(data) == "table") then
		local arr3 = conutils.eatglobal.arr3
		for i = 1, #data do
			local points = data[i][1]
			local modelFile = data[i][2]
			local length = data[i][3]
			local building = data[i][4] or ""
			local buildingAtFirstPoint = data[i][5] or true
			conutils.makeFence(points, modelFile, length, false, result, scale, rotationModel)
			if (building ~= "") then
				-- Gebäude setzen
				if (buildingAtFirstPoint == true) then
					local vecPos = vec3.new2(points[1])
					local vecRotation = vec3.new2(arr3.sub(points[2], points[1]))
					result[#result + 1] = {
						id = building,
						transf = transf.rotZTransl(vec3.xyAngle(vecRotation), vecPos),
					}
				else
					local vecPos = vec3.new2(points[#points])
					local vecRotation = vec3.new2(arr3.sub(points[#points], points[#points - 1]))
					result[#result + 1] = {
						id = building,
						transf = transf.rotZTransl(vec3.xyAngle(vecRotation), vecPos),
					}
				end
			end
		end
	end
end

function conutils.checkParams(origParams, runFnParams)
	local utils = conutils.eatglobal.utils
	local result = utils.copyTable(runFnParams)
	for i = 1, #origParams do
		local key = origParams[i].key
		local defaultValue = origParams[i].defaultIndex or 0
		result[key] = runFnParams[key] or defaultValue
	end
	
	return result
end

function conutils.makeStocks(config, result)
	local utils = conutils.eatglobal.utils
	--local logFn = utils.createLogFn("conutils")
	local logFn = function (...) end
	logFn("makeStocks | config = ", config)
	logFn("makeStocks | config.groundFaceTexture = ", config.groundFaceTexture)
	local dim = 8.0
	local groundFaceTexture = true
	if (type(config.groundFaceTexture) == "boolean") then
		groundFaceTexture = config.groundFaceTexture
	end
	logFn("makeStocks | groundFaceTexture = ", groundFaceTexture)
	
	for stock = 1, #config.stocks do
		local stockConfig = config.stocks[stock]
		
		local angle = stockConfig.angle == nil and .0 or stockConfig.angle		
		
		local cz = math.cos(angle)
		local sz = math.sin(angle)
				
		local dirx0 = cz * dim
		local diry0 = sz * dim
		
		local dirx1 = -diry0
		local diry1 = dirx0

		local dirx0_ = dirx0 * stockConfig.sizex * .5
		local diry0_ = diry0 * stockConfig.sizex * .5
		
		local dirx1_ = dirx1 * stockConfig.sizey * .5
		local diry1_ = diry1 * stockConfig.sizey * .5
		
		local px0 = stockConfig.x - dirx0_ - dirx1_
		local py0 = stockConfig.y - diry0_ - diry1_

		local px1 = stockConfig.x + dirx0_ - dirx1_
		local py1 = stockConfig.y + diry0_ - diry1_

		local px2 = stockConfig.x + dirx0_ + dirx1_
		local py2 = stockConfig.y + diry0_ + diry1_

		local px3 = stockConfig.x - dirx0_ + dirx1_
		local py3 = stockConfig.y - diry0_ + diry1_
		
		local pz = stockConfig.z or 0
		
		if groundFaceTexture then
			local groundFaceTextureFill = { 
				RECEIVING = "building_paving_fill",
				SENDING = "building_paving_fill"
			}
			
			local groundFaceTextureStroke = { 
				RECEIVING = "building_paving",
				SENDING = "building_paving"
			}
					
			result.groundFaces[#result.groundFaces + 1] = { 
				face = { { px0, py0 }, { px1, py1 }, { px2, py2 }, { px3, py3 } }, 
				modes = { { type = "FILL", key = groundFaceTextureFill[stockConfig.type] } } 
			}
			
			result.groundFaces[#result.groundFaces + 1] = { 
				face = { { px0, py0 }, { px1, py1 }, { px2, py2 }, { px3, py3 } }, 
				modes = { { type = "STROKE_OUTER", key = groundFaceTextureStroke[stockConfig.type] } } 
			}
		end

		px0 = px0 + dirx1 * .5
		py0 = py0 + diry1 * .5
		
		local stockEdges = { }
		
		for i = 0, stockConfig.sizex - 1 do
			for j = 0, stockConfig.sizey - 1 do
				stockEdges[#stockEdges + 1] = { #result.models, 0 }

				result.models[#result.models + 1] = {
					id = "industry/common/stock_lane_8m.mdl",
					transf = { cz, sz, .0, .0, -sz, cz, .0, .0, .0, .0, 1.0, .0, px0 + i * dirx0 + j * dirx1, py0 + i * diry0 + j * diry1, pz, 1.0 }				
				}
			end
		end
		
		result.stocks[#result.stocks + 1] = {
			cargoType = stockConfig.cargoType,
			type = stockConfig.type,
			edges = stockEdges
		}
	end
	
	for rule = 1, #config.stockRules do
		result.stockRules[#result.stockRules + 1] = config.stockRules[rule]
	end	
end

return conutils