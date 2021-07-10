SWH_OpenBox = {}

function SWH_OpenBox.CanOpenBoxes(scriptItems)
	scriptItems:addAll(getScriptManager():getItemsTag("CanOpenBoxes"))
end


function SWH_OpenBox.BURGERBOX(recipe, result, player)
	player:getInventory():AddItems("Base.MeatPatty", 50)
end

---@param player IsoGameCharacter | IsoMovingObject

	for i=0, items:size()-1 do
		rollInventoryContainer(items:get(i), player)
	end
end


function SWH_OpenBox.MERCHBOX(recipe, result, player)
	player:getInventory():AddItems("Base.Tshirt_SpiffoDECAL", 10)
	player:getInventory():AddItems("Base.Spiffo", 20)
end

function SWH_OpenBox.COSTUMEBOX(recipe, result, player)
	player:getInventory():AddItems("Base.SpiffoSuit", 4)
	player:getInventory():AddItems("Base.Hat_Spiffo", 4)
	player:getInventory():AddItems("Base.SpiffoTail", 4)
end

SWH_OpenBox.typesThatCanOpenBoxes = SWH_OpenBox.typesThatCanOpenBoxes or {}

---@param list table of type paths
function SWH_OpenBox.addCanOpenBoxTypes(list)
	for _,type in pairs(list) do
		table.insert(SWH_OpenBox.typesThatCanOpenBoxes, type)
	end
end

---Sub-mod authors will have to use the following function to add more types
SWH_OpenBox.addCanOpenBoxTypes(
		{"Base.Fork","Base.ButterKnife","Base.HuntingKnife","Base.KitchenKnife","Base.Scissors",
		 "Base.RedPen","Base.BluePen","Base.Pen","Base.Pencil","Base.Screwdriver","Base.GardenFork",
		 "Base.Scalpel","Base.LetterOpener","Base.IcePick","Base.BreadKnife","Base.MeatCleaver","Base.FlintKnife",
		 "Base.Machete","Base.Katana","Base.HandAxe","Base.Axe","Base.WoodAxe","Base.HandScythe",})


---Adds "CanOpenBoxes" tag to scripts for type
---@param type string
function SWH_OpenBox.addCanOpenBoxesTag(type)
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

---For each type in SWH_OpenBox.addCanOpenBoxTypes process SWH_OpenBox.addCanOpenBoxesTag(type)
function SWH_OpenBox.addCanOpenBoxesTagToTypesThatCan()
	for _,type in pairs(SWH_OpenBox.typesThatCanOpenBoxes) do
		SWH_OpenBox.addCanOpenBoxesTag(type)
	end
end

Events.OnGameBoot.Add(SWH_OpenBox.addCanOpenBoxesTagToTypesThatCan)
