--- This is a LUA translation of the function `rollContainerItem` (found in: \zombie\inventory\ItemPickerJava.java)
--- The function `rollContainerItem` fills an `InventoryContainer` object with items taken from a THashMap version of `Distributions`.
---
--- Reason this was written:
--- Once the game loads up LUA it converts the distribution lists into a THashMap. Trying to utilize THashMap.get() resulted in an error.
--- The function written here uses all of the same variables and logic but instead reads from `Distributions` directly.

--- This was written to fill container items like bags which are created through functions.

---@type string string
local function stringIsNullOrEmpty(text)
	return (text==nil or string.len(text)==0)
end


---@param inventoryContainer InventoryContainer | InventoryItem
---@param player IsoGameCharacter | IsoMovingObject
function rollInventoryContainer(inventoryContainer, player)
	local itemType = inventoryContainer:getType()
	local itemContainer = inventoryContainer:getInventory()
	local itemContainerDistribution = Distributions[1][itemType]

	if not itemContainerDistribution then
		return
	end

	local isoMetaChunk = getWorld():getMetaChunk(player:getX()/10,player:getY()/10)
	local lootZombieIntensity = 0

	if isoMetaChunk then
		lootZombieIntensity = tonumber(isoMetaChunk:getLootZombieIntensity())
	end

	local itemPickerJavaZombieDensityCap = tonumber(tostring(ItemPickerJava.zombieDensityCap))

	if lootZombieIntensity > itemPickerJavaZombieDensityCap then
		lootZombieIntensity = itemPickerJavaZombieDensityCap
	end

	if itemContainerDistribution.ignoreZombieDensity then
		lootZombieIntensity = 0
	end

	local bLucky = false
	local bUnlucky = false

	if player then
		bLucky = player:HasTrait("Lucky")
		bUnlucky = player:HasTrait("Unlucky")
	end

	if itemContainerDistribution.rolls <= 0 then
		return
	end

	for _=1, itemContainerDistribution.rolls do
		for k,v in pairs(itemContainerDistribution.items) do
			if type(v) == "string" then
				local type = v
				local chance = itemContainerDistribution.items[k+1]

				if bLucky then
					chance = chance*1.1
				end

				if bUnlucky then
					chance = chance*0.9
				end

				local lootModifier = ItemPickerJava.getLootModifier(type)

				if ZombRand(10000) <= chance * 100 * lootModifier * lootZombieIntensity * 10 then
					local createdItem = ItemPickerJava.tryAddItemToContainer(itemContainer, type, nil)
					if not createdItem then
						return
					end

					local maxMapIteration = 0
					
					if createdItem:getType()=="Map" and not stringIsNullOrEmpty(createdItem:getMapID()) and itemContainerDistribution.maxMap and itemContainerDistribution.maxMap > 0 then
						local maxMapCount = 0

						for iteration=0, itemContainer:getItems():size() do
							local maxMapItem = itemContainer:getItems():get(iteration)
							if not stringIsNullOrEmpty(maxMapItem:getMap()) then
								maxMapCount = maxMapCount+1
							end
						end

						if maxMapCount > itemContainerDistribution.maxMap then
							itemContainer:Remove(createdItem)
						end
					end

					if itemContainerDistribution.stashChance then
						if itemContainerDistribution.stashChance > 0 and not stringIsNullOrEmpty(createdItem:getMap()) then
							createdItem:setStashChance(itemContainerDistribution.stashChance)
						end
					end
					StashSystem.checkStashItem(createdItem)

					if itemContainer:getType() == "freezer" and instanceof(createdItem, "Food") and createdItem:isFreezing() then
						createdItem:freeze()
					end

					if instanceof(createdItem, "Key") then
						---@type Key
						local createdKey = createdItem
						createdKey:takeKeyId()
						createdKey:setName(getText("IGUI_HouseKey").." "..createdKey:getKeyId())
						if itemContainer:getSourceGrid() ~= nil and
								itemContainer:getSourceGrid():getBuilding() ~= nil and
								itemContainer:getSourceGrid():getBuilding():getDef() ~= nil then
							maxMapIteration = itemContainer:getSourceGrid():getBuilding():getDef():getKeySpawned()
							if maxMapIteration < 2 then
								itemContainer:getSourceGrid():getBuilding():getDef():setKeySpawned(maxMapIteration+1)
							else
								itemContainer:Remove(createdKey)
							end
						end
					end

					if not itemContainer:getType() == "freezer" then
						createdItem:setAutoAge()
					end
				end
			end
		end
	end
end