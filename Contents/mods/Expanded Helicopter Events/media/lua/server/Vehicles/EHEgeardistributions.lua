-- pull the vehicle distributions into a local table
local distributionTable = VehicleDistributions[1]

VehicleDistributions.HelicopterCrashCabin = {
    rolls = 4,
    items ={
        "Bag_ALICEpack_Army", 3,
        "Vest_BulletArmy", 3,
        "556Clip", 3,
        "556Clip", 3,
        "556Clip", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "Hat_Army", 3,
        "AssaultRifle", 2,
        "AssaultRifle", 2,
        "Pistol", 3,
        "Pistol", 3,
        "Pistol", 3,
        "9mmClip", 3,
        "9mmClip", 3,
        "9mmClip", 3,
        "Bullets9mm", 3,
        "Bullets9mm", 3,
        "Bullets9mm", 3,
        "Bullets9mm", 3,
        "Bullets9mm", 3,
		"HolsterSimple", 3,
        "Trousers_CamoGreen", 1,
        "Shirt_CamoGreen", 1,
        "Jacket_ArmyCamoGreen", 1,
        "Hat_BonnieHat_CamoGreen", 1,
        "Hat_BeretArmy", 0.5,
        "Shoes_ArmyBoots", 1,
        "Shirt_CamoGreen", 1,
        "Radio.WalkieTalkie5", 3,
        "HuntingKnife", 3,
        "FirstAidKit", 3,
		"x2Scope", 0.7,
		"x4Scope", 0.5,
		"x8Scope", 0.3,
    }
}


-- add a new military distributions table
VehicleDistributions.Helicopter = {
    TruckBed = VehicleDistributions.HelicopterCrashCabin;
    TruckbedOpen = VehicleDistributions.HelicopterCrashCabin;


-- now setup the cars. we can just use tables for already existing cars for them:
-- dont use the corvette table for the muscle cars, as it only encludes doctors stuff
-- and things for golfers. CarNormal will give a better selection of stuff for the
-- average joe.

-- use the custom military loot table for the hmmwv's
distributionTable["uh1interior"] = { Normal = VehicleDistributions.Helicopter; }