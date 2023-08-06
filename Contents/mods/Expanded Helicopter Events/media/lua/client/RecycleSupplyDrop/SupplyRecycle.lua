
--***********************************************************
--**                made by Tobias F. aka tiba666          **
--***********************************************************

require "ISUI/ISModalDialog"
require "luautils"

EME = {}
EME.cheat = false or getDebug()


EME.doTestMenu = function(player, context, worldObjects, test)
	local playerObj = getSpecificPlayer(player)
	local vehicle = playerObj:getVehicle()

	if not vehicle then
			-- for joypad players
			if JoypadState.players[player+1] then
				local px = playerObj:getX()
				local py = playerObj:getY()
				local pz = playerObj:getZ()
				local sqs = {}
				sqs[1] = getCell():getGridSquare(px, py, pz)
				local dir = playerObj:getDir()
				if (dir == IsoDirections.N) then        sqs[2] = getCell():getGridSquare(px-1, py-1, pz); sqs[3] = getCell():getGridSquare(px, py-1, pz);   sqs[4] = getCell():getGridSquare(px+1, py-1, pz);
				elseif (dir == IsoDirections.NE) then   sqs[2] = getCell():getGridSquare(px, py-1, pz);   sqs[3] = getCell():getGridSquare(px+1, py-1, pz); sqs[4] = getCell():getGridSquare(px+1, py, pz);
				elseif (dir == IsoDirections.E) then    sqs[2] = getCell():getGridSquare(px+1, py-1, pz); sqs[3] = getCell():getGridSquare(px+1, py, pz);   sqs[4] = getCell():getGridSquare(px+1, py+1, pz);
				elseif (dir == IsoDirections.SE) then   sqs[2] = getCell():getGridSquare(px+1, py, pz);   sqs[3] = getCell():getGridSquare(px+1, py+1, pz); sqs[4] = getCell():getGridSquare(px, py+1, pz);
				elseif (dir == IsoDirections.S) then    sqs[2] = getCell():getGridSquare(px+1, py+1, pz); sqs[3] = getCell():getGridSquare(px, py+1, pz);   sqs[4] = getCell():getGridSquare(px-1, py+1, pz);
				elseif (dir == IsoDirections.SW) then   sqs[2] = getCell():getGridSquare(px, py+1, pz);   sqs[3] = getCell():getGridSquare(px-1, py+1, pz); sqs[4] = getCell():getGridSquare(px-1, py, pz);
				elseif (dir == IsoDirections.W) then    sqs[2] = getCell():getGridSquare(px-1, py+1, pz); sqs[3] = getCell():getGridSquare(px-1, py, pz);   sqs[4] = getCell():getGridSquare(px-1, py-1, pz);
				elseif (dir == IsoDirections.NW) then   sqs[2] = getCell():getGridSquare(px-1, py, pz);   sqs[3] = getCell():getGridSquare(px-1, py-1, pz); sqs[4] = getCell():getGridSquare(px, py-1, pz);
				end
				for _,sq in ipairs(sqs) do
					vehicle = sq:getVehicleContainer()
					if vehicle then
						return EME.FillMenuOut(player, context, vehicle, test)
					end
				end
				return
			end

			-- for pc players 
			vehicle = IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(), getMouseYScaled())
			if vehicle then
				return EME.FillMenuOut(player, context, vehicle, test)
			end
	end
end

function EME.FillMenuOut(player, context, vehicle, test)
	local playerObj = getSpecificPlayer(player)
	
	--validate if the vehicle container SupplyDrop if ot her mod use the same words in other vehicle it should be remade to vehicle:getScript():getName(), "suvrvileSupplyDrop" or "femaSupplyDrop"
	if string.match(vehicle:getScript():getName(), "SupplyDrop") then 
	local option = context:addOption(getText("disassemble_Drop_Supply"),playerObj, DisassembleDropSupply, vehicle)	
	--local option = context:addOption(getText("disassemble_Drop_Supply"))	
	
	local toolTip = ISToolTip:new()
	toolTip:initialise()
	toolTip:setVisible(false)
	option.toolTip = toolTip
	toolTip:setName(getText("ContextMenu_DisassembleDropSupply"))
	toolTip.description = getText("Tooltip_DisassembleDropSupply") .. " <LINE> <LINE> "
	
	--make the box red if player doesnt have a crowbar in inventory 
	if playerObj:getInventory():containsTypeRecurse("Crowbar") then
		toolTip.description = toolTip.description .. " <LINE> <RGB:1,1,1> " .. getItemNameFromFullType("Base.Crowbar") .. " 1/1"
	else
		toolTip.description = toolTip.description .. " <LINE> <RGB:1,0,0> " .. getItemNameFromFullType("Base.Crowbar") .. " 0/1"
		option.notAvailable = true;
	end		
	end
	
end

--just used to find the crowbar in the chars inventory 
function getCrowbar(item)
	return item:getType() == "Crowbar" 
end

function DisassembleDropSupply(player, vehicle)
	

	if luautils.walkAdj(player, vehicle:getSquare()) then
	local items = {}
	-- partbyindex should always be 0 because it only contain one container in the car. otherwise the logic need to change in a loop under here
	local part = vehicle:getPartByIndex(0)
	local partId = part:getId()
	local partItem = part:getInventoryItem()
		print(partId)
		print("1")
		print(partItem)
		if partItem then
		print("2")
			-- have noticed its called truck id as the cargo so i just check if i get the correct id here for doing a legal actions
			-- i am then adding the items from the cargo to the items list so if i dessable the dropsupply "car" i will force the items in the inventory to be drop on the ground and not delete it
			if partId == "TruckBed" then
			print("3")
			print(part:isContainer())
			print(part:getContainerContentType())
			print("4")
				if part:isContainer() and not part:getContainerContentType() then
					local container = part:getItemContainer()
					print(container)
					for j = 1, container:getItems():size() do
					table.insert(items, container:getItems():get(j - 1))
					end
				end
			end
		end
			
	--equip the crowbar for using it
	ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), getCrowbar , true);
	print("5")
	-- an habit of mine to make everything timed actions queue so i can stack actions on top of eachother.	
    ISTimedActionQueue.add(ISRemoveDropSupply:new(player, vehicle, items))
    
	end
end


Events.OnFillWorldObjectContextMenu.Add(EME.doTestMenu);