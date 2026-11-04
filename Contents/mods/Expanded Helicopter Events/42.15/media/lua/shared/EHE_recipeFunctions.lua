local eheFlareSystem = require("EHE_flares.lua")
local ehefillInventoryContainer = require("EHE_fillInventoryContainer.lua")
local vehicleDismantle = require("EHE_vehicleDismantle.lua")

EHE_Recipe = EHE_Recipe or {}

local METAL_EFFICIENCY = 0.65

function EHE_Recipe.getTag(id) return ItemTag.get(ResourceLocation.of(id)) end


function EHE_Recipe.createItems(itemType, qty)
    local items = ArrayList.new()
    for i=1, qty do
        local item = instanceItem(itemType)
        if item then items:add(item) end
    end
    return items
end


function EHE_Recipe.giveItems(character, items)
    for i=0, items:size()-1 do Actions.addOrDropItem(character, items:get(i)) end
end


function EHE_Recipe.dismantleHeliPart(craftRecipeData, character)
    local items = craftRecipeData:getAllConsumedItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:hasTag(EHE_Recipe.getTag("ehe:heli_part_metal")) then
            local metalKg = item:getModData().EHE_metalKg or (item:getWeight() * METAL_EFFICIENCY)
            local bars, sheets = vehicleDismantle.metalToItems(metalKg)
            if bars   > 0 then EHE_Recipe.giveItems(character, EHE_Recipe.createItems("Base.MetalBar", bars)) end
            if sheets > 0 then EHE_Recipe.giveItems(character, EHE_Recipe.createItems("Base.SmallSheetMetal", sheets)) end
        end
    end
end


EHE_Recipe.supplyResults = {}

EHE_Recipe.supplyResults.FEMA_food = {
	["Base.WaterRationCan_Box"] = 1, ["Base.CannedFruitCocktail_Box"] = 1, ["Base.CannedCornedBeef_Box"] = 1}

EHE_Recipe.supplyResults.FEMA_medical = {
	["Base.Hat_SurgicalMask"] = 6, ["Base.Gloves_Surgical"] = 6, ["Base.FirstAidKit"] = 1, }

EHE_Recipe.supplyResults.FEMA_survival = {
	["Base.Torch"] = 2, ["Base.Battery"] = 12, ["Base.RadioBlack"] = 2, ["EHE.HandFlare"] = 2, }

EHE_Recipe.supplyResults.banditStash = {
	["Base.Whiskey"] = 2, ["Base.CigaretteCarton"] = 2, ["Base.CigarettePack"] = 5, ["Lighter"] = 2, ["HottieZ"] = 13, }

EHE_Recipe.supplyResults.survivor_medical = {
	["EHE.HandFlare"] = 2, ["Base.Hat_SurgicalMask"] = 2, ["Base.Gloves_Surgical"] = 2, ["Base.FirstAidKit"] = 1, }

EHE_Recipe.supplyResults.survivor_food = {
	["Base.CannedPotato"] = 2, ["Base.CannedCarrots"] = 2, ["Base.CannedCabbage"] = 2,
	["Base.CannedTomato"] = 2, ["Base.CannedBroccoli"] = 2, }

EHE_Recipe.supplyResults.survivor_seeds = {
	["Base.Fertilizer"] = 3, ["Base.CabbageBagSeed2"] = 3, ["Base.PotatoBagSeed2"] = 3, ["Base.BroccoliBagSeed2"] = 3,
	["Base.TomatoBagSeed2"] = 3, ["Base.CarrotBagSeed2"] = 3, }

EHE_Recipe.supplyResults.survivor_toilet = {
	["Base.ToiletPaper"] = 10, }

EHE_Recipe.supplyResults.survivor_fishing = {
	["Base.FishingRod"] = 3, ["Base.FishingLine"] = 3, ["Base.FishingHookBox"] = 3, ["Base.FishingNet"] = 4, }

EHE_Recipe.supplyResults.survivor_canning = {
	["Base.BoxOfJars"] = 2, ["Base.Sugar"] = 1, ["Base.Vinegar_Jug"] = 1, }


EHE_Recipe.supplyResults.airlift_food = {
	["Base.DriedBlackBeans"] = 2, ["Base.DriedLentils"] = 2, ["Base.DriedSplitPeas"] = 2, ["Base.Rice"] = 2,
	["Base.OatsRaw"] = 2, ["Base.CannedMilk_Box"] = 1, ["Base.WaterRationCan_Box"] = 1, }

