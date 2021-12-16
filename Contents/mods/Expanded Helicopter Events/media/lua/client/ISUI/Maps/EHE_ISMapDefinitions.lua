require 'Maps/ISMapDefinitions'

local MINZ = 0
local MAXZ = 24

local function overlayPNG(mapUI, x, y, scale, layerName, tex, alpha)
	local texture = getTexture(tex)
	if not texture then return end
	local mapAPI = mapUI.javaObject:getAPIv1()
	local styleAPI = mapAPI:getStyleAPI()
	local layer = styleAPI:newTextureLayer(layerName)
	layer:setMinZoom(MINZ)
	layer:addFill(MINZ, 255, 255, 255, (alpha or 1.0) * 255)
	layer:addTexture(MINZ, tex)
	layer:setBoundsInSquares(x, y, x + texture:getWidth() * scale, y + texture:getHeight() * scale)
end


LootMaps.Init.EHE_emergencyflyer = function(mapUI)

	-- Your custom initialization for MuldraughMap
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(10000, 10000, 12990, 10480)
	overlayPNG(mapUI, 10524, 9222, 1.0, "lootMapPNG", "media/ui/LootableMaps/emergencyflyer.png", 1.0)

end

LootMaps.Init.EHE_evacuationflyer = function(mapUI)

	-- Your custom initialization for RosewoodMap
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(10000, 10000, 12990, 10480)
	overlayPNG(mapUI, 10524, 9222, 1.0, "lootMapPNG", "media/ui/LootableMaps/evacuationflyer.png", 1.0)

end

LootMaps.Init.EHE_noticeflyer = function(mapUI)

	-- Your custom initialization for RosewoodMap
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(10540, 9240, 12990, 10480)
	overlayPNG(mapUI, 10524, 9222, 1.0, "lootMapPNG", "media/ui/LootableMaps/noticeflyer.png", 1.0)

end


LootMaps.Init.EHE_PAVflyer = function(mapUI)

	-- Your custom initialization for MuldraughMap
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(10540, 9240, 12990, 10480)
	overlayPNG(mapUI, 10524, 9222, 1.0, "lootMapPNG", "media/ui/LootableMaps/PAVflyer.png", 1.0)

end

LootMaps.Init.EHE_quarantineflyer = function(mapUI)

	-- Your custom initialization for RosewoodMap
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(10540, 9240, 12990, 10480)
	overlayPNG(mapUI, 10524, 9222, 1.0, "lootMapPNG", "media/ui/LootableMaps/quarantineflyer.png", 1.0)

end