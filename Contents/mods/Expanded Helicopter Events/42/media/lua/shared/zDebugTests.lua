if isClient() and not getDebug() then return end

require "zDebugPanel"
require "ExpandedHelicopter00f_WeatherImpact"
require "ExpandedHelicopter00a_Util"
require "ExpandedHelicopter00b_IsoRangeScan"
require "ExpandedHelicopter01a_MainVariables"

Events.OnGameBoot.Add(function()
	if EHE_DebugTests then
		EHE_DebugTests["Check Schedule"] = CustomDebugPanel.eHeliEventsOnSchedule
		EHE_DebugTests["Test All Voice Lines"] = CustomDebugPanel.testAllLines
		EHE_DebugTests["Raise The Dead"] = CustomDebugPanel.raiseTheDead
		EHE_DebugTests["Toggle All Crash"] = CustomDebugPanel.ToggleAllCrash
		EHE_DebugTests["Toggle Move HeliCloser"] = CustomDebugPanel.ToggleMoveHeliCloser
		for presetID,presetVars in pairs(eHelicopter_PRESETS) do
			EHE_DebugTests["Launch: "..presetID] = (function() CustomDebugPanel.launchHeliTest(presetID, getPlayer()) end)
		end
		EHE_DebugTests["Scheduler Unit Test [LAG]"] = CustomDebugPanel.eHeliEvents_SchedulerUnitTest
		EHE_DebugTests.SandboxVarsDUMP = CustomDebugPanel.SandboxVarsDUMP
		EHE_DebugTests.TemporaryTest = CustomDebugPanel.TemporaryTest
		EHE_DebugTests.checkSquare = CustomDebugPanel.checkSquare
		EHE_DebugTests.printEHEIsoPlayers = CustomDebugPanel.printEHEIsoPlayers
	end
end)


CustomDebugPanel = CustomDebugPanel or {}
CustomDebugPanel.TOGGLE_ALL_CRASH = false
---TEST FUNCTIONS:

function CustomDebugPanel.TemporaryTest()
	local sq = getPlayer():getSquare()
	local object = IsoObject.new(sq, "overlay_blood_wall_01_3")
	--sq:AddTileObject(IsoObject.new(sq, "overlay_blood_wall_01_3"));
	object:setSpriteModelName("SupplyBox")
	print("OBJECT TEST ", object)
	--print("EHE: Checking vanilla helicopter. Adding items to WorldItemRemovalList.")
	--print("getHelicopterDay: "..getGameTime():getHelicopterDay())
	--print("getHelicopterStartHour: "..getGameTime():getHelicopterStartHour())
	--print("getHelicopterEndHour: "..getGameTime():getHelicopterEndHour())
	--print("getOptionByName: "..getSandboxOptions():getOptionByName("Helicopter"):getValue())
	--print("SandboxVars.Helicopter: "..SandboxVars.Helicopter)
	--print("SandboxVars.WorldItemRemovalList: "..SandboxVars.WorldItemRemovalList)

	--print("SchedulerDuration: "..tostring(SandboxVars.ExpandedHeli.SchedulerDuration))
	--print("ContinueScheduling: "..tostring(SandboxVars.ExpandedHeli.ContinueScheduling))
	--print("ContinueSchedulingLateGameOnly: "..tostring(SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly))
end

function CustomDebugPanel.printEHEIsoPlayers()
	print("EHEIsoPlayers: ")
	for playerObj,v in pairs(EHEIsoPlayers) do
		print(" - "..playerObj:getFullName().." - "..playerObj:getUsername())
	end
end

function CustomDebugPanel.SandboxVarsDUMP()
	--SandboxVars
	print(" - SandboxVars:")
	local optionsSize = getSandboxOptions():getNumOptions()
	for i=1, optionsSize do
		---@type SandboxOptions.SandboxOption
		local option = getSandboxOptions():getOptionByIndex(i-1)
		local optionName = tostring(option:getShortName())
		local optionTableName = tostring(option:getTableName())
		print(" --- "..optionName.. " ("..optionTableName..")")
	end

