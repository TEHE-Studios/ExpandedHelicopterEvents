EHE_OpenBox = {}

function EHE_OpenBox.FOOD(recipe, result, player)
	player:getInventory():AddItems("Base.WaterBottleFull", 6)
	player:getInventory():AddItems("Base.Rice", 6)
	player:getInventory():AddItems("Base.TinnedBeans", 6)
end


function EHE_OpenBox.MEDICAL(recipe, result, player)
	player:getInventory():AddItems("Base.FirstAidKit", 2)
	player:getInventory():AddItems("Base.DustMask", 6)
	player:getInventory():AddItems("Base.SurgicalGloves", 12)
end


function EHE_OpenBox.SURVIVAL(recipe, result, player)
	player:getInventory():AddItems("Base.Torch", 2)
	player:getInventory():AddItems("Base.Battery", 10)
	player:getInventory():AddItems("Base.RadioBlack", 2)
end