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

for famID,family in pairs(SCHEDULER_ICON) do
    for colorID,texture in pairs(family) do
        table.insert(SCHEDULER_ICONS, texture)
    end
end


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
                    local currentDay, currentHour = GT:getNightsSurvived(), GT:getHour()
                    newTooltip = "currentDay: "..currentDay.." currentHour:"..currentHour.."\n"
                end

                for k,e in pairs(globalModData.EventsOnSchedule) do
                    if (not e.triggered) and ((e.preset and e.twitchTarget and e.twitchTarget==pUsername and e.startDay and e.startTime) or getDebug()) then
                        newTooltip = (newTooltip or "").." - "..(e.preset).."  Day:"..e.startDay.." Time:"..e.startTime
                        if getDebug() then newTooltip = newTooltip.." t:"..tostring(e.triggered)..(e.twitchTarget and " @"..tostring(e.twitchTarget) or "") end
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



--[[
local function drawDetailsTooltip(tooltip, tooltipStart, skillsRecord, x, y, fontType)
    local lineHeight = getTextManager():getFontFromEnum(fontType):getLineHeight()
    local fnt = {r=0.9, g=0.9, b=0.9, a=1}
    tooltip:drawText(tooltipStart, x, (y+(15-lineHeight)/2), fnt.r, fnt.g, fnt.b, fnt.a, fontType)
    if skillsRecord then
        y=y+(lineHeight*1.5)
        tooltip:drawText(skillsRecord, x+1, (y+(15-lineHeight)/2), fnt.r, fnt.g, fnt.b, fnt.a, fontType)
    end
end

local fontDict = { ["Small"] = UIFont.NewSmall, ["Medium"] = UIFont.NewMedium, ["Large"] = UIFont.NewLarge, }
local fontBounds = { ["Small"] = 28, ["Medium"] = 32, ["Large"] = 42, }

local ISToolTipInv_render = ISToolTipInv.render
function ISToolTipInv.render(self)
    if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then
        local itemObj = self.item
        if itemObj and itemObj:getType() == "SkillRecoveryJournal" then

            local tooltipStart, skillsRecord = SRJ.generateTooltip(itemObj)

            local font = getCore():getOptionTooltipFont()
            local fontType = fontDict[font] or UIFont.Medium
            local textWidth = math.max(getTextManager():MeasureStringX(fontType, tooltipStart),getTextManager():MeasureStringX(fontType, skillsRecord))
            local textHeight = getTextManager():MeasureStringY(fontType, tooltipStart)

            if skillsRecord then textHeight=textHeight+getTextManager():MeasureStringY(fontType, skillsRecord)+8 end

            local journalTooltipWidth = textWidth+fontBounds[font]
            ISToolTipInv_render_Override(self,journalTooltipWidth)

            local tooltipY = self.tooltip:getHeight()-1

            self:setX(self.tooltip:getX() - 11)
            if self.x > 1 and self.y > 1 then
                local yoff = tooltipY + 8
                local bgColor = self.backgroundColor
                local bdrColor = self.borderColor

                self:drawRect(0, tooltipY, journalTooltipWidth, textHeight + 8, math.min(1,bgColor.a+0.4), bgColor.r, bgColor.g, bgColor.b)
                self:drawRectBorder(0, tooltipY, journalTooltipWidth, textHeight + 8, bdrColor.a, bdrColor.r, bdrColor.g, bdrColor.b)
                drawDetailsTooltip(self, tooltipStart, skillsRecord, 15, yoff, fontType)
                yoff = yoff + 12
            end
        else
            ISToolTipInv_render(self)
        end
    end
end
--]]