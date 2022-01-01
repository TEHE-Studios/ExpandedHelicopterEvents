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
	player:getInventory():AddItems("EHE.PlentyTee", 5)
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



EHE_Recipe.typesThatCanOpenBoxes = EHE_Recipe.typesThatCanOpenBoxes or {}

---@param list table of type paths
function EHE_Recipe.addCanOpenBoxTypes(list)
	for _,type in pairs(list) do
		table.insert(EHE_Recipe.typesThatCanOpenBoxes, type)
	end
end

---Sub-mod authors will have to use the following function to add more types
EHE_Recipe.addCanOpenBoxTypes(
		{"Base.Fork","Base.ButterKnife","Base.HuntingKnife","Base.KitchenKnife","Base.Scissors",
		 "Base.RedPen","Base.BluePen","Base.Pen","Base.Pencil","Base.Screwdriver","Base.GardenFork",
		 "Base.Scalpel","Base.LetterOpener","Base.IcePick","Base.BreadKnife","Base.MeatCleaver","Base.FlintKnife",
		 "Base.Machete","Base.Katana","Base.HandAxe","Base.Axe","Base.WoodAxe","Base.HandScythe",})


---Adds "CanOpenBoxes" tag to scripts for type
---@param type string
function EHE_Recipe.addCanOpenBoxesTag(type)
	local item = ScriptManager.instance:getItem(type);
	if item then
		local tags = item:getTags()
		local tagString = "CanOpenBoxes"

		for i=0, tags:size()-1 do
			---@type string
			local tag = tags:get(i)
			tagString = tagString..";"..tag
		end

		item:DoParam("Tags = "..tagString);
		print("--AddTag:"..type..": "..tagString);
	end
end

---For each type in EHE_Recipe.addCanOpenBoxTypes process EHE_Recipe.addCanOpenBoxesTag(type)
function EHE_Recipe.addCanOpenBoxesTagToTypesThatCan()
	for _,type in pairs(EHE_Recipe.typesThatCanOpenBoxes) do
		EHE_Recipe.addCanOpenBoxesTag(type)
	end
end

Events.OnGameBoot.Add(EHE_Recipe.addCanOpenBoxesTagToTypesThatCan)
