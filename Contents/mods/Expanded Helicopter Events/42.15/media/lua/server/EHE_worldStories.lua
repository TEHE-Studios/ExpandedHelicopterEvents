if isClient() then return end

require("EHE_heliCore.lua")
require("EHE_mainEvents.lua")
require("EHE_spawner.lua")

local util = require("EHE_util.lua")
local modData = require("EHE_globalModData.lua")
local presetCore = require("EHE_presetCore.lua")
local eHelicopter = require("EHE_heliVariables.lua")
local targetSquareOnLoad = require("!_TargetSquare_OnLoad.lua")

local worldStories = {}

worldStories.cellSize = 256
worldStories.playerBuffer = 150
worldStories.zoneTypes = { Forest=true, DeepForest=true, Vegitation=true, Farm=true, FarmLand=true, Nav=true, TrailerPark=true }

worldStories.types = {
	crash = { weight = 4, presets = {"military_nonhostile", "military_hostile", "news_Bell206", "police", "survivors", "deserters"} },
	drop = { weight = 3, presets = {"military_UH1H_patrol_emergency", "survivors"} },
	flyers = { weight = 2, presets = {"military_UH1H_patrol_emergency", "military_UH1H_patrol_quarantine", "military_UH1H_attack_undead_evac"} },
	landed = { weight = 3 },
}

worldStories.landed = {
	{ vehicles = {"UH60Green", "UH60Desert"}, preset = "military_UH1H_patrol", gear = "military" },
	{ vehicles = {"UH60Medevac"}, preset = "military_UH1H_attack_undead_evac", gear = "medical" },
	{ vehicles = {"SC_UH1HVariant1", "SC_UH1HVariant2", "SC_UH1HVariant3"}, preset = "military_UH1H_patrol", gear = "military" },
	{ vehicles = {"Bell206Fuselage_N720HP", "Bell206Fuselage_N95SP", "Bell206Fuselage_N177TV", "Bell206Fuselage_N120LH"}, preset = "survivors", gear = "survivor" },
}

worldStories.landedVariants = { abandoned = 4, camp = 3, gunfight = 3 }

worldStories.gear = {
	military = {"Base.Bag_ALICEpack_Army", 1, "Base.556Clip", 2, "Base.CanteenMilitaryFull", 1, "Base.FirstAidKit_Military", 1, "Base.FlashLight_AngleHead_Army", 1, "Base.WalkieTalkie5", 1},
	medical = {"Base.FirstAidKit_Military", 1, "Base.BandageBox", 1, "Base.AlcoholBandage", 3, "Base.Bag_ProtectiveCaseSmallMilitary_FirstAid", 1, "Base.CanteenMilitaryFull", 1},
	survivor = {"Base.Bag_DuffelBag", 1, "Base.WaterBottle", 1, "Base.TinnedBeans", 2, "Base.Matches", 1, "Base.Tarp", 1},
	camp = {"Base.SleepingBag_Camo_Packed", 1, "Base.TinCanEmpty", 3, "Base.Pot", 1, "Base.TinOpener", 1},
	gunfight = {"Base.AssaultRifle", 1, "Base.556Clip", 2, "Base.Pistol", 1, "Base.9mmClip", 1, "Base.Bullets9mm", 6},
}


function worldStories.pickWeighted(weights)
	local total = 0
	for _,weight in pairs(weights) do total = total+weight end
	local roll = ZombRand(total)
	for id,weight in pairs(weights) do
		if roll < weight then return id end
		roll = roll-weight
	end
end


function worldStories.offset(x, y, minRange, maxRange)
	local angle = ZombRandFloat(0, math.pi*2)
	local range = ZombRand(minRange, maxRange+1)
	return math.floor(x+(math.cos(angle)*range)+0.5), math.floor(y+(math.sin(angle)*range)+0.5)
end


function worldStories.farFromPlayers(x, y, players)
	for i=1, #players do
		local p = players[i]
		if math.abs(p:getX()-x) < worldStories.playerBuffer and math.abs(p:getY()-y) < worldStories.playerBuffer then return false end
	end
	return true
end


