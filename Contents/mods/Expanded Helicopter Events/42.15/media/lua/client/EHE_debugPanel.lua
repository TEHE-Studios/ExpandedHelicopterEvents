if isClient() and not getDebug() then return end
if isServer() then return end

local util = require("EHE_util.lua")
local isoRangeScan = require("EHE_IsoRangeScan.lua")
local clientCommands = require("EHE_onServerToClientCommands.lua")
local presetCore = require("EHE_presetCore.lua")

require("DebugUIs/DebugMenu/ISDebugMenu.lua")
local ISDebugMenu_setupButtons = ISDebugMenu.setupButtons
function ISDebugMenu:setupButtons()
	self:addButtonInfo("EHE Debug Tests", function() EHE_DebugTestWindow.OnOpenPanel() end, "MAIN")
	ISDebugMenu_setupButtons(self)
end


function EHE_DebugTestWindow.populateTests()
	EHE_DebugTestWindow.Tests["Toggle All Crash"] = EHE_DebugTestWindow.ToggleAllCrash
	EHE_DebugTestWindow.Tests["Test All Voice Lines"] = EHE_DebugTestWindow.testAllLines
	EHE_DebugTestWindow.Tests["Toggle Move HeliCloser"] = EHE_DebugTestWindow.ToggleMoveHeliCloser
	EHE_DebugTestWindow.Tests["Scheduler Unit Test [LAG]"] = EHE_DebugTestWindow.eHeliEvents_SchedulerUnitTest
	EHE_DebugTestWindow.Tests["ClearGlobalModData"] = EHE_DebugTestWindow.ClearGlobalModData
	EHE_DebugTestWindow.Tests["Copy Schedule to Clipboard"] = EHE_DebugTestWindow.CopySchedule
	EHE_DebugTestWindow.Tests.SandboxVarsDUMP = EHE_DebugTestWindow.SandboxVarsDUMP
	EHE_DebugTestWindow.Tests.TemporaryTest = EHE_DebugTestWindow.TemporaryTest
	EHE_DebugTestWindow.Tests.checkSquare = EHE_DebugTestWindow.checkSquare
	EHE_DebugTestWindow.Tests.printEHEIsoPlayers = EHE_DebugTestWindow.printEHEIsoPlayers
	EHE_DebugTestWindow.Tests["Show Done Events"] = EHE_DebugTestWindow.ToggleShowDone

	EHE_DebugTestWindow.Tests["Launch"] = {}
	for presetID, _ in pairs(presetCore.PRESETS) do
		EHE_DebugTestWindow.Tests["Launch"][presetID] = function() EHE_DebugTestWindow.launchHeliTest(presetID, getPlayer()) end
	end
end
Events.OnGameBoot.Add(EHE_DebugTestWindow.populateTests)


EHE_DebugTestWindow.Tests = {}
EHE_DebugTestWindow = ISPanel:derive("EHE_DebugTestWindow")

EHE_DebugTestWindow.TOGGLE_ALL_CRASH = false
EHE_DebugTestWindow.MOVE_HELI_TEST_CLOSER = false
EHE_DebugTestWindow.TOGGLE_SHOW_DONE = false

EHE_DebugTestWindow.colors = {
	DEFAULT = {r=0, g=0, b=0, a=1.0},
	DEFAULT_HIGHLIGHT = {r=0.3, g=0.3, b=0.3, a=1.0},
	RED = {r=0.5, g=0.0, b=0.0, a=0.9},
	GREEN = {r=0.0, g=0.5, b=0.0, a=0.9},
	RED_HIGHLIGHT = {r=0.75, g=0.0, b=0.0, a=0.9},
	GREEN_HIGHLIGHT = {r=0.0, g=0.75, b=0.0, a=0.9},
}


function EHE_DebugTestWindow:ToggleShowDone()
	if EHE_DebugTestWindow.TOGGLE_SHOW_DONE == true then
		EHE_DebugTestWindow.TOGGLE_SHOW_DONE = false
		self.backgroundColor = EHE_DebugTestWindow.colors.DEFAULT
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.DEFAULT_HIGHLIGHT
	else
		EHE_DebugTestWindow.TOGGLE_SHOW_DONE = true
		self.backgroundColor = EHE_DebugTestWindow.colors.GREEN
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.GREEN_HIGHLIGHT
	end
	self.parent._dirty = true
