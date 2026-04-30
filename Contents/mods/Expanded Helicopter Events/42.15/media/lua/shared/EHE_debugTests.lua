if isClient() and not getDebug() then return end

require("EHE_debugPanel.lua")
local util = require("EHE_util.lua")
local modData = require("EHE_globalModData.lua")
local clientCommands = require("EHE_onServerToClientCommands.lua")
local isoRangeScan = require("EHE_IsoRangeScan.lua")
local announcerCore = require("EHE_announcersCore.lua")
local presetCore = require("EHE_presetCore.lua")
local eHelicopter = require("EHE_mainVariables.lua")
local eHeliScheduler = require("EHE_eventScheduler.lua")

CustomDebugPanel = CustomDebugPanel or {}
CustomDebugPanel.TOGGLE_ALL_CRASH = false

CustomDebugPanel.colors = {
	DEFAULT = {r=0, g=0, b=0, a=1.0},
	DEFAULT_HIGHLIGHT = {r=0.3, g=0.3, b=0.3, a=1.0},
	RED = {r=0.5, g=0.0, b=0.0, a=0.9},
	GREEN = {r=0.0, g=0.5, b=0.0, a=0.9},
	RED_HIGHLIGHT = {r=0.75, g=0.0, b=0.0, a=0.9},
	GREEN_HIGHLIGHT = {r=0.0, g=0.75, b=0.0, a=0.9},
}

Events.OnGameBoot.Add(function()
	if not EHE_DebugTests then return end

	EHE_DebugTests["Toggle All Crash"] = CustomDebugPanel.ToggleAllCrash
	EHE_DebugTests["Test All Voice Lines"] = CustomDebugPanel.testAllLines
	EHE_DebugTests["Toggle Move HeliCloser"] = CustomDebugPanel.ToggleMoveHeliCloser
	EHE_DebugTests["Scheduler Unit Test [LAG]"] = CustomDebugPanel.eHeliEvents_SchedulerUnitTest
	EHE_DebugTests["ClearGlobalModData"] = CustomDebugPanel.ClearGlobalModData
	EHE_DebugTests["Copy Schedule to Clipboard"] = CustomDebugPanel.CopySchedule
	EHE_DebugTests.SandboxVarsDUMP = CustomDebugPanel.SandboxVarsDUMP
	EHE_DebugTests.TemporaryTest = CustomDebugPanel.TemporaryTest
	EHE_DebugTests.checkSquare = CustomDebugPanel.checkSquare
	EHE_DebugTests.printEHEIsoPlayers = CustomDebugPanel.printEHEIsoPlayers
	EHE_DebugTests["Show Done Events"] = CustomDebugPanel.ToggleShowDone

	EHE_DebugTests["Launch"] = {}
	for presetID, _ in pairs(presetCore.PRESETS) do
		EHE_DebugTests["Launch"][presetID] = function() CustomDebugPanel.launchHeliTest(presetID, getPlayer()) end
	end
end)


function CustomDebugPanel.TemporaryTest()
end


function CustomDebugPanel.printEHEIsoPlayers()
	print("util.isoPlayers: ")
	for playerObj, _ in pairs(util.isoPlayers) do
		print(" - "..playerObj:getFullName().." - "..playerObj:getUsername())
	end
end


function CustomDebugPanel.ClearGlobalModData()
	print(" - ClearGlobalModData:")
	local globalModData = modData.get()
	for k in pairs(globalModData) do globalModData[k] = nil end
	triggerEvent("EHE_ServerModDataReady", false)
end


function CustomDebugPanel.SandboxVarsDUMP()
	print(" - SandboxVars:")
	local optionsSize = getSandboxOptions():getNumOptions()
	for i = 1, optionsSize do
		local option = getSandboxOptions():getOptionByIndex(i-1)
		print(" --- "..tostring(option:getShortName()).." ("..tostring(option:getTableName())..")")
	end
end


function CustomDebugPanel.RTP_indent(n)
	local text = ""
	for i = 0, n do text = text.."   " end
	return text
end

