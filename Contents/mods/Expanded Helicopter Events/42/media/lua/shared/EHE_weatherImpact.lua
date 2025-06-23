---Calculates if a flight should go out and the weather impact on flight safety
---@return boolean, number returns two values: willFly, impactOnFlightSafety
function eHeliEvent_weatherImpact()
	local CM = getClimateManager()

	local willFly = true
	local impactOnFlightSafety = 0

	local wind = CM:getWindIntensity()/2
	local fog = CM:getFogIntensity()/2
	local rain = CM:getRainIntensity()/3
	local snow = CM:getSnowIntensity()/2
	local thunder = CM:getIsThunderStorming()

	if (wind+rain+snow > 1.1) or (fog > 0.33) or (thunder == true) then willFly = false end

	impactOnFlightSafety = math.floor(((wind+rain+snow+fog)/6)+0.5)

	if SandboxVars.ExpandedHeli.WeatherImpactsEvents == false then return true, 0 end

	return willFly, impactOnFlightSafety
end