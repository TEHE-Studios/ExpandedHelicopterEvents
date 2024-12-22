local eheFlareSystem = require "ExpandedHelicopter_Flares"

EHE_Recipe = EHE_Recipe or {}

function EHE_Recipe.CanOpenBoxes(scriptItems)
	scriptItems:addAll(getScriptManager():getItemsTag("CanOpenBoxes"))
end


function EHE_Recipe.FOOD(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("EHE.EmergencyWaterRation", 4)
	itemContainer:AddItems("EHE.MealReadytoEatEHE", 2)
end

---@param player IsoGameCharacter | IsoMovingObject
function EHE_Recipe.MEDICAL(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("Hat_SurgicalMask_Blue", 6)
	itemContainer:AddItems("Gloves_Surgical", 6)
	local medKit = itemContainer:AddItem("Base.FirstAidKit")
	if medKit then rollInventoryContainer(medKit, player) end
end

function EHE_Recipe.SURVIVAL(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("Base.Torch", 2)
	itemContainer:AddItems("Base.Battery", 12)
	itemContainer:AddItems("Radio.RadioBlack", 2)
	itemContainer:AddItems("EHE.HandFlare", 2)
end

function EHE_Recipe.STASHBOX(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItem("WhiskeyFull")
	itemContainer:AddItems("Cigarettes", 4)
	itemContainer:AddItems("Lighter", 2)
	itemContainer:AddItems("HottieZ", 13)
end

function EHE_Recipe.SURVIVORMEDICAL(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("EHE.HandFlare", 2)
	itemContainer:AddItems("Hat_SurgicalMask_Blue", 2)
	itemContainer:AddItems("Gloves_Surgical", 2)
	local medKit = itemContainer:AddItem("Base.FirstAidKit")
	if medKit then rollInventoryContainer(medKit, player) end
end

function EHE_Recipe.SURVIVORFOOD(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("CannedPotato", 2)
	itemContainer:AddItems("CannedCarrots", 2)
	itemContainer:AddItems("CannedCabbage", 2)
	itemContainer:AddItems("CannedTomato", 2)
	itemContainer:AddItems("CannedBroccoli", 2)
end

function EHE_Recipe.SURVIVORSEEDS(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("Fertilizer", 3)
	itemContainer:AddItems("farming.CabbageBagSeed", 3)
	itemContainer:AddItems("farming.PotatoBagSeed", 3)
	itemContainer:AddItems("farming.BroccoliBagSeed", 3)
	itemContainer:AddItems("farming.TomatoBagSeed", 3)
	itemContainer:AddItems("farming.CarrotBagSeed", 3)
end

function EHE_Recipe.SURVIVORTOILET(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("ToiletPaper", 10)
end

function EHE_Recipe.SURVIVORFISHING(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("FishingRod", 3)
	itemContainer:AddItems("FishingLine", 3)
	itemContainer:AddItems("FishingTackle", 3)
	itemContainer:AddItems("FishingNet", 4)
end

function EHE_Recipe.SURVIVORCANNING(items, result, player)
	local itemContainer = player:getInventory()
	if not itemContainer then return end
	itemContainer:AddItems("BoxOfJars", 2)
	itemContainer:AddItem("Sugar")
	itemContainer:AddItem("Vinegar")
end


---Forces a numerically keyed list into a type=true table, Allows for: 'if list[key] == true' checks.
---@param list table of type paths
function EHE_Recipe.convertNumericListToKeyedTable(list,tbl) for _,value in pairs(list) do tbl[value]=true end end

EHE_Recipe.typesThatCanOpenBoxes = EHE_Recipe.typesThatCanOpenBoxes or {}
---Sub-mod authors will have to use the following function to add more types
EHE_Recipe.convertNumericListToKeyedTable(
	{"Base.IcePick","Base.HandScythe","Base.MeatCleaver","Base.LetterOpener","Base.Katana","Base.Scalpel","Base.GardenFork",}
	,EHE_Recipe.typesThatCanOpenBoxes)

EHE_Recipe.additionalTagChecks = EHE_Recipe.additionalTagChecks or {}
EHE_Recipe.convertNumericListToKeyedTable(
	{"Screwdriver","DullKnife","SharpKnife","Write","ChopTree","CutPlant","Scissors","Fork","Spoon"}
	, EHE_Recipe.additionalTagChecks)


local ran = false
---Scans through every item, checks for types listed above as well as additional tag checks - avoids redundant tags
function EHE_Recipe.addCanOpenBoxesTagToTypesThatCan()
	if ran then return else ran = true end
	---Adds "CanOpenBoxes" tag to scripts for type
	local allItems = ScriptManager.instance:getAllItems()
	local debugText = "EHE: Added Tag 'CanOpenBoxes' to: "

	for i=0, allItems:size()-1 do
		---@type Item
		local itemScript = allItems:get(i)
		local itemFullName = itemScript:getFullName()
		local tags = itemScript:getTags()
		local addCanOpenBoxesTag = EHE_Recipe.typesThatCanOpenBoxes[itemFullName]
		local tagString = ""

		if tags:contains("EHESignalFlare") then
			eheFlareSystem.addFlareType(itemFullName, "EHESignalFlare")
		elseif tags:contains("EHEFlare") then
			eheFlareSystem.addFlareType(itemFullName, "EHEFlare")
		end

		for ii=0, tags:size()-1 do
			---@type string
			local tag = tags:get(ii)

			if EHE_Recipe.additionalTagChecks[tag] then
				addCanOpenBoxesTag = true
			end
			tagString = tagString..tag..";"
		end

		if addCanOpenBoxesTag then
			debugText = debugText..itemFullName..", "
			itemScript:DoParam("Tags = "..tagString..";CanOpenBoxes")
		end
	end
	print(debugText)
end

Events.OnGameBoot.Add(EHE_Recipe.addCanOpenBoxesTagToTypesThatCan)
