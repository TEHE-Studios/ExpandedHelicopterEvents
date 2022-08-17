---Credit to Konijima (Konijima#9279) for clearing up networking :thumbsup:
if isServer() then return end -- execute in SP or on Client

CLIENT_ExpandedHelicopterEvents = {}
--CLIENT_ExpandedHelicopterEvents.EventsOnSchedule = {}
--CLIENT_ExpandedHelicopterEvents.DayOfLastCrash = 0
--CLIENT_ExpandedHelicopterEvents.DaysBeforeApoc = 0

local function initGlobalModData(isNewGame)

    if isClient() then
        if ModData.exists("ExpandedHelicopterEvents") then ModData.remove("ExpandedHelicopterEvents") end
    end

    CLIENT_ExpandedHelicopterEvents = ModData.getOrCreate("ExpandedHelicopterEvents")

    if isNewGame then print("- New Game Initialized!") else print("- Existing Game Initialized!") end
    triggerEvent("EHE_ClientModDataReady", isNewGame)
end
Events.OnInitGlobalModData.Add(initGlobalModData)

---@param name string
---@param data table
local function receiveGlobalModData(name, data)
    print("- Received ModData " .. name)
    if name == "ExpandedHelicopterEvents" then
        CLIENT_ExpandedHelicopterEvents = copyTable(data)
    end
end
Events.OnReceiveGlobalModData.Add(receiveGlobalModData)