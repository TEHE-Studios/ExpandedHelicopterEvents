--- Chuckleberry Finn
-- Adds the context menu for itemContainers than can be worn.
require "ISUI/ISInventoryPaneContextMenu"

local clothingItemContainerContextFix = {}
function clothingItemContainerContextFix.apply(player, context, items)

    local testItem, clothing

    for i,v in ipairs(items) do
        testItem = v
        if not instanceof(v, "InventoryItem") then testItem = v.items[1] end

        if instanceof(testItem, "InventoryContainer") then
            if testItem:canBeEquipped() ~= nil and testItem:canBeEquipped() ~= "" and not testItem:isEquipped() then
                clothing = testItem
            end
        end
    end

    if clothing then ISInventoryPaneContextMenu.doWearClothingMenu(player, clothing, items, context) end
end

Events.OnFillInventoryObjectContextMenu.Add(clothingItemContainerContextFix.apply)