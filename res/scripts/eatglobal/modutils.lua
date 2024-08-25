--- File-Filter
-- @author Enno Sylvester
-- @copyright 2019, 2020
-- @module eatglobal.modutils

local historie = [[
	Version 1.7:
	 - Added: Behandlung weiterer Usereinstellungen hinzugefügt
	Version 1.8:
	 - interne Version
	Version 1.9:
	 - Changed: komplette Umstellung von "settings.lua"-Unterstützung auf interne Game-UI
	 - Fixed: Versionskonflikte in function init() behoben. Daten älterer Versionen wurden gelöscht. Ab jetzt jede Version mit eigenen Daten.
]]

local verionsData = {
	majorVersion = 1,
	minorVersion = 9,
}

local modutils = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

-- Tools
local function getAsTable(data)
	if modutils.eatglobal.utils.isValidString(data) then
		return { data }
	elseif (type(data) == "table") then
		return data
	else
		return {}
	end
end

local function insertIfValidString(tbl, value)
	if modutils.eatglobal.utils.isValidString(value) then
		table.insert(tbl, value)
		return true
	end
	return false
end
--

local function init ()
	-- globale Daten
	if (type(eat1963_global_data) ~= "table") then
		eat1963_global_data = {}
	end
	-- modutils
	if (type(eat1963_global_data.modutils) ~= "table") then
		eat1963_global_data.modutils = {
			modelHandler = {
				modelHandlerRegistered = false,
				models = {},
			},
			modData = {},
		}
	end
	if (type(eat1963_global_data.modutils.modelHandler) ~= "table") then
		eat1963_global_data.modutils.modelHandler = {
			modelHandlerRegistered = false,
			models = {},
		}
	end
	if (type(eat1963_global_data.modutils.modelHandler.models) ~= "table") then
		eat1963_global_data.modutils.modelHandler.models = {}
	end
	if (type(eat1963_global_data.modutils.modData) ~= "table") then
		eat1963_global_data.modutils.modData = {}
	end
	eat1963_global_data.modutils.version = nil
end

local function getGlobalModUtils()
	return eat1963_global_data.modutils
end

-- Modifier
local function modelHandler(fileName, data, key)
	local function findObject(fileName)
		local models = getGlobalModUtils().modelHandler.models
		for model in modutils.eatglobal.utils.ipairs(models) do
			if string.ends(fileName, model.fileName) then
				return model
			end
		end
		return nil
	end
	
	local objectData = findObject(fileName)
	if (type(objectData) == "table") then
		return objectData.fun(fileName, data, key, modutils.eatglobal.mod.getSubKey(key), objectData.funData)
	end
	
	return data
end

local function doHandleObject (data, fun, funData)
	local handler = getGlobalModUtils().modelHandler
	local function putData(name)
		handler.models[#handler.models + 1] = {
			fileName = name,
			fun = fun,
			funData = funData,
		}
	end
	--------------------------
	if (not handler.modelHandlerRegistered) then
		modutils.eatglobal.mod.addModifier("all", modelHandler)
		handler.modelHandlerRegistered = true
	end
	
	if (type(data) == "table") then
		for name in modutils.eatglobal.utils.ipairs(data) do
			if modutils.eatglobal.utils.isValidString(name) then
				putData(name)
			end
		end
	elseif modutils.eatglobal.utils.isValidString(data) then
		putData(data)
	end
end
--

local function doHandleStartAndEndYear (fileName, data, key, subKey, funData)
	--modutils.logFn("doHandleStartAndEndYear | fileName = ", fileName, " / funData = ", funData)
	local function __do(key)
		--modutils.logFn("doHandleStartAndEndYear | fileName = ", fileName, " / key = ", key)
		if funData.handleStartYear then
			key.yearFrom = 0
		end
		if funData.handleEndYear then
			key.yearTo = 0
		end
	end
	if (subKey ~= "loadSoundSet") then
		if ((subKey == "loadModel") and (type(data.metadata) == "table") and (type(data.metadata.availability) == "table")) then
			__do(data.metadata.availability)
		elseif ((subKey == "loadConstruction") and (type(data.availability) == "table")) then
			__do(data.availability)
		else
			__do(data)
		end
	end
	--modutils.logFn("doHandleStartAndEndYear | fileName = ", fileName, " / data = ", data)
	return data
end

