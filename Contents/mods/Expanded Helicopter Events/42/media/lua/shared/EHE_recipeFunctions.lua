local eheFlareSystem = require "EHE_flares.lua"
local ehefillInventoryContainer = require "EHE_fillInventoryContainer.lua"

EHE_Recipe = EHE_Recipe or {}

function EHE_Recipe.dismantleHeliPart(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems()
	local itemContainer = character:getInventory()
	for i=0,items:size() - 1 do
		---@type InventoryItem
		local item = items:get(i)
		if item then
			local i_md = item:getModData().EHE_dismantleResult
			if i_md then
				for entry in i_md:gmatch("[^;]+") do
					local itm, qty = entry:match("([^=]+)=?(%d*)")
					qty = tonumber(qty) or 1
					itemContainer:AddItems(itm, qty)
				end
			end
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
	["Base.FishingRod"] = 3, ["Base.FishingLine"] = 3, ["Base.FishingTackle"] = 3, ["Base.FishingNet"] = 4, }

EHE_Recipe.supplyResults.survivor_canning = {
	["Base.BoxOfJars"] = 2, ["Base.Sugar"] = 1, ["Base.Vinegar"] = 1, }


EHE_Recipe.boxToResults = {}

EHE_Recipe.boxToResults["EHE.EmergencySupplyBox"] = { "FEMA_food", "FEMA_medical", "FEMA_survival" }
EHE_Recipe.boxToResults["EHE.BanditStashBox"] = { "banditStash" }
EHE_Recipe.boxToResults["EHE.SurvivorSupplyBox"] = { "survivor_medical", "survivor_food", "survivor_seeds", "survivor_toilet", "survivor_fishing", "survivor_canning"}


EHE_Recipe.boxToAdditionalFunc = {}

EHE_Recipe.boxToAdditionalFunc["EHE.EmergencySupplyBox"] = "fillBags"
EHE_Recipe.boxToAdditionalFunc["EHE.SurvivorSupplyBox"] = "fillBags"


function EHE_Recipe.fillBags(items, character)
	local first = items:get(0)
	if not instanceof(first, "InventoryContainer") then return end

	for i=0, items:size()-1 do
		local bag = items:get(i)
		if bag then ehefillInventoryContainer.roll(bag, character) end
	end
end


function EHE_Recipe.openSupplyBox(craftRecipeData, character)
	local items = craftRecipeData:getAllConsumedItems()
	local itemContainer = character:getInventory()
	for i=0,items:size() - 1 do
		---@type InventoryItem
		local box = items:get(i)
		if box then

			local i_type = box:getFullType()
			--- rather than have modData entries like with dismantling
			--- we can use a giant if chain like a forefathers' intended o7

			local boxToResults = EHE_Recipe.boxToResults[i_type]
			local results = boxToResults and EHE_Recipe.supplyResults[results]

			for itm,qty in pairs(results) do
				local itms = itemContainer:AddItems(itm, qty)
				local addFunc = EHE_Recipe.boxToAdditionalFunc[i_type]
				if addFunc then addFunc(itms) end
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
		local tags = itemScript:getTags()

		if tags:contains("EHESignalFlare") then
			eheFlareSystem.addFlareType(itemFullName, "EHESignalFlare")
		elseif tags:contains("EHEFlare") then
			eheFlareSystem.addFlareType(itemFullName, "EHEFlare")
		end
	end
end

Events.OnGameBoot.Add(EHE_Recipe.modifyItemScripts)
