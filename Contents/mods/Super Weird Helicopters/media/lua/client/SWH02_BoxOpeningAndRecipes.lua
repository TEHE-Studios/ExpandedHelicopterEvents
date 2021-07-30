---@param player IsoGameCharacter | IsoMovingObject
function EHE_OpenBox.BURGERBOX(recipe, result, player)
	player:getInventory():AddItems("Base.MeatPatty", 50)
end


function EHE_OpenBox.MERCHBOX(recipe, result, player)
	player:getInventory():AddItems("Base.Tshirt_SpiffoDECAL", 10)
	player:getInventory():AddItems("Base.Spiffo", 20)
end

function EHE_OpenBox.COSTUMEBOX(recipe, result, player)
	player:getInventory():AddItems("Base.SpiffoSuit", 4)
	player:getInventory():AddItems("Base.Hat_Spiffo", 4)
	player:getInventory():AddItems("Base.SpiffoTail", 4)
end

function EHE_OpenBox.COSTUMEBOX(recipe, result, player)
	player:getInventory():AddItems("Base.IceCream", 29)
end

