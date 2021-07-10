-- pull the vehicle distributions into a local table
local distributionTable = VehicleDistributions[1]



VehicleDistributions.Bell206IRSSeat = {
    rolls = 2,
    items ={
        "AssaultRifle", 5,
        "AssaultRifle", 5,
        "AssaultRifle", 5,
        "AssaultRifle", 5,
        "Pistol", 5,
        "Pistol", 5,
        "9mmClip", 3,
        "9mmClip", 3,
        "9mmClip", 3,
        "Bullets9mm", 3,
    }
}

VehicleDistributions.Bell206SpiffoSeat = {
    rolls = 2,
    items ={
        "Spiffo", 5,
        "Spiffo", 5,
        "Spiffo", 5,
        "Spiffo", 3,
        "9mmClip", 3,
        "9mmClip", 3,
        "Bullets9mm", 3,
    }
}

VehicleDistributions.SpiffoBurger = {
    rolls = 50,
    items ={
        "EHE.SpiffoDolls", 2,
        "EHE.SpiffoMerchandise", 2,
        "EHE.BurgerBox", 2,

        "EHE.SpiffoDolls", 2,
        "EHE.SpiffoMerchandise", 2,
        "EHE.BurgerBox", 2,

        "EHE.SpiffoDolls", 2,
        "EHE.SpiffoMerchandise", 2,
        "EHE.BurgerBox", 2,

        "EHE.SpiffoDolls", 2,
        "EHE.SpiffoMerchandise", 2,
        "EHE.BurgerBox", 2,

        "EHE.SpiffoDolls", 2,
        "EHE.SpiffoMerchandise", 2,
        "EHE.BurgerBox", 2,
    }
}

VehicleDistributions.Bell206IRS = {
	
    SeatFrontLeft = VehicleDistributions.Bell206IRSSeat;
    SeatFrontRight =  VehicleDistributions.Bell206IRSSeat;
    SeatRearLeft =  VehicleDistributions.Bell206IRSSeat;
    SeatRearRight =  VehicleDistributions.Bell206IRSSeat;
}    

VehicleDistributions.Bell206Spiffo = {
	
	SeatFrontLeft = VehicleDistributions.Bell206SpiffoSeat;
	SeatFrontRight =  VehicleDistributions.Bell206SpiffoSeat;
	SeatRearLeft =  VehicleDistributions.Bell206PSpiffoSeat;
	SeatRearRight =  VehicleDistributions.Bell206SpiffoSeat;
}

--Supply Drop
VehicleDistributions.SpiffoBurger = {
	
    TruckBed = VehicleDistributions.SpiffoBurger;

}    

--Distribution

distributionTable["Bell206IRS"] = { Normal = VehicleDistributions.Bell206IRSFuselage; }
distributionTable["Bell206Spiffo"] = { Normal = VehicleDistributions.Bell206SpiffoFuselage; }

-- Spiffo Supply Drop

distributionTable["SpiffoBurger"] = { Normal = VehicleDistributions.SpiffoBurger; }

