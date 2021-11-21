require "OptionScreens/ServerSettingsScreen"
require "OptionScreens/SandBoxOptions"

eHelicopterSandbox = eHelicopterSandbox or {}
eHelicopterSandbox.config = { debugTests = false, eventMarkersOn = true, resetEvents = false}
---voices added automatically

eHelicopterSandbox.modId = "ExpandedHelicopterEvents" -- needs to the same as in your mod.info
eHelicopterSandbox.name = "Expanded Helicopter Events" -- the name that will be shown in the MOD tab
eHelicopterSandbox.menuSpecificAccess = "mainmenu"

eHelicopterSandbox.menu = {
	sandBoxMovedText = {type = "Text", text = "Configuration options can be found in sandbox options.", r=1, g=0.2, b=0.2, a=0.65, customX=-56}
}



function loadAnnouncersToConfig()

	if eHelicopterSandbox.menu["voiceSpaceB"] then
		eHelicopterSandbox.menu["voiceSpaceB"] = nil
	end

	eHelicopterSandbox.menu["voiceSpaceA"] = {type = "Space"}
	eHelicopterSandbox.menu["voiceTitle"] = {type = "Text", text = "Voice Packs", }

	for k,params in pairs(eHelicopter_announcers) do
		if params.DoNotDisplayOnOptions ~= true then
			eHelicopterSandbox.menu[k] = {type = "Tickbox", title = k, tooltip = "", }
			eHelicopterSandbox.config[k] = eHelicopterSandbox.config[k] or true
		end
	end

	eHelicopterSandbox.menu["voiceSpaceB"] = {type = "Space"}
end

--[[
function loadPresetToConfig()
	eHelicopterSandbox.menu["presetsSpaceA"] = {type = "Space", iteration=2}
	eHelicopterSandbox.menu["presetsTitle"] = {type = "Text", text = "Events"}

	eHelicopterSandbox.menu["presetsSpaceB"] = {type = "Space"}
	eHelicopterSandbox.menu["presetsDefault"] = {type = "Text", text = "Default Values"}
	for var,value in pairs(eHelicopter_initialVars) do
		local varMenuID = "varForDefault"..var
		eHelicopterSandbox.menu[varMenuID] = {type = "Text", text = var.." = "..tostring(value),}
		--eHelicopterSandbox.config[var] = variableValue
	end
	eHelicopterSandbox.menu["presetsSpaceForpresetsDefault"] = {type = "Space", iteration=2}

	eHelicopterSandbox.menu["presetsSpaceC"] = {type = "Space"}
	for presetID,presetVars in pairs(eHelicopter_PRESETS) do
		eHelicopterSandbox.menu[presetID] = {type = "Text", text = presetID}
		for var,value in pairs(presetVars) do
			local varMenuID = "varFor"..presetID..var
			eHelicopterSandbox.menu[varMenuID] = {type = "Text", text = tostring(value),}
			--eHelicopterSandbox.config[var] = variableValue
		end
		local spaceID = "presetsSpaceFor"..presetID
		eHelicopterSandbox.menu[spaceID] = {type = "Space", iteration=2}
	end
	eHelicopterSandbox.menu["presetsSpaceD"] = {type = "Space"}
end
--run on Lua load
loadPresetToConfig()]]


--add buffer space for reset feature
function sandboxOptionsEnd()
	eHelicopterSandbox.menu["resetEventsA"] = nil
	eHelicopterSandbox.menu["resetEventsToolTip"] = nil
	eHelicopterSandbox.menu["resetEvents"] = nil
	eHelicopterSandbox.menu["generalSpaceD"] = nil
	eHelicopterSandbox.menu["eventMarkersOnToolTip"] =  nil
	eHelicopterSandbox.menu["eventMarkersOn"] = nil
	eHelicopterSandbox.menu["generalSpaceE"] = nil
	eHelicopterSandbox.menu["debugTests"] = nil

	eHelicopterSandbox.menu["resetEventsA"] = {type = "Space"}
	eHelicopterSandbox.menu["resetEventsToolTip"] = {type = "Text", text = "Reset scheduled events in case of emergency:", a=0.65, customX=-67}
	eHelicopterSandbox.menu["resetEvents"] = {type = "Tickbox", title = "Reset Events", tooltip = "", }
	eHelicopterSandbox.menu["generalSpaceD"] = {type = "Space"}
	eHelicopterSandbox.menu["eventMarkersOnToolTip"] = {type = "Text", text = "Toggle this on to enable event markers. \nNote: Events markers can be dragged.", a=0.65, customX=-67, }
	eHelicopterSandbox.menu["eventMarkersOn"] = { type = "Tickbox", title = "Event Markers", alwaysAccessible = true}
	eHelicopterSandbox.menu["generalSpaceE"] = {type = "Space"}

	if getDebug() then
		eHelicopterSandbox.menu["debugTests"] = {type = "Tickbox", title = "EHE: Debug Test Suite", tooltip = "", alwaysAccessible = true }
	end
end

EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}
EasyConfig_Chucked.mods[eHelicopterSandbox.modId] = eHelicopterSandbox


--Overrides vanilla helicopter frequency on game boot
---@param hookEvent string optional
function HelicopterSandboxOptions(hookEvent)

	loadAnnouncersToConfig()
	sandboxOptionsEnd()

	print("EHE: "..(hookEvent or "").."Disabling vanilla helicopter Day/StartHour/EndHour/Helicopter.")
	getGameTime():setHelicopterDay(-1)
	getGameTime():setHelicopterStartHour(-1)
	getGameTime():setHelicopterEndHour(-1)
	getSandboxOptions():getOptionByName("Helicopter"):setValue(1) -- 1 = Never
	SandboxVars.Helicopter = 1

	print("EHE: "..(hookEvent or "").."Adding items to WorldItemRemovalList.")
	local typesForRemovalList = {"EHE.EvacuationFlyer","EHE.EmergencyFlyer","EHE.QuarantineFlyer","EHE.PreventionFlyer","EHE.NoticeFlyer"}
	for k,type in pairs(typesForRemovalList) do
		if not string.find(SandboxVars.WorldItemRemovalList, type) then
			SandboxVars.WorldItemRemovalList = SandboxVars.WorldItemRemovalList..","..type
		end
	end
	getSandboxOptions():updateFromLua()
end

Events.OnGameBoot.Add(HelicopterSandboxOptions("OnGameBoot: "))

