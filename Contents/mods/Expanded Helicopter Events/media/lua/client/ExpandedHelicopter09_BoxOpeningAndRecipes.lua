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


EHE_OpenBox.typesThatCanOpenBoxes = {
	"HuntingKnife","KitchenKnife","MeatCleaver","FlintKnife","Machete","Katana",
	"KeyPadlock","CarKey","Key1","Key2","Key3","Key4","Key5"
	}

function EHE_OpenBox.addCanOpenBoxesTag(type, module)
	module = module or "Base."
	local item = ScriptManager.instance:getItem(module..type);
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