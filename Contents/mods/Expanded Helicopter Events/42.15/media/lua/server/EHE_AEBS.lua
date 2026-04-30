require("radio/ISWeatherChannel.lua")
local eHelicopter = require("EHE_mainVariables.lua")
local modData = require("EHE_globalModData.lua")
local util = require("EHE_util.lua")
local presetCore = require("EHE_presetCore.lua")

--- "loadThisAfter" was added to fix issues with Save Our Station
--TODO: CHECK IF THIS IS STILL NEEDED? SOS MIGHT NOT EVEN BE ON B42
Events.OnGameBoot.Add(function() Translator.loadFiles() end)

---stores and adds on to functions found in /media/lua/server/radio/ISWeatherChannel.lua
local EHE_WeatherChannel_FillBroadcast = WeatherChannel.FillBroadcast or nil
function WeatherChannel.FillBroadcast(_gametime, _bc)
	--call stored version from above using the same arguments
	EHE_WeatherChannel_FillBroadcast(_gametime, _bc)
	
	local c = { r=1.0, g=1.0, b=1.0 }
	--check if flights would be prevented due to weather
	local willFly,_ = util.weatherImpact()
	if willFly then
		--table of radio lines to send out - given keys to prevent repetitive lines
		local linesGoingOut = {}
		WeatherChannel.AddFuzz(c, _bc, 6)

		local globalModData = modData.get()
		if globalModData.EventsOnSchedule then
			for _,event in pairs(globalModData.EventsOnSchedule) do
				if (not event.triggered) and (event.startDay <= util.getWorldAgeDays()) then
					--pulls event's info to see if more lines can be added
					local presetID = event.preset
					local preset = presetCore.PRESETS[presetID]
					if preset then

						local radioChatter = preset.radioChatter or eHelicopter.radioChatter
						local lineColor = preset.markerColor or { r=1.0, g=1.0, b=1.0 }
						local callSigns = preset.callsigns
						local callsign = callSigns and callSigns[ZombRand(#callSigns)+1] or "flight"

						linesGoingOut[presetID] = {
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
