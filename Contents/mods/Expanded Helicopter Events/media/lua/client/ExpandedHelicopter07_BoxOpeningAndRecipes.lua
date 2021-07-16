EHE_OpenBox = {}

function EHE_OpenBox.CanOpenBoxes(scriptItems)
	scriptItems:addAll(getScriptManager():getItemsTag("CanOpenBoxes"))
end


function EHE_OpenBox.FOOD(recipe, result, player)
	player:getInventory():AddItems("Base.WaterBottleFull", 2)
	player:getInventory():AddItems("Base.TinnedBeans", 1)
	player:getInventory():AddItems("Base.CannedPeas", 1)
	player:getInventory():AddItems("Base.CannedCorn", 1)
	player:getInventory():AddItems("Base.Chocolate", 2)
	player:getInventory():AddItems("Base.Rice", 1)
end

---@param player IsoGameCharacter | IsoMovingObject
function EHE_OpenBox.MEDICAL(recipe, result, player)
	player:getInventory():AddItems("Hat_SurgicalMask_Blue", 6)
	player:getInventory():AddItems("Gloves_Surgical", 6)
	local items = player:getInventory():AddItems("Base.FirstAidKit", 1)

	for i=0, items:size()-1 do
		rollInventoryContainer(items:get(i), player)
	end
end


function EHE_OpenBox.SURVIVAL(recipe, result, player)
	player:getInventory():AddItems("Base.Torch", 2)
	player:getInventory():AddItems("Base.Battery", 12)
	player:getInventory():AddItems("Radio.RadioBlack", 2)
end

function EHE_OpenBox.STASHBOX(recipe, result, player)
	player:getInventory():AddItems("WhiskeyFull", 1)
	player:getInventory():AddItems("Cigarettes", 4)
	player:getInventory():AddItems("Lighter", 2)
	player:getInventory():AddItems("HottieZ", 13)
	player:getInventory():AddItems("EHE.PlentyTee", 5)
	player:getInventory():AddItems("Spiffo", 1)
end

EHE_OpenBox.typesThatCanOpenBoxes = EHE_OpenBox.typesThatCanOpenBoxes or {}

---@param list table of type paths
function EHE_OpenBox.addCanOpenBoxTypes(list)
	for _,type in pairs(list) do
		table.insert(EHE_OpenBox.typesThatCanOpenBoxes, type)
	end
end

---Sub-mod authors will have to use the following function to add more types
EHE_OpenBox.addCanOpenBoxTypes(
		{"Base.Fork","Base.ButterKnife","Base.HuntingKnife","Base.KitchenKnife","Base.Scissors",
		 "Base.RedPen","Base.BluePen","Base.Pen","Base.Pencil","Base.Screwdriver","Base.GardenFork",
		 "Base.Scalpel","Base.LetterOpener","Base.IcePick","Base.BreadKnife","Base.MeatCleaver","Base.FlintKnife",
		 "Base.Machete","Base.Katana","Base.HandAxe","Base.Axe","Base.WoodAxe","Base.HandScythe",})


---Adds "CanOpenBoxes" tag to scripts for type
---@param type string
function EHE_OpenBox.addCanOpenBoxesTag(type)
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

---For each type in EHE_OpenBox.addCanOpenBoxTypes process EHE_OpenBox.addCanOpenBoxesTag(type)
function EHE_OpenBox.addCanOpenBoxesTagToTypesThatCan()
	for _,type in pairs(EHE_OpenBox.typesThatCanOpenBoxes) do
		EHE_OpenBox.addCanOpenBoxesTag(type)
	end
end

Events.OnGameBoot.Add(EHE_OpenBox.addCanOpenBoxesTagToTypesThatCan)
