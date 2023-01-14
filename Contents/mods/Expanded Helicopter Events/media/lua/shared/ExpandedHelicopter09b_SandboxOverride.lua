--Overrides vanilla helicopter frequency on game boot
local function HelicopterSandboxOptions()
	print("EHE: Disabling vanilla helicopter. Adding items to WorldItemRemovalList.")

	getSandboxOptions():set("Helicopter", 1)
	SandboxVars.Helicopter = 1

	local typesForRemovalList = {"EHE.EvacuationFlyer","EHE.EmergencyFlyer","EHE.QuarantineFlyer","EHE.PreventionFlyer","EHE.NoticeFlyer"}
	for k,type in pairs(typesForRemovalList) do
		if not string.find(SandboxVars.WorldItemRemovalList, type) then
			SandboxVars.WorldItemRemovalList = SandboxVars.WorldItemRemovalList..","..type
		end
	end

	if isServer() then
		local serverFileName = getServerName()
		print("serverFileName: "..serverFileName)
		if serverFileName then
			getSandboxOptions():saveServerLuaFile(serverFileName)
		end
	end
end

Events.OnGameStart.Add(HelicopterSandboxOptions)
Events.OnGameBoot.Add(HelicopterSandboxOptions)
Events.OnLoad.Add(HelicopterSandboxOptions)