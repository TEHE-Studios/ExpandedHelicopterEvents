
local function map_symbol(name)
--- using "extra" prefix and *not* using "media/ui/LootableMaps/" should (sic!) make it compatibile with other map symbol mods, if any, for quite some time
    MapSymbolDefinitions.getInstance():addTexture("extra:" .. name, "media/ui/LootableMaps/" .. name .. ".png")
end

map_symbol("crashedHeli")
map_symbol("airDrop")
