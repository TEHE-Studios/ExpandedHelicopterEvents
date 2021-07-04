 -- define weapons to be attached to zombies when creating them
-- random knives inside their neck, spear in their stomach, meatcleaver in their back...
-- this is used in IsoZombie.addRandomAttachedWeapon()

AttachedWeaponDefinitions = AttachedWeaponDefinitions or {};

AttachedWeaponDefinitions.chanceOfAttachedWeapon = 9; -- Global chance of having an attached weapon, if we pass this we gonna add randomly one from the list


-- random weapon on police zombies holster
AttachedWeaponDefinitions.handgunHolster = {
	id = "handgunHolster",
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

-- assault rifle on back
AttachedWeaponDefinitions.assaultRifleOnBack = {
	id = "assaultRifleOnBack",
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

-- varmint/hunting rifle on back
AttachedWeaponDefinitions.huntingRifleOnBack = {
	id = "huntingRifleOnBack",
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