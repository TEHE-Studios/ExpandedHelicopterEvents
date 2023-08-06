--***********************************************************
--**                made by Tobias F. aka tiba666          **
--***********************************************************

require "TimedActions/ISBaseTimedAction"

ISRemoveDropSupply = ISBaseTimedAction:derive("ISRemoveDropSupply")

function ISRemoveDropSupply:isValid()
	return self.vehicle and not self.vehicle:isRemovedFromWorld();
end

function ISRemoveDropSupply:update()
	self.character:faceThisObject(self.vehicle)
	self.item:setJobDelta(self:getJobDelta())
	self.item:setJobType(getText("ContextMenu_DisassembleDropSupply"))

	if self.sound ~= 0 and not self.character:getEmitter():isPlaying(self.sound) then
		-- need to be Woodwork should be crowbar
		self.sound = self.character:playSound("Hammering")
	end

    self.character:setMetabolicTarget(Metabolics.HeavyWork);
end

function ISRemoveDropSupply:start()
	self.item = self.character:getPrimaryHandItem()
	--find the correct animation and sound. 
	self:setActionAnim("Crowbar")
	self:setOverrideHandModels(self.item, nil)
	self.sound = self.character:playSound("Hammering")
end

function ISRemoveDropSupply:stop()
	if self.item then
		self.item:setJobDelta(0)
	end
	if self.sound ~= 0 then
		self.character:getEmitter():stopSound(self.sound)
	end
	ISBaseTimedAction.stop(self)
end

function ISRemoveDropSupply:perform()
	print("perform")
	if self.sound ~= 0 then
		self.character:getEmitter():stopSound(self.sound)
	end
	
	local totalXp = 5;
	-- maybe more planks and nails items / change drop. 
	for i=1,math.max(5,self.character:getPerkLevel(Perks.Woodwork)) do
		if self:checkAddItem("Plank", 15) then totalXp = totalXp + 2 end;
		if self:checkAddItem("Plank", 15) then totalXp = totalXp + 2 end;
		if self:checkAddItem("Nails", 15) then totalXp = totalXp + 2 end;
	end

	-- drop the supplybox items on the ground. 
	if self.items then
		for i = 1 , #self.items do
			self:dropObj(self.items[i])
		end
	end
	

	self.character:getXp():AddXP(Perks.Woodwork, totalXp);
	sendClientCommand(self.character, "vehicle", "remove", { vehicle = self.vehicle:getId() })
	self.item:setJobDelta(0);
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISRemoveDropSupply:dropObj(item)
    return self.vehicle:getSquare():AddWorldInventoryItem(item, ZombRandFloat(0, 0.9), ZombRandFloat(0, 0.9), 0.0)
end

function ISRemoveDropSupply:checkAddItem(item, baseChance)
	if ZombRand(baseChance-self.character:getPerkLevel(Perks.Woodwork)) == 0 then

		self.vehicle:getSquare():AddWorldInventoryItem(item, ZombRandFloat(0,0.9), ZombRandFloat(0,0.9), 0);
		return true;
	end
	return false;
end

function ISRemoveDropSupply:new(character, vehicle, items)
	print("new")
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.items = items
	o.vehicle = vehicle
	o.maxTime = 300 - (character:getPerkLevel(Perks.Woodwork) * 20);
	if character:isTimedActionInstant() then o.maxTime = 10 end
	return o
end

