---This overrides the vanilla sandbox option for helicopter frequency

eHelicopterSandboxOptions = {}
eHelicopterSandboxOptions.freq = { ["value"]=2,
	["options"]={ [1]="Sandbox_HelicopterFreq_option1",--never
				  [2]="Sandbox_HelicopterFreq_option2",--once
				  [3]="Sandbox_HelicopterFreq_option3",--sometimes
				  [4]="Sandbox_HelicopterFreq_option4"} --often
	}


--- Sandbox Options discovery
function HelicopterSandboxOptionOverride()
	---@type SandboxOptions
	local SANDBOX_OPTIONS = getSandboxOptions()
	---@type SandboxOptions.EnumSandboxOption | SandboxOptions.SandboxOption
	local sandboxHeliFreq = SANDBOX_OPTIONS:getOptionByName("Helicopter")

	print("VANILLA HELICOPTER SANDBOX OPTION: ".."<"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")

	if sandboxHeliFreq:getValue() ~= 1 then
		print("sandboxHeliFreq not <".. sandboxHeliFreq:getValueTranslationByIndex(1).."> (1)")
		sandboxHeliFreq:setValue(1) --1 = Never
		print("setting now: <"..sandboxHeliFreq:getValueTranslationByIndex(sandboxHeliFreq:getValue()).."> ".."(".. sandboxHeliFreq:getValue()..")")
	end
end

Events.OnGameStart.Add(HelicopterSandboxOptionOverride)

Events.OnCustomUIKey.Add(function(key)
	if key == Keyboard.KEY_4 then
		HelicopterSandboxOptionOverride()
	end
end)