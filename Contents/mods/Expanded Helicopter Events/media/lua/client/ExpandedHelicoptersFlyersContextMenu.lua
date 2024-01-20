local paperContext = {}

paperContext._registeredTypes = {"EHE.EvacuationFlyer", "EHE.PreventionFlyer", "EHE.EmergencyFlyer", "EHE.QuarantineFlyer", "EHE.NoticeFlyer"}

paperContext.registeredTypes = {}
for _,iType in pairs(paperContext._registeredTypes) do paperContext.registeredTypes[iType] = true end

function paperContext.registerType(iType) paperContext.registeredTypes[iType] = true end

---@param context ISContextMenu
function paperContext.addInventoryItemContext(playerID, context, items)
    local playerObj = getSpecificPlayer(playerID)

    for _, v in ipairs(items) do

        ---@type InventoryItem
        local item = v
        local stack
        if not instanceof(v, "InventoryItem") then
            stack = v
            item = v.items[1]
        end

        local isFlyer = paperContext.registeredTypes[item:getFullType()]
        if isFlyer then

            local readOption = context:getOptionFromName(getText("ContextMenu_CheckMap"))
            readOption.name = getText("ContextMenu_Read")
            --context:addOption(getText("ContextMenu_CheckMap"), map, ISInventoryPaneContextMenu.onCheckMap, player);

            local renameOption = context:getOptionFromName(getText("ContextMenu_RenameMap"))
            renameOption.name = getText("ContextMenu_RenameBag")
            --context:addOption(getText("ContextMenu_RenameMap"), map, ISInventoryPaneContextMenu.onRenameMap, player);
        end
        break
    end
end

Events.OnFillInventoryObjectContextMenu.Add(paperContext.addInventoryItemContext)

return paperContext