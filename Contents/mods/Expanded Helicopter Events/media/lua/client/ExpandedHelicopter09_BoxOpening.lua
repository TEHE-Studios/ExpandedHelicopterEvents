EHE_OpenBox = {}

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