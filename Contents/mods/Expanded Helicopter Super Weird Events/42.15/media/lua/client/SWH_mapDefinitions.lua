require 'ISUI/Maps/ISMapDefinitions.lua'

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

local FlyerX1 = 10
local FlyerY1 = 10

local FlyerX2 = 1003
local FlyerY2 = 1255


LootMaps.Init.SWH_Form1040 = function(mapUI)
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(FlyerX1, FlyerY1, FlyerX2, FlyerY2)
	overlayPNG(mapUI, FlyerX1, FlyerY1, 1.0, "lootMapPNG", "media/ui/content/1040form.png", 1.0)
end

LootMaps.Init.SWH_SpiffoInvite = function(mapUI)
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(FlyerX1, FlyerY1, FlyerX2, FlyerY2)
	overlayPNG(mapUI, FlyerX1, FlyerY1, 1.0, "lootMapPNG", "media/ui/content/SpiffoInvite.png", 1.0)
end

LootMaps.Init.SWH_StrangeNewspaper = function(mapUI)
	local mapAPI = mapUI.javaObject:getAPIv1()
	MapUtils.initDirectoryMapData(mapUI, 'media/maps/Muldraugh, KY')
	mapAPI:setBoundsInSquares(FlyerX1, FlyerY1, FlyerX2, FlyerY2)
	overlayPNG(mapUI, FlyerX1, FlyerY1, 1.0, "lootMapPNG", "media/ui/content/StrangeNewspaper.png", 1.0)
end