function worldStories.place()
	local globalModData = modData.get()
	if not globalModData or globalModData.WorldStoriesPlaced then return end
	globalModData.WorldStoriesPlaced = true

	local count = SandboxVars.ExpandedHeli.WorldStories or 0
	if count <= 0 then return end

	local typeWeights = {}
	for id,storyType in pairs(worldStories.types) do typeWeights[id] = storyType.weight end

	local metaGrid = getWorld():getMetaGrid()
	local minX, minY = metaGrid:getMinX()*worldStories.cellSize, metaGrid:getMinY()*worldStories.cellSize
	local maxX, maxY = ((metaGrid:getMaxX()+1)*worldStories.cellSize)-1, ((metaGrid:getMaxY()+1)*worldStories.cellSize)-1
	local players = util.getActualPlayers()

	local placed, attempts = 0, 0
	while (placed < count) and (attempts < count*50) do
		attempts = attempts+1
		local x, y = ZombRand(minX, maxX+1), ZombRand(minY, maxY+1)
		local zone = metaGrid:getZoneAt(x, y, 0)
		if zone and worldStories.zoneTypes[zone:getType()] and (not getSquare(x, y, 0)) and worldStories.farFromPlayers(x, y, players) then
			targetSquareOnLoad.instance.addCommand(x, y, 0, { command="EHE_story", story=worldStories.pickWeighted(typeWeights) })
			placed = placed+1
		end
	end
	print("EHE: world stories placed: "..placed.." / "..count)
end


function worldStories.findGround(square)
	local x, y = square:getX(), square:getY()
	for r=0, 10 do
		for dx=-r, r do
			for dy=-r, r do
				if math.abs(dx)==r or math.abs(dy)==r then
					local sq = getSquare(x+dx, y+dy, 0)
					if sq and sq:getFloor() and (not sq:isWaterSquare()) and util.isIsoGridSquareOutside(sq) then return sq end
				end
			end
		end
	end
end


function worldStories.atSquare(x, y, z, command)
	local square = getSquare(x, y, z)
	if square then
		targetSquareOnLoad.instance.OnLoadCommands[command.command](square, command)
	else
		targetSquareOnLoad.instance.addCommand(x, y, z, command)
	end
end


function worldStories.resolvePreset(presetID, x, y)
	if not presetID or not presetCore.PRESETS[presetID] then return end
	local heli = setmetatable({}, {__index = eHelicopter})
	heli:loadPreset(presetID)
	heli.height = 0
	heli.currentPosition = Vector3.new()
	heli.currentPosition:set(x, y, 0)
	return heli
end


