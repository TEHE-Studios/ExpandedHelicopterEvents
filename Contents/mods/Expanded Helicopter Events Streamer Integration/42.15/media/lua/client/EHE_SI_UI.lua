--require "ISUI/ISUIElement"
require "ISUI/ISButton"
require "ExpandedHelicopter12c_EHEGlobalModDataCLIENT"

local SCHEDULER_ICON = {
    TWITCH =    { COLOR = getTexture("media/textures/scheduleButtons/t_color.png"),
                  WHITE = getTexture("media/textures/scheduleButtons/t_w.png"),
                  BLACK = getTexture("media/textures/scheduleButtons/t_b.png"), },
    YOUTUBE =   { COLOR = getTexture("media/textures/scheduleButtons/yt_color.png"),
                  WHITE = getTexture("media/textures/scheduleButtons/yt_w.png"),
                  BLACK = getTexture("media/textures/scheduleButtons/yt_b.png"), },
}

local SCHEDULER_ICONS = {}

for famID,family in pairs(SCHEDULER_ICON) do for colorID,texture in pairs(family) do table.insert(SCHEDULER_ICONS, texture) end end


---@class schedulerButton
schedulerButton = ISButton:derive("schedulerButton")

local currentSchedulerIconIndex = 1
local schedulerButtonUI
local function setUpSchedulerButton(player)
    ---@type schedulerButton|ISButton|ISPanel|ISUIElement
    schedulerButtonUI = schedulerButton:new(-50, -50, 20, 20, player)
end
Events.OnCreatePlayer.Add(setUpSchedulerButton)


function schedulerButton:onMouseUp(x, y)
    currentSchedulerIconIndex = currentSchedulerIconIndex+1
    if currentSchedulerIconIndex > #SCHEDULER_ICONS then currentSchedulerIconIndex = 1 end
end


function schedulerButton:initialise()
    ISButton.initialise(self)
    self:addToUIManager()
    self:setVisible(true)
    --schedulerEvents = {}
end


function schedulerButton:render()
    if self.visible then
        local speedControls = UIManager.getSpeedControls()
        local x = speedControls:getX()-(25)
        local y = speedControls:getY()
        self:setX(x)
        self:setY(y)
        self:drawTexture(SCHEDULER_ICONS[currentSchedulerIconIndex], -6, -6, 1, 1, 1, 1)
        self.tooltip = " No events on schedule. "
        if self:isMouseOver() then
            local playerChar = getPlayer()
            local pUsername = playerChar:getUsername()

            local globalModData = getExpandedHeliEventsModData_Client()
            if globalModData and globalModData.EventsOnSchedule and #globalModData.EventsOnSchedule>0 then
                local newTooltip

                if getDebug() then
                    local GT = getGameTime()
                    local currentDay, currentHour = EHE_getWorldAgeDays(), GT:getHour()
                    newTooltip = "currentDay: "..currentDay.." currentHour:"..currentHour.."\n"
                end

                for k,e in pairs(globalModData.EventsOnSchedule) do
                    if (not e.triggered) and ((e.preset and e.streamerTarget and e.streamerTarget==pUsername and e.startDay and e.startTime) or getDebug()) then
                        newTooltip = (newTooltip or "").." - "..(e.preset).."  Day:"..e.startDay.." Time:"..e.startTime
                        if getDebug() then newTooltip = newTooltip.." t:"..tostring(e.triggered)..(e.streamerTarget and " @"..tostring(e.streamerTarget) or "") end
                        newTooltip = newTooltip.."\n"
                    end
                end
                if newTooltip then self.tooltip = newTooltip end
            end
        end
        ISButton.render(self)
    end
end


function schedulerButton:new(x, y, width, height, player)
    local o = {}
    o = ISButton:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.displayBackground = false
    o.player = player
    o.width = width
    o.height = height
    o.visible = true
    o.title = ""
    o.tooltip = " "
    o.center = false
    o:initialise()
    return o
end