---stores and adds on to functions found in /media/lua/server/radio/ISWeatherChannel.lua
EHE_WeatherChannel_FillBroadcast = WeatherChannel.FillBroadcast

--local function from ISWeatherChannel.lua
local function comp(_str)
	--local radio = getZomboidRadio();
	--return radio:computerize(_str);
	return _str;
end

function WeatherChannel.FillBroadcast(_gametime, _bc)
	--call stored version from above using the same arguments
	EHE_WeatherChannel_FillBroadcast(_gametime, _bc)
	
	local c = { r=1.0, g=1.0, b=1.0 };
	--check if flights would be prevented due to weather
	local willFly,_ = eHeliEvent_weatherImpact()
	if willFly then
		--table of radio lines to send out - given keys to prevent repetitive lines
		local linesGoingOut = {}
		WeatherChannel.AddFuzz(c, _bc, 6);

		for _,event in pairs(getGameTime():getModData()["EventsSchedule"]) do
			if (not event.triggered) and (event.startDay <= getGameTime():getNightsSurvived()) then

				linesGoingOut["airActivity"] = getRadioText("AEBS_Choppah")
				--pulls event's info to see if more lines can be added
				local presetID = event["preset"]
				local eventPreset = eHelicopter_PRESETS[presetID]
				
				if eventPreset then
					local presetDropPackages = eventPreset.dropPackages
					if presetDropPackages then
						linesGoingOut["aidDrop"] = getRadioText("AEBS_SupplyDrop")
					end
				end

			end
		end
		
		for _,line in pairs(linesGoingOut) do
			_bc:AddRadioLine(RadioLine.new(comp(line), c.r, c.g, c.b) )
		end
		WeatherChannel.AddFuzz(c, _bc);
	end
end