end

function CustomDebugPanel.RTP_indent(n) local text = "" for i=0, n do text = text.."   " end return text end
function CustomDebugPanel.RecursiveTablePrint(object,nesting,every_other)
	nesting = nesting or 0
	local text = ""..CustomDebugPanel.RTP_indent(nesting)
	if type(object) == 'table' then
		local s = '{ \n'
		for k,v in pairs(object) do
			local items_print = false
			if k == "items" then items_print = true end
			if type(k) ~= 'number' then k = '"'..k..'"' end
			if (not every_other) or (every_other and (not (k % 2 == 0))) then s = s..CustomDebugPanel.RTP_indent(nesting+1) end
			s = s..'['..k..'] = '..CustomDebugPanel.RecursiveTablePrint(v,nesting+1,items_print)..", "
			if (not every_other) or (every_other and (k % 2 == 0)) then s = s.."\n" end
		end text = s.."\n"..CustomDebugPanel.RTP_indent(nesting).."}"
	else text = tostring(object) end
	return text
end
--function PrintProceduralDistributions() print("ProceduralDistributions:"..CustomDebugPanel.RecursiveTablePrint(ProceduralDistributions).."\nEnd Of ProceduralDistributions") end


function CustomDebugPanel.checkSquare()
	---@type IsoMovingObject | IsoGameCharacter | IsoPlayer
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
		for i = zones:size(),1,-1 do
			---@type IsoMetaGrid.Zone
			local zone = zones:get(i-1)
			if zone then

				zonePrint = zonePrint .. zone:getType() .. "("..zone:getOriginalName()..")"..", " .. "(d:"..zone:getZombieDensity()..")"
			end
		end
	end

	print("ZONE SCAN: ", zonePrint)
end


function CustomDebugPanel.ZombRandTest(imax)
	local results = {};
	for i = 1, imax do
		local testRand = (ZombRand(13)+1)/10
		results[tostring(testRand)] = (results[tostring(testRand)] or 0) + 1
	end
	print("ZombRand:")
	local output = ""
	for k,v in pairs(results) do
		output = output..k.." ("..v.." times)\n"
	end
	print(output)
end


function CustomDebugPanel.ToggleAllCrash()
	if CustomDebugPanel.TOGGLE_ALL_CRASH == true then
		CustomDebugPanel.TOGGLE_ALL_CRASH = false
	else
		CustomDebugPanel.TOGGLE_ALL_CRASH = true
	end
	print("EHE: DEBUG: TOGGLE_ALL_CRASH = "..tostring(CustomDebugPanel.TOGGLE_ALL_CRASH))
end


function CustomDebugPanel.ToggleMoveHeliCloser()
	if CustomDebugPanel.MOVE_HELI_TEST_CLOSER == true then
		CustomDebugPanel.MOVE_HELI_TEST_CLOSER = false
	else
		CustomDebugPanel.MOVE_HELI_TEST_CLOSER = true
	end
	print("EHE: DEBUG: MOVE_HELI_TEST_CLOSER = "..tostring(CustomDebugPanel.MOVE_HELI_TEST_CLOSER))
end


function CustomDebugPanel.moveHeliCloser(heli)
	if not heli or not heli.target then
		return
	end
	--move closer
	local tpX = heli.target:getX()
	local tpY = heli.target:getY()

	local offsetX = ZombRand(150, 300)
	if ZombRand(101) <= 50 then
		offsetX = 0-offsetX
	end

	local offsetY = ZombRand(150, 300)
	if ZombRand(101) <= 50 then
		offsetY = 0-offsetY
	end
	
	heli.currentPosition:set(tpX+offsetX, tpY+offsetY, heli.height)
end


