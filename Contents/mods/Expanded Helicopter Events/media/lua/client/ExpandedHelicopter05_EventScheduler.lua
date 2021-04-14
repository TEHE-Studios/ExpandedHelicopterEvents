eHeliEvent = {}
eHeliEvent.startDay = 0
eHeliEvent.startTime = 0
eHeliEvent.endTime = 0
eHeliEvent.params = {}

eHeliEventsOnSchedule = {}


function eHeliEvent:new(startDay,startTime,endTime,params)

	if (not startDay) or (not startTime) or (not endTime) or (not params) then
		return
	end

	local o = {}
	setmetatable(o, self)
	self.__index = self

	self.startDay = startDay
	self.startTime = startTime
	self.endTime = endTime
	self.params = params

	table.insert(eHeliEventsOnSchedule, o)

	return o
end


function eHeliEvents_OnGameStart()

end

--Events.OnGameStart.Add(eHeliEvents_OnGameStart)
--Events.EveryDays.Add()
--Events.EveryHours.Add()

--GameTime:getNightsSurvived()
--GameTime:getTimeOfDay()

--[[

		---@type eHelicopter heli
		local heli = getFreeHelicopter()
		heli:launch()

--heli start -- if config isn't 1 = never
	this.HelicopterDay1 = Rand.Next(6, 10);
	this.HelicopterTime1Start = Rand.Next(9, 19);
	this.HelicopterTime1End = this.HelicopterTime1Start + Rand.Next(4) + 1;


start time is 9-19
end is 1-5 after start

if it is "sometimes" helis get sent out 10-16 days later
if it is often they're sent 6-10 days later

--Events.OnInitWorld.Add()
--Events.OnNewGame.Add()

--Events.Ontick.Add()
--Events.EveryOneMinute.Add()
--Events.EveryTenMinutes.Add()
--Events.EveryHours.Add()
--Events.EveryDays.Add()

]]