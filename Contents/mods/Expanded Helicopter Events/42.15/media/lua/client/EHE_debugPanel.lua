if isClient() and not getDebug() then return end

---Global test list to add onto.
--[[ EXAMPLE
Events.OnGameBoot.Add(function()
	--`LABEL TEXT` represents what will be placed on the button.
	--`FUNCTION` represents a function. Arguments are optional.
	EHE_DebugTests["LABEL TEXT"] = FUNCTION
	EHE_DebugTests["LABEL TEXT"] = FUNCTION
	EHE_DebugTests["LABEL TEXT"] = FUNCTION
end)
--]]
require("DebugUIs/DebugMenu/ISDebugMenu.lua")
local util = require("EHE_util.lua")
local clientCommands = require("EHE_onServerToClientCommands.lua")

EHE_DebugTests = EHE_DebugTests or {}
EHE_DebugTestWindow = ISPanel:derive("EHE_DebugTestWindow")

local COLOR_NORMAL = {r=0.90, g=0.90, b=0.90, a=0.90}
local COLOR_TRIGGERED = {r=0.62, g=0.15, b=0.15, a=0.88}

local function buildSortedEntries(events, showTriggered)
	local sorted = {}
	for i = 1, #events do
		local ev = events[i]
		if ev and (showTriggered or not ev.triggered) then
			table.insert(sorted, {idx = i, ev = ev})
		end
	end
	table.sort(sorted, function(a, b)
		local ea, eb = a.ev, b.ev
		if ea.startDay ~= eb.startDay then return ea.startDay < eb.startDay end
		return (ea.startTime or 0) < (eb.startTime or 0)
	end)
	return sorted
end

local function countTriggered(events)
	local n = 0
	for i = 1, #events do if events[i] and events[i].triggered then n = n + 1 end end
	return n
end


