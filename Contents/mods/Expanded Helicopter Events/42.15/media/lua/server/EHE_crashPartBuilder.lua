if isClient() then return {} end

local EHE_crashPartBuilder = {}
local cache = {}

function EHE_crashPartBuilder.build(vehicleName)
    if cache[vehicleName] ~= nil then return cache[vehicleName] end

    local script = ScriptManager.instance:getVehicle(vehicleName)
    if not script then
        print("EHE crashPartBuilder: vehicle script not found: " .. tostring(vehicleName))
        cache[vehicleName] = false
        return false
    end

    local parts = {}
    for i = 0, script:getPartCount() - 1 do
        local scriptPart = script:getPart(i)
        local tables = scriptPart.tables
        if tables then
            local partVariation = tables:get("partVariation")
            if partVariation then
                local chances = partVariation:rawget("chances")
                if chances then
                    local defaultChance = tonumber(chances:rawget("default"))
                    if defaultChance then
                        local entry = {
                            part = scriptPart:getId(),
                            chance = defaultChance,
                        }
                        local scatter = partVariation:rawget("scatter")
                        if scatter then
                            local scrapItem = scatter:rawget("item")
                            local scrapVehicle = scatter:rawget("vehicle")
                            if scrapItem and scrapItem ~= "" then entry.scrapItem = scrapItem end
                            if scrapVehicle and scrapVehicle ~= "" then entry.scrapVehicle = scrapVehicle end
                        end
                        table.insert(parts, entry)
                    end
                end
            end
        end
    end

    local result = (#parts > 0) and parts or false
    cache[vehicleName] = result
    return result
end

local metaCache = {}

function EHE_crashPartBuilder.getMetalKg(vehicleName)
    if metaCache[vehicleName] ~= nil then return metaCache[vehicleName] end

    local script = ScriptManager.instance:getVehicle(vehicleName)
    if not script then
        metaCache[vehicleName] = false
        return false
    end

    local metaPart = script:getPartById("EHE_meta")
    if not metaPart or not metaPart.tables then
        metaCache[vehicleName] = false
        return false
    end

    local eheTable = metaPart.tables:get("EHE")
    local metalKg = eheTable and tonumber(eheTable:rawget("metalKg"))
    metaCache[vehicleName] = metalKg or false
    return metaCache[vehicleName]
end

function EHE_crashPartBuilder.invalidate(vehicleName)
    cache[vehicleName] = nil
    metaCache[vehicleName] = nil
end

function EHE_crashPartBuilder.invalidateAll()
    cache = {}
    metaCache = {}
end

return EHE_crashPartBuilder