function worldStories.resolveWith(presets, x, y, requiredVar)
	for i=1, 5 do
		local heli = worldStories.resolvePreset(presets[ZombRand(#presets)+1], x, y)
		if heli and heli[requiredVar] then return heli end
	end
end


function worldStories.scatterItems(list, x, y, minRange, maxRange)
	if not list then return end
	for i=1, #list, 2 do
		for n=1, (list[i+1] or 1) do
			local itemX, itemY = worldStories.offset(x, y, minRange, maxRange)
			EHE_spawner.request({ funcType="item", spawnThis=list[i], x=itemX, y=itemY, z=0, extraFunctions={"ageInventoryItem"} })
		end
	end
end


function worldStories.scatterDropItems(heli, fuzz, minQty, maxQty)
	for itemType,qty in pairs(heli.dropItems) do heli.dropItems[itemType] = math.min(qty, ZombRand(minQty, maxQty+1)) end
	heli:dropAllItems(fuzz)
end


function worldStories.spawnCrew(crew, x, y, minRange, maxRange, deadChance)
	if not crew then return end
	for i=1, #crew do
		local member = crew[i]
		if member and member.outfit and (ZombRand(101) <= (member.spawn or 100)) then
			local crewX, crewY = worldStories.offset(x, y, minRange, maxRange)
			local extraFunctions = (ZombRand(100) < deadChance) and {"applyDeathToCrew"} or nil
			EHE_spawner.request({ funcType="zombie", spawnThis=member.outfit, x=crewX, y=crewY, z=0,
				extraFunctions=extraFunctions, extraParam=member.female or 50 })
		end
	end
end


function worldStories.story_crash(ground)
	local x, y = ground:getX(), ground:getY()
	local heli = worldStories.resolveWith(worldStories.types.crash.presets, x, y, "crashType")
	if not heli then return end

	local extraFunctions = {"applyCrashOnVehicle", "applyCrashStructuralDamage"}
	local onCrashID = heli.currentPresetID.."OnCrash"
	if EHE_spawner.functionDictionary[onCrashID] then table.insert(extraFunctions, onCrashID) end

	local angle = ZombRandFloat(0, math.pi*2)
	EHE_spawner.request({ funcType="vehicle", spawnThis=heli.crashType[ZombRand(#heli.crashType)+1], x=x, y=y, z=0,
		extraFunctions=extraFunctions, extraParam={headingX=math.cos(angle), headingY=math.sin(angle)} })

	if heli.scrapItems or heli.scrapVehicles then heli:dropScrap(8) end
	if heli.dropItems then worldStories.scatterDropItems(heli, 5, 5, 15) end
	heli:spawnDeadCrew(x, y, 0)
end


function worldStories.story_drop(ground)
	local x, y = ground:getX(), ground:getY()
	local heli = worldStories.resolveWith(worldStories.types.drop.presets, x, y, "dropPackages")
	if not heli then return end

	EHE_spawner.request({ funcType="vehicle", spawnThis=heli.dropPackages[ZombRand(#heli.dropPackages)+1], x=x, y=y, z=0,
		extraFunctions={"applyParachuteToCarePackage"} })

	if heli.dropItems then worldStories.scatterDropItems(heli, 6, 5, 15) end
end


function worldStories.story_flyers(ground)
	local x, y = ground:getX(), ground:getY()
	local heli = worldStories.resolveWith(worldStories.types.flyers.presets, x, y, "dropItems")
	if not heli then return end
	worldStories.scatterDropItems(heli, 12, 15, 40)
end


function worldStories.story_landed(ground)
	local x, y = ground:getX(), ground:getY()
	local site = worldStories.landed[ZombRand(#worldStories.landed)+1]
	local heli = worldStories.resolvePreset(site.preset, x, y)
	if not heli then return end

	EHE_spawner.request({ funcType="vehicle", spawnThis=site.vehicles[ZombRand(#site.vehicles)+1], x=x, y=y, z=0,
		extraFunctions={"applyVehicleMetalKg"} })

	local variant = worldStories.pickWeighted(worldStories.landedVariants)
	worldStories["landed_"..variant](heli, site, x, y)
end


function worldStories.landed_abandoned(heli, site, x, y)
	worldStories.scatterItems(worldStories.gear[site.gear], x, y, 3, 8)
	worldStories.spawnCrew(heli.crew, x, y, 10, 25, 0)
end


function worldStories.landed_camp(heli, site, x, y)
	local campX, campY = worldStories.offset(x, y, 8, 12)
	worldStories.atSquare(campX, campY, 0, { command="EHE_storyCamp" })
	worldStories.scatterItems(worldStories.gear.camp, campX, campY, 1, 3)
	worldStories.scatterItems(worldStories.gear[site.gear], campX, campY, 1, 4)
	worldStories.spawnCrew(heli.crew, campX, campY, 1, 5, 50)
end


function worldStories.landed_gunfight(heli, site, x, y)
	worldStories.atSquare(x, y, 0, { command="EHE_storyBlood" })
	worldStories.scatterItems(worldStories.gear.gunfight, x, y, 2, 8)
	worldStories.scatterItems(worldStories.gear[site.gear], x, y, 2, 6)
	worldStories.spawnCrew(heli.crew, x, y, 2, 6, 100)
	local attackers = presetCore.PRESETS.deserters and presetCore.PRESETS.deserters.crew
	worldStories.spawnCrew(attackers, x, y, 6, 12, 100)
end


function worldStories.build(square, command)
	local ground = worldStories.findGround(square)
	if not ground then return end
	if not EHE_spawner.functionDictionary then EHE_spawner.setDictionary() end
	local story = worldStories["story_"..tostring(command.story)]
	if story then story(ground) end
end


function worldStories.buildCamp(square)
	local ground = worldStories.findGround(square)
	if not ground then return end
	if SCampfireSystem and SCampfireSystem.instance then SCampfireSystem.instance:addCampfire(ground) end
	if camping and camping.addTent and getSprite(camping.tentSprites.tarp.frontLeft) then
		local tentSquare = getSquare(ground:getX()+2, ground:getY()+1, 0)
		local tentBackSquare = getSquare(ground:getX()+1, ground:getY()+1, 0)
		if tentSquare and tentBackSquare and util.isIsoGridSquareOutside(tentSquare) and util.isIsoGridSquareOutside(tentBackSquare) then
			camping.addTent(tentSquare, camping.tentSprites.tarp.frontLeft)
		end
	end
end


function worldStories.buildBlood(square)
	local x, y = square:getX(), square:getY()
	for i=1, ZombRand(12, 25) do
		local sq = getSquare(x+ZombRand(-5, 6), y+ZombRand(-5, 6), 0)
		if sq then sq:getChunk():addBloodSplat(sq:getX()+ZombRandFloat(0, 1), sq:getY()+ZombRandFloat(0, 1), 0, ZombRand(20)) end
	end
end


function worldStories.addCommands()
	targetSquareOnLoad.instance.OnLoadCommands.EHE_story = worldStories.build
	targetSquareOnLoad.instance.OnLoadCommands.EHE_storyCamp = worldStories.buildCamp
	targetSquareOnLoad.instance.OnLoadCommands.EHE_storyBlood = worldStories.buildBlood
end
Events.OnSGlobalObjectSystemInit.Add(worldStories.addCommands)

if not isServer() then Events.OnGameStart.Add(worldStories.place) end
if isServer() then Events.OnServerStarted.Add(worldStories.place) end

return worldStories