--- Test launch heli
function CustomDebugPanel.launchHeliTest(presetID, player, moveCloser, crashIt)

	moveCloser = moveCloser or CustomDebugPanel.MOVE_HELI_TEST_CLOSER
	crashIt = crashIt or CustomDebugPanel.TOGGLE_ALL_CRASH

	if isClient() then
		sendClientCommand("CustomDebugPanel", "launchHeliTest", {presetID=presetID,moveCloser=moveCloser,crashIt=crashIt})
	else
		--print("launchHeliTest: isClient():"..tostring(isClient())..", isServer():"..tostring(isServer()))
		---@type eHelicopter heli
		local heli = getFreeHelicopter(presetID)
		print("- EHE: DEBUG: launchHeliTest: "..tostring(presetID))
		heli:launch(player)
		if moveCloser == true then CustomDebugPanel.moveHeliCloser(heli) end
		if crashIt == true then
			heli.crashing = true
			heli:crash()
		end
	end
end


--- Check weather
function CustomDebugPanel.CheckWeather()
	local CM = getClimateManager()
	print("--- CM:getWindIntensity: "..CM:getWindIntensity())
	print("--- CM:getFogIntensity: "..CM:getFogIntensity())
	print("--- CM:getRainIntensity: "..CM:getRainIntensity())
	print("--- CM:getSnowIntensity: "..CM:getSnowIntensity())
	print("--- CM:getIsThunderStorming:(b) "..tostring(CM:getIsThunderStorming()))

	local willFly, impactOnFlightSafety = eHeliEvent_weatherImpact()
	local willFlyCall = "--- willFly: "..tostring(willFly).."   % to crash: "..impactOnFlightSafety*100
	print(willFlyCall)
end


function CustomDebugPanel.eHeliEvents_SchedulerUnitTest()
	local globalModData = getExpandedHeliEventsModData()
	globalModData.EventsOnSchedule = {}
	for freq=1, 6 do
		local testsRan = {}
		for day=0, 90 do
			for hour=0, 24 do
				eHeliEvent_ScheduleNew(day,hour,freq,true)
				for k,v in pairs(globalModData.EventsOnSchedule) do
					if v.triggered then
						globalModData.EventsOnSchedule[k] = nil
					elseif (v.startDay <= day) and (v.startTime == hour) then
						testsRan[v.preset] = testsRan[v.preset] or 0
						testsRan[v.preset] = testsRan[v.preset]+1
						globalModData.EventsOnSchedule[k].triggered = true
					end
				end
			end
		end
		print("======================================")
		print("HeliEvents_SchedulerUnitTest: FREQ: "..getText("Sandbox_ExpandedHeli_Frequency_option"..freq))
		print("--------------------------------------")
		local totalTimes= 0
		for preset,times in pairs(testsRan) do
			totalTimes = totalTimes+times
			print("-preset:"..preset.."  x"..times)
		end
		print("--- TOTAL EVENTS: "..totalTimes)
		print("======================================")
	end
end


--- Check eHeliEvent within eHeliEventsOnSchedule
function CustomDebugPanel.eHeliEventsOnSchedule()

	local GT = getGameTime()
	local globalModData = getExpandedHeliEventsModData()
	local nightsSurvived = tostring(GT:getNightsSurvived())
	local daysIntoApoc = (globalModData.DaysBeforeApoc or 0)+nightsSurvived
	local hour = tostring(GT:getHour())
	local eventsScheduled = false
	print("--- eHeliEventsOnSchedule: ".." daysIntoApoc: "..daysIntoApoc.."  nights-surv: "..nightsSurvived.."  hr: "..hour)

	for k,v in pairs(globalModData.EventsOnSchedule) do
		eventsScheduled = true
		local text = "------ \["..k.."\]"
		if type(v)=="table" then for kk,vv in pairs(v) do text = text.."  "..string.sub(kk, 1, 1)..":"..tostring(vv) end
		else text = text.." = "..v end
		print(text)
	end
	if not eventsScheduled then
		print("------ \[0\]  No Events Schedule")
	end
