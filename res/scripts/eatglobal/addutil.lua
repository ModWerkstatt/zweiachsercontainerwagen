--- addutil
-- @author Enno Sylvester
-- @copyright 2018, 2019
-- @module eatglobal.addutil

local addutil = {
	version = "1.0",
}

--- Tools
local function initResultList(resultList)
	if (type(resultList) ~= "table") then
		resultList = {}
	end
	
	if (type(resultList.edges) ~= "table") then
		resultList.edges = {}
	end
	
	if (type(resultList.snapNodes) ~= "table") then
		resultList.snapNodes = {}
	end
	
	if (type(resultList.models) ~= "table") then
		resultList.models = {}
	end
	
	if (type(resultList.edgeObjects) ~= "table") then
		resultList.edgeObjects = {}
	end
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

--------------

local function createListManager(resultList)
	local manager = { }
	initResultList(resultList)
	
	manager.addEgdes = function(p0, t0, p1, t1)
			resultList.edges[#resultList.edges + 1] = { p0, t0 }
			resultList.edges[#resultList.edges + 1] = { p1, t1 }
		end
		
	manager.makeSnapNodes = function(firstIndex, snapNodes)
			local _snapNodes = checkBoolArray(snapNodes)
			if (_snapNodes[1] == true) then
				resultList.snapNodes[#resultList.snapNodes + 1] = firstIndex
			end
			if (_snapNodes[2] == true) then
				resultList.snapNodes[#resultList.snapNodes + 1] = #resultList.edges - 1
			end
		end
		
	manager.addFace = function(listType, face)
			if type(resultList[listType]) ~= "table" then
				resultList[listType] = {}
			end
			resultList[listType][#resultList[listType] + 1] = face
		end
	
	manager.addModel = function(id, transf)
			resultList.models[#resultList.models + 1] = {
				id = id,
				transf = transf,
			}
		end
	
	manager.addEdgeObjects = function(edgeObjects)
			if (type(edgeObjects) == "table") then
				local ixEdge = (#resultList.edges - #edgeObjects)
				for i = 1, #edgeObjects do
					if (edgeObjects[i] ~= nil) then
						resultList.edgeObjects[#resultList.edgeObjects + 1] = {
							edge = ixEdge + i, 
							param = edgeObjects[i].params,
							left = edgeObjects[i].left,
							model = edgeObjects[i].model,
						}
					end
				end
			end
		end
	
	return manager
end
-------------
	
function addutil.createAdder(mapping, resultList)
	local arr3 = addutil.eatglobal.arr3
	local logFn = addutil.eatglobal.utils.createLogFn ("[addutil.adder]")
	
	local adder = { }
	adder.mapping = mapping
	initResultList(resultList)
	
	local function addEdges(p0, t0, p1, t1)
		resultList.edges[#resultList.edges + 1] = { p0, t0 }
		resultList.edges[#resultList.edges + 1] = { p1, t1 }
	end
	
	local function makeSnapNodes(firstIndex, snapNodes)
		local _snapNodes = checkBoolArray(snapNodes)
		if (_snapNodes[1] == true) then
			resultList.snapNodes[#resultList.snapNodes + 1] = firstIndex
		end
		if (_snapNodes[2] == true) then
			resultList.snapNodes[#resultList.snapNodes + 1] = #resultList.edges - 1
		end
	end
	
	adder.addSingleEdge = function (p0, p1, snapNodes, slopes)
			local countEdgesOld = #resultList.edges
			local p0Data = mapping.pointData(p0)
			
			addEdges(p0Data.calcCompleteMapping(p1, slopes))
			makeSnapNodes(countEdgesOld, snapNodes)
		end
		
	adder.addNSplittedEdge = function (p0, p1, n, snapNodes, slopes)
			if (n <= 1) then
				adder.addSingleEdge(p0, p1, snapNodes, slopes)
			else
				local countEdgesOld = #resultList.edges
				local _slopes = checkBoolArray(slopes)
				local points = arr3.calcNSectors(p0, p1, n)
				for i = 1, #points - 1 do
					local pointData = mapping.pointData(points[i])
					addEdges(
						pointData.calcCompleteMapping(
							points[i + 1],
							{(i == 1) and _slopes[1] or false, (i == #points - 1) and _slopes[2] or false}
						)
					)
				end
				
				makeSnapNodes(countEdgesOld, snapNodes)
			end
		end
	
	adder.addFaces = function (listType, faceList)
			local function mapFaces(faces, result)
				result[#result + 1] = mapping.mapPoints(faces)
			end
			
			if type(resultList[listType]) ~= "table" then
				resultList[listType] = {}
			end
			for i = 1, #faceList do
				mapFaces(faceList[i], resultList[listType])
			end
		end
	
	adder.addModel = function (p, modelId, doYScale, additionalScale, additionalRotate, forceXScale)
			local pointData = mapping.pointData(p)
			resultList.models[#resultList.models + 1] = {
				id = modelId,
				transf = pointData.getMeshTransf(doYScale, additionalScale, additionalRotate, forceXScale),
			}
		end
		
	--[[
		Fügt einen Zaun, eine Mauer o. ä. parallel der y-Achse beginnend bei
		pStart bis pEnd hinzu.
		Das Mesh wird entsprechend der Länge skaliert.
		
		pStart:						Startpunkt (arr3, xyz)
		pEnd:							Endpunkt (arr3, xyz)
		modelId:					FileName des Modells
		modelLength:			y-Länge des Models
		additionalRotate:	Zusätzliche Rotationsangaben (optional, arr3)
		forceXScale:			Erzwingt eine x-Skaliereung anstelle der normalen Y-Skaliereung (optional, bool)
		followZAxis:			(optional, bool)
		Bemerkung(en):
			-	x und z-Koordinaten werden ausschliesslich von pStart verwendet (pEnd wird ignoriert)
	]]
	adder.addYFences = function(pStart, pEnd, modelId, modelLength, additionalRotate, forceXScale)
			local sx, sy, sz = arr3.toParams(pStart)
			local ex, ey, ez = arr3.toParams(pEnd)
			local length = math.abs(ey - sy)
			local segmentCount = math.round(length / modelLength)
			local segmentLength = length / segmentCount
			local _start = (sy < ey) and sy or ey
			local offset = segmentLength / 2
			local additionalScale = {1, segmentLength / modelLength, 1}
			
			for i = 0, segmentCount - 1 do
				local y = _start + (i * segmentLength) + offset
				adder.addModel(
					{ sx, y, sz },
					modelId,
					true,
					additionalScale,
					additionalRotate,
					forceXScale
				)
			end
		end
		
	--[[
		Fügt einen Zaun, eine Mauer o. ä. parallel der x-Achse beginnend bei
		pStart bis pEnd hinzu.
		Das Mesh wird entsprechend der Länge skaliert.
		
		pStart:						Startpunkt (arr3, xyz)
		pEnd:							Endpunkt (arr3, xyz)
		modelId:					FileName des Modells
		modelLength:			x-Länge des Models
		additionalRotate:	Zusätzliche Rotationsangaben (optional, arr3)
		forceYScale:			Bei true wird die y-Achse skaliert, andernfalls x. Sinnvoll, wenn Meshes
											um 90 Grad gedreht sind
		Bemerkung(en):
			-	y und z-Koordinaten werden ausschliesslich von pStart verwendet (pEnd wird ignoriert)
	]]
	adder.addXFences = function(pStart, pEnd, modelId, modelLength, additionalRotate, forceYScale)
			local sx, sy, sz = arr3.toParams(pStart)
			local ex, ey, ez = arr3.toParams(pEnd)
			local length = math.abs(ex - sx)
			local segmentCount = math.round(length / modelLength)
			local segmentLength = length / segmentCount
			local _start = (sx < ex) and sx or ex
			local offset = segmentLength / 2
			local additionalScale = {}
			if forceYScale then
				additionalScale = {1, segmentLength / modelLength, 1}
			else
				additionalScale = {segmentLength / modelLength, 1, 1}
			end
			local _additionalRotate = (sx < ex) and arr3.new(0, 0, math.rad(180)) or arr3.new(0, 0, 0)
			if (type(additionalRotate) == "table") then
				_additionalRotate = _additionalRotate + arr3.copy(additionalRotate)
			end

			for i = 0, segmentCount - 1 do
				local x = _start + (i * segmentLength) + offset
				adder.addModel(
					{ x, sy, sz },
					modelId,
					false,
					additionalScale,
					_additionalRotate
				)
			end
		end
		
	return adder
end

function addutil.createSimpleStationAdder(resultList)
	local arr3 = addutil.eatglobal.arr3
	local logFn = addutil.eatglobal.utils.createLogFn ("[addutil.createSimpleStationAdder]")
	
	local adder = { }
	local manager = createListManager(resultList)
	
	adder.addSingleEdge = function (p0, p1, splitMiddle, snapNodes, edgeObjects)
			local result
			local countEdgesOld = #resultList.edges
			
			if (splitMiddle == true) then
				local points = arr3.calcNSectors(p0, p1, 2)
				local t = arr3.copy(points[2]) - arr3.copy(points[1])
				manager.addEdges(points[1], t, points[2], t)
				t = arr3.copy(points[3]) - arr3.copy(points[2])
				manager.addEdges(points[2], t, points[3], t)
				result = points[2]
			else
				local t = arr3.copy(p1) - arr3.copy(p0)
				manager.addEdges(p0, t, p1, t)
				result = p0
			end
			manager.makeSnapNodes(countEdgesOld, snapNodes)
			manager.addEdgeObjects(edgeObjects)
			
			return result
		end
		
	return adder
end
	
return addutil