local function printVersionInfo()

    local text = "Expanded Helicopter Events: ver:0.9.2 FEB_04_23"

    local gameTime = getGameTime()
    local heliValue = SandboxVars.Helicopter
    local day, startHr, endHr = gameTime:getHelicopterDay(), gameTime:getHelicopterStartHour(), gameTime:getHelicopterEndHour()
    text = text.."\n\n    DEBUG: Vanilla Helicopter: ("..heliValue..")  day:"..day.." startHr:"..startHr.." endHr"..endHr

    text = text.."\n\n    EHE-Sandbox Options:"
    for k,v in pairs(SandboxVars.ExpandedHeli) do text = text.."\n       "..tostring(k).." = "..tostring(v) end

    print(text.."\n")
end
Events.OnGameBoot.Add(printVersionInfo)
