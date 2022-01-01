require "ExpandedHelicopter03b_AnnouncersCore"

function EHE_SendSound(emitterID, x, y, z, soundByName)
	print("--EHE_SendSound:")
	if isClient() then
		print("----sendClientCommand:")
		sendClientCommand("EHE_SendSound", "sendPlay", {})
		sendClientCommand("EHE_SendSound", "sendStop", {})
	else
		print("----direct:")
	end
end