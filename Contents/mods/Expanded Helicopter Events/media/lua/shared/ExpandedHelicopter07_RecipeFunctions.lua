EHE_Recipe = {}

function EHE_Recipe.CanOpenBoxes(scriptItems)
	scriptItems:addAll(getScriptManager():getItemsTag("CanOpenBoxes"))
end


function EHE_Recipe.FOOD(recipe, result, player)
	player:getInventory():AddItems("EHE.EmergencyWaterRation", 5)
	player:getInventory():AddItems("EHE.MealReadytoEat", 5)
end

---@param player IsoGameCharacter | IsoMovingObject
function EHE_Recipe.MEDICAL(recipe, result, player)
	player:getInventory():AddItems("Hat_SurgicalMask_Blue", 6)
	player:getInventory():AddItems("Gloves_Surgical", 6)
	local items = player:getInventory():AddItems("Base.FirstAidKit", 1)

	for i=0, items:size()-1 do
		rollInventoryContainer(items:get(i), player)
	end
end

function EHE_Recipe.SURVIVAL(recipe, result, player)
	player:getInventory():AddItems("Base.Torch", 2)
	player:getInventory():AddItems("Base.Battery", 12)
	player:getInventory():AddItems("Radio.RadioBlack", 2)
end

function EHE_Recipe.STASHBOX(recipe, result, player)
	player:getInventory():AddItems("WhiskeyFull", 1)
	player:getInventory():AddItems("Cigarettes", 4)
	player:getInventory():AddItems("Lighter", 2)
	player:getInventory():AddItems("HottieZ", 13)
	player:getInventory():AddItems("EHE.ProteinBar", 5)
end

function EHE_Recipe.SURVIVORMEDICAL(recipe, result, player)
	player:getInventory():AddItems("Hat_SurgicalMask_Blue", 2)
	player:getInventory():AddItems("Gloves_Surgical", 2)
	local items = player:getInventory():AddItems("Base.FirstAidKit", 1)

	for i=0, items:size()-1 do
		rollInventoryContainer(items:get(i), player)
	end
end

function EHE_Recipe.SURVIVORFOOD(recipe, result, player)
	player:getInventory():AddItems("CannedPotato", 2)
	player:getInventory():AddItems("CannedCarrots", 2)
	player:getInventory():AddItems("CannedCabbage", 2)
	player:getInventory():AddItems("CannedTomato", 2)
	player:getInventory():AddItems("CannedBroccoli", 2)
end

function EHE_Recipe.SURVIVORSEEDS(recipe, result, player)
	player:getInventory():AddItems("Fertilizer", 3)
	player:getInventory():AddItems("farming.CabbageBagSeed", 3)
	player:getInventory():AddItems("farming.PotatoBagSeed", 3)
	player:getInventory():AddItems("farming.BroccoliBagSeed", 3)
	player:getInventory():AddItems("farming.TomatoBagSeed", 3)
	player:getInventory():AddItems("farming.CarrotBagSeed", 3)
end

function EHE_Recipe.SURVIVORTOILET(recipe, result, player)
	player:getInventory():AddItems("ToiletPaper", 10)
end

function EHE_Recipe.SURVIVORFISHING(recipe, result, player)
	player:getInventory():AddItems("FishingRod", 3)
	player:getInventory():AddItems("FishingLine", 3)
	player:getInventory():AddItems("FishingTackle", 3)
	player:getInventory():AddItems("FishingNet", 4)
end

function EHE_Recipe.SURVIVORCANNING(recipe, result, player)
	player:getInventory():AddItems("BoxOfJars", 2)
	player:getInventory():AddItems("Sugar", 1)
	player:getInventory():AddItems("Vinegar", 1)
end


---Forces a numerically keyed list into a type=true table
---
---Allows for: 'if list[key] == true'
---@param list table of type paths
function EHE_Recipe.convertNumericListToKeyedTable(list,table)
	for _,value in pairs(list) do
		print(" x - "..value)
		table[value]=true
	end
end


EHE_Recipe.typesThatCanOpenBoxes = EHE_Recipe.typesThatCanOpenBoxes or {}
---Sub-mod authors will have to use the following function to add more types
EHE_Recipe.convertNumericListToKeyedTable(
		---List param
		{"Base.IcePick","Base.HandScythe","Base.MeatCleaver","Base.LetterOpener","Base.Katana","Base.Scalpel","Base.GardenFork",}
	---Table param
	,EHE_Recipe.typesThatCanOpenBoxes)


EHE_Recipe.additionalTagChecks = EHE_Recipe.additionalTagChecks or {}
EHE_Recipe.convertNumericListToKeyedTable(
		---List param
		{"Screwdriver","DullKnife","SharpKnife","Write","ChopTree","CutPlant","Scissors","Fork","Spoon"}
	---Table param
	, EHE_Recipe.additionalTagChecks)


---Scans through every item, checks for types listed above as well as additional tag checks - avoids redundant tags
function EHE_Recipe.addCanOpenBoxesTagToTypesThatCan()
	---Adds "CanOpenBoxes" tag to scripts for type
	local allItems = ScriptManager.instance:getAllItems()
	for i=0, allItems:size()-1 do

		---@type Item
		local itemScript = allItems:get(i)
		local itemFullName = itemScript:getFullName()
		local tags = itemScript:getTags()
		local addCanOpenBoxesTag = EHE_Recipe.typesThatCanOpenBoxes[itemFullName]
		local tagString = ""
		for i=0, tags:size()-1 do
			---@type string
			local tag = tags:get(i)
			if EHE_Recipe.additionalTagChecks[tag] then
				addCanOpenBoxesTag = true
			end
			tagString = tagString..tag..";"
		end

		if addCanOpenBoxesTag then
			print("EHE: Added Tag 'CanOpenBoxes' to: "..itemFullName)
			itemScript:DoParam("Tags = "..tagString..";CanOpenBoxes");
		end
	end
end

Events.OnGameBoot.Add(EHE_Recipe.addCanOpenBoxesTagToTypesThatCan)
