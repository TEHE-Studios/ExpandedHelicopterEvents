require "EasyConfigChucked1_Main"

eHelicopterSandbox = eHelicopterSandbox or {}

eHelicopterSandbox.modId = "ExpandedHelicopterEvents" -- needs to the same as in your mod.info
eHelicopterSandbox.menuSpecificAccess = "mainmenu"

eHelicopterSandbox.config = eHelicopterSandbox.config or {}
eHelicopterSandbox.config.eventMarkersOn = true
eHelicopterSandbox.config.resetEvents = false

eHelicopterSandbox.menu = eHelicopterSandbox.menu or {}
eHelicopterSandbox.menu.sandBoxMovedText = {type = "Text", r=1, g=0.2, b=0.2, a=0.65,customX=-56}
---voices added automatically


function loadAnnouncersToConfig()

	if eHelicopterSandbox.menu.voiceSpaceB then
		eHelicopterSandbox.menu.voiceSpaceB = nil
	end

	eHelicopterSandbox.menu.voiceSpaceA = {type = "Space"}
	eHelicopterSandbox.menu.voiceTitle = {type = "Text", }

	for k,params in pairs(eHelicopter_announcers) do
		if params.DoNotDisplayOnOptions ~= true then
			eHelicopterSandbox.menu[k] = {type = "Tickbox", title = k, tooltip = "", noTranslate=true}
			eHelicopterSandbox.config[k] = eHelicopterSandbox.config[k] or true
		end
	end

	eHelicopterSandbox.menu["voiceSpaceB"] = {type = "Space"}
end

--add buffer space for reset feature
function sandboxOptionsEnd()
	eHelicopterSandbox.menu.generalSpaceA = nil
	eHelicopterSandbox.menu.resetEventsToolTip = nil
	eHelicopterSandbox.menu.resetEvents = nil
	eHelicopterSandbox.menu.generalSpaceD = nil
	eHelicopterSandbox.menu.eventMarkersOnToolTip1 =  nil
	eHelicopterSandbox.menu.eventMarkersOnToolTip2 =  nil
	eHelicopterSandbox.menu.eventMarkersOn = nil
	eHelicopterSandbox.menu.generalSpaceE = nil

	eHelicopterSandbox.menu.generalSpaceA = {type = "Space", alwaysAccessible = true}
	eHelicopterSandbox.menu.resetEventsToolTip = {type = "Text", a=0.65, customX=-67}
	eHelicopterSandbox.menu.resetEvents = {type = "Tickbox", tooltip = "", }
	eHelicopterSandbox.menu.generalSpaceD = {type = "Space"}
	eHelicopterSandbox.menu.eventMarkersOnToolTip1 = {type = "Text", a=0.65, customX=-67, alwaysAccessible = true}
	eHelicopterSandbox.menu.eventMarkersOnToolTip2 = {type = "Text", a=0.65, customX=-67, alwaysAccessible = true}
	eHelicopterSandbox.menu.eventMarkersOn = { type = "Tickbox", alwaysAccessible = true}
	eHelicopterSandbox.menu.generalSpaceE = {type = "Space", alwaysAccessible = true}

	loadAnnouncersToConfig()
end

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
EasyConfig_Chucked.mods[eHelicopterSandbox.modId] = eHelicopterSandbox
Events.OnGameBoot.Add(sandboxOptionsEnd)