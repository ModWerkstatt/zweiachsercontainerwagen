--- Utils
-- @author Enno Sylvester
-- @copyright 2017, 2018, 2019, 2020
-- @module eatglobal.utils

local historie = [[
	Version 1.14:
	 - Added:	getFileExtension(fileName, includeDot)
	 - Added:	getFileNameAndExtension(fileName, includePath)
	 - Added:	getFileFolders(fileName)
]]

local verionsData = {
	majorVersion = 1,
	minorVersion = 14,
}

local utils = {
	historie = historie,
	version = string.format("%d.%d", verionsData.majorVersion, verionsData.minorVersion),
}

--[[
			##########################################
			environment-tools
			##########################################
]]

local function init()
	if (type(utils.env) ~= "table") then
		utils.env = {}
	end
	utils.env.isWinOS = (os.getenv("OS") == "Windows_NT")
end

init ()

local function concatTable( tbl, CR )
	local doCR = CR or false
	local stack = {}
	for i = 1, #tbl do
		stack[#stack + 1] = utils.toString(tbl[i])
		if (doCR) and (i < #tbl) then
			stack[#stack + 1] = "\n"
		end
	end
	return table.concat(stack)
end

--- log mit Präfix
function utils.createLogFn (prefix)
	local prefix = prefix..": "
	local logfn = function (...)
		print(concatTable({prefix, ...}, false))
	end
	return logfn
end

function utils.createLogFnCounter (prefix)
	local prefix = prefix..": "
	local counter = 1
	local logfn = function (...)
		print(concatTable({"["..counter.."] ", prefix, ...}, false))
		counter = counter + 1
	end
	return logfn
end

function utils.getModulFileName ( level )
	if (level == nil) then
		level = 1
	end
	local info = debug.getinfo(level, "S")
	if (info ~= nil) then
		return string.gsub(string.gsub(info.source, '\\', '/'), '@', "")
	else
		return ""
	end
end

function utils.getModPath ()
	local function debugPath ()
		local level = 1
		local info
		
		repeat
			info = debug.getinfo(level, "S")
			level = level + 1
		until (info == nil)
		if (level > 1) then
			return string.gsub(string.gsub(debug.getinfo(level - 2, 'S').source, '\\', '/'), '@', "")
		else
			return ""
		end
	end

	local result = debugPath ()
	local i = result:find("/res/")
	if i then
		return result:sub(1, i)
	else
		return result:match("(.*[/\\])")
	end
end

function utils.splitString(str, sep)
	local result = {}
	local regex = ("([^%s]+)"):format(sep)
	for each in str:gmatch(regex) do
		table.insert(result, each)
	end
	return result
end

function utils.getFileName(file)
	return file:match("^.+/(.+)$")
end

function utils.getFileExtension(fileName, includeDot)
	local str = fileName
	local temp = ""
	includeDot = (includeDot == nil) and true or includeDot
	local result = includeDot and "." or ""

	for i = str:len(), 1, -1 do
		if str:sub(i, i) ~= "." then
			temp = temp..str:sub(i, i)
		else
			break
		end
	end

	-- Reverse order of full file name
	for j = temp:len(), 1, -1 do
		result = result..temp:sub(j, j)
	end

	return result
end

function utils.getFileNameAndExtension(fileName, includePath)
	local ext = utils.getFileExtension(fileName, false)
	includePath = (includePath == nil) and true or includePath
	local fName = includePath and fileName or utils.getFileName(fileName)
	return fName:sub(1, fName:find(ext, 1, true) - 2), ext
end

function utils.getFileFolders(fileName)
	local result = {}
	local currentIndex = 1
	local currentFound = fileName:find("/", currentIndex, true)
	while currentFound do
		if (currentFound > currentIndex) then
			result[#result + 1] = fileName:sub(currentIndex, currentFound - 1)
		end
		currentIndex = currentFound + 1
		currentFound = fileName:find("/", currentIndex, true)
	end
	return result
end

--[[
			##########################################
			table-tools
			##########################################
]]

--- Kopiert eine Tabelle incl. der metatable
-- @param tbl
-- @return Kopie von tbl
-- Achtung: In Kopien von Proxytabellen kann nicht geschrieben oder gelöscht werden.
function utils.copyTable (tbl)
	local function doCopy (t)
		local result
		if (type(t) == 'table') then
			result = {}
			for key, value in next, t, nil do
				result[doCopy(key)] = doCopy(value)
			end
			setmetatable(result, doCopy(getmetatable(t)))
		else -- number, string, boolean, etc
			result = t
		end
		return result
	end
	return doCopy(tbl)
end

--- Create a ordered table
-- @return {table} a table with ordered key value iteration
-- @author Oskar Eisemuth
-- @copyright 2017
 function utils.createOrderedTable()
	local t = {}
	local mt = {
		__index = {
			_keyorder = {},
			_delete = function(self, key)
				if self[key] == nil then
					return
				end
				self[key] = nil
				local keyorder = self._keyorder
				for i, k in ipairs(keyorder) do
					if k == key then
						table.remove(keyorder, i)
					end
				end
			end
		},
		__newindex = function(self, key, value)
			rawset(self, key, value)
			local keyorder = self._keyorder
			keyorder[#keyorder+1] = key
		end,
		__pairs = function(tbl)
			local i = 0
			local function pairs_iter(self)
				i = i + 1
				local key = self._keyorder[i]
				if (key) then
					return key, self[key]
				end
				return
			end
			return pairs_iter, tbl, nil
		end
	}
	setmetatable(t, mt)
	return t
end

--- Erzeugt eine Proxy-Tabelle.
--	Alle Zugriffe werden direkt auf den 'master' umgeleitet
-- @utils.proxyTable
-- @param master
-- @return proxy
function utils.proxyTable(master)
  local metatable = {
    __index = master,
    __newindex = master,
		
		__len = function (tbl)
			return #master
		end,
		
		__pairs = function (tbl)
      local function iterFn(tbl, k)
        local v
        -- Implement your own key,value selection logic in place of next
        k, v = next(master, k)
        if v then
          return k,v
        end
      end    
      -- Return an iterator function, the table, starting point
      return iterFn, tbl, nil
    end,
    
		__ipairs = function (tbl)
			-- Iterator function
			local function iterFn(tbl, i)
				-- Implement your own index, value selection logic
				i = i + 1
				local v = master[i]
				if v then
					return i, v
				end
			end
			-- return iterator function, table, and starting point
			return iterFn, tbl, 0
    end,
  }
  local proxy = {}
  setmetatable(proxy, metatable)
  return proxy
end

local function buildFilterFn(filterFn)
	local function noFilterFn(tbl, key, value)
		return true
	end
	local function filterTableFn(tbl, key, value)
		for i = 1, #filterFn do
			if not filterFn[i](tbl, key, value) then
				return false
			end
		end
		return true
	end
	if (type(filterFn) == "function") then
		return filterFn
	elseif (type(filterFn) == "table") then
		return filterTableFn
	else
		return noFilterFn
	end
end
--- Äquivalent zu pairs (ab Version 1.10)
--	Iteriert über eine Tabelle, wobei nur Einträge berücksichtigt werden, welche
--		filterFn mit "true" passiert haben
-- Nutzung:
-- for key, value in filterPairs (tbl, filterFn) do
-- end
--	Beispiel filterFn:
--	local function filterFn(tbl, key, value)
--		return (value ~= "1000") and value ~= "760"
--	end
function utils.filterPairs ( tbl, filterFn )
	-- collect the keys
	local keys = {}
	for k in pairs(tbl) do
		keys[#keys + 1] = k
	end

	local doFilter = buildFilterFn(filterFn)
	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		while keys[i] and (not doFilter(tbl, keys[i], tbl[keys[i]])) do
			i = i + 1
		end
		
		if keys[i] then
			return keys[i], tbl[keys[i]]
		end
	end
end

--- Äquivalent zu pairs
-- Iteriert über eine Tabelle, wobei die Keys in sortierter Reihenfolge aufgerufen werden.
-- Nutzung:
-- for key, value in sortPairs (tbl) do
-- end
-- ab Version 1.10 mit filterFn
function utils.sortPairs ( tbl, orderFn, filterFn )
	local function noFilter(tbl, key, value)
		return true
	end
	-- collect the keys
	local keys = {}
	for k in pairs(tbl) do
		keys[#keys + 1] = k
	end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if orderFn then
		table.sort(keys, function(a,b) return orderFn(tbl, a, b) end)
	else
		table.sort(keys)
	end

	local doFilter = buildFilterFn(filterFn)
	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		while keys[i] and (not doFilter(tbl, keys[i], tbl[keys[i]])) do
			i = i + 1
		end
		
		if keys[i] then
			return keys[i], tbl[keys[i]]
		end
	end
end

function utils.ipairs(tbl)
	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if tbl[i] then
			return tbl[i]
		end
	end
end
--- Gibt eine sortierte Kopie von tbl zurück
--	
-- @utils.sortTable
-- @param tbl
-- @param orderFn
-- @return die sortierte Tabelle, oder das Original, wenn orderFn == nil
function utils.sortTable ( tbl, orderFn )
	if (type(orderFn) == "function") then
		local temp = {}
		for k in utils.sortPairs(tbl, orderFn) do
			temp[k] = tbl[k]
		end
		return temp
	else
		return tbl
	end
end

--- Ergänzt Tabelle "tbl" mit Werten aus Tabelle "source"
--
-- @utils.fillTable
-- @param tbl
-- @param source
-- @return die ergänzte Tabelle, oder das Original, wenn source keine Tabelle
function utils.fillTable (tbl, source)
	local function merge(a, b)
		if (type(a) == 'table') and (type(b) == 'table') then
			for k,v in pairs(b) do
				if (type(v) == 'table') and (type(a[k] or false) == 'table') then
					merge(a[k],v)
				else
					a[k] = v
				end
			end
		end
		return a
	end
	
	if (type(source) == 'table') then
		return merge(tbl, source)
	else
		return tbl
	end
end

function utils.indexOf(tbl, element)
	if (type(tbl) == 'table') and (type(element) ~= nil) then
		for i = 1, #tbl do
			if (tbl[i] == element) then
				return i
			end
		end
	end
	return 0
end

function utils.isEmptyTable(tbl)
	for k in pairs(tbl) do
		return false
	end
	
	return true
end
--[[
			##########################################
			Filetools
			##########################################
]]

--- prüft, ob eine Datei vorhanden ist
-- @utils.fileExists
-- @param fileName
-- @return true, wenn vorhanden
function utils.fileExists (fileName)
	local file = io.open(fileName, "r")
	if file then
		file:close()
		return true
	end
	return false
end

--- Daten aus Datei einlesen
-- @utils.readData
-- @param fileName
-- @return Tabelle mit eingelesene Datan oder eine leere Tabelle
local function _readFileToEnv( fileName, env)
	if (env ~= nil) then
		setmetatable(env, {__index = _G})
		file, err = loadfile(fileName, "tb", env)
		if (file~= nil) then
			file()
			return true
		else
			utils.logFn("utils.readData - File '", fileName, "' Error: ", err)
			return false, err
		end
	end
	
	return false, ""
end

--- Daten aus Datei einlesen
-- @utils.readData
-- @param fileName
-- @param dataFormat: "TEXT", "BLANK", "FUNC_DATA", "RETURN"
function utils.readData (fileName, dataFormat)
	dataFormat = dataFormat or "STRUCT"
	
	if (dataFormat == "FUNC_DATA") then
		local env = {
			data = function()
				return {}
			end
		}
		local result, err = _readFileToEnv(fileName, env)
		if result then
			if (env.data ~= nil) then
				return env.data()
			else
				utils.logFn("utils.readData - File '", fileName, "' contains no function 'data()'.")
				return {}
			end
		else
			return {}, err
		end
	elseif (dataFormat == "TEXT") then
		local file = io.open(fileName, "r")
		if file then
			local s = file:read("*a")
			file:close()
			return s
		else
			return nil, "Unable to open ["..fileName.."]."
		end
	else
		local file, err = loadfile(fileName)
		if (file ~= nil) then
			local result = file()
			if (type(result) ~= "table") then
				result = {}
				utils.logFn("utils.readData - File '", fileName, "' is not a valid datafile. Maybe he's corrupt?!")
			end
			return result
		else
			if utils.fileExists(fileName) then
				utils.logFn("utils.readData - File '", fileName, "' Error: ", err)
			end
			return {}, err
		end
	end
	
	
	--[[
	if (file ~= nil) then
		local result = file()
		if (type(result) ~= "table") then
			result = {}
			utils.logFn("utils.readData - File '", fileName, "' is not a valid datafile. Maybe he's corrupt?!")
		end
		return result
	else
		if utils.fileExists(fileName) then
			utils.logFn("utils.readData - File '", fileName, "' Error: ", err)
		end
		return {}, err
	end
	]]
end

--- Liest Datenstruktur aus fileName.
--	Ist die Datei vorhanden, aber enthält keine Datenstruktur,
--	so wird die Datei geleert und mit einer leeren Datenstruktur gefüllt.
-- @utils.readDataEx
-- @param fileName
-- @return Tabelle mit eingelesene Datan oder eine leere Tabelle
function utils.readDataEx(fileName)
	local file, err = loadfile(fileName)
	if (file ~= nil) then
		local result = file()
		if (type(result) ~= "table") then
			utils.saveData({}, fileName)
			utils.logFn("utils.readDataEx - File '", fileName, "' is not a valid datafile. Maybe he's corrupt?!")
			return {}
		else
			return result
		end
	else
		if utils.fileExists(fileName) then
			utils.logFn("utils.readDataEx - File '", fileName, "' Error: ", err)
			utils.saveData({}, fileName)
		end
		return {}, err
	end
end

--- Daten in Datei schreiben
-- @utils.saveData
-- @param data
-- @param fileName
-- @param dataFormat: "TEXT", "BLANK", "FUNC_DATA", "RETURN"
-- @param append - boolean (nur bei dataFormat == "TEXT")
function utils.saveData (data, fileName, dataFormat, append)
	local file
	local s
	local dataFormat = dataFormat or "RETURN"
	if (dataFormat == "TEXT") then
		local fileMode = (append == true) and "a" or "w"
		file = io.open(fileName, fileMode)
	else
		file = io.open(fileName, "w")
	end

	if file then
		if (dataFormat == "BLANC") then
			s = utils.eatglobal.serialize.serializeBlanc(data)
		elseif (dataFormat == "FUNC_DATA") then
			s = utils.eatglobal.serialize.serializeDatafmt(data)
		elseif (dataFormat == "TEXT") then
			s = data
		else
			s = utils.eatglobal.serialize.serializeReturnfmt(data)
		end
		
		file:write(s)
		file:close()
	end
end

function utils.deleteFile(fileName)
	local function quote( var )
		return '"'..string.gsub(var, '/', '\\')..'"'
	end
		
	if utils.fileExists (fileName) then
		local cmd = nil
		if utils.env.isWinOS then
			cmd = '"del '..quote(fileName)..'" '
		else
			cmd = '"rm '..quote("./"..fileName)..'" '
		end
		p = io.popen(cmd)
		if p then
			p:close()
		end
	end
end

function utils.getSubDirs(dir)
	local result = {}
	local f = io.popen(string.format([[dir "%s" /b /ad]], dir))
	if f then
		for s in f:lines() do
			if (string.len(s) > 0) then
				result[#result + 1] = string.format([[%s%s/]], dir, s)
			end
		end
		f:close()
	end
	
	return result
end

function utils.getFiles(dir, filterFn)
	filterFn = filterFn or function(fileName) return true end
	local result = {}
	local f = io.popen(string.format([[dir "%s" /b /a-d]], dir))
	if f then
		for s in f:lines() do
			if ((string.len(s) > 0) and filterFn(s))then
				result[#result + 1] = string.format([[%s%s]], dir, s)
			end
		end
		f:close()
	end
	
	return result
end

function utils.listFiles(baseDir, includeSubDirs, whiteList, blackList)
	includeSubDirs = (type(includeSubDirs) == "boolean") and includeSubDirs or true
	whiteList = whiteList or {}
	blackList = blackList or {}
	local function filterFn(fileName)
		local result = false
		if (#whiteList > 0) then
			for i = 1, #whiteList do
				if (string.ends(fileName, whiteList[i])) then
					result = true
					break
				end
			end
		else
			result = true
		end
		if (result and (#blackList > 0)) then
			for i = 1, #blackList do
				if (string.ends(fileName, blackList[i])) then
					result = false
					break
				end
			end
		end
		
		return result
	end
	local lenBaseDir = string.len(baseDir)
	local function doIt(subDir)
		local result = {}
		if includeSubDirs then
			local subDirs = utils.getSubDirs(subDir)
			
			for i = 1, #subDirs do
				local models = doIt(subDirs[i])
				for j = 1, #models do
					result[#result + 1] = models[j]
				end
			end
		end
		
		local files = utils.getFiles(subDir, filterFn)
		for i = 1, #files do
			result[#result + 1] = string.sub(files[i], lenBaseDir + 1, string.len(files[i]))
		end
		
		return result
	end
	
	return doIt(baseDir)
end

--[[
			##########################################
			math-tools
			##########################################
]]

function utils.getIndex(data, params, compareFn)
	for i = 1, #data do
		if compareFn (data[i], params) then
			return i
		end
	end
	return 0
end

function utils.getArrayIndex (array, params, compareFn)
	for index, value in ipairs(array) do
		if compareFn (value, params) then
			return index
		end
	end
	return 0
end

function utils.toString (var)
	if type(var) == "nil" then
		return "nil"
	elseif type(var) == "boolean" then
		return tostring(var)
	elseif type(var) == "number" then
		return tostring(var)
	elseif type(var) == "string" then
		return var
	elseif type(var) == "table" then
		return utils.eatglobal.serialize.serializeBlanc(var)
	else
		return ""
	end
end

function utils.round (var)
	return math.floor (var + 0.5)
end

--[[
			##########################################
			string-tools
			##########################################
]]

function utils.isValidString(s)
	return ((type(s) == "string") and (s ~= ""))
end
--[[
			##########################################
			misc-tools
			##########################################
]]

function utils.concatParams (...)
	return concatTable( {...}, false)
end

function utils.concatParamsCr (...)
	return concatTable( {...}, true)
end

function utils.pRequire(modulName)
	local state, result_or_error = pcall(require, modulName)
	if state then
		return result_or_error
	else
		return nil, result_or_error
	end
end

function utils.getOrder(userId, modId, modOrder)
	return (userId * 10000) + (modId * 100) + modOrder
end

function utils.getValue(value, default)
	if (type(value) == type(default)) then
		return value
	else
		return default
	end
end

function utils.dateTimeString()
	return os.date("%d.%m.%Y %X", os.time())
end

return utils