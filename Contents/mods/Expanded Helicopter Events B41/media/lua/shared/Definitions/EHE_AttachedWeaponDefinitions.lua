AttachedWeaponDefinitions = AttachedWeaponDefinitions or {};

-- same as vanilla handgun attachment-define but higher chance and pointed to EHE outfits

AttachedWeaponDefinitions.EHE_handgunHolster = {
	id = "EHE_handgunHolster",
	chance = 90,
	outfit = {"1PolicePilot", "1PoliceOfficer","1Survivalist","1SurvivalistPilot"},
	weaponLocation =  {"Holster Right"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	ensureItem = "Base.HolsterSimple",
	weapons = {
		"Base.Pistol",
		"Base.Pistol2",
		"Base.Pistol3",
		"Base.Revolver",
		"Base.Revolver_Long",
		"Base.Revolver_Short",
	},
}

AttachedWeaponDefinitions.EHE_assaultRifleOnBack = {
	id = "EHE_assaultRifleOnBack",
	chance = 90,
	outfit = {"1Soldier", "1Survivalist", "1PoliceOfficer"},
	weaponLocation =  {"Rifle On Back"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.AssaultRifle",
	},
}

AttachedWeaponDefinitions.EHE_huntingRifleOnBack = {
	id = "EHE_huntingRifleOnBack",
	chance = 90,
	outfit = {"1PoliceOfficer", "1PressArmored"},
	weaponLocation =  {"Rifle On Back"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {
		"Base.VarmintRifle",
		"Base.HuntingRifle",
		"Base.Shotgun",
	},
}