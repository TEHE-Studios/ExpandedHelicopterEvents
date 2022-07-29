--Overrides vanilla helicopter frequency on game boot
function HelicopterSandboxOptions()
	print("EHE: Disabling vanilla helicopter. Adding items to WorldItemRemovalList.")
	getSandboxOptions():getOptionByName("Helicopter"):setValue(1) -- 1 = Never
	SandboxVars.Helicopter = 1

	getSandboxOptions():getOptionByName("Helicopter")

	--appreciate depreciated values, --TODO: Remove this in a while
	if SandboxVars.ExpandedHeli.CutOffDay ~= 90 and SandboxVars.ExpandedHeli.SchedulerDuration == 90 then
		print("WARNING: SandboxVars.ExpandedHeli.CutOffDay non-default value found: appreciating SchedulerDuration to match.")
		SandboxVars.ExpandedHeli.SchedulerDuration = SandboxVars.ExpandedHeli.CutOffDay
	end
	if SandboxVars.ExpandedHeli.NeverEnding ~= false and SandboxVars.ExpandedHeli.ContinueScheduling == false then
		print("WARNING: SandboxVars.ExpandedHeli.NeverEnding non-default value found: appreciating ContinueScheduling to match.")
		SandboxVars.ExpandedHeli.ContinueScheduling = SandboxVars.ExpandedHeli.NeverEnding
	end
	if SandboxVars.ExpandedHeli.NeverEndingLateGameOnly ~= true and SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly == true then
		print("WARNING: SandboxVars.ExpandedHeli.NeverEndingLateGameOnly non-default value found: appreciating ContinueSchedulingLateGameOnly to match.")
		SandboxVars.ExpandedHeli.ContinueSchedulingLateGameOnly = SandboxVars.ExpandedHeli.NeverEndingLateGameOnly
	end

	local typesForRemovalList = {"EHE.EvacuationFlyer","EHE.EmergencyFlyer","EHE.QuarantineFlyer","EHE.PreventionFlyer","EHE.NoticeFlyer"}
	for k,type in pairs(typesForRemovalList) do
		if not string.find(SandboxVars.WorldItemRemovalList, type) then
			SandboxVars.WorldItemRemovalList = SandboxVars.WorldItemRemovalList..","..type
		end
	end
	--getSandboxOptions():updateFromLua()
end


Events.OnGameBoot.Add(HelicopterSandboxOptions)
Events.OnLoad.Add(HelicopterSandboxOptions)