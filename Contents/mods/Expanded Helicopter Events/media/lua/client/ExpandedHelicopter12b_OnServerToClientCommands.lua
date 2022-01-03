require "ExpandedHelicopter00c_SpawnerAPI"

--if isClient() then sendClientCommand(player, module, command, args) end -- to server
local function onCommand(_module, _command, _dataA, _dataB)
	--clientside
	if _module == "sendLooper" then
		print("--pong")
		if _command == "play" then
			print("--play")
			eventSoundHandler:playLooperEvent(_dataA.reusableID, _dataA.soundEffect, _dataA.command)

		elseif _command == "setPos" then
			print("--loop setPos")
			eventSoundHandler:playLooperEvent(_dataA.reusableID, {x=_dataA.x,y=_dataA.y,z=_dataA.z}, _dataA.command)

		elseif _command == "stop" then
			print("--loop stop")
			eventSoundHandler:playLooperEvent(_dataA.reusableID, _dataA.soundEffect, _dataA.command)

		elseif _command == "drop" then
			print("--loop drop")
			eventSoundHandler:playLooperEvent(_dataA.reusableID, nil, _dataA.command)
		end

	end
end
--Events.OnClientCommand.Add(onCommand)--/client/ to server
Events.OnServerCommand.Add(onCommand)--/server/ to client
