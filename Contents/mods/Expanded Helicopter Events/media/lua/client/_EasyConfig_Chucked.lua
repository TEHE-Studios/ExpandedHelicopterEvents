---Original EasyConfig found in Sandbox+ (author: derLoko)
EasyConfig_Chucked = EasyConfig_Chucked or {}
EasyConfig_Chucked.mods = EasyConfig_Chucked.mods or {}

EasyConfig_Chucked.addMod = function(modId, name, config, configMenu, tabName, menuSpecificAccess)
	if not config or not configMenu then
		return
	end

	EasyConfig_Chucked.mods[modId] = {}
	EasyConfig_Chucked.mods[modId].name = name
	EasyConfig_Chucked.mods[modId].config = config
	EasyConfig_Chucked.mods[modId].configMenu = configMenu
	EasyConfig_Chucked.mods[modId].tabName = tabName
	EasyConfig_Chucked.mods[modId].menuSpecificAccess = menuSpecificAccess

	--link all the things!
	for gameOptionName,menuEntry in pairs(configMenu) do
		if menuEntry.options then
			menuEntry.optionsIndexes = menuEntry.options
			menuEntry.optionsKeys = {}
			menuEntry.optionsValues = {}
			menuEntry.optionLabels = {} -- passed on to UI elements
			for i,table in ipairs(menuEntry.optionsIndexes) do
				menuEntry.optionLabels[i] = table[1]
				local k = table[1]
				local v = table[2]
				menuEntry.optionsKeys[k] = {i, v}
				menuEntry.optionsValues[v] = {i, k}
			end
		end
	end

	for gameOptionName,value in pairs(config) do
		local menuEntry = configMenu[gameOptionName]
		if menuEntry.options then
			menuEntry.selectedIndex = menuEntry.optionsValues[value][1]
			menuEntry.selectedLabel = menuEntry.optionsValues[value][2]
		end
		menuEntry.selectedValue = value
	end

	EasyConfig_Chucked.loadConfig(modId)
end


-- copied from client/Optionscreens/MainOptions.lua because GameOption is local
-- -- -- -- -- >
local GameOption = ISBaseObject:derive("GameOptions")
function GameOption:new(name, control)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.control = control

	if control.isCombobox then
		control.onChange = self.onChange
		control.target = o
	elseif control.isTickBox then
		control.changeOptionMethod = self.onChange
		control.changeOptionTarget = o
	else
		local go = o.gameOptions
		control.onTextChange = function()
			o.gameOptions.changed = true
		end
	end
	return o
end
function GameOption:onChange()
	self.gameOptions:onChange(self)
end
-- -- -- -- -- >


EHE_MainOptions_create = MainOptions.create