end

function EHE_DebugTestWindow:ToggleAllCrash()
	if EHE_DebugTestWindow.TOGGLE_ALL_CRASH == true then
		EHE_DebugTestWindow.TOGGLE_ALL_CRASH = false
		self.backgroundColor = EHE_DebugTestWindow.colors.DEFAULT
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.DEFAULT_HIGHLIGHT
	else
		EHE_DebugTestWindow.TOGGLE_ALL_CRASH = true
		self.backgroundColor = EHE_DebugTestWindow.colors.GREEN
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.GREEN_HIGHLIGHT
	end
end

function EHE_DebugTestWindow:ToggleMoveHeliCloser()
	if EHE_DebugTestWindow.MOVE_HELI_TEST_CLOSER == true then
		EHE_DebugTestWindow.MOVE_HELI_TEST_CLOSER = false
		self.backgroundColor = EHE_DebugTestWindow.colors.DEFAULT
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.DEFAULT_HIGHLIGHT
	else
		EHE_DebugTestWindow.MOVE_HELI_TEST_CLOSER = true
		self.backgroundColor = EHE_DebugTestWindow.colors.GREEN
		self.backgroundColorMouseOver = EHE_DebugTestWindow.colors.GREEN_HIGHLIGHT
	end
end


function EHE_DebugTestWindow.TemporaryTest()
end

function EHE_DebugTestWindow.printEHEIsoPlayers()
	print("util.isoPlayers: ")
	for playerObj, _ in pairs(util.isoPlayers) do
		print(" - "..playerObj:getFullName().." - "..playerObj:getUsername())
	end
end

function EHE_DebugTestWindow.SandboxVarsDUMP()
	print(" - SandboxVars:")
	local optionsSize = getSandboxOptions():getNumOptions()
	for i = 1, optionsSize do
		local option = getSandboxOptions():getOptionByIndex(i-1)
		print(" --- "..tostring(option:getShortName()).." ("..tostring(option:getTableName())..")")
	end
end

function EHE_DebugTestWindow.RTP_indent(n)
	local text = ""
	for i = 0, n do text = text.."   " end
	return text
end

function EHE_DebugTestWindow.RecursiveTablePrint(object, nesting, every_other)
	nesting = nesting or 0
	local text = ""..EHE_DebugTestWindow.RTP_indent(nesting)
	if type(object) == "table" then
		local s = "{ \n"
		for k, v in pairs(object) do
			local items_print = k == "items"
			if type(k) ~= "number" then k = '"'..k..'"' end
			if (not every_other) or (every_other and (not (k % 2 == 0))) then
				s = s..EHE_DebugTestWindow.RTP_indent(nesting+1)
			end
			s = s.."["..k.."] = "..EHE_DebugTestWindow.RecursiveTablePrint(v, nesting+1, items_print)..", "
			if (not every_other) or (every_other and (k % 2 == 0)) then s = s.."\n" end
		end
		text = s.."\n"..EHE_DebugTestWindow.RTP_indent(nesting).."}"
	else
		text = tostring(object)
	end
	return text
end

function EHE_DebugTestWindow.checkSquare()
	local player = getSpecificPlayer(0)
	local square = player:getSquare()
	if not square then print("square is null") return end
	print("square:isOutside() : ", square:isOutside())
	print("square:isSolidFloor() : ", square:isSolidFloor())
	print("square:getRoomID()==-1 : ", square:getRoomID()==-1)
	print("square:isSolid() : ", square:isSolid())
	print("square:isSolidTrans() : ", square:isSolidTrans())
	print("square:getZoneType() : ", square:getZoneType())

	local zonePrint = ""
	local zones = getWorld():getMetaGrid():getZonesAt(square:getX(), square:getY(), 0)
	if zones then
		for i = zones:size(), 1, -1 do
			local zone = zones:get(i-1)
			if zone then
				zonePrint = zonePrint..zone:getType().."("..zone:getOriginalName()..")"..", ".."(d:"..zone:getZombieDensity()..")"
			end
		end
	end
	print("ZONE SCAN: ", zonePrint)
