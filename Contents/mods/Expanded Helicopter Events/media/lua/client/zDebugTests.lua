Events.OnGameBoot.Add(print("Expanded Helicopter Events: ver:0.2.5-fixforSP-disabledMP"))
require "zDebugPanel"

Events.OnGameBoot.Add(function()
	ISCustomDebugTestsPanel.Tests["Check Schedule"] = CustomDebugPanel.eHeliEventsOnSchedule
	ISCustomDebugTestsPanel.Tests["Test All Voice Lines"] = CustomDebugPanel.testAllLines
	ISCustomDebugTestsPanel.Tests["Raise The Dead"] = CustomDebugPanel.raiseTheDead
	ISCustomDebugTestsPanel.Tests["Toggle All Crash"] = CustomDebugPanel.ToggleAllCrash
	ISCustomDebugTestsPanel.Tests["Toggle Move HeliCloser"] = CustomDebugPanel.ToggleMoveHeliCloser
	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		ISCustomDebugTestsPanel.Tests["Launch: "..presetID] = (function() CustomDebugPanel.launchHeliTest(presetID, getPlayer()) end)
	end
	ISCustomDebugTestsPanel.Tests["Scheduler Unit Test 90 Days [LAG]"] = CustomDebugPanel.eHeliEvents_SchedulerUnitTest
	ISCustomDebugTestsPanel.Tests.TemporaryTest = CustomDebugPanel.TemporaryTest
end)


CustomDebugPanel = CustomDebugPanel or {}
CustomDebugPanel.TOGGLE_ALL_CRASH = false
---TEST FUNCTIONS:

function CustomDebugPanel.TemporaryTest()
	local osDate = os.date("*t")
	local currentSystemDate = {osDate.month, osDate.day}
	local currentInGameDate = {getGameTime():getMonth(), getGameTime():getDay()}
	print("currentSystemDate: "..currentSystemDate[1].."/"..currentSystemDate[2].."  currentInGameDate:"..currentInGameDate[1].."/"..currentInGameDate[2])

	--11/26  6/30

	local TESTS = {
		{{1}},
		{{1,1}},
		{{1,15},{12}},
		{{1},{12}},
		{{1},{12}},
		{{1},{12}},
		{{1},{12}},
		{{1},{12}},
		{{11}},
		{{11,1},{11,15}},
	}

	for k,v in pairs(TESTS) do
		local systemDateTest = eHeliEvent_processSchedulerDates(currentSystemDate, v)
		local inGameDateTest = eHeliEvent_processSchedulerDates(currentInGameDate, v)
		print("test "..k.." systemDateTest:"..tostring(systemDateTest).."  inGameDateTest:"..tostring(inGameDateTest))
	end
end


function CustomDebugPanel.SandboxVarsDUMP()
	--SandboxVars
	print("SandboxVars:"..CustomDebugPanel.RecursiveTablePrint(SandboxVars).."\nEnd Of SandboxVars")
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
function CustomDebugPanel.launchHeliTest(presetID, player)
	---@type eHelicopter heli
	local heli = getFreeHelicopter(presetID)
	print("- EHE: DEBUG: launchHeliTest: "..tostring(presetID))
	heli:launch(player)
	if CustomDebugPanel.MOVE_HELI_TEST_CLOSER == true then
		CustomDebugPanel.moveHeliCloser(heli)
	end
	if CustomDebugPanel.TOGGLE_ALL_CRASH == true then
		heli.crashing = true
		heli:crash()
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
	print("======================================")
	print("neHeliEvents_SchedulerUnitTest: (SandboxVars.ExpandedHeli.CutOffDay:"..SandboxVars.ExpandedHeli.CutOffDay..")")
	print("--------------------------------------")
	for day=0, 90 do
		for hour=0, 24 do
			eHeliEvent_ScheduleNew(day,hour)
			for k,v in pairs(globalModData.EventsOnSchedule) do
				if v.triggered then
					globalModData.EventsOnSchedule[k] = nil
				elseif (v.startDay <= day) and (v.startTime == hour) then
					globalModData.EventsOnSchedule[k].triggered = true
				end
			end
		end
	end
	print("======================================")
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
		print("------ \["..k.."\]  day:"..tostring(v.startDay).." time:"..tostring(v.startTime).." id:"..tostring(v.preset).." done:"..tostring(v.triggered))
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


function eHelicopter:hoverAndFlyOverReport(STATE)
	if self.trueTarget and self.trueTarget:getClass() and self.target and self.target:getClass() then
		print(" - "..self:heliToString(true).." "..STATE..(self.trueTarget:getClass():getSimpleName()).." "..(self.target:getClass():getSimpleName()))
	end
end


--- Debug: Reports helicopter's useful variables -- note: this will flood your output
function eHelicopter:Report(aiming, dampen)
	---@type eHelicopter heli
	local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." "
	print(" > "..self:heliToString(true))
	print("   TARGET: (x:"..Vector3GetX(self.targetPosition)..", y:"..Vector3GetY(self.targetPosition)..")")
	print("   (dist: "..self:getDistanceToVector(self.target).."  "..report)
	print("-----------------------------------------------------------------")
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


--- Test all announcements
--GLOBAL DEBUG VARS
testAllLines__ALL_LINES = {}
testAllLines__DELAYS = {}
testAllLines__lastDemoTime = 0

function CustomDebugPanel.testAllLines()
	if #testAllLines__ALL_LINES > 0 then
		testAllLines__ALL_LINES = {}
		testAllLines__DELAYS = {}
		testAllLines__lastDemoTime = 0
		return
	end

	for voiceID,voiceData in pairs(eHelicopter_announcers) do
		if eHelicopterSandbox.config[voiceID] == true then
			for lineID,lineData in pairs(voiceData["Lines"]) do
				table.insert(testAllLines__ALL_LINES, lineData[2])
				table.insert(testAllLines__DELAYS, lineData[1])
			end
		end
	end
	table.insert(testAllLines__ALL_LINES, "eHeli_machine_gun_fire_single")
	table.insert(testAllLines__DELAYS, 1)
end

function CustomDebugPanel.testAllLinesLOOP()
	if #testAllLines__ALL_LINES > 0 then
		if (testAllLines__lastDemoTime < getTimestampMs()) then
			local line = testAllLines__ALL_LINES[1]
			local delay = testAllLines__DELAYS[1]
			testAllLines__lastDemoTime = getTimestampMs()+delay
			---@type IsoPlayer | IsoGameCharacter player
			local player = getSpecificPlayer(0)
			player:playSound(line)
			table.remove(testAllLines__ALL_LINES, 1)
			table.remove(testAllLines__DELAYS, 1)
		end
	end
end

Events.OnTick.Add(CustomDebugPanel.testAllLinesLOOP)