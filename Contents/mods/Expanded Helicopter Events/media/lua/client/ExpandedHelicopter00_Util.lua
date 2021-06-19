Events.OnGameBoot.Add(print("Expanded Helicopter Events: ver:0.9.2"))

eheBounds = {}
eheBounds.MAX_X = false
eheBounds.MIN_X = false
eheBounds.MAX_Y = false
eheBounds.MIN_Y = false
eheBounds.threshold = 5000

function setDynamicGlobalXY()
	local numActivePlayers = getNumActivePlayers()-1

	eheBounds.MAX_X = false
	eheBounds.MIN_X = false
	eheBounds.MAX_Y = false
	eheBounds.MIN_Y = false

	for i=0, numActivePlayers do
		---@type IsoGameCharacter p
		local p = getSpecificPlayer(i)
		local pX = p:getX()
		local pY = p:getY()

		if not eheBounds.MIN_X then
			eheBounds.MIN_X = pX-eheBounds.threshold
		else
			eheBounds.MIN_X = math.min(eheBounds.MIN_X, pX-eheBounds.threshold)
		end

		if not eheBounds.MAX_X then
			eheBounds.MAX_X = pX+eheBounds.threshold
		else
			eheBounds.MAX_X = math.max(eheBounds.MAX_X, pX+eheBounds.threshold)
		end

		if not eheBounds.MIN_Y then
			eheBounds.MIN_Y = pY-eheBounds.threshold
		else
			eheBounds.MIN_Y = math.min(eheBounds.MIN_Y, pY-eheBounds.threshold)
		end

		if not eheBounds.MAX_Y then
			eheBounds.MAX_Y = pY+eheBounds.threshold
		else
			eheBounds.MAX_Y = math.max(eheBounds.MAX_Y, pY+eheBounds.threshold)
		end
	end

	eheBounds.MAX_X = math.floor(eheBounds.MAX_X)
	eheBounds.MIN_X = math.floor(eheBounds.MIN_X)
	eheBounds.MAX_Y = math.floor(eheBounds.MAX_Y)
	eheBounds.MIN_Y = math.floor(eheBounds.MIN_Y)
	print("EHE: Setting global XY: ".." MIN_X:"..eheBounds.MIN_X.." MAX_X:"..eheBounds.MAX_X.." MIN_Y:"..eheBounds.MIN_Y.." MAX_Y:"..eheBounds.MAX_Y)
end