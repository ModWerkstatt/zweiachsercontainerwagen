--- Usersettings
-- @author Enno Sylvester
-- @copyright 2017, 2019
-- @module eatglobal.usersettings

local usersettings = {
	version = "1.4",
}

local function init ()
	if type(eat1963_global_data) ~= "table" then
		eat1963_global_data = {}
	end
	if type(eat1963_global_data.userSettings) ~= "table" then
		eat1963_global_data.userSettings = {}
	end
	return true
end

local function doImportSettings(modSettings, importSettings)
	local userSettingsCount = 0
	for key, value  in pairs(importSettings) do
		userSettingsCount = userSettingsCount + 1
	end
	modSettings.values = {}
	local defaultCount = 0
	local importCount = 0
	for key, value in pairs(modSettings.defaultSettings) do
		if (value.type ~= nil) then
			local importValue = importSettings[key]
			if (type(importValue) == value.type) then
				if value.type == "number" then
					if (value.min ~= nil) then
						importValue = math.max(value.min, importValue)
					end
					if (value.max ~= nil) then
						importValue = math.min(value.max, importValue)
					end
				end
				modSettings.values[key] = importValue
				importCount = importCount + 1
			else
				if (value.default ~= nil) then
					modSettings.values[key] = value.default
				else
					if (value.type == "boolean") then
						modSettings.values[key] = false
					elseif (value.type == "number") then
						modSettings.values[key] = 0
					elseif (value.type == "string") then
						modSettings.values[key] = ""
					elseif (value.type == "table") then
						result[key] = {}
					end
				end
			end
		end
		defaultCount = defaultCount + 1
	end
	
	if (not usersettings.eatglobal.utils.fileExists(modSettings.settingsFile)) or (importCount ~= defaultCount) or (userSettingsCount ~= defaultCount) then
		usersettings.eatglobal.utils.saveData(modSettings.values, modSettings.settingsFile)
	end
	
	return modSettings
end

function usersettings.create(id, defaultSettings)
	if init() and (type(defaultSettings) == "table") then
		local modSettings = {
			defaultSettings = defaultSettings,
			modPath = usersettings.eatglobal.utils.getModPath(),
			values = {},
		}
		modSettings.settingsFile = modSettings.modPath.."settings.lua"
		
		local fileSettings = usersettings.eatglobal.utils.readData(modSettings.settingsFile)
		if (type(fileSettings) ~= "table") then
			fileSettings = {}
		end
		
		eat1963_global_data.userSettings[id] = doImportSettings(modSettings, fileSettings)
		
		return eat1963_global_data.userSettings[id].values
	else
		return {}
	end
end

function usersettings.importUserSettings(id, usersettings)
	if init () and (type(eat1963_global_data.userSettings[id]) == "table") and (type(usersettings) == "table") then
		eat1963_global_data.userSettings[id] = doImportSettings(eat1963_global_data.userSettings[id], usersettings)
		return eat1963_global_data.userSettings[id].values
	else
		return {}
	end
end

function usersettings.getSettings(id)
	if init () and (type(eat1963_global_data.userSettings[id]) == "table") then
		return eat1963_global_data.userSettings[id].values
	else
		return {}
	end
end

function usersettings.getDefaultSettings(id)
	if init () and (type(eat1963_global_data.userSettings[id]) == "table") then
		return eat1963_global_data.userSettings[id].defaultSettings
	else
		return {}
	end
end

function usersettings.existsSettings(id)
	return (init () and (type(eat1963_global_data.userSettings[id]) == "table"))
end

function usersettings.flushSettings(id)
	if init () and (type(eat1963_global_data.userSettings[id]) == "table") then
		usersettings.eatglobal.utils.saveData(eat1963_global_data.userSettings[id].values, eat1963_global_data.userSettings[id].settingsFile)
	end
end

return usersettings