function CustomDebugPanel.RecursiveTablePrint(object, nesting, every_other)
	nesting = nesting or 0
	local text = ""..CustomDebugPanel.RTP_indent(nesting)
	if type(object) == "table" then
		local s = "{ \n"
		for k, v in pairs(object) do
			local items_print = k == "items"
			if type(k) ~= "number" then k = '"'..k..'"' end
			if (not every_other) or (every_other and (not (k % 2 == 0))) then
				s = s..CustomDebugPanel.RTP_indent(nesting+1)
			end
			s = s.."["..k.."] = "..CustomDebugPanel.RecursiveTablePrint(v, nesting+1, items_print)..", "
			if (not every_other) or (every_other and (k % 2 == 0)) then s = s.."\n" end
		end
		text = s.."\n"..CustomDebugPanel.RTP_indent(nesting).."}"
	else
		text = tostring(object)
	end
	return text
end


function CustomDebugPanel.checkSquare()
	local player = getSpecificPlayer(0)
	local square = player:getSquare()
	if not square then print("square is null") return end
	print("square:isOutside() : ", square:isOutside())
	print("square:isSolidFloor() : ", square:isSolidFloor())
	print("square:getRoomID()==-1 : ", square:getRoomID()==-1)
	print("square:isSolid() : ", square:isSolid())
	print("square:isSolidTrans() : ", square:isSolidTrans())
	print("square:getZoneType() : ", square:getZoneType())

	local zonePrint = ""
	local zones = getWorld():getMetaGrid():getZonesAt(square:getX(), square:getY(), 0)
	if zones then
		for i = zones:size(), 1, -1 do
			local zone = zones:get(i-1)
			if zone then
				zonePrint = zonePrint..zone:getType().."("..zone:getOriginalName()..")"..", ".."(d:"..zone:getZombieDensity()..")"
			end
		end
	end
	print("ZONE SCAN: ", zonePrint)
end


function CustomDebugPanel.ZombRandTest(imax)
	local results = {}
	for i = 1, imax do
		local testRand = (ZombRand(13)+1)/10
		results[tostring(testRand)] = (results[tostring(testRand)] or 0) + 1
	end
	print("ZombRand:")
	local output = ""
	for k, v in pairs(results) do output = output..k.." ("..v.." times)\n" end
	print(output)
end


function CustomDebugPanel:CopySchedule()
	local finalText = "SCHEDULE:\n"
	local globalModData = clientCommands.get()
	if globalModData and globalModData.EventsOnSchedule and #globalModData.EventsOnSchedule > 0 then
		for i = 1, #globalModData.EventsOnSchedule do
			local event = globalModData.EventsOnSchedule[i]
			finalText = finalText.."["..i.."]"
			for k, v in pairs(event) do finalText = finalText.."  "..k..":"..tostring(v) end
			finalText = finalText.."\n"
		end
	end
	print(finalText)
	Clipboard.setClipboard(finalText)
end


function CustomDebugPanel:ToggleShowDone()
	if CustomDebugPanel.TOGGLE_SHOW_DONE == true then
		CustomDebugPanel.TOGGLE_SHOW_DONE = false
		self.backgroundColor = CustomDebugPanel.colors.DEFAULT
		self.backgroundColorMouseOver = CustomDebugPanel.colors.DEFAULT_HIGHLIGHT
	else
		CustomDebugPanel.TOGGLE_SHOW_DONE = true
		self.backgroundColor = CustomDebugPanel.colors.GREEN
		self.backgroundColorMouseOver = CustomDebugPanel.colors.GREEN_HIGHLIGHT
	end
	self.parent._dirty = true
end


function CustomDebugPanel:ToggleAllCrash()
	if CustomDebugPanel.TOGGLE_ALL_CRASH == true then
		CustomDebugPanel.TOGGLE_ALL_CRASH = false
		self.backgroundColor = CustomDebugPanel.colors.DEFAULT
		self.backgroundColorMouseOver = CustomDebugPanel.colors.DEFAULT_HIGHLIGHT
	else
		CustomDebugPanel.TOGGLE_ALL_CRASH = true
		self.backgroundColor = CustomDebugPanel.colors.GREEN
		self.backgroundColorMouseOver = CustomDebugPanel.colors.GREEN_HIGHLIGHT
	end
end