end

function EHE_DebugTestWindow.ZombRandTest(imax)
	local results = {}
	for i = 1, imax do
		local testRand = (ZombRand(13)+1)/10
		results[tostring(testRand)] = (results[tostring(testRand)] or 0) + 1
	end
	print("ZombRand:")
	local output = ""
	for k, v in pairs(results) do output = output..k.." ("..v.." times)\n" end
	print(output)
end

function EHE_DebugTestWindow:CopySchedule()
	local finalText = "SCHEDULE:\n"
	local globalModData = clientCommands.get()
	if globalModData and globalModData.EventsOnSchedule and #globalModData.EventsOnSchedule > 0 then
		for i = 1, #globalModData.EventsOnSchedule do
			local event = globalModData.EventsOnSchedule[i]
			finalText = finalText.."["..i.."]"
			for k, v in pairs(event) do finalText = finalText.."  "..k..":"..tostring(v) end
			finalText = finalText.."\n"
		end
	end
	print(finalText)
	Clipboard.setClipboard(finalText)
end

function EHE_DebugTestWindow.launchHeliTest(presetID, player, moveCloser, crashIt)
	moveCloser = moveCloser or EHE_DebugTestWindow.MOVE_HELI_TEST_CLOSER
	crashIt = crashIt or EHE_DebugTestWindow.TOGGLE_ALL_CRASH
	sendClientCommand("CustomDebugPanel", "launchHeliTest", {presetID=presetID, moveCloser=moveCloser, crashIt=crashIt})
end

function EHE_DebugTestWindow.CheckWeather()
	local CM = getClimateManager()
	print("--- CM:getWindIntensity: "..CM:getWindIntensity())
	print("--- CM:getFogIntensity: "..CM:getFogIntensity())
	print("--- CM:getRainIntensity: "..CM:getRainIntensity())
	print("--- CM:getSnowIntensity: "..CM:getSnowIntensity())
	print("--- CM:getIsThunderStorming:(b) "..tostring(CM:getIsThunderStorming()))
	local willFly, impactOnFlightSafety = util.weatherImpact()
	print("--- willFly: "..tostring(willFly).."   % to crash: "..impactOnFlightSafety*100)
end

function EHE_DebugTestWindow.ClearGlobalModData()
	sendClientCommand("CustomDebugPanel", "clearGlobalModData", {})
end

function EHE_DebugTestWindow.eHeliEvents_SchedulerUnitTest()
	sendClientCommand("CustomDebugPanel", "schedulerUnitTest", {})
end

