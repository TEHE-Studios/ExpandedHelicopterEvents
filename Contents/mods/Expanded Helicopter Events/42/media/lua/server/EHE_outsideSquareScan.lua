function isIsoGridSquareOutside(square)
    if square and square:isOutside() and not square:isSolidTrans() and square:getRoomID()==-1 then
        return true
    end
    return false
end

--This attempts to get the outside (roof or ground) IsoGridSquare to any X/Y coordinate
---@param square IsoGridSquare
---@return IsoGridSquare
function getOutsideSquareFromAbove(square)
    if not square or not instanceof(square, "IsoGridSquare") then return end
    if isIsoGridSquareOutside(square) then
        print("isIsoGridSquareOutside: ",square:getZ())
        return square
    end

    local x, y = square:getX(), square:getY()

    for i=1, 7 do
        local sq = getSquare(x, y, i)
        if isIsoGridSquareOutside(sq) then
            print("isIsoGridSquareOutside: ",square:getZ())
            return sq
        end
    end
end