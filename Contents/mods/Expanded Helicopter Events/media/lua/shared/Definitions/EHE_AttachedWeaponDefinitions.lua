
if not AttachedWeaponDefinitions then
	print("EHE: ERROR: Vanilla AttachedWeaponDefinitions not found - can't load `EHE_AttachedWeaponDefinitions`")
else
	function EHE_AttachedWeaponDefinitions()
		--handguns
		table.insert(AttachedWeaponDefinitions.handgunHolster.outfit,"1PolicePilot")
		table.insert(AttachedWeaponDefinitions.handgunHolster.outfit,"1PoliceOfficer")
		table.insert(AttachedWeaponDefinitions.handgunHolster.outfit,"1Survivalist")
		table.insert(AttachedWeaponDefinitions.handgunHolster.outfit,"1SurvivalistPilot")

		-- assault rifle on back
		table.insert(AttachedWeaponDefinitions.assaultRifleOnBack.outfit,"1Soldier")
		table.insert(AttachedWeaponDefinitions.assaultRifleOnBack.outfit,"1Survivalist")
		table.insert(AttachedWeaponDefinitions.assaultRifleOnBack.outfit,"1PoliceOfficer")

		-- varmint/hunting rifle on back
		table.insert(AttachedWeaponDefinitions.huntingRifleOnBack.outfit,"1PoliceOfficer")
		table.insert(AttachedWeaponDefinitions.huntingRifleOnBack.outfit,"1PressArmored")
	end

	Events.OnGameBoot.Add(EHE_AttachedWeaponDefinitions)
end 