local function doRun(modId, params)
	local modData = getGlobalModUtils().modData[modId]
	local intern = modData.modutilsIntern
	local utils = modutils.eatglobal.utils
	-- checkAutoFiles
	local function checkAutoFiles(key, suffix, result)
		local function isFile(tbl, fileName)
			for i = 1, #tbl do
				if (tbl[i] == fileName) then
					return true
				end
			end
			return false
		end
		local set = eatset.new(intern.availableModelFiles)
		if ((params[key] or 0) == 0) then
			-- nur ausblenden, wenn HauptObjekt (Lok, Waggon, etc.) auch asgeblendet wird
			for val in set:_pairs() do
				local fName, fExt = utils.getFileNameAndExtension(val)
				local file = fName..suffix.."."..fExt
				if isFile(intern.hideFiles, val) then
					table.insert(intern.hideFiles, file)
				else
					table.insert(result, file)
				end
			end
		else
			-- alle Ausblenden
			for val in set:_pairs() do
				local fName, fExt = utils.getFileNameAndExtension(val)
				table.insert(intern.hideFiles, fName..suffix.."."..fExt)
			end
		end
	end
	-- params (für evtl. späteren Zugriff) sichern
	intern.userParams = params
	-- alle in myParams hinterlegten Methoden ausführen
	modData.myParams.runAllFun(params)
	
	-- Autofiles abarbeiten
	local validAutoFiles = {}
	for key, value in pairs(intern.autoFiles) do
		checkAutoFiles(key, value, validAutoFiles)
	end
	local set = eatset.new(validAutoFiles)
	for val in set:_pairs() do
		table.insert(intern.availableModelFiles, val)
	end
	-- eigentliche Arbeit (Modifier, FileFilter, etc.) starten
	--		hideFiles
	modutils.eatglobal.mod.hideObject(intern.hideFiles)
	
	--		Startjahr und Endjahr
	local yearData = {
		handleStartYear = (params[intern.disableStartYearKey] or 0) == 0,
		handleEndYear = (params[intern.disableEndYearKey] or 0) == 0,
	}
	if ((yearData.handleStartYear == true) or (yearData.handleEndYear == true)) then
		doHandleObject(intern.availableModelFiles, doHandleStartAndEndYear, yearData)
	end
	modutils.logFn("doRun | globalModUtils = ", getGlobalModUtils())
end

local function doCreate(modId, modData)
	local utils = modutils.eatglobal.utils
	local getValue = utils.getValue
	local isValidString = modutils.eatglobal.utils.isValidString
	-- myParamsRunAtFiles 
	local function myParamsRunAtFiles(data)
		if ((type(data) == "table") and (type(data.tbl) == "table")) then
			local files = eatset.new(getAsTable(data.values))
			for val in files:_pairs() do
				insertIfValidString(data.tbl, val)
			end
		end
	end
	-- createUI
	local function createUI(myParams, modData)
		local userSelection = getValue(modData.userSelection, {})
		local intern = modData.modutilsIntern
		local set
		-- handle Modelfiles
		set = eatset.new(getValue(userSelection.files, {}))
		for val in set:_pairs() do
			local modelFiles = getAsTable(val.modelFiles)
			myParams.makeButton(val.key, val.name, val.values, val.default == false and 1 or 0, val.tooltip,
				{{tbl = intern.availableModelFiles, values = modelFiles}, {tbl = intern.hideFiles, values = modelFiles}},
				myParamsRunAtFiles)
		end
		
		-- handle autoFiles
		set = eatset.new(getValue(userSelection.autoFiles, {}))
		for val in set:_pairs() do
			if (isValidString(val.key) and isValidString(val.autoString)) then
				intern.autoFiles[val.key] = val.autoString
				myParams.makeButton(val.key, val.name, val.values, val.default == false and 1 or 0, val.tooltip)
			end
		end
		
		-- handle Startjahr
		if (type(userSelection.disableStartYear) == "table") then
			local entry = userSelection.disableStartYear
			intern.disableStartYearKey = entry.key
			myParams.makeButton(entry.key, entry.name, entry.values, entry.default == false and 1 or 0, entry.tooltip)
		end
		
		-- handle Endjahr
		if (type(userSelection.disableEndYear) == "table") then
			local entry = userSelection.disableEndYear
			intern.disableEndYearKey = entry.key
			myParams.makeButton(entry.key, entry.name, entry.values, entry.default == false and 1 or 0, entry.tooltip)
		end
		
	end
	-- weitere Behandlungen (hideFiles, etc.)
	local function handleGeneralSection(modData)
		local general = getValue(modData.general, {})
		modutils.eatglobal.mod.hideObject(general.hideFiles, true)
	end
	--- HIER geht's los!!!!
	init()
	local globalModUtils = getGlobalModUtils()
	if utils.isValidString(modId) then
		local result = {}
		if (type(globalModUtils.modData[modId]) ~= "table") then
			-- Daten-Validität checken/herstellen
			modData = getValue(modData, {})
			modData.modutilsIntern = {
				disableStartYearKey = "",
				disableEndYearKey = "",
				availableModelFiles = {},
				autoFiles = {},
				hideFiles = {},
				userParams = {},
			}
			
			-- modData global abspeichern
			globalModUtils.modData[modId] = modData
			
			-- Tool für UI erzeugen
			globalModUtils.modData[modId].myParams = modutils.eatglobal.paramutils.create()
			
			-- UI erstellen
			createUI(globalModUtils.modData[modId].myParams, modData)
			
			-- Section modData.general bearbeiten
			handleGeneralSection(modData)
		end
		
		result.myParams = globalModUtils.modData[modId].myParams
		result.execute = function(params) doRun(modId, params) end
		result.getUserSelections = function() return globalModUtils.modData[modId].modutilsIntern.userParams end
		return result, true, ""
	else
		return {}, false, "Invalid modId"
	end
end

modutils.userSettings = {
	create = doCreate,
}

return modutils