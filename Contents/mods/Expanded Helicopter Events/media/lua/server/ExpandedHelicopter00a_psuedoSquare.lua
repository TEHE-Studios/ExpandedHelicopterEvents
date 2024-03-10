local pseudoSquare = {}

pseudoSquare.x = 0
pseudoSquare.y = 0
pseudoSquare.z = 0

function pseudoSquare:new(x, y, z)
    local newSquare = copyTable(self)
    newSquare.x = x
    newSquare.y = y
    newSquare.z = z
    return newSquare
end

function pseudoSquare:getX() return self.x end

function pseudoSquare:getY() return self.y end

function pseudoSquare:getZ() return self.z end

function pseudoSquare:getSquare() return getSquare(self.x, self.y, self.z) end

function pseudoSquare:isOutside() return true end

function pseudoSquare:getClass() return { getSimpleName = function() return "pseudoSquare" end } end

return pseudoSquare