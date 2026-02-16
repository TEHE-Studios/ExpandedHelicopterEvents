require "radio/ISWeatherChannel"
require "EHE_weatherImpact"

--- "loadThisAfter" was added to fix issues with Save Our Station
Events.OnGameBoot.Add(function() Translator.loadFiles() end)

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
		WeatherChannel.AddFuzz(c, _bc, 6)

		local globalModData = getExpandedHeliEventsModData()
		if globalModData.EventsOnSchedule then
			for _,event in pairs(globalModData.EventsOnSchedule) do
				if (not event.triggered) and (event.startDay <= getGameTime():getNightsSurvived()) then
					--pulls event's info to see if more lines can be added
					local presetID = event.preset

					if eHelicopter_PRESETS[presetID] then

						local radioChatter = eHelicopter_PRESETS[presetID].radioChatter or eHelicopter.radioChatter
						local lineColor = eHelicopter_PRESETS[presetID].markerColor or { r=1.0, g=1.0, b=1.0 }
						local callSigns = eHelicopter_PRESETS[presetID].callsigns
						local callsign = callSigns and callSigns[ZombRand(1,#callSigns)] or "flight"

						linesGoingOut.presetID = {

							line = string.format(getRadioText(radioChatter), callsign),
							color = lineColor,
						}
					end
				end
			end
		end
		
		for _,data in pairs(linesGoingOut) do
			_bc:AddRadioLine(RadioLine.new(data.line, data.color.r, data.color.g, data.color.b))
		end
		WeatherChannel.AddFuzz(c, _bc)
	end
end
