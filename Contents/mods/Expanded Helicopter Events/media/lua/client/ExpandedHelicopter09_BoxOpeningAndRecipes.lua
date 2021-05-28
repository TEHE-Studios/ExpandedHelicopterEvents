EHE_OpenBox = {}

function EHE_OpenBox.CanOpenBoxes(scriptItems)
	scriptItems:addAll(getScriptManager():getItemsTag("CanOpenBoxes"))
end


function EHE_OpenBox.FOOD(recipe, result, player)
	player:getInventory():AddItems("Base.WaterBottleFull", 20)
	player:getInventory():AddItems("Base.Rice", 10)
	player:getInventory():AddItems("Base.TinnedBeans", 10)
end


function EHE_OpenBox.MEDICAL(recipe, result, player)
	player:getInventory():AddItems("Base.FirstAidKit", 4)
	player:getInventory():AddItems("Hat_DustMask", 6)
	player:getInventory():AddItems("Gloves_Surgical", 12)
end


function EHE_OpenBox.SURVIVAL(recipe, result, player)
	player:getInventory():AddItems("Base.Torch", 2)
	player:getInventory():AddItems("Base.Battery", 10)
	player:getInventory():AddItems("Radio.RadioBlack", 2)

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
		{"Base.HuntingKnife","Base.KitchenKnife","Base.MeatCleaver","Base.FlintKnife","Base.Machete","Base.Katana",
		 "Base.KeyPadlock","Base.CarKey","Base.Key1","Base.Key2","Base.Key3","Base.Key4","Base.Key5"})


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

function EHE_OpenBox.addCanOpenBoxesTagToTypesThatCan()
	for _,type in pairs(EHE_OpenBox.typesThatCanOpenBoxes) do
		EHE_OpenBox.addCanOpenBoxesTag(type)
	end
end

Events.OnGameBoot.Add(EHE_OpenBox.addCanOpenBoxesTagToTypesThatCan)