function MainOptions:create() -- override

	EHE_MainOptions_create(self) -- call original

	function self.gameOptions:toUI()
		for _,option in ipairs(self.options) do
			if option then option:toUI() end
		end
		self.changed = false
	end
	function self.gameOptions:apply()
		for _,option in ipairs(self.options) do
			if option then option:apply() end
		end
		EasyConfig_Chucked.saveConfig()
		EasyConfig_Chucked.loadConfig()
		self.changed = false
	end

	local x = self:getWidth()/2.5
	local y = 30
	local width = 200
	local height = 20

	--new addText because MainOptions doesn't have it
	function addText(text, font, r, g, b, a, customX)
		local label = ISLabel:new(x+(customX or 20),y+self.addY,height, text, r or 1, g or 1, b or 1, a or 1, font, true)
		label:initialise()
		self.mainPanel:addChild(label)
		self.addY = self.addY + height +5
		return label
	end

	--alternative addTickBox because I didn't like the one in MainOptions
	function addTickBox(text)
		local label = ISLabel:new(x,y+self.addY,20, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTickBox:new(x+20,y+self.addY, width,height)
		box.choicesColor = {r=1, g=1, b=1, a=1}
		box:initialise()
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		box:addOption("", nil) -- only add a single option with no values, our tickbox can only be true/false.
		self.addY = self.addY + height +5
		return box
	end
	--new addNumberBox because MainOptions doesn't have it
	function addNumberBox(text)
		local label = ISLabel:new(x,y+self.addY,height, text, 1,1,1,1, UIFont.Small, false)
		label:initialise()
		self.mainPanel:addChild(label)
		local box = ISTextEntryBox:new("", x+20,y+self.addY, 200,20)
		box.font = UIFont.Small
		box:initialise()
		box:instantiate()
		box:setOnlyNumbers(true)
		self.mainPanel:addChild(box)
		self.mainPanel:insertNewLineOfButtons(box)
		self.addY = self.addY + height +5
		return box
	end
	--new addSpace
	function addSpace()
		self.addY = self.addY + height +5
	end


	function createElements(mod)
		--addText(mod.name, UIFont.Medium)
		--addSpace()

		for gameOptionName,menuEntry in pairs(mod.configMenu) do

			--- TEXT ---
			if menuEntry.type == "Text" then
				addText(menuEntry.text, UIFont.Small, menuEntry.r, menuEntry.g, menuEntry.b, menuEntry.a, menuEntry.customX)
			end

			--- SPACE ---
			if menuEntry.type == "Space" then
				local iteration = menuEntry.iteration or 1
				for i=1, iteration do
					addSpace()
				end
			end

			--- TICK BOX ---
			if menuEntry.type == "Tickbox" then
				local box = addTickBox(menuEntry.title)
				local gameOption = GameOption:new(gameOptionName, box)
				function gameOption.toUI(self)
					local box = self.control
					local bool = menuEntry.selectedValue
					box.selected[1] = bool
				end
				function gameOption.apply(self)
					local box = self.control
					local bool = box.selected[1]
					menuEntry.selectedValue = bool
					menuEntry.selectedLabel = tostring(bool)
				end
				self.gameOptions:add(gameOption)
			end

			--- NUMBER BOX ---
			if menuEntry.type == "Numberbox" then
				local box = addNumberBox(menuEntry.title)
				local gameOption = GameOption:new(gameOptionName, box)
				function gameOption.toUI(self)
					local box = self.control
					box:setText( tostring(menuEntry.selectedValue) )
				end
				function gameOption.apply(self)
					local box = self.control
					local value = box:getText()
					menuEntry.selectedValue = tonumber(value)
				end
				self.gameOptions:add(gameOption)
			end

			--- COMBO BOX ---
			if menuEntry.type == "Combobox" then
				--addCombo(x,y,w,h, name,options, selected, target, onchange)
				local box = self:addCombo(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
				if menuEntry.tooltip then
					box:setToolTipMap({defaultTooltip = menuEntry.tooltip})
				end
				local gameOption = GameOption:new(gameOptionName, box)
				function gameOption.toUI(self)
					local box = self.control
					box.selected = menuEntry.selectedIndex
				end
				function gameOption.apply(self)
					local box = self.control
					menuEntry.selectedIndex = box.selected
					menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
					menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
				end
				self.gameOptions:add(gameOption)
			end

			--- SPIN BOX ---
			if menuEntry.type == "Spinbox" then
				--addSpinBox(x,y,w,h, name, options, selected, target, onchange)
				local box = self:addSpinBox(x,y,200,20, menuEntry.title, menuEntry.optionLabels)
				local gameOption = GameOption:new(gameOptionName, box)
				function gameOption.toUI(self)
					local box = self.control
					box.selected = menuEntry.selectedIndex
				end
				function gameOption.apply(self)
					local box = self.control
					menuEntry.selectedIndex = box.selected
					menuEntry.selectedLabel = menuEntry.optionsIndexes[box.selected][1]
					menuEntry.selectedValue = menuEntry.optionsIndexes[box.selected][2]
				end
				self.gameOptions:add(gameOption)
			end

		end
		self.addY = self.addY + 30
	end

	for modId,mod in pairs(EasyConfig_Chucked.mods) do

		self.addY = 0
		self:addPage(mod.tabName)

		if (not mod.menuSpecificAccess) or (getPlayer() and mod.menuSpecificAccess=="ingame") or (not getPlayer() and mod.menuSpecificAccess=="mainmenu") then
			createElements(mod)
		else
			if (not getPlayer() and mod.menuSpecificAccess=="ingame") then
				addText("This mod's options can only be accessed", UIFont.Medium)
				addText("from the in-game options menu.", UIFont.Medium)
			end
			if (getPlayer() and mod.menuSpecificAccess=="mainmenu") then
				addText("This mod's options can only be", UIFont.Medium)
				addText("accessed from the main menu options menu.", UIFont.Medium)
				addText(" ", UIFont.Medium)
				addText("Note: Make sure to enable this mod", UIFont.Medium)
				addText("from the main menu to view the options.", UIFont.Medium)
			end
		end

		self.addY = self.addY + MainOptions.translatorPane:getHeight() + 22
		self.mainPanel:setScrollHeight(self.addY + 20)

	end
end



EasyConfig_Chucked.saveConfig = function()
	for modId,mod in pairs(EasyConfig_Chucked.mods) do
		local config = mod.config
		local configMenu = mod.configMenu
		local configFile = "media/config/"..modId..".config"
		local fileWriter = getModFileWriter(modId, configFile, true, false)
		if fileWriter then
			print("modId: "..modId.." saving")
			for gameOptionName,_ in pairs(config) do
				local menuEntry = configMenu[gameOptionName]

				if menuEntry.selectedLabel then
					local menuEntry_selectedLabel = menuEntry.selectedLabel
					if type(menuEntry.selectedLabel) == "boolean" then
						menuEntry_selectedLabel = tostring(menuEntry_selectedLabel)
					end
					fileWriter:write(gameOptionName.."="..menuEntry_selectedLabel..",\r")
				else
					local menuEntry_selectedValue = menuEntry.selectedValue
					if type(menuEntry.selectedValue) == "boolean" then
						menuEntry_selectedValue = tostring(menuEntry_selectedValue)
					end
					fileWriter:write(gameOptionName.."="..menuEntry_selectedValue..",\r")
				end
			end
			fileWriter:close()
		end
	end
end
EasyConfig_Chucked.loadConfig = function()
	for modId,mod in pairs(EasyConfig_Chucked.mods) do
		local config = EasyConfig_Chucked.mods[modId].config
		local configMenu = EasyConfig_Chucked.mods[modId].configMenu
		local configFile = "media/config/"..modId..".config"
		local fileReader = getModFileReader(modId, configFile, false)
		if fileReader then
			print("modId: "..modId.." loading")
			for _,_ in pairs(config) do
				local line = fileReader:readLine()
				if not line then break end
				for gameOptionName,label in string.gmatch(line, "([^=]*)=([^=]*),") do
					local menuEntry = configMenu[gameOptionName]
					if menuEntry then

						if menuEntry.options then
							if menuEntry.optionsKeys[label] then
								menuEntry.selectedIndex = menuEntry.optionsKeys[label][1]
								menuEntry.selectedValue = menuEntry.optionsKeys[label][2]
								menuEntry.selectedLabel = label
							end
						else
							if label == "true" then menuEntry.selectedValue = true
							elseif label == "false" then menuEntry.selectedValue = false
							else menuEntry.selectedValue = tonumber(label) end
						end
						config[gameOptionName] = menuEntry.selectedValue
					end
				end
			end
			fileReader:close()
		end
	end
end
