---stores and adds on to the functions in /media/lua/server/radio/ISWeatherChannel.lua
local WeatherChannel_FillBroadcast = WeatherChannel.FillBroadcast

--local function from ISWeatherChannel.lua
local function comp(_str)
	--local radio = getZomboidRadio();
	--return radio:computerize(_str);
	return _str;
end

function WeatherChannel.FillBroadcast(_gametime, _bc)

	WeatherChannel_FillBroadcast(_gametime, _bc)

	local c = { r=1.0, g=1.0, b=1.0 };

	local willFly,_ = eHeliEvent_weatherImpact()
	if willFly then
		for _,v in pairs(getGameTime():getModData()["EventsSchedule"]) do
			if (not v.triggered) and (v.startDay <= getGameTime():getNightsSurvived()) then
				WeatherChannel.AddFuzz(c, _bc, 6);
				_bc:AddRadioLine( RadioLine.new(comp(getRadioText("AEBS_Choppah")), c.r, c.g, c.b) );
				break
			end
		end
		WeatherChannel.AddFuzz(c, _bc);
	end
end
