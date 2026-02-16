---FLARE SYSTEM PROPER
local eheFlareSystem = {}

eheFlareSystem.activeObjects = {}
eheFlareSystem.activeLocations = {}
eheFlareSystem.activeTimes = {}
eheFlareSystem.activeLightSources = {}
eheFlareSystem.activeSoundLoop = {}

eheFlareSystem.Duration = 30

eheFlareSystem.flareTypes = {} --["HandFlare"] = "EHEFlare", ["SignalFlare"] = "EHESignalFlare", }

function eheFlareSystem.getFlareTypes() return eheFlareSystem.flareTypes end
function eheFlareSystem.addFlareType(itemModuleDotType, flareType)
    if not itemModuleDotType or not flareType then return end
    eheFlareSystem.flareTypes[itemModuleDotType] = flareType
end

---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.getFlareWhereContained(flareObject)
    if flareObject and instanceof(flareObject, "InventoryItem") then

        --print("getFlareWhereContained: ")

        local containing = flareObject:getOutermostContainer()
        --print("   -- containing:  "..tostring(containing))
        if containing then return containing:getParent() end


        ---@type IsoWorldInventoryObject|IsoObject
        local worldItem = flareObject:getWorldItem()
        --print("   -- worldItem:  "..tostring(worldItem))
        if worldItem then return worldItem end

        local sentLoc = eheFlareSystem.activeLocations[flareObject:getID()]
        if sentLoc then return getSquare(sentLoc.x,sentLoc.y,sentLoc.z) end
    end
end



---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.getFlareOuterMostSquare(flareObject)
    local containedIn = eheFlareSystem.getFlareWhereContained(flareObject)
    --print("- containedIn: "..tostring(containedIn).."   "..tostring(flareObject))
    if containedIn then
        if instanceof(containedIn, "IsoGridSquare") then return containedIn end
        return containedIn:getSquare()
    end
end


---@param flareObject InventoryItem|IsoObject
function eheFlareSystem.activateFlare(flareObject, duration, location)
    if not flareObject or not duration or (duration and duration<=0) then return end

    flareObject:getModData()["flareDuration"] = duration
    local flareSquare = eheFlareSystem.getFlareOuterMostSquare(flareObject)
    local fSquareXYZ = flareSquare and {x=flareSquare:getX(),y=flareSquare:getY(),z=flareSquare:getZ()}

    if isClient() then
        --print(" -- activateFlare: client   "..tostring(flareObject).."   ID:"..flareObject:getID())
        sendClientCommand("flare","activate", {flare=flareObject, duration=duration, loc=fSquareXYZ})
        return
    end

    --print("flareObject:"..tostring(flareObject).."   ID:"..flareObject:getID().."   duration:"..duration)
    eheFlareSystem.activeObjects[flareObject:getID()] = flareObject
    eheFlareSystem.activeLocations[flareObject:getID()] = location or fSquareXYZ
    eheFlareSystem.activeTimes[flareObject:getID()] = getGameTime():getMinutesStamp()+duration
    triggerEvent("EHE_OnActivateFlare", flareObject)
end


function eheFlareSystem.processLightSource(flare, x, y, z, active)
    if isServer() then return end
    --print("PROCESS LIGHT -- x"..tostring(x)..", y"..tostring(y)..", z"..tostring(z).." = "..tostring(active))

    ---@type IsoLightSource
    local currentLight = eheFlareSystem.activeLightSources[flare:getID()]
    local ignoreUpdate = currentLight and currentLight:getX()==x and currentLight:getY()==y and currentLight:getZ()==z

    if active==true then
        if ignoreUpdate then return end

        eheFlareSystem.activeLightSources[flare:getID()] = IsoLightSource.new(x, y, z, 200, 0, 0, 4)
        --print("activeLightSources ID:"..tostring(eheFlareSystem.activeLightSources[flare:getID()]))
        getCell():addLamppost(eheFlareSystem.activeLightSources[flare:getID()])
    end

    if currentLight then
        currentLight:setActive(false)
        getCell():removeLamppost(currentLight)
    end

    if active==false then
        flare:setCondition(0)
        flare:setName(getText("IGUI_Spent").." "..flare:getScriptItem():getDisplayName())
    end
end


function eheFlareSystem.sendDuration(flare, duration)
    if (not flare) or (not duration) then return end
    flare:getModData()["flareDuration"] = duration
end


