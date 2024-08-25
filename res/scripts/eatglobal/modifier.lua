--- Modifier
-- @author Enno Sylvester
-- @copyright 2017
-- @module eatglobal.modifier

local modifier = {
	version = "1.2",
}

local function init ()
	if type(game) == "table" then
		if type(game.eat1963) ~= "table" then
			game.eat1963 = {}
		end
		if type(game.eat1963.modifier) ~= "table" then
			game.eat1963.modifier = {}
		end
		if type(game.eat1963.modifier.modifiers) ~= "table" then
			game.eat1963.modifier.modifiers = {}
		end
		return true
	else
		return false
	end
end

--- addModifier
-- @param modifierId, Id des Modifiers. So können mehrere, unterschiedliche Modifier angelegt werden (für unterschiedliche Mods z.B.).
-- @param callerId, Id, des Aufrufers.
-- @param sequensList, Sortierbare (Keys) Liste welche Reihenfolge festlegt ["1"] = "callerId 1", ["2"] = "callerId 2"
-- @param runFn, fn (fileName, data), welche letztlich aufgerufen wird.
-- @return, fnfn (fileName, data), welche aufgerufen werden muss, ohne Angaben der Id's
function modifier.addModifier ( modifierId, callerId, sequensList, key, runFn )
	--local logFn = modifier.eatglobal.utils.createLogFn ("eatglobal.modifier")
	if init () then
		local m = game.eat1963.modifier
		local modifierId = modifierId
		local callerId = callerId
		local function resultFn (fileName, data)
			local function getTopCallerId ()
				local result = ""
				for key, value in modifier.eatglobal.utils.sortPairs (m[modifierId].sequensList) do
					if (value ~= nil) and (m[modifierId].modifiers[value] ~= nil) then
						result = value
					end
				end
				--logFn ("topCallerId", result)
				return result
			end

			--logFn ("try running | fileName = "..fileName.."; modifierId = "..modifierId..", callerId = "..callerId)
			if (callerId == getTopCallerId ()) then
				for key, value in modifier.eatglobal.utils.sortPairs (m[modifierId].sequensList) do
					local daten = m[modifierId].modifiers[value] or nil
					if daten then
						--logFn ("running "..value.." | fileName", fileName)
						data = daten.runFn (fileName, data)
					end
				end
			end

			return data
		end
		
		local function isInSequencList ( var )
			for key, value in pairs (m[modifierId].sequensList) do
				if (value == var) then
					return true
				end
			end
			return false
		end
			
		if (m[modifierId] == nil) then
			m[modifierId] = {
				modifiers = {},
				sequensList = {},
			}
		end
		if (m[modifierId].modifiers[callerId] == nil) then
			m[modifierId].modifiers[callerId] = {
				runFn = runFn,
			}
			if not isInSequencList (callerId) then
				m[modifierId].sequensList = sequensList
			end
		end

		addModifier(key, resultFn)
		return true
	else
		return false
	end
end

return modifier