EHE_Recipe.supplyResults.airlift_farming = {
	["Base.Fertilizer"] = 2, ["Base.GardenHoe"] = 1, ["Base.HandFork"] = 1, ["Base.WateredCan"] = 1,
	["Base.CornBagSeed"] = 3, ["Base.WheatBagSeed"] = 3, ["Base.PotatoBagSeed2"] = 3, ["Base.CarrotBagSeed2"] = 3, }

EHE_Recipe.supplyResults.airlift_metalworking = {
	["Base.SheetMetal"] = 2, ["Base.SmallSheetMetal"] = 6, ["Base.MetalBar"] = 4, ["Base.WeldingRods"] = 2, ["Base.BlowTorch"] = 1, }

EHE_Recipe.supplyResults.airlift_construction = {
	["Base.NailsBox"] = 2, ["Base.ScrewsBox"] = 2, ["Base.Hammer"] = 1, ["Base.Saw"] = 1,
	["Base.DuctTape"] = 2, ["Base.Glue"] = 2, ["Base.Rope"] = 2, }

EHE_Recipe.supplyResults.airlift_medical = {
	["Base.FirstAidKit_Military"] = 1, ["Base.AntibioticsBox"] = 1, ["Base.BandageBox"] = 2, ["Base.PillsVitamins"] = 2, ["Base.Disinfectant"] = 1, }


EHE_Recipe.boxToResults = {}

EHE_Recipe.boxToResults["EHE.EmergencySupplyBox"] = { "FEMA_food", "FEMA_medical", "FEMA_survival" }
EHE_Recipe.boxToResults["EHE.BanditStashBox"] = { "banditStash" }
EHE_Recipe.boxToResults["EHE.AirliftSupplyBox"] = { "airlift_food", "airlift_farming", "airlift_metalworking", "airlift_construction", "airlift_medical" }
EHE_Recipe.boxToResults["EHE.SurvivorSupplyBox"] = { "survivor_medical", "survivor_food", "survivor_seeds", "survivor_toilet", "survivor_fishing", "survivor_canning"}


EHE_Recipe.boxToAdditionalFunc = {}

EHE_Recipe.boxToAdditionalFunc["EHE.EmergencySupplyBox"] = "fillBags"
EHE_Recipe.boxToAdditionalFunc["EHE.SurvivorSupplyBox"] = "fillBags"


function EHE_Recipe.fillBags(items, character)
	if items:size() <= 0 then return end
	local first = items:get(0)
	if not instanceof(first, "InventoryContainer") then return end

	for i=0, items:size()-1 do
		local bag = items:get(i)
		if bag then ehefillInventoryContainer.roll(bag, character) end
	end
end


function EHE_Recipe.openSupplyBox(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems()
	for i=0,items:size() - 1 do
		---@type InventoryItem
		local box = items:get(i)
		if box then

			local i_type = box:getFullType()
			--- rather than have modData entries like with dismantling
			--- we can use a giant if chain like a forefathers' intended o7

			local boxToResults = EHE_Recipe.boxToResults[i_type]
			local results = boxToResults and EHE_Recipe.supplyResults[boxToResults[ZombRand(#boxToResults)+1]]

			if results then
				local addFunc = EHE_Recipe.boxToAdditionalFunc[i_type]
				for itm,qty in pairs(results) do
					local itms = EHE_Recipe.createItems(itm, qty)
					if addFunc and EHE_Recipe[addFunc] then EHE_Recipe[addFunc](itms, character) end
					EHE_Recipe.giveItems(character, itms)
				end
			end
		end
	end
end


local ran = false
---Scans through every item, checks for types listed above as well as additional tag checks - avoids redundant tags
function EHE_Recipe.modifyItemScripts()
	if ran then return else ran = true end
	---Adds "CanOpenBoxes" tag to scripts for type
	local allItems = ScriptManager.instance:getAllItems()

	for i=0, allItems:size()-1 do
		---@type Item
		local itemScript = allItems:get(i)
		local itemFullName = itemScript:getFullName()
		if itemScript:hasTag(EHE_Recipe.getTag("ehe:signal_flare")) then
			eheFlareSystem.addFlareType(itemFullName, "EHESignalFlare")
		elseif itemScript:hasTag(EHE_Recipe.getTag("ehe:flare")) then
			eheFlareSystem.addFlareType(itemFullName, "EHEFlare")
		end
	end
end

Events.OnGameBoot.Add(EHE_Recipe.modifyItemScripts)
