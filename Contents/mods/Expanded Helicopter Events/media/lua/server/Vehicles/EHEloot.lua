-- pull the vehicle distributions into a local table
local distributionTable = VehicleDistributions[1]


VehicleDistributions.UH1Seat = {
    rolls = 7,
    items ={
        "Bag_ALICEpack_Army", 5,
        "Vest_BulletArmy", 5,
        "556Clip", 3,
        "556Clip", 3,
        "556Clip", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "556Box", 3,
        "Hat_Army", 3,
        "Hat_GasMask", 3,
        "Hat_GasMask", 3,
        "Hat_GasMask", 3,
        "AssaultRifle", 5,
        "AssaultRifle", 5,
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
		"EmptyPetrolCan", 3,
		"PetrolCan", 2,
		"x2Scope", 0.7,
		"x4Scope", 0.5,
		"x8Scope", 0.3,
	
    }
}



-- add a new m113 distributions table
VehicleDistributions.UH1H = {
	
	SeatRearFrontLeft = VehicleDistributions.UH1Seat;
	SeatRearFrontRight = VehicleDistributions.UH1Seat;
	SeatRearMiddleLeft = VehicleDistributions.UH1Seat;
	SeatRearMiddleRight = VehicleDistributions.UH1Seat;
}


distributionTable["UH1H"] = { Normal = VehicleDistributions.UH1H; }



