--- eatglobal_intern
-- @author Enno Sylvester
-- @copyright 2017, 2018, 2019, 2020
-- @module eatglobal.eatglobal_intern

local historie = [[
	Version 1.8:
	 - Added: Added to lib math: clamp, sign, clearNumberArray, splitNumberRange
	 - Added: Global functions _pcall, _xpcall, _pRequire
	 - Changed: Abfrage, ob Funktionen nicht bereits in lib math verfügbar.
	 - Changed: struct versionsData hinzugefügt
]]

--- Laden benötigter Module, damit weitere require in den Modulen nicht nötig sind.
require "stringutil"

local verionsData = {
	majorVersion = 1,
	minorVersion = 8,
}

local eatglobal_intern = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
	classes = {},
}

--global functions
function _pcall(fnc, ...)
  local args = nil
	if (select('#', ...) > 0) then
		args = {...}
  end
  local state, result_or_error = pcall((args~= nil) and (function() return fnc(unpack(args)) end) or fnc)
  return state and result_or_error or nil, result_or_error
end

function _xpcall(fnc, catch, ...)
  local args = nil
	if (select('#', ...) > 0) then
		args = {...}
  end
  local state, result_or_error = xpcall((args~= nil) and (function() return fnc(unpack(args)) end) or fnc, catch)
  return state and result_or_error or nil, result_or_error
end

function _pRequire(modulName)
	local state, result_or_error = pcall(require, modulName)
	return state and result_or_error or nil, result_or_error
end

-- math eine Round-Funktion "unterjubeln"
local function round (var)
	return math.floor (var + 0.5)
end

local function floorX (var, decimals)
	local factor = 10 ^ (decimals or 0)
	return round(var * factor) / factor
end

