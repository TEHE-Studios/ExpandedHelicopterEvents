local isoRangeScan = require "EHE_IsoRangeScan"

function isIsoGridSquareOutside(square)
    if square and square:isOutside() and not square:isSolidTrans() and square:getRoomID()==-1 then
        return true
    end
    return false
end

--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function getOutsideSquareFromAbove(square,isVehicle)
    if not instanceof(square, "IsoGridSquare") then return end
    if not square then return end
    if isIsoGridSquareOutside(square) then return square end
    --if isVehicle is true don't allow the code to look for roof tiles
    if isVehicle then return end

    local x, y = square:getX(), square:getY()

    for i=1, 7 do
        local sq = getSquare(x, y, i)
        if isIsoGridSquareOutside(sq) then
            return sq
        end
    end
end

--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
function getOutsideSquareFromAbove_vehicle(square)
    if not instanceof(square, "IsoGridSquare") then return end
    local foundSquare
    local aSqOutsideAbove = {}
    for k,sq in pairs(isoRangeScan.getIsoRange(square, 2)) do
        local outsideSq = getOutsideSquareFromAbove(sq,true)
        if outsideSq then table.insert(aSqOutsideAbove,outsideSq) end
    end
    if #aSqOutsideAbove > 0 then foundSquare = aSqOutsideAbove[ZombRand(#aSqOutsideAbove)+1] end

    return foundSquare
end