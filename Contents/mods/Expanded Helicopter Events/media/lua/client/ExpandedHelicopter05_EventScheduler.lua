eHeliEvent = {}
eHeliEvent.startDay = 0
eHeliEvent.startTime = 0
eHeliEvent.endTime = 0
eHeliEvent.renew = false
eHeliEvent.triggered = false

eHeliEventsOnSchedule = {}


function eHeliEvent:new(startDay,startTime,endTime,renew)

	if (not startDay) or (not startTime) or (not endTime) then
		return
	end

	local o = {}
	setmetatable(o, self)
	self.__index = self
	self:set(startDay,startTime,endTime,renew)

	table.insert(eHeliEventsOnSchedule, o)

	return o
end


function eHeliEvent:set(startDay,startTime,endTime,renew)
	self.startDay = startDay
	self.startTime = startTime
	self.endTime = endTime
	self.renew = renew
end


function eHeliEvent:engage()
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end
	print("--- eHeliEvent:engage:")
	getFreeHelicopter():launch()
	self.triggered = true
	if self.renew then
		setNextHeliFrom(self)
	end
end


function setNextHeliFrom(lastHeliEvent, heliDay, heliStart, heliEnd)
	print("--- setNextHeliFrom:")
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end
	print("------ freq checks out")

	if not heliDay then
		if lastHeliEvent then
			heliDay = lastHeliEvent.startDay
		else
			heliDay = getGameTime():getDay()
		end
		-- options = Never=0, Once=1, Sometimes=2, Often=3
		if eHelicopterSandbox.config.frequency <= 2 then
			heliDay = heliDay+ZombRand(10, 16)
			-- if frequency is 3 / often
		elseif eHelicopterSandbox.config.frequency == 3 then
			heliDay = heliDay+ZombRand(6, 10)
		end
	end

	if not heliStart then
		--start time is random from hour 9 to 19
		heliStart = ZombRand(9, 19)
	end

	if not heliEnd then
		--end time is start time + 1 to 5 hours
		heliEnd = heliStart+ZombRand(1,5)
	end

	if lastHeliEvent then
		print("--------- eHeliEvent:set")
		lastHeliEvent:set(heliDay, heliStart, heliEnd, lastHeliEvent.renew)
		lastHeliEvent.triggered = false
	else
		print("--------- eHeliEvent:new")
		local renewHeli = true
		if eHelicopterSandbox.config.frequency == 1 then
			renewHeli = false
		end

		eHeliEvent:new(heliDay, heliStart, heliEnd, renewHeli)
	end
end

function eHeliEvents_OnGameStart()
	print("--- eHeliEvents_OnGameStart:")
	if #eHeliEventsOnSchedule < 1 then
		setNextHeliFrom()
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)


function eHeliEvent_Loop()
	print("--- eHeliEvent_Loop: "..#eHeliEventsOnSchedule)
	local DAY = getGameTime():getDay()
	local HOUR = getGameTime():getHour()
	for k,v in pairs(eHeliEventsOnSchedule) do
		print("------ "..k.." startDay:"..tostring(v.startDay).." startTime:"..tostring(v.startTime)..
				" endTime:"..tostring(v.endTime).." renew:"..tostring(v.renew).." triggered:"..tostring(v.triggered))
		if not v.triggered then
			if (v.startDay >= DAY) and (v.startTime >= HOUR) then
				v:engage()
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)