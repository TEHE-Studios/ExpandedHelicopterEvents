require "DebugUIs/DebugMenu/Base/ISDebugSubPanelBase"

---@class ISCustomDebugTestsPanel : ISCustomDebugTestsPanel
ISCustomDebugTestsPanel = ISDebugSubPanelBase:derive("ISCustomDebugTestsPanel")

ISCustomDebugTestsPanel.Tests = ISCustomDebugTestsPanel.Tests or {}

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
	local x,y,w,margin = 10,10,self.width-30,5
	y, obj = ISDebugUtils.addLabel(self,"game_title",x+(w/2),y,"Custom Debug Tests", UIFont.Medium)
	obj.center = true
	y = y+10
	local h = 20
	if self.buttons then
		for k,v in ipairs(self.buttons)  do
			y, obj = ISDebugUtils.addButton(self,v,x,y+margin,w,h,v.title,ISCustomDebugTestsPanel.onClick)
			if v.marginBot and v.marginBot>0 then
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


---=-=-=-=-=-==|[ Override debug panel ]|==-=-=-=-=-=---
require "DebugUIs/DebugMenu/Base/ISDebugPanelBase"

local stored__ISGeneralDebug_initialise = ISGeneralDebug.initialise
function ISGeneralDebug:initialise()
	stored__ISGeneralDebug_initialise(self)
	self:registerPanel("Debug Tests",ISCustomDebugTestsPanel)
end