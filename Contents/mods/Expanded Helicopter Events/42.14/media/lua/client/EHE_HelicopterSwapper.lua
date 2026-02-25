print("EHE_HelicopterSwapper loading")

local EHE_HelicopterSwapper = {}

-- Define helicopter crash variants with optional matching tails
EHE_HelicopterSwapper.swapTable = {
	-- Huey variants (with tails)
	["Base.SC_UH1H"] = {
		{ vehicle = "Base.SC_UH1HVariant1", chance = 25 },
		{ vehicle = "Base.SC_UH1HVariant2", chance = 25 },
		{ vehicle = "Base.SC_UH1HVariant3", chance = 25 },
	},
	
	-- Bell 206 variants (no tails in this example - just omit tail property)
	["Base.SC_Bell206"] = {
		{ vehicle = "Base.SC_Bell206Variant1", chance = 33 },
		{ vehicle = "Base.SC_Bell206Variant2", chance = 33 },
		{ vehicle = "Base.SC_Bell206Variant3", chance = 34 },
	},

	["Base.SC_UH60"] = {
		{ vehicle = "Base.UH60GreenFuselage", tail = "Base.UH60GreenTail", chance = 25 },
		{ vehicle = "Base.UH60DesertFuselage", tail = "Base.UH60DesertTail", chance = 25 },
		{ vehicle = "Base.UH60MedevacFuselage", tail = "Base.UH60MedevacTail", chance = 25 },
	},

	-- Add more helicopter types here
}

-- Tail spawn positions (offset from main crash in tiles)
EHE_HelicopterSwapper.tailOffset = {
	x = 5,  -- 5 tiles away on X axis
	y = 3,  -- 3 tiles away on Y axis
	z = 0   -- Same Z level
}

function EHE_HelicopterSwapper.getRandomVariant(originalName)
	local options = EHE_HelicopterSwapper.swapTable[originalName]
	if not options then return nil end
	
	local roll = ZombRandFloat(0, 100)
	local cumulative = 0
	
	for _, option in ipairs(options) do
		cumulative = cumulative + option.chance
		if roll <= cumulative then
			return option
		end
	end
	
	return nil
end

function EHE_HelicopterSwapper.swapHelicopter(vehicle)
	if not vehicle then return end
	
	local scriptName = vehicle:getScriptName()
	if not scriptName then return end
	
	local variantData = EHE_HelicopterSwapper.getRandomVariant(scriptName)
	if not variantData then return end
	
	if not ScriptManager.instance:getVehicle(variantData.vehicle) then 
		print("ERROR: Helicopter variant not found: " .. variantData.vehicle)
		return 
	end
	
	-- Swap the main helicopter
	vehicle:setScriptName(variantData.vehicle)
	vehicle:scriptReloaded(true)
	
	local skinCount = ScriptManager.instance:getVehicle(variantData.vehicle):getSkinCount()
	if skinCount > 1 then
		vehicle:setSkinIndex(ZombRand(skinCount))
		vehicle:transmitSkinIndex()
	end
	
	print(variantData.vehicle .. " spawned")
	
	-- Spawn matching tail ONLY if defined
	if variantData.tail then
		local square = vehicle:getSquare()
		if square then
			local tailX = square:getX() + EHE_HelicopterSwapper.tailOffset.x
			local tailY = square:getY() + EHE_HelicopterSwapper.tailOffset.y
			local tailZ = square:getZ() + EHE_HelicopterSwapper.tailOffset.z
			
			local tailSquare = getCell():getGridSquare(tailX, tailY, tailZ)
			if tailSquare then
				local tail = addVehicleDebug(variantData.tail, IsoDirections.N, nil, tailSquare)
				if tail then
					print(variantData.tail .. " spawned (matching tail)")
				else
					print("ERROR: Failed to spawn tail: " .. variantData.tail)
				end
			end
		end
	end
end

Events.OnSpawnVehicleStart.Add(EHE_HelicopterSwapper.swapHelicopter)