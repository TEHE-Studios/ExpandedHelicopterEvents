--Overrides vanilla helicopter frequency on game boot
function HelicopterSandboxOptions()
	print("EHE: Disabling vanilla helicopter. Adding items to WorldItemRemovalList.")
	getGameTime():setHelicopterDay(0)
	getGameTime():setHelicopterStartHour(0)
	getGameTime():setHelicopterEndHour(0)
	getSandboxOptions():getOptionByName("Helicopter"):setValue(1) -- 1 = Never
	SandboxVars.Helicopter = 1

	local typesForRemovalList = {"EHE.EvacuationFlyer","EHE.EmergencyFlyer","EHE.QuarantineFlyer","EHE.PreventionFlyer","EHE.NoticeFlyer"}
	for k,type in pairs(typesForRemovalList) do
		if not string.find(SandboxVars.WorldItemRemovalList, type) then
			SandboxVars.WorldItemRemovalList = SandboxVars.WorldItemRemovalList..","..type
		end
	end
	getSandboxOptions():updateFromLua()
end

Events.OnLoad.Add(HelicopterSandboxOptions)