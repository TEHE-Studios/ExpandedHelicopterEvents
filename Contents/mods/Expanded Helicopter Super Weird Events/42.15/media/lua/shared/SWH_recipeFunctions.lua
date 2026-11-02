require("EHE_recipeFunctions.lua")

EHE_Recipe.supplyResults.spiffoBurgers = { ["Base.MeatPatty"] = 50, }
EHE_Recipe.supplyResults.spiffoMerch = { ["Base.Tshirt_SpiffoDECAL"] = 10, ["Base.Spiffo"] = 6, }
EHE_Recipe.supplyResults.spiffoCostume = { ["Base.SpiffoSuit"] = 1, ["Base.Hat_Spiffo"] = 1, ["Base.SpiffoTail"] = 1, }
EHE_Recipe.supplyResults.icecream = { ["Base.IcecreamMelted"] = 29, }

EHE_Recipe.boxToResults["SWH.SWH_SpiffoBox"] = { "spiffoBurgers", "spiffoMerch", "spiffoCostume" }
EHE_Recipe.boxToResults["SWH.SWH_IceCreamBox"] = { "icecream"}

EHE_Recipe.boxToAdditionalFunc["SWH.SWH_SpiffoBox"] = "ageBurgers"

function EHE_Recipe.ageBurgers(items)
	for i=0, items:size()-1 do
		local meat = items:get(i)
		if meat then meat:setAutoAge() end
	end
end