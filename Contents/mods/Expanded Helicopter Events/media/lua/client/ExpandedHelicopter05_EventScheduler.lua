eHeliEvent = {}
eHeliEvent.startDay = 0
eHeliEvent.startTime = 0
eHeliEvent.endTime = 0
eHeliEvent.renew = false
eHeliEvent.expired = false

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
	print("--- eHeliEvent:engage:")
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end

	local heli = getFreeHelicopter()

	heli:launch()
	if self.renew then
		setNextHeli(self)
	else
		self.expired = true
	end
end


function setNextHeliFrom(lastHeli, heliDay, heliStart, heliEnd)
	print("--- setNextHeliFrom:")
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end
	print("------ freq checks out")

	if not heliDay then
		if lastHeli then
			heliDay = lastHeli.startDay
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

	if lastHeli then
		print("------ eHeliEvent:set")
		lastHeli:set(heliDay, heliStart, heliEnd, lastHeli.renew)
		lastHeli.expired = false
	else
		print("------ eHeliEvent:new")
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
		setNextHeliFrom(nil, 1)
	end
end

Events.OnGameStart.Add(eHeliEvents_OnGameStart)


function eHeliEvent_Loop()
	print("--- eHeliEvent_Loop: "..#eHeliEventsOnSchedule)
	local DAY = getGameTime():getDay()
	local HOUR = getGameTime():getHour()
	for _,v in pairs(eHeliEventsOnSchedule) do
		if not v.expired then
			if (v.startDay == DAY) and (v.startTime == HOUR) then
				v:engage()
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)