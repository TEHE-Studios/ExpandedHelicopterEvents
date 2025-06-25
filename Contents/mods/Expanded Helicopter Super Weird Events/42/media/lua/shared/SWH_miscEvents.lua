---@param heli eHelicopter
function eHelicopter_dropAliensOff(heli)
    if not heli then
        return
    end

    local x, y, z = heli:getXYZAsInt()
    local xOffset = ZombRand(20,35)
    local yOffset = ZombRand(20,35)

    local trueTarget = heli.trueTarget
    if trueTarget then
        local tX, tY = trueTarget:getX(), trueTarget:getY()
        xOffset=math.max(0,xOffset-tX)
        yOffset=math.max(0,yOffset-tY)
    end

    if ZombRand(101) <= 50 then
        xOffset=0-xOffset
    end
    if ZombRand(101) <= 50 then
        yOffset=0-yOffset
    end

    x = x+xOffset
    y = y+yOffset

    --[[DEBUG]] print("SWH: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
    --for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

    eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/aliens.png", 750, x, y, heli.markerColor)
    heli:spawnCrew(x, y, 0)
    heli.addedFunctionsToEvents.OnHover = false
end