function EHE_DebugTestWindow:render()
	ISPanel.render(self)

	local GT = getGameTime()
	local timeStr = string.format("Day: %.2f   Hour: %d", util.getWorldAgeDays(), GT:getHour())
	self:drawText(timeStr, self.listbox.x+15, self.listbox.y-(self.listbox.fontHgt*1.33), 1,1,1,1, self.listbox.font)

	local globalModData = clientCommands.get()
	local events = globalModData and globalModData.EventsOnSchedule
	if not events or #events == 0 then return end

	local totalCount = #events
	local triggeredCount = countTriggered(events)

	if self._lastTotal == totalCount
	and self._lastTriggered == triggeredCount
	and not self._dirty then return end

	self._lastTotal = totalCount
	self._lastTriggered = triggeredCount
	self._dirty = false

	self.listbox.items = {}
	self.listbox.selected = 1

	local sorted = buildSortedEntries(events, CustomDebugPanel.TOGGLE_SHOW_DONE == true)
	for _, entry in ipairs(sorted) do
		self.listbox:addItem("[" .. entry.idx .. "]", entry.ev)
	end

	local rowH = self.listbox.fontHgt
	local listH = math.max(rowH, math.min(10, #sorted) * rowH)
	self.listbox:setHeight(listH)

	local closeY = self.listbox.y + self.listbox.height + 20
	self.Close:setY(closeY)
	self:setHeight(closeY + 28)
end


function EHE_DebugTestWindow.OnOpenPanel()
	local x = ISDebugMenu.instance:getX() + ISDebugMenu.instance:getWidth() + 5
	local y = ISDebugMenu.instance:getY()

	if not EHE_DebugTestWindow.instance then
		EHE_DebugTestWindow.instance = EHE_DebugTestWindow:new(x, y, 600, 200)
		EHE_DebugTestWindow.instance:initialise()
		EHE_DebugTestWindow.instance:addToUIManager()
		EHE_DebugTestWindow.instance:setVisible(true)
		return
	end

	if EHE_DebugTestWindow.instance:getIsVisible() then
		EHE_DebugTestWindow.instance:setVisible(false)
	else
		EHE_DebugTestWindow.instance:setVisible(true)
		EHE_DebugTestWindow.instance:setX(x)
		EHE_DebugTestWindow.instance:setY(y)
	end
end


function EHE_DebugTestWindow:drawScrollingListLine(y, item, alt)
	local ev = item.item
	local col = COLOR_NORMAL
	local text

	if ev and type(ev) == "table" then
		if ev.triggered then col = COLOR_TRIGGERED end
		text = string.format("%s  preset:%-24s  Day:%-6s  Hr:%-3s  done:%s",
			item.text,
			tostring(ev.preset or "?"),
			ev.startDay ~= nil and string.format("%.1f", ev.startDay) or "?",
			tostring(ev.startTime or "?"),
			tostring(ev.triggered or false))
	else
		text = item.text .. "  ERROR (NIL or NOT A TABLE)"
	end

	self:drawText(text, 24, y+(item.height-self.fontHgt)/2, col.r, col.g, col.b, col.a, self.font)
	return y + item.height
end


function EHE_DebugTestWindow:initialise()
	ISPanel.initialise(self)

	local padding = 10
	local yOffset = 8
	local y = padding + 5
	local w = self.width/2 - (padding*1.5)
	local h = 18

	local numeration = 0
	for title, func in pairs(EHE_DebugTests) do
		numeration = numeration + 1
		local evenNumber = (numeration % 2 == 0)
		local newX, newY
		if evenNumber then
			newX = self.width - w - padding
			newY = y - h - yOffset
		else
			newX = padding
			newY = y
		end

		if type(func) == "table" then
			EHE_DebugTestWindow.addComboList(self, func, title, newX, newY, w, h)
		else
			EHE_DebugTestWindow.addButton(self, func, title, newX, newY, w, h)
		end
		y = newY + h + yOffset
	end

	local font = UIFont.AutoNormSmall
	local fontHeight = getTextManager():getFontHeight(font)

	self.listbox = ISScrollingListBox:new(padding, y+yOffset+(fontHeight*1.33), self.width-(padding*2), fontHeight)
	self.listbox:initialise()
	self.listbox.backgroundColor.a = 0.0
	self.listbox.font = font
	self.listbox.fontHgt = fontHeight
	self.listbox.itemheight = fontHeight
	self.listbox.doDrawItem = EHE_DebugTestWindow.drawScrollingListLine
	self:addChild(self.listbox)

	local closeY = self.listbox.y + self.listbox.height + (padding*2)

	EHE_DebugTestWindow.addButton(self, function() self:close() end, "Close", padding, closeY, w, h)

	self._lastTotal = nil
	self._lastTriggered = nil
	self._dirty = false

	self:setHeight(closeY + 28)
end


function EHE_DebugTestWindow.addButton(UIElement, setFunction, title, x, y, width, height)
	local btn = ISButton:new(x, y, width, height, title, nil, setFunction)
	btn.target = btn
	UIElement[title] = btn
	UIElement:addChild(btn)
end

function EHE_DebugTestWindow:comboSelected()
	local selection = self:getSelected()
	local optionData = self:getOptionData(selection)
	optionData()
end

function EHE_DebugTestWindow.addComboList(UIElement, tableOfFunc, title, x, y, width, height)
	local btnWidth = (width/2) - 2
	local combo = ISComboBox:new(x+btnWidth+4, y, btnWidth, height)
	UIElement:addChild(combo)
	for key, func in pairs(tableOfFunc) do combo:addOptionWithData(key, func) end
	local btn = ISButton:new(x, y, btnWidth, height, title, combo, EHE_DebugTestWindow.comboSelected)
	UIElement:addChild(btn)
end

function EHE_DebugTestWindow:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.x = x
	o.y = y
	o.background = true
	o.backgroundColor = {r=0, g=0, b=0, a=0.5}
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
	o.width = width
	o.height = height
	o.anchorLeft = true
	o.anchorRight = false
	o.anchorTop = true
	o.anchorBottom = false
	o.moveWithMouse = true
	return o
end


require("DebugUIs/DebugMenu/ISDebugMenu.lua")
local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons
function ISDebugMenu:setupButtons()
	self:addButtonInfo("EHE Debug Tests", function() EHE_DebugTestWindow.OnOpenPanel() end, "MAIN")
	ISDebugMenu_setupButtons(self)
end
