require "Vehicles/VehicleDistributions.lua"

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

VehicleDistributions.UFOSeat = {
    rolls = 6,
    items ={
        "SWH.AlienBlaster", 4,
        "SWH.AlienBlaster", 3,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.StrangeNewspaper", 5,
        "SWH.StrangeNewspaper", 5,
        "SWH.StrangeNewspaper", 5,
    }
}

VehicleDistributions.UFOTrunk = {
    rolls = 6,
    items ={
        "SWH.AlienBlaster", 7,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.StrangeNewspaper", 5,
        "SWH.StrangeNewspaper", 5,
        "SWH.StrangeNewspaper", 5,
    }
}

VehicleDistributions.UFORedneckSeat = {
    rolls = 6,
    items ={
        "SWH.AlienBlaster", 4,
        "SWH.AlienBlaster", 3,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
        "SWH.AlienPowerCells", 10,
    }
}

VehicleDistributions.UFORedneckTrunk = {
    rolls = 10,
    items ={
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
        "BeerCan", 10,
    }
}

VehicleDistributions.TISTrunk = {
    rolls = 6,
    items ={
        "SWH.SWH_IceCreamBox", 10,
        "SWH.SWH_IceCreamBox", 10,
        "SWH.SWH_IceCreamBox", 10,
        "Base.SWH_IceCreamBox", 10,
        "Base.SWH_IceCreamBox", 10,
    }
}

VehicleDistributions.SpiffoBurger = {
    rolls = 18,
    items ={
        "SWH.SWH_SpiffoBox", 25,
    }
}

VehicleDistributions.MCSupplyDrop = {
    rolls = 64,
    items ={
        "Base.Dirtbag", 1000,
        "EHE.SurvivorSupplyBox", 1,
        "EHE.SurvivorSupplyBox", 2,
        "EHE.SurvivorSupplyBox", 1,
        "EHE.SurvivorSupplyBox", 1,
        "EHE.SurvivorSupplyBox", 1,
        "EHE.SurvivorSupplyBox", 1,
        "EHE.SurvivorSupplyBox", 1,
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


VehicleDistributions.UFO = {
	
	SeatFrontLeft = VehicleDistributions.UFOSeat;
	SeatFrontRight =  VehicleDistributions.UFOSeat;
    TruckBed = VehicleDistributions.UFOTrunk;
}


VehicleDistributions.UFORedneck = {
	
	SeatFrontLeft = VehicleDistributions.UFORedneckSeat;
	SeatFrontRight =  VehicleDistributions.UFORedneckSeat;
    TruckBed = VehicleDistributions.UFORedneckTrunk;
}

VehicleDistributions.IceCreamTrunk = {
	
	SeatFrontLeft = VehicleDistributions.TISTrunk;
	SeatFrontRight =  VehicleDistributions.TISTrunk;
    TruckBed = VehicleDistributions.TISTrunk;
}

--Supply Drop
VehicleDistributions.SpiffoBurger = {

    TruckBed = VehicleDistributions.SpiffoBurger;
}

VehicleDistributions.MCSupplyDrop = {

    TruckBed = VehicleDistributions.MCSupplyDrop;
}

--Distribution

distributionTable["Bell206IRS"] = { Normal = VehicleDistributions.Bell206IRSFuselage; }
distributionTable["Bell206Spiffo"] = { Normal = VehicleDistributions.Bell206SpiffoFuselage; }
distributionTable["UFO"] = { Normal = VehicleDistributions.UFO; }
distributionTable["UFORedneck"] = { Normal = VehicleDistributions.UFORedneck; }
distributionTable["TISIceCreamTruck"] = { Normal = VehicleDistributions.IceCreamTrunk; }

-- Spiffo Supply Drop

distributionTable["SpiffoBurger"] = { Normal = VehicleDistributions.SpiffoBurger; }

distributionTable["MCSupplyDrop"] = { Normal = VehicleDistributions.MCSupplyDrop; }