LuaEventManager.AddEvent("EHE_ServerModDataReady")

local function onServerModDataReady(isNewGame) sendServerCommand("EHE_ServerModData", "severModData_received", {}) end
Events.EHE_ServerModDataReady.Add(onServerModDataReady)

require "EHE_spawner"
require "EHE_shadowSystem"
local eheFlareSystem = require "EHE_flares"
local heatMap = require "EHE_heatMap"
local mainCore = require "EHE_mainCore"

--sendClientCommand(player, module, command, args) end -- to server
local function onClientCommand(_module, _command, _player, _data)
	--serverside

	if _module == "CustomDebugPanel" then
		if _command == "launchHeliTest" then
			---@type eHelicopter heli
			local heli = mainCore.getFreeHelicopter(_data.presetID)
			print("- EHE: DEBUG: launchHeliTest: "..tostring(_data.presetID))
			heli:launch(_player)
			if _data.moveCloser == true then
				if not heli or not heli.target then return end
				--move closer
				local tpX = heli.target:getX()
				local tpY = heli.target:getY()

				local offsetX = ZombRand(150, 300)
				if ZombRand(101) <= 50 then offsetX = 0-offsetX end

				local offsetY = ZombRand(150, 300)
				if ZombRand(101) <= 50 then offsetY = 0-offsetY end
				heli.currentPosition:set(tpX+offsetX, tpY+offsetY, heli.height)
			end

			if _data.crashIt == true then
				heli.crashing = true
				heli:crash()
			end
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
