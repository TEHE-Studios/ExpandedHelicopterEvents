LuaEventManager.AddEvent("EHE_ServerModDataReady")

local function onServerModDataReady(isNewGame) sendServerCommand("EHE_ServerModData", "severModData_received", {}) end
Events.EHE_ServerModDataReady.Add(onServerModDataReady)

require "EHE_spawner"
require "EHE_shadowSystem"
local eheFlareSystem = require "EHE_flares"
local heatMap = require "EHE_heatMap"

--sendClientCommand(player, module, command, args) end -- to server
local function onClientCommand(_module, _command, _player, _data)
	--serverside

	if _module == "CustomDebugPanel" then
		if _command == "launchHeliTest" then
			CustomDebugPanel.launchHeliTest(_data.presetID, _player, _data.moveCloser, _data.crashIt)
		end
	end

	if _module == "heatMapEHE" then
		heatMap.registerEventByObject(_player, _data.intensity, "EventSpottedPlayer")
	end
	
	if _module == "flare" then
		if _command == "activate" then
			eheFlareSystem.activateFlare(_data.flare, _data.duration, _data.loc)

		elseif _command == "validate" then
			eheFlareSystem.validateFlare(_data.flare, _data.timestamp, _data.loc)
		end
	end

	if _module == "SpawnerAPI" and _command == "spawn" then
		EHE_spawner.attemptToSpawn(_data.x, _data.y, _data.z, _data.funcType, _data.spawnThis, _data.extraFunctions, _data.extraParam, _data.processSquare)
	end
end
Events.OnClientCommand.Add(onClientCommand)--/client/ to server
