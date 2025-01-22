require "ExpandedHelicopter00a_Util"

local twitchKeys = {["KP_1"]="Numpad1",["KP_2"]="Numpad2",["KP_3"]="Numpad3",
			  ["KP_4"]="Numpad4",["KP_5"]="Numpad5",["KP_6"]="Numpad6",
			  ["KP_7"]="Numpad7",["KP_8"]="Numpad8",["KP_9"]="Numpad9",}

function twitchIntegration_OnKeyPressed(key)

	if isClient() then
		if (not isAdmin() and not isCoopHost() and not getDebug()) then
			return
		end
	end

	local twitchKey = twitchKeys[Keyboard.getKeyName(key)]
	if twitchKey then

		local players = getActualPlayers()
		---@type IsoGameCharacter|IsoPlayer|IsoMovingObject|IsoObject
		local playerChar = players[ZombRand(#players)+1]

		if eHelicopterSandbox.config.twitchStreamerTargeted == true then playerChar = getPlayer() end
		if playerChar then
			local presetConfigNum = eHelicopterSandbox.config[twitchKey]
			print("-- scheduleEvent: twitchKey: "..tostring(twitchKey))
			local pUsername = playerChar:getUsername()
			sendClientCommand("twitchIntegration", "scheduleEvent", {twitchKey=twitchKey,presetConfigNum=presetConfigNum,twitchTarget=pUsername})
		end
	end
end

Events.OnKeyPressed.Add(twitchIntegration_OnKeyPressed)