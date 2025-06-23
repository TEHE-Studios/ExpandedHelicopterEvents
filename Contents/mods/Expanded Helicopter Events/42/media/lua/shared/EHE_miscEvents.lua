---@param heli eHelicopter
function eHelicopter_dropCrewOff(heli)
	if not heli then
		return
	end

	local x, y, z = heli:getXYZAsInt()
	local xOffset = ZombRand(20,35)
	local yOffset = ZombRand(20,35)

	local trueTarget = heli.trueTarget
	if trueTarget then
		local tX, tY = trueTarget:getX(), trueTarget:getY()
		xOffset=math.max(0,xOffset-tX)
		yOffset=math.max(0,yOffset-tY)
	end

	if ZombRand(101) <= 50 then
		xOffset=0-xOffset
	end
	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end

	x = x+xOffset
	y = y+yOffset

	--[[DEBUG]] print("SWH: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
	--for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crew.png", 750, x, y)
	heli:spawnCrew(x, y, 0)
	heli.addedFunctionsToEvents.OnHover = false
end


---@param crew table
function eHelicopter_crewSeek(crew)

	if not crew then
		return
	end

	local choice
	local location

	if crew:size() > 0 then
		location = crew:get(0):getSquare()
	end
	if not location then
		return
	end

	for character,_ in pairs(EHEIsoPlayers) do
		if (not choice) or (choice and character and (location:DistTo(choice) < location:DistTo(character)) ) then
			choice = character
		end
	end

	if choice then
		for i=0, crew:size()-1 do
			---@type IsoZombie
			local zombie = crew:get(i)
			if zombie then
				zombie:spotted(choice, true)
			end
		end
	end
end


local activeMods = {}
local activeModIDs = getActivatedMods()
for i=1, activeModIDs:size() do
	local modID = activeModIDs:get(i-1)
	if not activeMods[modID] then
		activeMods[modID] = true
	end
end


superWeirdForcedDancersAnim = {}
local OrdinaryDance = {
	"BobTA_African_Noodle", "BobTA_African_Rainbow", "BobTA_Arm_Push", "BobTA_Arm_Wave_One", "BobTA_Arm_Wave_Two",
	"BobTA_Arms_Hip_Hop", "BobTA_Around_The_World", "BobTA_Bboy_Hip_Hop_One", "BobTA_Bboy_Hip_Hop_Three", "BobTA_Bboy_Hip_Hop_Two",
	"BobTA_Body_Wave", "BobTA_Booty_Step", "BobTA_Breakdance_Brooklyn_Uprock", "BobTA_Cabbage_Patch", "BobTA_Can_Can",
	"BobTA_Charleston", "BobTA_Chicken", "BobTA_Crazy_Legs", "BobTA_Defile_De_Samba_Parade", "BobTA_Gandy", "BobTA_Hokey_Pokey",
	"BobTA_House_Dancing", "BobTA_Kick_Step", "BobTA_Locking", "BobTA_Macarena", "BobTA_Maraschino", "BobTA_MoonWalk_One",
	"BobTA_Moonwalk_Two", "BobTA_Northern_Soul_Spin", "BobTA_Northern_Soul_Spin_On_Floor", "BobTA_Raise_The_Roof",
	"BobTA_Really_Twirl", "BobTA_Rib_Pops", "BobTA_Rockette_Kick", "BobTA_Rumba_Dancing", "BobTA_Running_Man_One",
	"BobTA_Running_Man_Three", "BobTA_Running_Man_Two", "BobTA_Salsa", "BobTA_Salsa_Double_Twirl", "BobTA_Salsa_Double_Twirl_and_Clap",
	"BobTA_Salsa_Side_to_Side", "BobTA_Shim_Sham", "BobTA_Shimmy", "BobTA_Shuffling", "BobTA_Side_to_Side", "BobTA_Thriller_One",
	"BobTA_Twist_One", "BobTA_Twist_Two", "BobTA_Uprock_Indian_Step", "BobTA_YMCA",}
---@param char IsoGameCharacter
function forceDance(heli, char)
	if not activeMods["TrueActionsDancing"] then return end

	if instanceof(char, "IsoPlayer") then
		local currentEmote = char:getVariableString("emote")
		if (not superWeirdForcedDancersAnim[char]~=currentEmote) then
			local dance = superWeirdForcedDancersAnim[char] or OrdinaryDance[ZombRand(#OrdinaryDance)+1]
			local danceRecipe = string.gsub(dance, "_", " ")
			if not char:isRecipeKnown(danceRecipe) then
				char:getKnownRecipes():add(danceRecipe)
			end
			char:playEmote(dance)
			superWeirdForcedDancersAnim[char] = dance
		end
	end
end
function onLaunchClearDance() superWeirdForcedDancersAnim = {} end