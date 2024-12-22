local function applyLootBoxLoot()

    -- pull the vehicle distributions into a local table
    local distributionTable = VehicleDistributions[1]

    VehicleDistributions.UH60 = {
        rolls = 3,
        items ={
            "556Clip", 3,
            "556Clip", 3,
            "556Clip", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "AssaultRifle", 7,
            "AssaultRifle", 7,
            "Pistol", 5,
            "Pistol", 5,
            "Pistol", 5,
            "9mmClip", 3,
            "9mmClip", 3,
            "9mmClip", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "HolsterSimple", 3,
            "Radio.WalkieTalkie5", 3,
            "FirstAidKit", 10,
            "FirstAidKit", 10,
            "FirstAidKit", 10,
            "x2Scope", 0.7,

            -- MEA --
            "MEA.ANPRC112", 10,
            "MEA.ANPRC112", 10,
            
            -- EHE --
            "EHE.MealReadytoEat", 10,
            "EHE.MealReadytoEat", 10,

            -- AZ --
            "AuthenticZClothing.Authentic_MilitaryFlashlightGreen", 10,
            "AuthenticZClothing.AuthenticCanteenForestGreen", 10,
            "AuthenticZClothing.AuthenticSmokeBomb", 10,

        }
    }


    VehicleDistributions.RaiderCargo = {
        rolls = 3,
        items ={
            "Bag_ALICEpack_Army", 4,
            "Vest_BulletArmy", 9,
            "556Clip", 3,
            "556Clip", 3,
            "556Clip", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "AssaultRifle", 7,
            "AssaultRifle", 7,
            "Pistol", 5,
            "Pistol", 5,
            "Pistol", 5,
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
            "Shoes_ArmyBoots", 1,
            "Shirt_CamoGreen", 1,
            "Radio.WalkieTalkie5", 3,
            "HuntingKnife", 3,
            "FirstAidKit", 3,
            "x2Scope", 0.7,
            "HottieZ", 10,
            "HottieZ", 10,
            "AmmoStraps", 10,
            "AmmoStrap_Bullets", 10,
            "Speaker", 10,
            "Speaker", 10,
            "ElectronicsScrap", 10,
            "ElectronicsScrap", 10,

            -- EHE --
            "EHE.BanditStashBox", 1,
            "EHE.MealReadytoEat", 10,
            "EHE.MealReadytoEat", 10,

            -- AZ --
            "AuthenticZClothing.Authentic_MilitaryFlashlightGreen", 10,
            "AuthenticZClothing.AuthenticCanteenForestGreen", 10,
            "AuthenticZClothing.AuthenticSmokeBomb", 10,
            "AuthenticZClothing.Tshirt_Rock2", 3,
            "AuthenticZClothing.Tshirt_PostalDude", 3,
            "AuthenticZClothing.Jacket_PostalDude", 3,

        }
    }

    VehicleDistributions.UH60Medevac = {
        rolls = 3,
        items ={
            "556Clip", 3,
            "556Clip", 3,
            "556Clip", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "AssaultRifle", 7,
            "AssaultRifle", 7,
            "Pistol", 5,
            "Pistol", 5,
            "Pistol", 5,
            "9mmClip", 3,
            "9mmClip", 3,
            "9mmClip", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "HolsterSimple", 3,
            "Radio.WalkieTalkie5", 3,
            "FirstAidKit", 10,
            "FirstAidKit", 10,
            "FirstAidKit", 10,
            "x2Scope", 0.7,

            -- MEA --
            "MEA.ANPRC112", 10,
            "MEA.ANPRC112", 10,

            -- AZ --
            "AuthenticZClothing.Authentic_MilitaryFlashlightGreen", 10,
            "AuthenticZClothing.AuthenticCanteenForestGreen", 10,
            "AuthenticZClothing.AuthenticSmokeBomb", 10,
        }
    }

    VehicleDistributions.Bell206PoliceSeat = {
        rolls = 3,
        items ={
            "Vest_BulletPolice", 9,
            "556Clip", 3,
            "556Clip", 3,
            "556Clip", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "556Box", 3,
            "Pistol", 5,
            "Pistol", 5,
            "Pistol", 5,
            "9mmClip", 3,
            "9mmClip", 3,
            "9mmClip", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "HolsterSimple", 3,
            "Radio.WalkieTalkie3", 3,
            "AssaultRifle2", 10,
            "AssaultRifle2", 3,
            "Shotgun", 10,
            "Shotgun", 3,
            "FirstAidKit", 3,
            "x2Scope", 0.7,
            "Hat_SPHPolice", 10,
            "AmmoStraps", 10,
            "AmmoStrap_Bullets", 10,

        }
    }

    VehicleDistributions.Bell206NewsSeat = {
        rolls = 3,
        items ={
            "Pistol", 5,
            "Pistol", 5,
            "Pistol", 5,
            "9mmClip", 3,
            "9mmClip", 3,
            "9mmClip", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "FirstAidKit", 5,
            "Shotgun", 5,
            "Shotgun", 3,
            "ShotgunShellsBox", 7,
            "ShotgunShellsBox", 7,
            "ShotgunShellsBox", 7,

            -- AZ --
            "AuthenticZClothing.CameraDSLR", 3,
        }
    }

    VehicleDistributions.Bell206SurvivalistSeat = {
        rolls = 3,
        items ={
            "Pistol", 5,
            "Pistol", 5,
            "9mmClip", 3,
            "9mmClip", 3,
            "9mmClip", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "Bullets9mm", 3,
            "HuntingKnife", 3,
            "AmmoStraps", 10,
            "AmmoStrap_Bullets", 10,
            "AssaultRifle2", 7,
            "Shotgun", 7,
            "FirstAidKit", 5,
            "Bag_Duffelbag", 7,

            -- EHE--
            "EHE.MealReadytoEat", 10,
            "EHE.MealReadytoEat", 10,

            -- AZ --
            "AuthenticZClothing.Authentic_MilitaryFlashlightGreen", 10,
            "AuthenticZClothing.AuthenticCanteenForestGreen", 10,
            "AuthenticZClothing.AuthenticSmokeBomb", 10,

        }
    }

    VehicleDistributions.FEMASupplyDrop = {
        rolls = 50,
        items ={
            "EHE.EmergencyMedicalSupplyBox", 2,
            "EHE.EmergencySurvivalSupplyBox", 1,
            "EHE.EmergencyFoodSupplyBox", 2,

            "EHE.EmergencyMedicalSupplyBox", 2,
            "EHE.EmergencySurvivalSupplyBox", 1,
            "EHE.EmergencyFoodSupplyBox", 2,

            "EHE.EmergencyMedicalSupplyBox", 2,
            "EHE.EmergencySurvivalSupplyBox", 1,
            "EHE.EmergencyFoodSupplyBox", 2,

            "EHE.EmergencyMedicalSupplyBox", 2,
            "EHE.EmergencySurvivalSupplyBox", 1,
            "EHE.EmergencyFoodSupplyBox", 2,

            "EHE.EmergencyMedicalSupplyBox", 2,
            "EHE.EmergencySurvivalSupplyBox", 1,
            "EHE.EmergencyFoodSupplyBox", 2,
        }
    }

    VehicleDistributions.SurvivorSupplyDrop = {
        rolls = 50,
        items ={
            "EHE.SurvivorMedicalSupplyBox", 1,
            "EHE.SurvivorToiletSupplyBox", 2,
            "EHE.SurvivorFoodSupplyBox", 1,
            "EHE.SurvivorFishingSupplyBox", 1,
            "EHE.SurvivorCanningSupplyBox", 1,
            "EHE.SurvivorSeedSupplyBox", 1,

            "EHE.SurvivorMedicalSupplyBox", 1,
            "EHE.SurvivorToiletSupplyBox", 2,
            "EHE.SurvivorFoodSupplyBox", 1,
            "EHE.SurvivorFishingSupplyBox", 1,
            "EHE.SurvivorCanningSupplyBox", 1,
            "EHE.SurvivorSeedSupplyBox", 1,

            "EHE.SurvivorMedicalSupplyBox", 1,
            "EHE.SurvivorToiletSupplyBox", 1,
            "EHE.SurvivorFoodSupplyBox", 1,
            "EHE.SurvivorFishingSupplyBox", 1,
            "EHE.SurvivorCanningSupplyBox", 1,
            "EHE.SurvivorSeedSupplyBox", 1,

            "EHE.SurvivorMedicalSupplyBox", 1,
            "EHE.SurvivorToiletSupplyBox", 1,
            "EHE.SurvivorFoodSupplyBox", 1,
            "EHE.SurvivorFishingSupplyBox", 1,
            "EHE.SurvivorCanningSupplyBox", 1,
            "EHE.SurvivorSeedSupplyBox", 1,

            "EHE.SurvivorMedicalSupplyBox", 1,
            "EHE.SurvivorToiletSupplyBox", 1,
            "EHE.SurvivorFoodSupplyBox", 1,
            "EHE.SurvivorFishingSupplyBox", 1,
            "EHE.SurvivorCanningSupplyBox", 1,
            "EHE.SurvivorSeedSupplyBox", 1,
        }
    }

    -- UH-60A tables
    VehicleDistributions.UH60Cargo = { TruckBedOpen = VehicleDistributions.UH60; }
    VehicleDistributions.UH60MedevacCargo = { TruckBedOpen =  VehicleDistributions.UH60Medevac; }

    --Bell 206 tables
    VehicleDistributions.Bell206Police = {
        SeatFrontRight =  VehicleDistributions.Bell206PoliceSeat;
        SeatRearLeft =  VehicleDistributions.Bell206PoliceSeat;
        SeatRearRight =  VehicleDistributions.Bell206PoliceSeat;
    }

    VehicleDistributions.Bell206News = {
        SeatFrontRight =  VehicleDistributions.Bell206NewsSeat;
        SeatRearLeft =  VehicleDistributions.Bell206NewsSeat;
        SeatRearRight =  VehicleDistributions.Bell206NewsSeat;
    }

    VehicleDistributions.Bell206Survivalist = {
        SeatFrontRight =  VehicleDistributions.Bell20SurvivalistSeat;
        SeatRearLeft =  VehicleDistributions.Bell206SurvivalistSeat;
        SeatRearRight =  VehicleDistributions.Bell206SurvivalistSeat;
    }

    --Supply Drop
    VehicleDistributions.FEMASupplyDrop = { TruckBed = VehicleDistributions.FEMASupplyDrop; }
    VehicleDistributions.SurvivorSupplyDrop = { TruckBed = VehicleDistributions.SurvivorSupplyDrop; }

    --Distribution
    distributionTable["UH60GreenFuselage"] = { Normal = VehicleDistributions.UH60Cargo; }
    distributionTable["UH60DesertFuselage"] = { Normal = VehicleDistributions.UH60Cargo; }
    distributionTable["UH60MedevacFuselage"] = { Normal = VehicleDistributions.UH60MedevacCargo; }
    distributionTable["Bell206PoliceFuselage"] = { Normal = VehicleDistributions.Bell206Police; }
    distributionTable["Bell206LBMWFuselage"] = { Normal = VehicleDistributions.Bell206News; }
    distributionTable["Bell206SurvivalistFuselage"] = { Normal = VehicleDistributions.Bell206Survivalist; }
    distributionTable["Bell206BlackFuselage"] = { Normal = VehicleDistributions.Bell206Black; }

    -- Supply Drops
    distributionTable["FEMASupplyDrop"] = { Normal = VehicleDistributions.FEMASupplyDrop; }
    distributionTable["SurvivorSupplyDrop"] = { Normal = VehicleDistributions.SurvivorSupplyDrop; }

end

Events.OnPostDistributionMerge.Add(applyLootBoxLoot)