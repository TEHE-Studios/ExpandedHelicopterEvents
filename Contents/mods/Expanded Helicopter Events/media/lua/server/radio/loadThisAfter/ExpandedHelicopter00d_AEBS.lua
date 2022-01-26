require "radio/ISWeatherChannel"
require "ExpandedHelicopter00f_WeatherImpact"

---stores and adds on to functions found in /media/lua/server/radio/ISWeatherChannel.lua
local EHE_WeatherChannel_FillBroadcast = WeatherChannel.FillBroadcast or nil
function WeatherChannel.FillBroadcast(_gametime, _bc)
	--call stored version from above using the same arguments
	EHE_WeatherChannel_FillBroadcast(_gametime, _bc)
	
	local c = { r=1.0, g=1.0, b=1.0 }
	--check if flights would be prevented due to weather
	local willFly,_ = eHeliEvent_weatherImpact()
	if willFly then
		--table of radio lines to send out - given keys to prevent repetitive lines
		local linesGoingOut = {}
		WeatherChannel.AddFuzz(c, _bc, 6);

		local globalModData = getExpandedHeliEventsModData()
		if globalModData.EventsOnSchedule then
			for _,event in pairs(globalModData.EventsOnSchedule) do
				if (not event.triggered) and (event.startDay <= getGameTime():getNightsSurvived()) then
					--pulls event's info to see if more lines can be added
					local presetID = event.preset
					local radioChatter = eHelicopter.radioChatter
					if eHelicopter_PRESETS[presetID] and eHelicopter_PRESETS[presetID].radioChatter then
						radioChatter = eHelicopter_PRESETS[presetID].radioChatter
					end
					linesGoingOut.presetID = getRadioText(radioChatter)
				end
			end
		end
		
		for _,line in pairs(linesGoingOut) do
			_bc:AddRadioLine(RadioLine.new(line, c.r, c.g, c.b))
		end
		WeatherChannel.AddFuzz(c, _bc);
	end
end
