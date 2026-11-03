--- Chuckleberry Finn

require "ISUI/ISInventoryPaneContextMenu"

local clothingInventoryContainerContextFix = {}
function clothingInventoryContainerContextFix.apply(player, context, items)

    local testItem, clothing

    for i,v in ipairs(items) do
        testItem = v
        if not instanceof(v, "InventoryItem") then testItem = v.items[1] end

        if instanceof(testItem, "InventoryContainer") and testItem:canBeEquipped() ~= nil and testItem:canBeEquipped() ~= "" and not testItem:isEquipped() then
            clothing = testItem
        end
    end

    if clothing and
            not context:getOptionFromName(getText("ContextMenu_Wear")) and
            not context:getOptionFromName(getText("ContextMenu_Equip_on_your_Back")) then
        ISInventoryPaneContextMenu.doWearClothingMenu(player, clothing, items, context)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(clothingInventoryContainerContextFix.apply)