local function clearNumberArray(numbers)
	local result = {}
	for i, value in ipairs(numbers) do
		local res = ((value > -0.001) and (value < 0.001)) and 0 or value
		res = floorX(res, 3)
		result[#result + 1] = res
	end
	
	return result
end

local function splitNumberRange(number1, number2, steps, insertLast)
	local result = { number1, }
	local step = (number2 - number1) / steps
	local currentStep = number1
	for i = 1, steps - 1 do
		local nextStep = currentStep + step
		table.insert(result, nextStep)
		currentStep = nextStep
	end
	insertLast = (insertLast == nil) and true or insertLast
	if insertLast then
		table.insert(result, number2)
	end
	
	return clearNumberArray(result)
end

local function setMathFunctions()
	if (type(math.round) ~= "function") then
		math.round = round
	end
	if (type(math.floorX) ~= "function") then
		math.floorX = floorX
	end
	if (type(math.clearNumberArray) ~= "function") then
		math.clearNumberArray = clearNumberArray
	end
	if (type(math.splitNumberRange) ~= "function") then
		math.splitNumberRange = splitNumberRange
	end
	
	if (type(math.randomDeg) ~= "function") then
		math.randomDeg = function(Deg) return math.random(Deg) - (Deg / 2) end
	end
	if (type(math.addPercent) ~= "function") then
		math.addPercent = function(arg, percent) return arg + ((arg * percent) / 100) end
	end
	if (type(math.clamp) ~= "function") then
		math.clamp = function(value, min, max) return math.min(math.max(value, min), max) end
	end
	if (type(math.sign) ~= "function") then
		math.sign = function(x) return (x > 0) and 1 or (x < 0) and -1 or 0 end
	end
end
setMathFunctions()

--	class set
local function buildFilterFnc(filterFnc)
	local function noFilterFnc(value)
		return true
	end
	local function filterTableFnc(value)
		for i = 1, #filterFnc do
			if not filterFnc[i](value) then
				return false
			end
		end
		return true
	end
	if (type(filterFnc) == "function") then
		return filterFnc
	elseif (type(filterFnc) == "table") then
		return filterTableFnc
	else
		return noFilterFnc
	end
end

local set = {}
local mt_set = {
  __add = function(self, var)
    local result = set.new{}
    for i, v in ipairs(self) do
      table.insert(result, (var[i] ~= nil) and _pcall(function() return v + var[i] end) or nil)
    end
    return result
  end,
  __sub = function(self, var)
    local result = set.new{}
    for i, v in ipairs(self) do
      table.insert(result, (var[i] ~= nil) and _pcall(function() return v - var[i] end) or nil)
    end
    return result
  end,
  __mul = function(self, var)
    local result = set.new{}
    for i, v in ipairs(self) do
      table.insert(result, (var[i] ~= nil) and _pcall(function() return v * var[i] end) or nil)
    end
    return result
  end,
  __div = function(self, var)
    local result = set.new{}
    for i, v in ipairs(self) do
      table.insert(result, (var[i] ~= nil) and _pcall(function() return v / var[i] end) or nil)
    end
    return result
  end,
	__eq = function(self, var)
		if (#self == #var) then
			for i, v in ipairs(self) do
				if (v ~= var[i]) then
					return false
				end
			end
			return true
		else
			return false
		end
	end,
	__tostring = function(self)
		local stack = {"{"}
		local sep = ", "
		for i, v in ipairs(self) do
			if (i > 1) then
				table.insert(stack, sep)
			end
			table.insert(stack, tostring(v))
		end
		table.insert(stack, "}")
		return table.concat(stack)
	end,
	__index = {
		intersection = function(self, var)
			local result = set.new{}
			for i, v in ipairs(self) do
				for j, w in ipairs(var) do
					if (v == w) then
						table.insert(result, v)
						break
					end
				end
			end
			return result
		end,
		_pairs = function(self, orderFnc, filterFnc)
			-- collect the keys
			local keys = {}
			for k in pairs(self) do
				keys[#keys + 1] = k
			end
			if orderFnc then
				table.sort(keys, function(a, b) return orderFnc(self[a], self[b]) end)
			end
			
			local doFilter = buildFilterFnc(filterFnc)
			-- return the iterator function
			local i = 0
			return function()
				i = i + 1
				while keys[i] and (not doFilter(self[keys[i]])) do
					i = i + 1
				end
				if keys[i] then
					return self[keys[i]]
				end
			end
		end,
    contains = function(self, value, compareFnc, filterFnc)
			for val in self:_pairs(nil, filterFnc) do
        if (type(compareFnc) == "function") then
          if compareFnc(val, value) then
            return true
          end
        else
          if (val == value) then
            return true
          end
        end
			end
      return false
    end,
		filter = function(self, filterFnc)
      local result = set.new{}
			for value in self:_pairs(nil, filterFnc) do
				table.insert(result, value)
			end
      return result
    end,
		forEach = function(self, fnc, filterFnc)
			for value in self:_pairs(nil, filterFnc) do
				fnc(value)
			end
		end,
		map = function(self, fnc, filterFnc)
      local result = set.new{}
			for value in self:_pairs(nil, filterFnc) do
				table.insert(result, fnc(value))
			end
      return result
    end,
		print = function(self)
			print(tostring(self))
		end,
		tostring = function (self)
			return tostring(self)
		end,
		union = function(self, var)
			local result = set.new{}
			for i, v in ipairs(self) do table.insert(result, v) end
			for i, v in ipairs(var) do table.insert(result, v) end
			return result
		end,
	},
}
setmetatable(set, mt_set)

function set.new(var)
  local result = {}
  setmetatable(result, mt_set)
  for i, v in ipairs(var) do result[i] = v end
  return result
end

function set.add(a, b)
	return set.new(a) + b
end

function set.sub(a, b)
	return set.new(a) - b
end

function set.mul(a, b)
	return set.new(a) * b
end

function set.div(a, b)
	return set.new(a) / b
end

--

function set._pairs(a, orderFnc, filterFnc)
  return set.new(a):_pairs(orderFnc, filterFnc)
end

function set.contains(a, value, compareFnc, filterFnc)
	return set.new(a):contains(value, compareFnc, filterFnc)
end

function set.filter(a, filterFnc)
  return set.new(a):filter(filterFnc)
end

function set.forEach(a, fnc, filterFnc)
  set.new(a):forEach(fnc, filterFnc)
end

function set.map(a, fnc, filterFnc)
  return set.new(a):map(fnc, filterFnc)
end

function set.intersection (a, b)
	return set.new(a):intersection(b)
end

function set.tostring(a)
	return set.new(a):tostring()
end

function set.print (a)
  set.new(a):print()
end

function set.union (a, b)
	return set.new(a):union(b)
end
--eatglobal_intern.classes.set = set
eatset = set

return eatglobal_intern
