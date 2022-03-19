require "Vehicle/Vehicles"

-- TO DO: Learn not to just paste functions over and over

function Vehicles.ContainerAccess.HelicopterInterior(vehicle, part, chr)
    if chr:getVehicle() == vehicle then
        return true
    end
end
