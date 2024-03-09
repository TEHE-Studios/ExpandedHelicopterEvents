--Overrides vanilla helicopter frequency on game boot
local function HelicopterSandboxOptions(EVENT)
	EVENT = EVENT or "ERROR-NoEventID"
	local text = "EHE: ("..EVENT..")  Disabling vanilla helicopter. Adding items to WorldItemRemovalList."
	SandboxVars.Helicopter = 1

	local gameTime = getGameTime()
	local nightsSurvived = gameTime:getNightsSurvived()
	local currentHelicopterDay = gameTime:getHelicopterDay1()
	local later = math.max(nightsSurvived, currentHelicopterDay) + 6
	gameTime:setHelicopterDay(later)
	gameTime:setHelicopterStartHour(0)
	gameTime:setHelicopterEndHour(0)

	local typesForRemovalList = {"EHE.EvacuationFlyer","EHE.EmergencyFlyer","EHE.QuarantineFlyer","EHE.PreventionFlyer","EHE.NoticeFlyer"}
	for k,type in pairs(typesForRemovalList) do
		if not string.find(SandboxVars.WorldItemRemovalList, type) then
			SandboxVars.WorldItemRemovalList = SandboxVars.WorldItemRemovalList..","..type
		end
	end

	local core = getCore()
	text = text.."\n    GAME-MODE: "..(isIngameState() and "Main-Menu" or core:getGameMode()).."  "..core:getVersion()..(getDebug() and " (DEBUG)" or "")


	local heliValue = SandboxVars.Helicopter
	local day, startHr, endHr = gameTime:getHelicopterDay(), gameTime:getHelicopterStartHour(), gameTime:getHelicopterEndHour()

	if getDebug() then text = text.."\n    DEBUG: Vanilla Helicopter: ("..heliValue..")  day:"..day.." startHr:"..startHr.." endHr"..endHr end

	text = text.."\n    Current Day:"..gameTime:getNightsSurvived().." Hour:"..gameTime:getHour()
	text = text.."\n    EHE-Sandbox Options:"
	for k,v in pairs(SandboxVars.ExpandedHeli) do text = text.."\n       "..tostring(k).." = "..tostring(v) end

	print(text.."\n")
end

--Events.OnGameStart.Add(function() HelicopterSandboxOptions("OnGameStart") end)
Events.OnLoad.Add(function() HelicopterSandboxOptions("OnLoad") end)
if isServer() then Events.OnGameBoot.Add(function() HelicopterSandboxOptions("OnGameBoot") end) end