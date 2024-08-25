--- lanemanager
-- @author Enno Sylvester
-- @copyright 2017, 2019
-- @module eatglobal.lanemanager

lanemanager = {
	version = "1.6",
}

function lanemanager:new()
	local res = {
		data = {
			lanes = {
			},
			node = {
			},
			nodes = {
			},
			edges = {
			},
		},
	}
	setmetatable(res, self)
	self.__index = self
	return res
end

local function calcScale(dist, angle)
	if (angle < .001) then
		return dist
	end
	
	local pi = 3.14159
	local pi2 = pi / 2	
	local sqrt2 = 1.41421
	
	local scale = 1.0
	if (angle >= pi2) then 
		scale = 1.0 + (sqrt2 - 1.0) * ((angle - pi2) / pi2)
	end

	return .5 * dist / math.cos(.5 * pi - .5 * angle) * angle * scale
end

local function calcLanes(input)
	local arr3 = lanemanager.eatglobal.arr3
	local result = { }
	
	for i = 1, #input do
		local entry = input[i]
	
		local p0 = entry[1]
		local p1 = entry[2]
		local t0 = entry[3]
		local t1 = entry[4]

		t0 = arr3.normalize(t0)
		t1 = arr3.normalize(t1)
		
		local length = arr3.distance(p0, p1)
		local angle = arr3.angleUnit(t0, t1)
		
		local scale = calcScale(length, angle)
		
		t0 = arr3.mul(scale, t0)
		t1 = arr3.mul(scale, t1)
		
		result[#result + 1] = {p0, t0}
		result[#result + 1] = {p1, t1}
	end	
	
	return result
end

function lanemanager:addPoints(points, useAllPoints, width, node, nodes, edges)
	local arr3 = lanemanager.eatglobal.arr3
	local directions = {}
	local temp = {}
	local p1
	local p2
	local t
	
	if (type(points) == 'table') and (#points > 1) then
		for i = 1, #points do
			p1 = points[i]
			p2 = points[i + 1]
			if (p2 ~= nil) then
				t = arr3.sub(p2, p1)
			end
			table.insert(directions, t)
		end
		
		--directions = arr3.mormize(directions)

		local numLanes = useAllPoints and #points - 1 or #points - 2
		for i = 1, #points do
			local d1 = points[i]
			local d2 = points[i + 1]
			if (d2 ~= nil) and (#temp < numLanes) then
				temp[#temp + 1] = {d1, d2, directions[i], directions[i + 1]}
			end
		end
		temp = calcLanes(temp)
		for i = 1, #temp do
			table.insert(temp[i], width)
			self.data.lanes[#self.data.lanes + 1] = temp[i]
		end
		local offset = #self.data.lanes
		if (type(node) == 'table') then
			for i = 1, #node do
				table.insert(self.data.node, offset + node[i])
			end
		end
		if (type(nodes) == 'table') then
			for i = 1, #nodes do
				table.insert(self.data.node, offset + nodes[i])
			end
		end
		if (type(edges) == 'table') then
			for i = 1, #edges do
				table.insert(self.data.edges, offset + edges[i])
			end
		end
	end
end

--- erstellt Lane, wobei die Erste und 
--	Wir benötigen 4 Punkte:
--		1:	Punkt vor der Lane
--		2:	Startpunkt der Lane
--		3:	Endpunkt der Lane
--		4:	Punkt nach der Lane
-- @lanemanager:addPointsEx
-- @param points
-- @param width
-- @param useFirst	bool, default false
-- @param useLast		bool, default false
-- @param node
-- @param nodes
-- @param edges
function lanemanager:addPointsEx(points, width, useFirst, useLast, node, nodes, edges)
	local arr3 = lanemanager.eatglobal.arr3
	local temp = {}
	local p1
	local p2
	local t
	
	if (type(points) == 'table') and (#points > 1) then
		for i = 1, #points do
			p1 = points[i]
			p2 = points[i + 1]
			if (p2 ~= nil) then
				t = arr3.sub(p2, p1)
			end
			table.insert(temp, {p1, p2, t, t})
		end
	end
end

--- erstellt eine einzelne geschwungene Lane
--	Wir benötigen 4 Punkte:
--		1:	Punkt vor der Lane
--		2:	Startpunkt der Lane
--		3:	Endpunkt der Lane
--		4:	Punkt nach der Lane
-- @lanemanager:addSingleLane
-- @param points
function lanemanager:addSingleLane(points, width, node, nodes, edges)
	local arr3 = lanemanager.eatglobal.arr3
	local temp = {}
	local t1, t2
	
	if (type(points) == 'table') and (#points == 4) then
		t1 = arr3.sub(points[2], points[1])
		t2 = arr3.sub(points[4], points[3])
		temp = calcLanes({ {points[2], points[3], t1, t2} })
		for i = 1, #temp do
			table.insert(temp[i], width)
			self.data.lanes[#self.data.lanes + 1] = temp[i]
		end

		if node then
			table.insert(self.data.node, #self.data.lanes)
		end
		if nodes then
			table.insert(self.data.nodes, #self.data.lanes)
		end
		if edges then
			table.insert(self.data.edges, #self.data.lanes)
		end
	end
end

function lanemanager:getLanes ()
	return self.data.lanes
end

return lanemanager