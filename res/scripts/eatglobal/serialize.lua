--- Serialize
-- @author UG, Enno Sylvester (Anpassung von UG-Code)
-- @copyright 2017, 2019
-- @module eatglobal.serialize

local serialize = {
	version = "1.5",
}

local function doSerialize(object)
	local stack = {}
	local function writeFn(...)
		stack[#stack + 1] = table.concat({...})
	end
	
	local function _serialize(o, prefix)
		local function writeKey(k)
			if type(k) == "string" and string.find(k, "^[_%a][_%w]*$") then
				writeFn(k, " = ")
			else
				writeFn("[")
				_serialize(k, "")
				writeFn("] = ")
			end
		end
		
		if type(o) == "nil" then
			writeFn("nil")
		elseif type(o) == "boolean" then
			writeFn(o and "true" or "false")
		elseif type(o) == "number" then
			writeFn(o)
		elseif type(o) == "string" then
			writeFn(string.format("%q", o))
		elseif type(o) == "table" then
			local metatag = o["__metatag__"]
			if metatag then
				if metatag == 0 then
					writeFn("_(")
					_serialize(o.val, prefix)
					writeFn(")")
				else
					error("invalid metatag: " .. metatag)
				end
				return
			end
			
			
			local oneLine = true
			local listKeys = {}
			local tableKeys = {}
			for k,v in ipairs(o) do
				listKeys[k] = true
			end
			for k,v in pairs(o) do
				if type(v) == "table" then oneLine = false end
				if not listKeys[k] then
					table.insert(tableKeys, k)
					oneLine = false
				end
			end
			table.sort(tableKeys)
			
			if oneLine then
				writeFn("{ ")
				for k,v in ipairs(o) do
					_serialize(v, "")
					writeFn(", ")
				end
				for i,k in ipairs(tableKeys) do
					local v = o[k]
					writeKey(k)
					_serialize(v, "")
					writeFn(", ")	
				end
				writeFn("}")
			else
				local prefix2 = prefix .. "\t"
				writeFn("{\n")
				for k,v in ipairs(o) do
					writeFn(prefix2)
					_serialize(v, prefix2)
					writeFn(",\n")
				end
				for i,k in ipairs(tableKeys) do
					local v = o[k]
					writeFn(prefix2)
					writeKey(k)
					_serialize(v, prefix2)
					writeFn(",\n")	
				end
				writeFn(prefix, "}")
			end
		elseif type(o) == "userdata" then
			local mt = getmetatable(o)
			local members = mt.__members
			if mt and mt.pairs then
				local prefix2 = prefix .. "\t"
				writeFn("{\n")
				for k,v in pairs(o) do
					writeFn(prefix2)
					writeKey(k)
					_serialize(v, prefix2)
					writeFn(",\n")
				end
				writeFn(prefix, "}")
			elseif mt and members then
				local prefix2 = prefix .. "\t"
				writeFn("{\n")
				for i = 1, #members do
					local k = members[i]
					local v = o[k]
					writeFn(prefix2)
					writeKey(k)
					_serialize(v, prefix2)
					writeFn(",\n")	
				end
				writeFn(prefix, "}")
			else
				writeFn(tostring(o))
			end
		elseif type(o) == "function" then
			writeFn("function(...)")
		else
			writeFn('"', type(o), '"')
		end
	end
	
	_serialize(object, "")
	return table.concat(stack)
end

--- Serialisiert 'object' und gibt die "reinen" Daten zurück
--	Format:	{
--						value1, value2, etc.
--					}
-- @serialize.serializeBlanc
-- @param object
-- @return String
function serialize.serializeBlanc(object)
	return doSerialize(object)
end

--- Serialisiert 'object' und gibt Data-Format zurück
--	Format:	function data()
--						return {
--							value1, value2, etc.
--						}
--					end
-- @serialize.serializeDatafmt
-- @param object
-- @return String
function serialize.serializeDatafmt(object)
	return "function data()\nreturn "..doSerialize(object).."\nend\n"
end

--- Serialisiert 'object' und gibt Return-Format zurück
--	Format:	return {
--						value1, value2, etc.
--					}
-- @serialize.serializeReturnfmt
-- @param object
-- @return String
function serialize.serializeReturnfmt(object)
	return "return "..doSerialize(object).."\n"
end

--- Serialisiert 'object' und gibt Table-Format zurück
--	Format:	local nameOfTable or "table" =
--						{
--							value1, value2, etc.
--						}
-- @serialize.serializeTablefmt
-- @param object
-- @param nameOfTable
-- @return String
function serialize.serializeTablefmt(object, nameOfTable)
	return "local "..(nameOfTable or "table").." = "..doSerialize(object).."\n"
end

--- Serialisiert 'object' und gibt Table/Return-Format zurück
--	Format:	local nameOfTable or "table" =
--						{
--							value1, value2, etc.
--						}
--
--						return nameOfTable or "table"
-- @serialize.serializeTablefmt_Returnfmt
-- @param object
-- @param nameOfTable
-- @return String
function serialize.serializeTablefmt_Returnfmt(object, nameOfTable)
	return "local "..(nameOfTable or "table").." = "..doSerialize(object).."\n\nreturn "..(nameOfTable or "table")
end

return serialize