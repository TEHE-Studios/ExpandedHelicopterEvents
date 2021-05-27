EHE_OpenBox = {}

function EHE_OpenBox.FOOD(recipe, ingredients, result, player)
	player:getInventory():AddItems("EHE.NoticeFlyer", 6)

end

function EHE_OpenBox.MEDICAL(recipe, ingredients, result, player)
	player:getInventory():AddItems("Base.FirstAidKit", 2)
	
end

function EHE_OpenBox.SURVIVAL(recipe, ingredients, result, player)
	player:getInventory():AddItems("Base.Torch", 2)

end