function CustomDebugPanel:ToggleMoveHeliCloser()
	if CustomDebugPanel.MOVE_HELI_TEST_CLOSER == true then
		CustomDebugPanel.MOVE_HELI_TEST_CLOSER = false
		self.backgroundColor = CustomDebugPanel.colors.DEFAULT
		self.backgroundColorMouseOver = CustomDebugPanel.colors.DEFAULT_HIGHLIGHT
	else
		CustomDebugPanel.MOVE_HELI_TEST_CLOSER = true
		self.backgroundColor = CustomDebugPanel.colors.GREEN
		self.backgroundColorMouseOver = CustomDebugPanel.colors.GREEN_HIGHLIGHT
	end
end


function CustomDebugPanel.launchHeliTest(presetID, player, moveCloser, crashIt)
	moveCloser = moveCloser or CustomDebugPanel.MOVE_HELI_TEST_CLOSER
	crashIt = crashIt or CustomDebugPanel.TOGGLE_ALL_CRASH
	sendClientCommand("CustomDebugPanel", "launchHeliTest", {presetID=presetID, moveCloser=moveCloser, crashIt=crashIt})
end


function CustomDebugPanel.CheckWeather()
	local CM = getClimateManager()
	print("--- CM:getWindIntensity: "..CM:getWindIntensity())
	print("--- CM:getFogIntensity: "..CM:getFogIntensity())
	print("--- CM:getRainIntensity: "..CM:getRainIntensity())
	print("--- CM:getSnowIntensity: "..CM:getSnowIntensity())
	print("--- CM:getIsThunderStorming:(b) "..tostring(CM:getIsThunderStorming()))
	local willFly, impactOnFlightSafety = util.weatherImpact()
	print("--- willFly: "..tostring(willFly).."   % to crash: "..impactOnFlightSafety*100)
end


function CustomDebugPanel.eHeliEvents_SchedulerUnitTest()
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
end


function CustomDebugPanel.getHumanoidsInFractalRange()
	local player = getSpecificPlayer(0)
	local fractalObjectsFound = isoRangeScan.getHumanoidsInFractalRange(player, 1, 2, "IsoZombie")
	print("-----[ getHumanoidsInFractalRange ]-----")
	for fractalIndex = 1, #fractalObjectsFound do
		print(" "..fractalIndex..":  hostile count:"..#fractalObjectsFound[fractalIndex])
	end
end


function CustomDebugPanel.getHumanoidsInRange()
	local player = getSpecificPlayer(0)
	local objectsFound = isoRangeScan.getHumanoidsInRange(player, 1, "IsoZombie")
	print("-----[ getHumanoidsInRange ]-----")
	print(" objectsFound: ".." count: "..#objectsFound)
	for i = 1, #objectsFound do
		print(" "..i..":  "..tostring(objectsFound[i]:getClass()))
	end
end


local testAllLines = {ALL_LINES={}, DELAYS={}, lastDemoTime=0}

function CustomDebugPanel.testAllLines()
	if #testAllLines.ALL_LINES > 0 then
		testAllLines.ALL_LINES = {}
		testAllLines.DELAYS = {}
		testAllLines.lastDemoTime = 0
		getPlayer():Say("Cancelling testAllLines")
		return
	end
	for _, voiceData in pairs(announcerCore.announcers) do
		for _, lineData in pairs(voiceData["Lines"]) do
			table.insert(testAllLines.ALL_LINES, lineData[2])
			table.insert(testAllLines.DELAYS, lineData[1])
		end
	end
	table.insert(testAllLines.ALL_LINES, "eHeli_machine_gun_fire_single")
	table.insert(testAllLines.DELAYS, 1)
end

function CustomDebugPanel.testAllLinesLOOP()
	if #testAllLines.ALL_LINES > 0 and testAllLines.lastDemoTime < getTimeInMillis() then
		local line = testAllLines.ALL_LINES[1]
		local delay = testAllLines.DELAYS[1]
		testAllLines.lastDemoTime = getTimeInMillis() + delay
		getWorld():getFreeEmitter():playSound(line)
		getPlayer():Say(line)
		table.remove(testAllLines.ALL_LINES, 1)
		table.remove(testAllLines.DELAYS, 1)
	end
end

Events.OnTick.Add(CustomDebugPanel.testAllLinesLOOP)
