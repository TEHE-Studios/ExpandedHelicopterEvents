local paperContext = require "EHE_flyersContextMenu.lua"
Events.OnFillInventoryObjectContextMenu.Add(paperContext.addInventoryItemContext)

--[[
---Leaving this for later
local errorMagnifier = require "errorMagnifier_Main"
if errorMagnifier and errorMagnifier.registerDebugReport then
    errorMagnifier.registerDebugReport("ExpandedHelicopterEvents", function()
        return { }
    end, "Expanded Helicopter Events")
end
--]]