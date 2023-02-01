eheFlares = {}
eheFlares.activeObjects = {}
eheFlares.activeTimes = {}
eheFlares.activeLightSources = {}
eheFlares.activeSoundLoop = {}
eheFlares.Duration = 30
eheFlares.flareTypes = {}

function eheFlares.addFlareType(itemModuleDotType, flareType)
    if not itemModuleDotType or not flareType then return end
    eheFlares.flareTypes[itemModuleDotType] = flareType
end

---@param flareObject InventoryItem|IsoObject
function eheFlares.getFlareWhereContained(flareObject)
    if flareObject and instanceof(flareObject, "InventoryItem") then
        local containing = flareObject:getOutermostContainer()
        if containing then
            return containing:getParent()
        end

        ---@type IsoWorldInventoryObject|IsoObject
        local worldItem = flareObject:getWorldItem()
        if worldItem then
            return worldItem
        end
    end
end

---@param flareObject InventoryItem|IsoObject
function eheFlares.getFlareOuterMostSquare(flareObject)
    local containedIn = eheFlares.getFlareWhereContained(flareObject)
    if containedIn then
        return containedIn:getSquare()
    end
end

LuaEventManager.AddEvent("EHE_OnActivateFlare")

---@param flareObject InventoryItem|IsoObject
function eheFlares.activateFlare(flareObject, duration)
    if not flareObject or not duration or (duration and duration<=0) then return end
    eheFlares.activeObjects[flareObject] = true
    eheFlares.activeTimes[flareObject] = getGameTime():getMinutesStamp()+duration

    triggerEvent("EHE_OnActivateFlare", flareObject)
end


function eheFlares.validateFlares()
    for flareObject,timestamp in pairs(eheFlares.activeTimes) do
        ---@type InventoryItem
        local flare = flareObject
        if flare and timestamp and timestamp > getGameTime():getMinutesStamp() then

            flare:getModData()["flareDuration"] = (timestamp-getGameTime():getMinutesStamp())

            ---@type IsoLightSource|IsoLightSource
            local oldLightSource = eheFlares.activeLightSources[flare]

            ---@type IsoGridSquare
            local flareSquare = eheFlares.getFlareOuterMostSquare(flare)
            if flareSquare then
                eheFlares.activeLightSources[flare] = IsoLightSource.new(flareSquare:getX(), flareSquare:getY(), flareSquare:getZ(), 200, 0, 0, 4)
                getCell():addLamppost(eheFlares.activeLightSources[flare])
                addSound(nil, flareSquare:getX(),flareSquare:getY(), flareSquare:getZ(), 15, 25)

                if not eheFlares.activeSoundLoop[flare] or eheFlares.activeSoundLoop[flare] < getTimeInMillis() then
                    eheFlares.activeSoundLoop[flare] = getTimeInMillis()+800
                    flareSquare:playSound("eheFlare")
                end
            end

            if oldLightSource then
                oldLightSource:setActive(false)
                getCell():removeLamppost(oldLightSource)
            end

        else
            eheFlares.activeObjects[flare] = nil
            eheFlares.activeTimes[flare] = nil
            ---@type IsoLightSource|IsoLightSource
            local lightSource = eheFlares.activeLightSources[flare]
            lightSource:setActive(false)
            getCell():removeLamppost(lightSource)
            flare:getModData()["flareDuration"] = 0
            flare:setCondition(0)
            flare:setName(getText("IGUI_Spent").." "..flare:getScriptItem():getDisplayName())
        end
    end
end
if not isClient() then
    Events.OnTick.Add(eheFlares.validateFlares)
end


---@param player IsoGameCharacter|IsoPlayer|IsoMovingObject
---@param result InventoryItem
function eheFlares.onCreate(recipe, result, player)
    local flare

    for i=0, recipe:size()-1 do
        ---@type InventoryItem
        local item = recipe:get(i)
        if eheFlares.flareTypes[item:getFullType()]=="EHEFlare" then
            flare = item
            item:setName(getText("IGUI_Lit").." "..item:getScriptItem():getDisplayName())
        elseif eheFlares.flareTypes[item:getFullType()]=="EHESignalFlare" then
            item:setCondition(0)
            item:setName(getText("IGUI_Spent").." "..item:getScriptItem():getDisplayName())
            if not player:isOutside() then
                local pSquare = player:getSquare()
                IsoFireManager.StartFire(getCell(), pSquare, true, 5, 20)
            end
        end
    end

    if eheFlares.flareTypes[result:getFullType()]=="EHEFlare" then
        flare = flare or result
        if result==flare then
            player:getInventory():DoRemoveItem(result)
            player:getSquare():AddWorldInventoryItem(result, 0, 0, 0)
        end
    end

    eheFlares.activateFlare(flare, eheFlares.Duration)
end


---@param player IsoGameCharacter | IsoPlayer
---@param item InventoryItem
function eheFlares.onCanPerform(recipe, player, item)
    if item and (not item:isBroken()) and (not eheFlares.activeObjects[item]) then
        return true
    end
    return false
end



eheFlares.scannedObjects = {}
---@param object IsoPlayer|IsoObject|IsoGridSquare|IsoGameCharacter
function eheFlares.scanForActiveFlares(object)
    if not object then return end

    if eheFlares.scannedObjects[object] then return end
    eheFlares.scannedObjects[object] = true

    local items

    if instanceof(object, "IsoGameCharacter") then
        items = object:getInventory():getItems()
    elseif instanceof(object, "IsoGridSquare") then
        items = object:getWorldObjects()
    end

    if items and items:size()>0 then
        for iteration=0, items:size()-1 do
            local item = items:get(iteration)

            if item and instanceof(item, "IsoWorldInventoryObject") then
                item = item:getItem()
            end

            if item and instanceof(item, "InventoryItem") then
                local flareDuration = item:getModData()["flareDuration"]
                local flareType = eheFlares.flareTypes[item:getFullType()]
                if item and flareType and (flareType =="EHEFlare") and (not item:isBroken()) and flareDuration and flareDuration>0 then
                    --print(" -- found previously active flare: "..tostring(object).."  durationLeft: "..flareDuration)
                    eheFlares.activateFlare(item, flareDuration)
                end
            end
        end
    end
end
Events.OnPlayerUpdate.Add(eheFlares.scanForActiveFlares)
Events.LoadGridsquare.Add(eheFlares.scanForActiveFlares)