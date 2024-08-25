--- Mod-Tools
-- @author Enno Sylvester
-- @copyright 2019, 2020
-- @module eatglobal.mod
local verionsData = {
	majorVersion = 1,
	minorVersion = 2,
}

local _mod = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

local subKeyData = {
	["model/vehicle"] = "loadModel",
	["model/person"] = "loadModel",
	["model/car"] = "loadModel",
	["model/rock"] = "loadModel",
	["model/tree"] = "loadModel",
	["model/signal"] = "loadModel",
	["model/other"] = "loadModel",

	multipleUnit = "loadMultipleUnit",
	street = "loadStreet",
	track = "loadTrack",
	bridge = "loadBridge",
	tunnel = "loadTunnel",
	railroadCrossing = "loadRailroadCrossing",
	trafficLight = "loadTrafficLight",
	environment = "loadEnvironment",
	construction = "loadConstruction",
	module = "loadModule",
	autoGroundTex = "autoGroundTex",
	groundTex = "loadGroundTex",
	terrainGenerator = "loadTerrainGenerator",
	terrainMaterial = "loadTerrainMaterial",
	cargoType = "loadCargoType",
	grass = "loadGrass",
	gameScript = "loadGameScript",
	climate = "loadClimate",
}

function _mod.getSubKey(key)
	for k, v in pairs(subKeyData) do
		if string.starts(k, key) then
			return v
		end
	end

	return key
end

local function isHideObject(fileName, tbl)
	for i = 1, #tbl do
		if string.ends(fileName, tbl[i]) then
			return true
		end
	end
	
	return false
end

local function getTable(tbl, key)
	return _mod.eatglobal.utils.getValue(tbl[key], {})
end

local function handleHideObjectsFF(fileName, data, key)
	return (not isHideObject(fileName, eat1963_global_data.mod_lua.filefilters.hideObjects.ffObjects))
end

local function handleHideObjectsMF(fileName, data, key)
	local function doIt(availability)
		availability.yearTo = 1849
		availability.yearFrom = 1849
	end
	if isHideObject(fileName, eat1963_global_data.mod_lua.filefilters.hideObjects.mfObjects) then
		if (type(data.availability) == "table") then
			doIt(data.availability)
		elseif ((type(data.metadata) == "table") and (type(data.metadata.availability) == "table")) then
			doIt(data.metadata.availability)
		else
			doIt(data)
		end
	end
	return data
end

local function newApplyFileFilters(key, fileName, data)
	local function getKey(t)
		if string.ends(key, "/") then
			for k, v in pairs(t) do
				if string.starts(k, key) then
					return k
				end
			end
		end
		return key
	end
	
	local function doHook(_data, result)
		local _key = getKey(eat1963_global_data.mod_lua.filefilters.filterHooks)
		local hooks = {
			getTable(eat1963_global_data.mod_lua.filefilters.filterHooks, "all"),
			getTable(eat1963_global_data.mod_lua.filefilters.filterHooks, _key),
		}
		for hook in _mod.eatglobal.utils.ipairs(hooks) do
			for fn in _mod.eatglobal.utils.ipairs(hook) do
				fn(fileName, _data, _key, result)
			end
		end
	end
	
	local function filter()
		local _key = getKey(eat1963_global_data.mod_lua.filefilters.filters)
		local filters = {
			getTable(eat1963_global_data.mod_lua.filefilters.filters, "all"),
			getTable(eat1963_global_data.mod_lua.filefilters.filters, _key),
		}
		
		for f in _mod.eatglobal.utils.ipairs(filters) do
			for fn in _mod.eatglobal.utils.ipairs(f) do
				if not fn(fileName, data, _key) then
					return nil
				end
			end
		end
		return data
	end
	
	local result = eat1963_global_data.mod_lua.filefilters.origApplyFileFilters(key, fileName, data)
	if result then
		result = filter()
	end
	doHook(_mod.eatglobal.utils.copyTable(data), result)

	return result
end

local function newApplyModifiers(key, fileName, data)
	local function doHook(result)
		local hooks = {
			getTable(eat1963_global_data.mod_lua.filefilters.modifierHooks, "all"),
			getTable(eat1963_global_data.mod_lua.filefilters.modifierHooks, key),
		}
		for hook in _mod.eatglobal.utils.ipairs(hooks) do
			for fn in _mod.eatglobal.utils.ipairs(hook) do
				fn(fileName, result, key)
			end
		end
	end
	local function doModifier(result)
		local modifierList = {
			getTable(eat1963_global_data.mod_lua.filefilters.modifier, "all"),
			getTable(eat1963_global_data.mod_lua.filefilters.modifier, key),
		}
		for modifiers in _mod.eatglobal.utils.ipairs(modifierList) do
			for fn in _mod.eatglobal.utils.ipairs(modifiers) do
				result = fn(fileName, result, key)
			end
		end
		return result
	end
	data = eat1963_global_data.mod_lua.filefilters.origApplyModifiers(key, fileName, data)
	data = doModifier(data)
	doHook(_mod.eatglobal.utils.copyTable(data))
	
	return data
