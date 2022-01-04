require "ExpandedHelicopter00c_SpawnerAPI"
require "ExpandedHelicopter01f_ShadowSystem"
require "ExpandedHelicopter01b_MainSounds"

--if isClient() then sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	if _module == "sendLooper" then
		--print("--pong")
		if _command == "play" then
			--print("--play")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID,
					{soundEffect=_dataA.soundEffect, x=_dataA.coords.x, y=_dataA.coords.y, z=_dataA.coords.z}, _dataA.command)

		elseif _command == "setPos" then
			--print("--loop setPos")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, {x=_dataA.coords.x, y=_dataA.coords.y, z=_dataA.coords.z}, _dataA.command)

		elseif _command == "stop" then
			--print("--loop stop")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, _dataA.soundEffect, _dataA.command)

		elseif _command == "drop" then
			--print("--loop drop")
			eventSoundHandler:handleLooperEvent(_dataA.reusableID, nil, _dataA.command)
		end

	elseif _module == "eventShadowHandler" and _command == "setShadowPos" then
		--sendServerCommand("eventShadowHandler", "setShadowPos", _dataB)
		eventShadowHandler:setShadowPos(_dataB.ID, _dataB.texture, _dataB.x, _dataB.y, _dataB.z, true)
	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client
