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
require "DebugUIs/DebugMenu/ISDebugMenu"

EHE_DebugTests = EHE_DebugTests or {}

EHE_DebugTestWindow = ISPanel:derive("EHE_DebugTestWindow")

function EHE_DebugTestWindow:render()
	ISPanel.render(self)

	local GT = getGameTime()
	local currentDay, currentHour = GT:getNightsSurvived(), GT:getHour()
	local time = "currentDay: "..currentDay.." currentHour:"..currentHour

	self:drawText(time, self.listbox.x+15, self.listbox.y-(self.listbox.fontHgt*1.33), 1,1,1,1, self.listbox.font)

	local globalModData = getExpandedHeliEventsModData_Client()
	if globalModData and globalModData.EventsOnSchedule and #globalModData.EventsOnSchedule>0 then

		if #self.listbox.items < #globalModData.EventsOnSchedule then

			local listHeight = math.min(10,#globalModData.EventsOnSchedule)*self.listbox.fontHgt
			self.listbox:setHeight(listHeight)
			local closeY = self.listbox.y + self.listbox.height + 20
			self:setHeight(closeY+28)
			self.Close:setY(closeY)

			local nextUp = #self.listbox.items+1
			local event = globalModData.EventsOnSchedule[nextUp]

			self.listbox:addItem("["..nextUp.."]", event)
		end
	end
end

function EHE_DebugTestWindow.OnOpenPanel()

	local x = ISDebugMenu.instance:getX()+ISDebugMenu.instance:getWidth()+5
	local y = ISDebugMenu.instance:getY()

	if not EHE_DebugTestWindow.instance then
		EHE_DebugTestWindow.instance = EHE_DebugTestWindow:new(x, y, 550, 200)
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
	local textToDisplay = item.text

	if item.item and type(item.item) == "table" then
		for k,v in pairs(item.item) do textToDisplay = textToDisplay.."  "..k..":"..tostring(v) end
	else
		textToDisplay = textToDisplay .. "ERROR (NIL or NOT A TABLE)"
	end
	self:drawText(textToDisplay, 24, y+(item.height-self.fontHgt)/2, 0.9, 0.9, 0.9, 0.9, self.font)
	y = y + item.height
	return y
end


function EHE_DebugTestWindow:initialise()
	ISPanel.initialise(self)

	local padding = 10
	local yOffset = 8
	local y = padding+5
	local w = self.width/2-(padding*1.5)
	local h = 18

	local numeration = 0
	for title,func in pairs(EHE_DebugTests) do
		numeration = numeration+1
		local evenNumber = (numeration % 2 == 0)
		local newY = 0
		local newX = 0
		if evenNumber then
			newX = self.width - w - padding
			newY = y-h-yOffset
		else
			newX = padding
			newY = y
		end

		if type(func) == "table" then
			EHE_DebugTestWindow.addComboList(self, func, title, newX, newY, w, h)
		else
			EHE_DebugTestWindow.addButton(self, func, title, newX, newY, w, h)
		end
		y = newY+h+yOffset
	end

	local font = UIFont.AutoNormSmall
	local fontHeight = getTextManager():getFontHeight(font)

	local height = fontHeight
	local globalModData = getExpandedHeliEventsModData_Client()
	if globalModData and globalModData.EventsOnSchedule and #globalModData.EventsOnSchedule>0 then
		height = #globalModData.EventsOnSchedule*height
	end

	self.listbox = ISScrollingListBox:new(padding, y+yOffset+(fontHeight*1.33), self.width-(padding*2), height)
	self.listbox:initialise()
	self.listbox.backgroundColor.a = 0.0
	self.listbox.font = font
	self.listbox.fontHgt = fontHeight
	self.listbox.itemheight = fontHeight
	self.listbox.doDrawItem = EHE_DebugTestWindow.drawScrollingListLine
	self:addChild(self.listbox)

	local closeY = self.listbox.y + self.listbox.height + (padding*2)

	EHE_DebugTestWindow.addButton(self, function() self:close() end, "Close", (self.width/2)-(w/2), closeY, w, h)

	self:setHeight(closeY+28)
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
	local btnWidth = (width/2)-2
	local combo = ISComboBox:new(x+btnWidth+4, y, btnWidth, height)
	UIElement:addChild(combo)

	for key,func in pairs(tableOfFunc) do combo:addOptionWithData(key, func) end

	local btn = ISButton:new(x, y, btnWidth, height, title, combo, EHE_DebugTestWindow.comboSelected)
	UIElement:addChild(btn)
end


function EHE_DebugTestWindow:new(x, y, width, height)
	local o = {}
	o = ISPanel:new(x, y, width, height)
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


require "DebugUIs/DebugMenu/ISDebugMenu"
local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons
function ISDebugMenu:setupButtons()
	self:addButtonInfo("EHE Debug Tests", function() EHE_DebugTestWindow.OnOpenPanel() end, "MAIN")
	ISDebugMenu_setupButtons(self)
end