if getDebug() then

	Events.OnCustomUIKey.Add(function(key)
		if key == Keyboard.KEY_1 then
			DEBUG_TESTS.testAllLines()

		elseif key == Keyboard.KEY_2 then
			DEBUG_TESTS.raiseTheDead()

		elseif key == Keyboard.KEY_3 then
			DEBUG_TESTS.eHeliEventsOnSchedule()

		elseif key == Keyboard.KEY_4 then
			--DEBUG_TESTS.CheckWeather()
			DEBUG_TESTS.shakeTrees()

		elseif key == Keyboard.KEY_5 then
			DEBUG_TESTS.launch_jet()

		elseif key == Keyboard.KEY_6 then
			DEBUG_TESTS.launch_news_chopper()

		elseif key == Keyboard.KEY_7 then
			DEBUG_TESTS.launch_attack_only_all()

		elseif key == Keyboard.KEY_8 then
			DEBUG_TESTS.launch_attack_only_undead()

		elseif key == Keyboard.KEY_9 then
			DEBUG_TESTS.launch_increasingly_hostile()

		elseif key == Keyboard.KEY_0 then
			DEBUG_TESTS.launchBaseHeli()
		end
	end)

	DEBUG_TESTS = {}

	--- Check weather
	function DEBUG_TESTS.CheckWeather()
		local CM = getClimateManager()
		print("--- CM:getWindIntensity: "..CM:getWindIntensity())
		print("--- CM:getFogIntensity: "..CM:getFogIntensity())
		print("--- CM:getRainIntensity: "..CM:getRainIntensity())
		print("--- CM:getSnowIntensity: "..CM:getSnowIntensity())
		print("--- CM:getIsThunderStorming:(b) "..tostring(CM:getIsThunderStorming()))

		local willFly, impactOnFlightSafety = eHeliEvent_weatherImpact()
		local willFlyCall = "--- willFly: "..tostring(willFly)
		if willFly then willFlyCall = willFlyCall.."   % to crash: "..impactOnFlightSafety*100 end
		print(willFlyCall)
	end


	--- Check eHeliEvent within eHeliEventsOnSchedule
	function DEBUG_TESTS.eHeliEventsOnSchedule()
		print("--- eHeliEventsOnSchedule: ".."current day: "..tostring(getGameTime():getNightsSurvived()).." hr: "..tostring(getGameTime():getHour()))
		for k,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
			print("------ \["..k.."\]  day:"..tostring(v.startDay).." time:"..tostring(v.startTime).." p:"..tostring(v.preset)..
					" r:"..tostring(v.renew).." t:"..tostring(v.triggered))
		end
	end


	--- Raise the dead
	function DEBUG_TESTS.raiseTheDead()
		local player = getSpecificPlayer(0)
		local squaresInRange = getIsoRange(player, 15)
		local reanimated=0
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

	--- Debug: Reports helicopter's useful variables -- note: this will flood your output
	function eHelicopter:Report(aiming, dampen)
		---@type eHelicopter heli
		local heli = self
		local report = " a:"..tostring(aiming).." d:"..tostring(dampen).." "
		print("HELI: "..heli.ID.." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
		print("TARGET: (x:"..Vector3GetX(heli.targetPosition)..", y:"..Vector3GetY(heli.targetPosition)..")")
		print("(dist: "..heli:getDistanceToVector(self.target).."  "..report)
		print("-----------------------------------------------------------------")
	end


	--- Test launch heli
	function DEBUG_TESTS.launchBaseHeli()
		---@type eHelicopter heli
		local heli = getFreeHelicopter()
		heli:launch()
		print("HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end

	--- Test launch heli
	function DEBUG_TESTS.launch_jet()
		---@type eHelicopter heli
		local heli = getFreeHelicopter("jet")
		heli:launch()
		print("\"jet\" HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end

	--- Test launch close "attack_only_undead" heli
	function DEBUG_TESTS.launch_attack_only_undead()
		---@type eHelicopter heli
		local heli = getFreeHelicopter("attack_only_undead")
		heli:launch()
		--move closer
		local tpX = heli.target:getX()
		local tpY = heli.target:getY()
		local offset = ZombRand(300)
		heli.currentPosition:set(tpX+offset, tpY+offset, heli.height)
		print("\"attack_only_undead\" HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end


	--- Test launch close "attack_only_all" heli
	function DEBUG_TESTS.launch_attack_only_all()
		---@type eHelicopter heli
		local heli = getFreeHelicopter("attack_only_all")
		heli:launch()
		--move closer
		local tpX = heli.target:getX()
		local tpY = heli.target:getY()
		local offset = ZombRand(300)
		heli.currentPosition:set(tpX+offset, tpY+offset, heli.height)
		print("\"attack_only_all\" HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end


	--- Test launch close "increasingly_hostile" heli
	function DEBUG_TESTS.launch_increasingly_hostile()
		---@type eHelicopter heli
		local heli = getFreeHelicopter("increasingly_hostile")
		heli:launch()
		--move closer
		local tpX = heli.target:getX()
		local tpY = heli.target:getY()
		local offset = ZombRand(300)
		heli.currentPosition:set(tpX+offset, tpY+offset, heli.height)
		print("\"increasingly_hostile\" HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end


	--- Test launch close "news_chopper" heli
	function DEBUG_TESTS.launch_news_chopper()
		---@type eHelicopter heli
		local heli = getFreeHelicopter("news_chopper")
		heli:launch()

		--move closer
		local tpX = heli.target:getX()
		local tpY = heli.target:getY()
		local offset = ZombRand(300)
		heli.currentPosition:set(tpX+offset, tpY+offset, heli.height)

		print("\"news_chopper\" HELI: "..heli.ID.." LAUNCHED".." (x:"..Vector3GetX(heli.currentPosition)..", y:"..Vector3GetY(heli.currentPosition)..")")
	end


	--- Test getHumanoidsInFractalRange
	function DEBUG_TESTS.getHumanoidsInFractalRange()
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
	function DEBUG_TESTS.getHumanoidsInRange()
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

	function DEBUG_TESTS.testAllLines()
		if #eHelicopter_announcersLoaded <= 0 then
			print("ERROR: NO VOICES LOADED")
			return
		end

		if #testAllLines__ALL_LINES > 0 then
			testAllLines__ALL_LINES = {}
			testAllLines__DELAYS = {}
			testAllLines__lastDemoTime = 0
			return
		end

		for _,v in pairs(eHelicopter_announcersLoaded) do
			for _,v2 in pairs(eHelicopter_announcers[v]["Lines"]) do
				for k3,_ in pairs(v2) do
					if k3 ~= 1 then
						table.insert(testAllLines__ALL_LINES, v2[k3])
						table.insert(testAllLines__DELAYS, v2[1])
					end
				end
			end
		end
		table.insert(testAllLines__ALL_LINES, "heli_fire_single")
		table.insert(testAllLines__DELAYS, 1)
	end

	function DEBUG_TESTS.testAllLinesLOOP()
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

	Events.OnTick.Add(DEBUG_TESTS.testAllLinesLOOP)


	---Try to shake trees near by
	function DEBUG_TESTS.shakeTrees()
		print("impactEnvironment: ")
		if not getCore():getOptionDoWindSpriteEffects() then
			print("-- Core:getOptionDoWindSpriteEffects == false; No effects for you. ")
			return
		end

		---@type IsoObject | IsoGameCharacter |IsoMovingObject
		local player = getSpecificPlayer(0)
		local centerSquare = player:getSquare()--self:getIsoGridSquare()
		print("-- square:"..tostring(centerSquare:getClass():getSimpleName()))
		--local cell = (not square) or square:getCell()
		--print("-- cell:"..tostring(cell))
		local squaresInRange = (not centerSquare) or getIsoRange(centerSquare, 5)
		print("-- squaresInRange: "..tostring(squaresInRange))

		if squaresInRange then
			for _,v in pairs(squaresInRange) do
				---@type IsoGridSquare
				local square = v
				--print("--- square: "..tostring(square))
				---@type IsoTree | IsoObject
				local tree = (not square) or square:getTree()
				if tree then
					print("--- tree: "..tostring(tree:getClass():getSimpleName()))

					--local CM = getClimateManager()
					--local windTick = CM:getWindTickFinal()
					--local windAngle = CM:getWindAngleIntensity()
					--print("windTick: "..windTick.."   windAngle: "..windAngle)

					tree:setRenderEffect(RenderEffectType, true)

					local renderEffect = tree:getWindRenderEffects()

					if renderEffect then
						print("--- --- Render Effect getNextWindEffect")
						---HANGS HERE
						--renderEffect:getNextWindEffect(1,true)
						print("--- --- Render Effect update")
						renderEffect:update()--0.1,0.5)
					else
						print("--- --- No Render Effect")
					end
					--renderEffect:getNextWindEffect(1,true)
					--renderEffect:getNew(tree, RenderEffectType.Vegetation_Rustle, false, false) ---RenderEffectType is private
				end
			end
		end
	end


end