end

local function init ()
	_mod.logFn([[init() | eat1963_global_data =]], eat1963_global_data)
	-- globale Daten
	if (type(eat1963_global_data) ~= "table") then
		eat1963_global_data = {}
		_mod.logFn([[init() | table "eat1963_global_data" created]])
	end
	-- mod_lua
	if (type(eat1963_global_data.mod_lua) ~= "table") then
		eat1963_global_data.mod_lua = {
			version = verionsData,
		}
		_mod.logFn([[init() | table "mod_lua" created: ]], eat1963_global_data.mod_lua)
	end
	-- globale Filter und Modifier
	if (type(eat1963_global_data.mod_lua.filefilters) ~= "table") then
		eat1963_global_data.mod_lua.filefilters = {
			filters = {},
			modifier = {},
			filterHooks = {},
			modifierHooks = {},
			hideObjects = {
				ffRegistered = false,
				mfRegistered = false,
				ffObjects = {},
				mfObjects = {},
			},
			origApplyFileFilters = applyFileFilters,
			origApplyModifiers = applyModifiers,
		}
		applyFileFilters = newApplyFileFilters
		applyModifiers = newApplyModifiers
		_mod.logFn([[init() | table "mod_lua.filefilters" created: ]], eat1963_global_data.mod_lua)
	else
		local version = _mod.eatglobal.utils.getValue(eat1963_global_data.mod_lua.version, {majorVersion = 0, minorVersion = 0})
		if ((version.majorVersion < verionsData.majorVersion) or (version.minorVersion < verionsData.minorVersion)) then
			eat1963_global_data.mod_lua.version = verionsData
			applyFileFilters = newApplyFileFilters
			applyModifiers = newApplyModifiers
			_mod.logFn("init() | invalid version (", version, ").\nnew version: ", eat1963_global_data.mod_lua.version)
		end
	end
end

local function doInsert(tbl, key, runFn)
	local t = getTable(tbl, key)
	table.insert(t, runFn)
	tbl[key] = t
end

function _mod.addFilterHook(key, runFn)
	init()
	doInsert(eat1963_global_data.mod_lua.filefilters.filterHooks, key, runFn)
end

function _mod.addFileFilter(key, runFn)
	init()
	doInsert(eat1963_global_data.mod_lua.filefilters.filters, key, runFn)
end

function _mod.addModifierHook(key, runFn)
	init()
	doInsert(eat1963_global_data.mod_lua.filefilters.modifierHooks, key, runFn)
end

function _mod.addModifier(key, runFn)
	init()
	doInsert(eat1963_global_data.mod_lua.filefilters.modifier, key, runFn)
end

function _mod.addCommonApiSavedModifier(key, runFn)
	local function doFilter(fileName, data, _key)
		runFn(fileName, data, _key)
		return true
	end
	
	_mod.addFileFilter(key, doFilter)
	_mod.addModifier(key, runFn)
end

function _mod.hideObject(data, useModifier)
	local function doHide(name)
		useModifier = (useModifier == nil) and false or useModifier
		local hideObjects
		if useModifier then
			if (not eat1963_global_data.mod_lua.filefilters.hideObjects.mfRegistered) then
				--_mod.addModifier("all", handleHideObjectsMF)
				_mod.addCommonApiSavedModifier("all", handleHideObjectsMF)
				eat1963_global_data.mod_lua.filefilters.hideObjects.mfRegistered = true
			end
			hideObjects = eat1963_global_data.mod_lua.filefilters.hideObjects.mfObjects
		else
			if (not eat1963_global_data.mod_lua.filefilters.hideObjects.ffRegistered) then
				_mod.addFileFilter("all", handleHideObjectsFF)
				eat1963_global_data.mod_lua.filefilters.hideObjects.ffRegistered = true
			end
			hideObjects = eat1963_global_data.mod_lua.filefilters.hideObjects.ffObjects
		end
		
		hideObjects[#hideObjects + 1] = name
	end
	-----------------------------------------
	init()
	if (type(data) == "table") then
		for name in _mod.eatglobal.utils.ipairs(data) do
			if _mod.eatglobal.utils.isValidString(name) then
				doHide(name)
			end
		end
	elseif _mod.eatglobal.utils.isValidString(data) then
		doHide(data)
	end
end

return _mod
