require "EHE_util"
local config = require "EHE_SI_config"

local keyPress = {}

local EHE_SI_Keys = {
	["KP_1"]="Numpad1",["KP_2"]="Numpad2",["KP_3"]="Numpad3",
	["KP_4"]="Numpad4",["KP_5"]="Numpad5",["KP_6"]="Numpad6",
	["KP_7"]="Numpad7",["KP_8"]="Numpad8",["KP_9"]="Numpad9",}

function keyPress.OnKeyPressed(key)

	if isClient() then if (not isAdmin() and not isCoopHost() and not getDebug()) then return end end

	local EHE_SI_Key = EHE_SI_Keys[getKeyName(key)]
	if EHE_SI_Key then
		local players = getActualPlayers()
		---@type IsoGameCharacter|IsoPlayer|IsoMovingObject|IsoObject
		local playerChar = players[ZombRand(#players)+1]

		if (config and config.checkValue("EHE_SI_KeyPresserTargeted") or true) == true then
			playerChar = getPlayer()
		end

		if playerChar then
			print("EHE_SI_Key: ", EHE_SI_Key)
			local presetID = config.checkValue("EHE_SI_"..EHE_SI_Key)
			print("presetID: ", presetID)
			if not presetID or presetID == "NONE" then return end
			local pUsername = playerChar:getUsername()
			sendClientCommand("EHE_SI_Integration", "scheduleEvent",
					{EHE_SI_Key=EHE_SI_Key,presetID=presetID,EHE_SI_Target=pUsername})
		end
	end
end

return keyPress