require "EHE_recipeFunctions"

---@param player IsoGameCharacter | IsoMovingObject
function EHE_Recipe.BURGERBOX(recipe, result, player)
	local meats = player:getInventory():AddItems("Base.MeatPatty", 50)
	for i=0, meats:size()-1 do
		local meat = meats:get(i)
		if meat then
			meat:setAutoAge()
		end
	end
end


function EHE_Recipe.MERCHBOX(recipe, result, player)
	player:getInventory():AddItems("Base.Tshirt_SpiffoDECAL", 10)
	player:getInventory():AddItems("Base.Spiffo", 20)
end

function EHE_Recipe.COSTUMEBOX(recipe, result, player)
	player:getInventory():AddItems("Base.SpiffoSuit", 4)
	player:getInventory():AddItems("Base.Hat_Spiffo", 4)
	player:getInventory():AddItems("Base.SpiffoTail", 4)
end

function EHE_Recipe.ICECREAMBOX(recipe, result, player)
	player:getInventory():AddItems("Base.IcecreamMelted", 29)
end