end


--- Raise the dead
function CustomDebugPanel.raiseTheDead()
	local player = getSpecificPlayer(0)
	local squaresInRange = getIsoRange(player, 15)
	local reanimated=0

	if not squaresInRange then
		print("- Scanning for bodies: ERROR: found no squares to scan")
	end

	print("- Scanning for bodies: ".." #squaresInRange: "..#squaresInRange)
	for sq=1, #squaresInRange do
		---@type IsoGridSquare
		local square = squaresInRange[sq]
		local squareContents = square:getDeadBodys()

		for i=0, squareContents:size()-1 do
			---@type IsoDeadBody
			local foundObj = squareContents:get(i)

			if instanceof(foundObj, "IsoDeadBody") then
				reanimated = reanimated+1
				foundObj:reanimateNow()
			end
		end
	end
	print("-- Reanimated: "..reanimated)
end


--- Test getHumanoidsInFractalRange
function CustomDebugPanel.getHumanoidsInFractalRange()
	local player = getSpecificPlayer(0)
	local fractalObjectsFound = getHumanoidsInFractalRange(player, 1, 2, "IsoZombie")

	---debug: list type found
	print("-----[ getHumanoidsInFractalRange ]-----")
	for fractalIndex=1, #fractalObjectsFound do
		local objectsArray = fractalObjectsFound[fractalIndex]
		print(" "..fractalIndex..":  hostile count:"..#objectsArray)
	end
end


--- Test getHumanoidsInRange
function CustomDebugPanel.getHumanoidsInRange()
	local player = getSpecificPlayer(0)
	local objectsFound = getHumanoidsInRange(player, 1, "IsoZombie")

	---debug: list type found
	print("-----[ getHumanoidsInRange ]-----")
	print(" objectsFound: ".." count: "..#objectsFound)
	for i=1, #objectsFound do
		---@type IsoMovingObject|IsoGameCharacter foundObj
		local foundObj = objectsFound[i]
		print(" "..i..":  "..tostring(foundObj:getClass())) -- "IsoZombie" or "IsoPlayer"
	end
end


---- Test all announcements
--GLOBAL DEBUG VARS
local testAllLines = {}
testAllLines.ALL_LINES = {}
testAllLines.DELAYS = {}
testAllLines.lastDemoTime = 0

function CustomDebugPanel.testAllLines()
	if #testAllLines.ALL_LINES > 0 then
		testAllLines.ALL_LINES = {}
		testAllLines.DELAYS = {}
		testAllLines.lastDemoTime = 0

		local player = getPlayer()
		player:Say("Cancelling testAllLines")
		return
	end

	for voiceID,voiceData in pairs(eHelicopter_announcers) do
		if eHelicopterSandbox.config[voiceID] == true then
			for lineID,lineData in pairs(voiceData["Lines"]) do
				table.insert(testAllLines.ALL_LINES, lineData[2])
				table.insert(testAllLines.DELAYS, lineData[1])
			end
		end
	end
	table.insert(testAllLines.ALL_LINES, "eHeli_machine_gun_fire_single")
	table.insert(testAllLines.DELAYS, 1)
end

function CustomDebugPanel.testAllLinesLOOP()
	if #testAllLines.ALL_LINES > 0 then
		if (testAllLines.lastDemoTime < getTimeInMillis()) then
			local line = testAllLines.ALL_LINES[1]
			local delay = testAllLines.DELAYS[1]
			testAllLines.lastDemoTime = getTimeInMillis()+delay
			local emitter = getWorld():getFreeEmitter()
			local player = getPlayer()
			player:Say(line)
			emitter:playSound(line)
			table.remove(testAllLines.ALL_LINES, 1)
			table.remove(testAllLines.DELAYS, 1)
		end
	end
end

Events.OnTick.Add(CustomDebugPanel.testAllLinesLOOP)
