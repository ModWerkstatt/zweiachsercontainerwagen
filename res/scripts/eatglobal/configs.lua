--- Configs
-- @author Enno Sylvester
-- @copyright 2017, 2018, 2019
-- @module eatglobal.configs

local configs = {
	version = "1.5",
}

local function init ()
	if type(eat1963_global_data) ~= "table" then
		eat1963_global_data = {}
	end
	if type(eat1963_global_data.configs) ~= "table" then
		eat1963_global_data.configs = {}
	end
	return true
end

function configs.createConfig ( id, params )
	local function checkLogFn (id)
		local config = eat1963_global_data.configs[id]
		if config.env.debug then
			config.logFn = configs.eatglobal.utils.createLogFn (id)
			config.logFnCounter = configs.eatglobal.utils.createLogFnCounter (id)
		else
			config.logFn = function (...) end
			config.logFnCounter = function (...) end
		end
	end
	local function createSetDebugFn ( id )
		local id = id
		local function fn ( _debug )
			eat1963_global_data.configs[id].env.debug = _debug
			checkLogFn (id)
		end
		return fn
	end
	local function createGetIdFn (id)
		local id = id
		local function fn ()
			return id
		end
		return fn
	end
	
	local function createSaveModSettingsFn (id)
		local id = id
		local function fn ()
			configs.eatglobal.utils.saveData(eat1963_global_data.configs[id].modSettings, eat1963_global_data.configs[id].env.mod_settingsFile)
		end
		return fn
	end
	
	local function createSaveUserConfigFn (id)
		local id = id
		local function fn ()
			configs.eatglobal.userSettings.flushSettings (id)
		end
		return fn
	end
	
	local function createImportUserConfigFn (id)
		local id = id
		local function fn (userConfig)
			eat1963_global_data.configs[id].userConfig = 
				configs.eatglobal.utils.proxyTable(configs.eatglobal.userSettings.importUserSettings(id, userConfig))
		end
		return fn
	end
	
	local function createInitializeUserConfigFn (id)
		local id = id
		local function fn (defaultUserSettings)
			eat1963_global_data.configs[id].userConfig = 
				configs.eatglobal.utils.proxyTable(configs.eatglobal.userSettings.create(id, defaultUserSettings))
		end
		return fn
	end
	
	if (init () and (type(id) == "string")) then
		if not eat1963_global_data.configs[id] then
			local temp = params or {}
			if (temp.env == nil) then
				temp.env = {}
			end
			if (temp.userConfig == nil) then
				temp.userConfig = {}
			end
			if (temp.modSettings == nil) then
				temp.modSettings = {}
			end
			if (temp.modifierSequenceList == nil) then
				temp.modifierSequenceList = {
					["01"] = id,
				}
			end
			-- Umgebung (env(ironment))
			temp.env.modPath = configs.eatglobal.utils.getModPath ()
			temp.env.settingsFile = temp.env.modPath.."settings.lua"
			temp.env.mod_settingsFile = temp.env.modPath.."mod_settings.lua"
			temp.env.scriptsPath = temp.env.modPath.."res/scripts/"
			temp.env.isWinOS = (os.getenv("OS") == "Windows_NT")
			
			temp.setDebug = createSetDebugFn (id)
			temp.getId = createGetIdFn (id)
			-- Mod-Settings
			temp.modSettings = configs.eatglobal.utils.readDataEx(temp.env.mod_settingsFile)
			temp.saveModSettings = createSaveModSettingsFn (id)
			-- User-Settings
			temp.initializeUserConfig = createInitializeUserConfigFn (id)
			temp.saveUserConfig = createSaveUserConfigFn (id)
			temp.importUserConfig = createImportUserConfigFn (id)
			-- zuweisen der Daten
			eat1963_global_data.configs[id] = temp
			
			--
			checkLogFn(id)
		end
		return eat1963_global_data.configs[id]
	else
		return {}
	end
end

function configs.getConfig ( id )
	if init () and (type(eat1963_global_data.configs[id]) == "table") then
		return eat1963_global_data.configs[id]
	else
		return {}
	end
end

function configs.existsConfig ( id )
	return (init () and (type(eat1963_global_data.configs[id]) == "table"))
end

return configs