function EHE_DebugTestWindow.getHumanoidsInFractalRange()
	local player = getSpecificPlayer(0)
	local fractalObjectsFound = isoRangeScan.getHumanoidsInFractalRange(player, 1, 2, "IsoZombie")
	print("-----[ getHumanoidsInFractalRange ]-----")
	for fractalIndex = 1, #fractalObjectsFound do
		print(" "..fractalIndex..":  hostile count:"..#fractalObjectsFound[fractalIndex])
	end
end

function EHE_DebugTestWindow.getHumanoidsInRange()
	local player = getSpecificPlayer(0)
	local objectsFound = isoRangeScan.getHumanoidsInRange(player, 1, "IsoZombie")
	print("-----[ getHumanoidsInRange ]-----")
	print(" objectsFound: ".." count: "..#objectsFound)
	for i = 1, #objectsFound do
		print(" "..i..":  "..tostring(objectsFound[i]:getClass()))
	end
end


local testAllLines = {ALL_LINES={}, DELAYS={}, lastDemoTime=0}

function EHE_DebugTestWindow.testAllLines()
	if #testAllLines.ALL_LINES > 0 then
		testAllLines.ALL_LINES = {}
		testAllLines.DELAYS = {}
		testAllLines.lastDemoTime = 0
		getPlayer():Say("Cancelling testAllLines")
		return
	end
	sendClientCommand("CustomDebugPanel", "getAnnouncerLines", {})
end

function EHE_DebugTestWindow.testAllLinesLOOP()
	if #testAllLines.ALL_LINES > 0 and testAllLines.lastDemoTime < getTimeInMillis() then
		local line = testAllLines.ALL_LINES[1]
		local delay = testAllLines.DELAYS[1]
		testAllLines.lastDemoTime = getTimeInMillis() + delay
		getWorld():getFreeEmitter():playSound(line)
		getPlayer():Say(line)
		table.remove(testAllLines.ALL_LINES, 1)
		table.remove(testAllLines.DELAYS, 1)
	end
end
Events.OnTick.Add(EHE_DebugTestWindow.testAllLinesLOOP)

local function onServerCommand(_module, _command, _data)
	if _module ~= "CustomDebugPanel" then return end
	if _command == "announcerLines" then
		testAllLines.ALL_LINES = _data.lines or {}
		testAllLines.DELAYS = _data.delays or {}
		testAllLines.lastDemoTime = 0
	end
end
Events.OnServerCommand.Add(onServerCommand)


local COLOR_NORMAL = {r=0.90, g=0.90, b=0.90, a=0.90}
local COLOR_TRIGGERED = {r=0.62, g=0.15, b=0.15, a=0.88}

local function buildSortedEntries(events, showTriggered)
	local sorted = {}
	for i = 1, #events do
		local ev = events[i]
		if ev and (showTriggered or not ev.triggered) then
			table.insert(sorted, {idx = i, ev = ev})
		end
	end
	table.sort(sorted, function(a, b)
		local ea, eb = a.ev, b.ev
		if ea.startDay ~= eb.startDay then return ea.startDay < eb.startDay end
		return (ea.startTime or 0) < (eb.startTime or 0)
	end)
	return sorted
end

local function countTriggered(events)
	local n = 0
	for i = 1, #events do if events[i] and events[i].triggered then n = n + 1 end end
	return n
end


function EHE_DebugTestWindow:render()
	ISPanel.render(self)

	local GT = getGameTime()
	local timeStr = string.format("Day: %.2f   Hour: %d", util.getWorldAgeDays(), GT:getHour())
	self:drawText(timeStr, self.listbox.x+15, self.listbox.y-(self.listbox.fontHgt*1.33), 1,1,1,1, self.listbox.font)

	local globalModData = clientCommands.get()
	local events = globalModData and globalModData.EventsOnSchedule
	if not events or #events == 0 then return end

	local totalCount = #events
	local triggeredCount = countTriggered(events)

	if self._lastTotal == totalCount
	and self._lastTriggered == triggeredCount
	and not self._dirty then return end

	self._lastTotal = totalCount
	self._lastTriggered = triggeredCount
	self._dirty = false

	self.listbox.items = {}
	self.listbox.selected = 1

	local sorted = buildSortedEntries(events, EHE_DebugTestWindow.TOGGLE_SHOW_DONE == true)
	for _, entry in ipairs(sorted) do
		self.listbox:addItem("[" .. entry.idx .. "]", entry.ev)
	end

	local rowH = self.listbox.fontHgt
	local listH = math.max(rowH, math.min(10, #sorted) * rowH)
	self.listbox:setHeight(listH)

	local closeY = self.listbox.y + self.listbox.height + 20
	self.Close:setY(closeY)
	self:setHeight(closeY + 28)
end


function EHE_DebugTestWindow.OnOpenPanel()
	local x = ISDebugMenu.instance:getX() + ISDebugMenu.instance:getWidth() + 5
	local y = ISDebugMenu.instance:getY()

	if not EHE_DebugTestWindow.instance then
		EHE_DebugTestWindow.instance = EHE_DebugTestWindow:new(x, y, 600, 200)
		EHE_DebugTestWindow.instance:initialise()
		EHE_DebugTestWindow.instance:addToUIManager()
		EHE_DebugTestWindow.instance:setVisible(true)
		return
	end

	if EHE_DebugTestWindow.instance:getIsVisible() then
		EHE_DebugTestWindow.instance:setVisible(false)
	else
		EHE_DebugTestWindow.instance:setVisible(true)
		EHE_DebugTestWindow.instance:setX(x)
		EHE_DebugTestWindow.instance:setY(y)
	end
end


function EHE_DebugTestWindow:drawScrollingListLine(y, item, alt)
	local ev = item.item
	local col = COLOR_NORMAL
	local text

	if ev and type(ev) == "table" then
		if ev.triggered then col = COLOR_TRIGGERED end
		text = string.format("%s  preset:%-24s  Day:%-6s  Hr:%-3s  done:%s",
			item.text,
			tostring(ev.preset or "?"),
			ev.startDay ~= nil and string.format("%.1f", ev.startDay) or "?",
			tostring(ev.startTime or "?"),
			tostring(ev.triggered or false))
	else
		text = item.text .. "  ERROR (NIL or NOT A TABLE)"
	end

	self:drawText(text, 24, y+(item.height-self.fontHgt)/2, col.r, col.g, col.b, col.a, self.font)
	return y + item.height
end


function EHE_DebugTestWindow:initialise()
	ISPanel.initialise(self)

	local padding = 10
	local yOffset = 8
	local y = padding + 5
	local w = self.width/2 - (padding*1.5)
	local h = 18

	local numeration = 0
	for title, func in pairs(EHE_DebugTestWindow.Tests) do
		numeration = numeration + 1
		local evenNumber = (numeration % 2 == 0)
		local newX, newY
		if evenNumber then
			newX = self.width - w - padding
			newY = y - h - yOffset
		else
			newX = padding
			newY = y
		end

		if type(func) == "table" then
			EHE_DebugTestWindow.addComboList(self, func, title, newX, newY, w, h)
		else
			EHE_DebugTestWindow.addButton(self, func, title, newX, newY, w, h)
		end
		y = newY + h + yOffset
	end

	local font = UIFont.AutoNormSmall
	local fontHeight = getTextManager():getFontHeight(font)

	self.listbox = ISScrollingListBox:new(padding, y+yOffset+(fontHeight*1.33), self.width-(padding*2), fontHeight)
	self.listbox:initialise()
	self.listbox.backgroundColor.a = 0.0
	self.listbox.font = font
	self.listbox.fontHgt = fontHeight
	self.listbox.itemheight = fontHeight
	self.listbox.doDrawItem = EHE_DebugTestWindow.drawScrollingListLine
	self:addChild(self.listbox)

	local closeY = self.listbox.y + self.listbox.height + (padding*2)

	EHE_DebugTestWindow.addButton(self, function() self:close() end, "Close", padding, closeY, w, h)

	self._lastTotal = nil
	self._lastTriggered = nil
	self._dirty = false

	self:setHeight(closeY + 28)
end


function EHE_DebugTestWindow.addButton(UIElement, setFunction, title, x, y, width, height)
	local btn = ISButton:new(x, y, width, height, title, nil, setFunction)
	btn.target = btn
	UIElement[title] = btn
	UIElement:addChild(btn)
end

function EHE_DebugTestWindow:comboSelected()
	local selection = self:getSelected()
	local optionData = self:getOptionData(selection)
	optionData()
end

function EHE_DebugTestWindow.addComboList(UIElement, tableOfFunc, title, x, y, width, height)
	local btnWidth = (width/2) - 2
	local combo = ISComboBox:new(x+btnWidth+4, y, btnWidth, height)
	UIElement:addChild(combo)
	for key, func in pairs(tableOfFunc) do combo:addOptionWithData(key, func) end
	local btn = ISButton:new(x, y, btnWidth, height, title, combo, EHE_DebugTestWindow.comboSelected)
	UIElement:addChild(btn)
end

function EHE_DebugTestWindow:new(x, y, width, height)
	local o = ISPanel:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.x = x
	o.y = y
	o.background = true
	o.backgroundColor = {r=0, g=0, b=0, a=0.5}
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
	o.width = width
	o.height = height
	o.anchorLeft = true
	o.anchorRight = false
	o.anchorTop = true
	o.anchorBottom = false
	o.moveWithMouse = true
	return o
end
