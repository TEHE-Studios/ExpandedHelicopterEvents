if not getDebug() then return end

require("EHE_debugPanel.lua")
local presetCore = require("EHE_presetCore.lua")

Events.OnGameBoot.Add(function()
	if not EHE_DebugTests or not EHE_DebugTestWindow then return end

	EHE_DebugTests["Toggle All Crash"] = EHE_DebugTestWindow.ToggleAllCrash
	EHE_DebugTests["Test All Voice Lines"] = EHE_DebugTestWindow.testAllLines
	EHE_DebugTests["Toggle Move HeliCloser"] = EHE_DebugTestWindow.ToggleMoveHeliCloser
	EHE_DebugTests["Scheduler Unit Test [LAG]"] = EHE_DebugTestWindow.eHeliEvents_SchedulerUnitTest
	EHE_DebugTests["ClearGlobalModData"] = EHE_DebugTestWindow.ClearGlobalModData
	EHE_DebugTests["Copy Schedule to Clipboard"] = EHE_DebugTestWindow.CopySchedule
	EHE_DebugTests.SandboxVarsDUMP = EHE_DebugTestWindow.SandboxVarsDUMP
	EHE_DebugTests.TemporaryTest = EHE_DebugTestWindow.TemporaryTest
	EHE_DebugTests.checkSquare = EHE_DebugTestWindow.checkSquare
	EHE_DebugTests.printEHEIsoPlayers = EHE_DebugTestWindow.printEHEIsoPlayers
	EHE_DebugTests["Show Done Events"] = EHE_DebugTestWindow.ToggleShowDone

	EHE_DebugTests["Launch"] = {}
	for presetID, _ in pairs(presetCore.PRESETS) do
		EHE_DebugTests["Launch"][presetID] = function() EHE_DebugTestWindow.launchHeliTest(presetID, getPlayer()) end
	end
end)


local function onClientCommand(_module, _command, _player, _data)
	if _module ~= "CustomDebugPanel" then return end

	if _command == "clearGlobalModData" then
		local modData = require("EHE_globalModData.lua")
		print(" - ClearGlobalModData:")
		local globalModData = modData.get()
		for k in pairs(globalModData) do globalModData[k] = nil end
		triggerEvent("EHE_ServerModDataReady", false)

	elseif _command == "schedulerUnitTest" then
		local modData = require("EHE_globalModData.lua")
		local eHeliScheduler = require("EHE_eventScheduler.lua")
		local globalModData = modData.get()
		local savedEvents = globalModData.EventsOnSchedule
		local savedLastDay = globalModData.lastDayScheduled

		globalModData.EventsOnSchedule = {}
		globalModData.lastDayScheduled = nil

		for freq = 2, 6 do
			local testsRan = {}
			globalModData.EventsOnSchedule = {}
			for day = 0, 89 do
				for hour = 0, 23 do
					eHeliScheduler.ScheduleNew(day, hour, freq, true)
					for k, v in pairs(globalModData.EventsOnSchedule) do
						if v.triggered then
							globalModData.EventsOnSchedule[k] = nil
						elseif (v.startDay <= day) and (v.startTime == hour) then
							testsRan[v.preset] = (testsRan[v.preset] or 0) + 1
							globalModData.EventsOnSchedule[k].triggered = true
						end
					end
				end
			end
			print("======================================")
			print("HeliEvents_SchedulerUnitTest: FREQ: "..getText("Sandbox_ExpandedHeli_Frequency_option"..freq))
			print("--------------------------------------")
			local totalTimes = 0
			for preset, times in pairs(testsRan) do
				totalTimes = totalTimes + times
				print("-preset:"..preset.."  x"..times)
			end
			print("--- TOTAL EVENTS: "..totalTimes)
			print("======================================")
		end

		globalModData.EventsOnSchedule = savedEvents
		globalModData.lastDayScheduled = savedLastDay

	elseif _command == "getAnnouncerLines" then
		local announcerCore = require("EHE_announcersCore.lua")
		local lines = {}
		local delays = {}
		for _, voiceData in pairs(announcerCore.announcers) do
			for _, lineData in pairs(voiceData["Lines"]) do
				table.insert(lines, lineData[2])
				table.insert(delays, lineData[1])
			end
		end
		table.insert(lines, "eHeli_machine_gun_fire_single")
		table.insert(delays, 1)
		sendServerCommand(_player, "CustomDebugPanel", "announcerLines", {lines=lines, delays=delays})
	end
end
Events.OnClientCommand.Add(onClientCommand)
