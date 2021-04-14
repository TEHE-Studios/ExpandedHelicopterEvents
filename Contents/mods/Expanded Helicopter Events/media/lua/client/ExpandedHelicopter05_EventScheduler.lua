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


function setNextHeliFrom(lastHeli)
	print("--- setNextHeliFrom:")
	if eHelicopterSandbox.config.frequency == 0 then
		return
	end
	print("------ freq checks out")
	local heliDay = 0
	if lastHeli then
		heliDay = lastHeli.startDay
	else
		heliDay = getGameTime():getDay() or 0
	end
	-- if frequency is 2 / sometimes
	if eHelicopterSandbox.config.frequency <= 2 then
		heliDay = heliDay+ZombRand(6,10)
	-- if frequency is 3 / often
	elseif eHelicopterSandbox.config.frequency == 3 then
		heliDay = heliDay+ZombRand(9,19)
	end

	--start time is random from hour 9 to 19
	local heliStart = ZombRand(9, 19)
	--end time is start time + 1 to 5 hours
	local heliEnd = heliStart+ZombRand(1,5)

	if lastHeli then
		print("------ eHeliEvent:set")
		lastHeli:set(heliDay, heliStart, heliEnd, lastHeli.renew)
	else
		print("------ eHeliEvent:new")
		eHeliEvent:new(heliDay, heliStart, heliEnd, true)
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
	for _,v in pairs(eHeliEventsOnSchedule) do
		if not v.expired then
			if (v.startDay == DAY) and (v.startTime == HOUR) then
				v:engage()
			end
		end
	end
end

Events.EveryHours.Add(eHeliEvent_Loop)