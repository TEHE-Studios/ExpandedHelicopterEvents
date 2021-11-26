require "DebugUIs/DebugMenu/Base/ISDebugSubPanelBase"

---@class ISCustomDebugTestsPanel : ISCustomDebugTestsPanel
ISCustomDebugTestsPanel = ISDebugSubPanelBase:derive("ISCustomDebugTestsPanel")

---Global test list to add onto.
--[[ EXAMPLE
Events.OnGameBoot.Add(function()
	--`LABEL TEXT` represents what will be placed on the button.
	--`FUNCTION` represents a function. Arguments are optional.
	ISCustomDebugTestsPanel.Tests["LABEL TEXT"] = FUNCTION
	ISCustomDebugTestsPanel.Tests["LABEL TEXT"] = FUNCTION
	ISCustomDebugTestsPanel.Tests["LABEL TEXT"] = FUNCTION
end)
--]]

ISCustomDebugTestsPanel.Tests = {}


function ISCustomDebugTestsPanel:initialise()
	ISPanel.initialise(self)

	for title,func in pairs(ISCustomDebugTestsPanel.Tests) do
		self:addButtonInfo(title,func)
	end
end


function ISCustomDebugTestsPanel:addButtonInfo(_title, _command, _marginBot)
	self.buttons = self.buttons or {}
	table.insert(self.buttons, { title = _title, command = _command, marginBot = (_marginBot or 0) })
end


function ISCustomDebugTestsPanel:createChildren()
	ISPanel.createChildren(self)

	local v, obj
	local x = 20
	local y = 5
	local w = self.width-30
	local h = 18
	local margin = 5

	y, obj = ISDebugUtils.addLabel(self,"game_title",x+(w/2),y,"Custom Debug Tests", UIFont.Medium)
	obj.center = true

	if self.buttons then
		for k,v in ipairs(self.buttons)  do

			local evenNumber = (k % 2 == 0)
			local newY = 0
			local newX = 0
			if evenNumber then
				newX = x - 5 + w/2
				newY = y-h
			else
				newX = x
				newY = y+margin
			end

			y, obj = ISDebugUtils.addButton(self,v,newX,newY,(w/2)-20,h,v.title,ISCustomDebugTestsPanel.onClick)
			if (not evenNumber) and v.marginBot and v.marginBot>0 then
				y = y+v.marginBot
			end
		end
	end
	self:setScrollHeight(y+10)
end


function ISCustomDebugTestsPanel:onClick(_button)
	if _button.customData and _button.customData.command then
		local c = _button.customData.command
		c()
	end
end


function ISCustomDebugTestsPanel:prerender()
	ISDebugSubPanelBase.prerender(self)
end

function ISCustomDebugTestsPanel:update()
	ISPanel.update(self)
end


function ISCustomDebugTestsPanel:new(x, y, width, height, doStencil)
	local o = {}
	o = ISDebugSubPanelBase:new(x, y, width, height, doStencil)
	setmetatable(o, self)
	self.__index = self
	return o
end


---Override debug panel
require "DebugUIs/DebugMenu/Base/ISDebugPanelBase"

local stored__ISGeneralDebug_initialise = ISGeneralDebug.initialise
function ISGeneralDebug:initialise()
	stored__ISGeneralDebug_initialise(self)
	self:registerPanel("Debug Tests",ISCustomDebugTestsPanel)
end