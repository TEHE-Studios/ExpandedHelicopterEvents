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


function EHE_DebugTestWindow:initialise()
	ISPanel.initialise(self)
	--self:instantiate()

	local padding = 10
	local yOffset = 4

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
		EHE_DebugTestWindow.addButton(self, func, title, newX, newY, w, h)
		y = newY+h+yOffset
	end

	local newWindowHeight = y + (padding*2) + h
	self:setHeight( newWindowHeight )

	EHE_DebugTestWindow.addButton(self, function() self:close() end, "Close", (self.width/2)-(w/2), newWindowHeight-padding-h, w, h)


end


function EHE_DebugTestWindow.addButton(UIElement, setFunction, title, x, y, width, height)
	local btn = ISButton:new(x, y, width, height, title, nil, setFunction)
	UIElement:addChild(btn)
end


function EHE_DebugTestWindow:new(x, y, width, height)
	local o = {}
	--o.data = {}
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