---@param flare InventoryItem|IsoObject
function eheFlareSystem.validateFlare(flare, timestamp, location)

    if isClient() then
        if not location then
            local flareSquare = eheFlareSystem.getFlareOuterMostSquare(flare)
            location = flareSquare and {x=flareSquare:getX(),y=flareSquare:getY(),z=flareSquare:getZ()}
        end
        --print(" -- validateFlare: client   "..tostring(flare).."   (ID:"..flare:getID()..")")
        sendClientCommand("flare","validate", {flare=flare, timestamp=timestamp, loc=location})
        return
    end

    --print(" -- flare:"..tostring(flare).."  (ID:"..tostring(flare:getID()).."  "..tostring(timestamp).."  "..getGameTime():getMinutesStamp())

    timestamp = timestamp or eheFlareSystem.activeTimes[flare:getID()]

    if not eheFlareSystem.activeLocations[flare:getID()] then
        local flareDuration = flare:getModData()["flareDuration"]
        eheFlareSystem.activateFlare(flare, flareDuration, location)
        return
    end

    if location then eheFlareSystem.activeLocations[flare:getID()] = location end

    local serverCommandData --={}

    if timestamp > getGameTime():getMinutesStamp() then
        --print(" -- -- flare ts > gTgMS  "..tostring(flare).."  server:"..tostring(isServer()))
        flare:getModData()["flareDuration"] = (timestamp-getGameTime():getMinutesStamp())
        if isServer() then
            serverCommandData = serverCommandData or {}
            serverCommandData.flare = flare
            serverCommandData.duration = flare:getModData()["flareDuration"]
        end

        ---@type IsoGridSquare
        local flareLoc = eheFlareSystem.activeLocations[flare:getID()]
        if flareLoc then

            eheFlareSystem.processLightSource(flare, flareLoc.x, flareLoc.y, flareLoc.z, true)
            addSound(nil, flareLoc.x, flareLoc.y, flareLoc.z, 15, 25)

            serverCommandData = serverCommandData or {}
            serverCommandData.coords = {x=flareLoc.x,y=flareLoc.y,z=flareLoc.z}
            serverCommandData.active = true

            if not eheFlareSystem.activeSoundLoop[flare:getID()] or eheFlareSystem.activeSoundLoop[flare:getID()] < getTimeInMillis() then
                eheFlareSystem.activeSoundLoop[flare:getID()] = getTimeInMillis()+750

                if isServer() then
                    serverCommandData.soundEffect = "eheFlare"
                else
                    local square = getSquare(flareLoc.x, flareLoc.y, flareLoc.z)
                    if square then square:playSound("eheFlare") end
                end
            end
        end

    else
        eheFlareSystem.activeObjects[flare:getID()] = nil
        eheFlareSystem.activeLocations[flare:getID()] = nil
        eheFlareSystem.activeTimes[flare:getID()] = nil
        flare:getModData()["flareDuration"] = 0
        eheFlareSystem.processLightSource(flare, nil, nil, nil, false)
        if isServer() then
            serverCommandData = serverCommandData or {}
            serverCommandData.flare = flare
            serverCommandData.duration = 0
            serverCommandData.coords = {x=nil, y=nil, z=nil}
            serverCommandData.active = false
        end
    end

    if serverCommandData then sendServerCommand("flare", "updateClient", serverCommandData) end
end


function eheFlareSystem.validateFlares()
    for flareID,flare in pairs(eheFlareSystem.activeObjects) do eheFlareSystem.validateFlare(flare, eheFlareSystem.activeTimes[flareID]) end
end

if not isClient() then Events.OnTick.Add(eheFlareSystem.validateFlares) end


eheFlareSystem.scannedObjects = {}
---@param object IsoPlayer|IsoObject|IsoGridSquare|IsoGameCharacter
function eheFlareSystem.scanForActiveFlares(object)
    if not object then return end

    local items

    if instanceof(object, "IsoGameCharacter") then
        items = object:getInventory():getItems()
    elseif instanceof(object, "IsoGridSquare") then
        if eheFlareSystem.scannedObjects[object] then return end
        eheFlareSystem.scannedObjects[object] = true
        items = object:getWorldObjects()
    end

    if items and items:size()>0 then
        for iteration=0, items:size()-1 do
            local item = items:get(iteration)

            if item and instanceof(item, "IsoWorldInventoryObject") then item = item:getItem() end

            if item and instanceof(item, "InventoryItem") then
                --local flareDuration = item:getModData()["flareDuration"]
                local flareType = eheFlareSystem.flareTypes[item:getFullType()]
                if item and flareType and (flareType =="EHEFlare") then
                    if (not item:isBroken()) and item:getModData()["flareLit"] then
                        --print(" ---- validateFlare: "..tostring(item))
                        --eheFlareSystem.activateFlare(item, flareDuration)

                        local flareXYZ = {x=object:getX(),y=object:getY(),z=object:getZ()}
                        eheFlareSystem.validateFlare(item, nil, flareXYZ)--, eheFlareSystem.activeTimes[item])
                    end
                end
            end
        end
    end
end
Events.OnPlayerUpdate.Add(eheFlareSystem.scanForActiveFlares)
Events.LoadGridsquare.Add(eheFlareSystem.scanForActiveFlares)



LuaEventManager.AddEvent("EHE_OnActivateFlare")

---RECIPE STUFF
EHE_Recipe = EHE_Recipe or {}

---@param character IsoGameCharacter|IsoPlayer|IsoMovingObject
function EHE_Recipe.onFlareLight(craftRecipeData, character)
    local flare

    local items = craftRecipeData:getAllConsumedItems()
    for i=0,items:size() - 1 do
        ---@type InventoryItem
        local item = items:get(i)
        if eheFlareSystem.getFlareTypes()[item:getFullType()]=="EHEFlare" then
            flare = item
            item:setName(getText("IGUI_Lit").." "..item:getScriptItem():getDisplayName())

        elseif eheFlareSystem.flareTypes[item:getFullType()]=="EHESignalFlare" then
            item:setCondition(0)
            item:setName(getText("IGUI_Spent").." "..item:getScriptItem():getDisplayName())
            character:getInventory():DoRemoveItem(item)

            local flareCharge = "EHE.FlareCharge"
            character:getSquare():AddWorldInventoryItem(flareCharge, 0, 0, 0)
            flareCharge:getWorldItem():transmitCompleteItemToServer()

            if not character:isOutside() then
                local pSquare = getSquare(character:getX()+ZombRand(-2,2), character:getY()+ZombRand(-2,2), 0)
                if pSquare then
                    IsoFireManager.StartFire(getCell(), pSquare, true, 5, 20)
                end
            end
        end
    end

    flare:getModData()["flareLit"] = true
    eheFlareSystem.activateFlare(flare, eheFlareSystem.Duration)
end


---@param player IsoGameCharacter | IsoPlayer
---@param item InventoryItem
function EHE_Recipe.onCanLightFlare(recipe, player, item)
    if item and (not item:isBroken()) and (not item:getModData()["flareLit"]) then
        return true
    end
    return false
end


return eheFlareSystem