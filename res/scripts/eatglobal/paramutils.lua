--- Parameter Utils
-- @author Enno Sylvester
-- @copyright 2020
-- @module eatglobal.paramutils

local historie = [[
	Version 1.0:
	 - Release
	Version 1.1:
	 - Changed:	Eliminate minor bugs.
]]

local verionsData = {
	majorVersion = 1,
	minorVersion = 1,
}

local paramutils = {
	historie = historie,
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

local function valuesToStrings(values)
	local set = eatset.new(values)
	local result = {}
	for val in set:_pairs() do
		if (type(val) == "string") then
			table.insert(result, val)
		else
			table.insert(result, tostring(val))
		end
	end
	
	return result
end

local function makeRange(min, max, step)
	step = step or 1
	max = max + (step * 0.001)
	local result = {}
	for i = min, max, step do
		table.insert(result, i)
	end
	return result
end

local function makeMiddledRange(max, step)
	local steps = makeRange(0, max, step)
	local result = { 0 }
	for i = 2, #steps do
		table.insert(result, 1, -steps[i])
		table.insert(result, steps[i])
	end
	return result
end

local function translateCaptions(captions)
	local set = eatset.new(captions)
	local result = {}
	for val in set:_pairs() do
		table.insert(result, _(val))
	end
	
	return result
end

local function makeEntry(result, uiType, key, name, values, defaultIndex, tooltip, data, fun)
	local function checkName(name)
		if ((type(name) == "string") and (name:sub(1, 1) == "*")) then
			return key..name:sub(2)
		else
			return name
		end
	end
	
	table.insert(result.params, {
		uiType = uiType,
		key = key,
		name = _(checkName(name)),
		values = values,
		defaultIndex = defaultIndex or 0,
		tooltip = _(checkName(tooltip)),
	})
	result.data[key] = {
		data = (data ~= nil) and ((type(data) == "table") and data or {data}) or {},
		fun = (type(fun) == "function") and fun or nil,
	}
end

function paramutils.create()
	local result = {
		params = {},
		data = {},
	}
	result.makeButton = function(key, name, values, defaultIndex, tooltip, data, fun)
		makeEntry(result, "BUTTON", key, name, translateCaptions(valuesToStrings(values)), defaultIndex, tooltip, data, fun)
	end
	result.makeCheckbox = function(key, name, values, isChecked, data, fun)
		makeEntry(result, "CHECKBOX", key, name, values or translateCaptions({"No", "Yes"}), isChecked and 1 or 0, nil, data, fun)
	end
	result.makeCombobox = function(key, name, values, defaultIndex, tooltip, data, fun)
		makeEntry(result, "COMBOBOX", key, name, translateCaptions(valuesToStrings(values)), defaultIndex, tooltip, data, fun)
	end
	result.makeIconButton = function(key, name, icons, defaultIndex, tooltip, data, fun)
		makeEntry(result, "ICON_BUTTON", key, name, icons, defaultIndex, tooltip, data, fun)
	end
	result.makeSlider = function(key, name, values, defaultIndex, tooltip, data, fun)
		makeEntry(result, "SLIDER", key, name, valuesToStrings(values), defaultIndex, tooltip, data, fun)
	end
	
	result.getIndex = function(params, key) return params[key] or 0 end
	result.getData = function(params, key)
		return result.data[key].data[(params[key] or 0) + 1]
	end
	result.getValue = function(params, key)
		return result.data[key].values[(params[key] or 0) + 1]
	end
	result.runAllFun = function(params)
		for key, val in pairs(result.data) do
			if (type(val.fun) == "function") then
				val.fun(val.data[(params[key] or 0) + 1])
			end
		end
	end
	
	return result
end

paramutils.tools = {
	valuesToStrings = valuesToStrings,
	makeRange = makeRange,
	makeMiddledRange = makeMiddledRange,
	translateArray = translateCaptions,
}

return paramutils

