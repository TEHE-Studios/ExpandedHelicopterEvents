require "Vehicles/ISUI/ISVehicleMenu"
local vehicleDismantle = require("EHE_vehicleDismantle.lua")

local function onDismantle(player, vehicle)
    if luautils.walkAdj(player, vehicle:getSquare()) then
        ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), vehicleDismantle.predicateBlowTorch, true)
        local mask = player:getInventory():getFirstEvalRecurse(vehicleDismantle.predicateWeldingMask)
        if mask then ISInventoryPaneContextMenu.wearItem(mask, player:getPlayerNum()) end
        ISTimedActionQueue.add(EHE_DismantleVehicleAction:new(player, vehicle))
    end
end


local FillMenuOutsideVehicle = ISVehicleMenu.FillMenuOutsideVehicle
function ISVehicleMenu.FillMenuOutsideVehicle(player, context, vehicle, test)
    local result = FillMenuOutsideVehicle(player, context, vehicle, test)
    if not vehicleDismantle.isEligibleVehicle(vehicle) then return result end

    local playerObj = getSpecificPlayer(player)
    local option = context:addOption(getText("ContextMenu_EHE_DismantleWreck"), playerObj, onDismantle, vehicle)
    local toolTip = ISToolTip:new()
    toolTip:initialise()
    toolTip:setVisible(false)
    option.toolTip = toolTip
    toolTip:setName(getText("ContextMenu_EHE_DismantleWreck"))

    local bars, sheets = vehicleDismantle.metalToItems(vehicle:getModData().EHE_metalKg)
    toolTip.description = getItemNameFromFullType("Base.MetalBar").." x"..bars.." <LINE> "..getItemNameFromFullType("Base.SmallSheetMetal").." x"..sheets.." <LINE> "

    if not vehicleDismantle.meetsSkill(playerObj) then
        toolTip.description = toolTip.description.." <LINE> <RGB:1,0,0> "..getText("Tooltip_EHE_NeedWeldingSkill", vehicleDismantle.SKILL_REQ)
        option.notAvailable = true
    end
    if not playerObj:getInventory():containsEvalRecurse(vehicleDismantle.predicateBlowTorch) then
        toolTip.description = toolTip.description.." <LINE> <RGB:1,0,0> "..getText("Tooltip_EHE_NeedTorch")
        option.notAvailable = true
    end
    if not playerObj:getInventory():containsEvalRecurse(vehicleDismantle.predicateWeldingMask) then
        toolTip.description = toolTip.description.." <LINE> <RGB:1,0,0> "..getText("Tooltip_EHE_NeedMask")
        option.notAvailable = true
    end

    return result
end
