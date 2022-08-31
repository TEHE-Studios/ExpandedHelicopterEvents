---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
if isServer() then return end -- execute in SP or on Client

local ExpandedHeliEventsModData
--CLIENT_ExpandedHelicopterEvents.EventsOnSchedule = {}
--CLIENT_ExpandedHelicopterEvents.DayOfLastCrash = 0
--CLIENT_ExpandedHelicopterEvents.DaysBeforeApoc = 0

function EHE_copyAgainst(tableA,tableB)
    if not tableA or not tableB then return end
    for key,value in pairs(tableB) do tableA[key] = value end
    for key,_ in pairs(tableA) do if not tableB[key] then tableA[key] = nil end end
end

local function initGlobalModData(isNewGame)

    if isClient() then if ModData.exists("ExpandedHelicopterEvents") then ModData.remove("ExpandedHelicopterEvents") end end

    ExpandedHeliEventsModData = ModData.getOrCreate("ExpandedHelicopterEvents")

    if isNewGame then print("- New Game Initialized!") else print("- Existing Game Initialized!") end
    triggerEvent("EHE_ClientModDataReady", isNewGame)
end
Events.OnInitGlobalModData.Add(initGlobalModData)


---@param name string
---@param data table
local function receiveGlobalModData(name, data)
    print("- Received ModData " .. name)
    if name == "ExpandedHelicopterEvents" then
        EHE_copyAgainst(ExpandedHeliEventsModData,data)
    end
end
Events.OnReceiveGlobalModData.Add(receiveGlobalModData)


function getExpandedHeliEventsModData()
    return ExpandedHeliEventsModData
end