--- Main
-- @author Oskar Eisemuth, Enno Sylvester (Anpassung)
-- @copyright 2017, 2018, 2019, 2020
-- @module eatglobal
local __debug__ = false
local verionsData = {
	majorVersion = 2,
	minorVersion = 29,
}

local eatglobal = {
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
	dmp = function(...)
		local ok, inspect = pcall(require, "inspect")
		if (ok) then
			print(inspect(...))
		end
	end,
}

local moduleFile = ""
local modulePath = ""

local function createLogFn (prefix)
	local prefix = prefix..": "
	local function fn(...)
		print(table.concat({prefix, ...}))
	end
	return fn
end

local logFn = createLogFn("eatglobal")

local function getPath ()
	local function debugPath ()
		local info = debug.getinfo(1, "S")
		local result = ""
		if (info ~= nil) then
			return string.gsub(string.gsub(info.source, '\\', '/'), '@', "")
		end
		return ""
	end
	moduleFile = debugPath ()
	modulePath = string.match(moduleFile, '(.*/).*lua')
end

getPath ()

logFn("init [", moduleFile, "] (Version ", eatglobal.version, ")")

local function doLoadFile (fileName)
	local f, err = loadfile(fileName)
	if (f ~= nil) then
		return f ()
	else
		return nil, err
	end
end
		
local utils = nil

local eatglobal_metatable = {
	__index = function(t, key)
		local fileName = modulePath.."eatglobal/"..key..".lua"
		local data, err = doLoadFile (fileName)
		if (data ~= nil) then
			t[key] = data
			t[key].eatglobal = eatglobal
			if __debug__ then
				if (utils ~= nil) and (key ~= "utils") then
					t[key].logFn = utils.createLogFn ("eatglobal."..key)
				end
				-- Ab Version 2.24 Ausgabe nur noch bei Debug.
				logFn("loaded module 'eatglobal.", key, "' [", fileName, "] (Version ", data.version or "0.0", ")")
			else
				t[key].logFn = function(...) end
			end
			return t[key]
		else
			logFn("can not load module 'eatglobal.",key, "'. Message: ", (err or ""))
			return nil		
		end
	end
}
setmetatable(eatglobal, eatglobal_metatable)

local eatglobal_intern = eatglobal.eatglobal_intern
utils = eatglobal.utils
if (__debug__) then
	utils.logFn = utils.createLogFn ("eatglobal.utils")
else
	utils.logFn = function(...) end
end

return eatglobal