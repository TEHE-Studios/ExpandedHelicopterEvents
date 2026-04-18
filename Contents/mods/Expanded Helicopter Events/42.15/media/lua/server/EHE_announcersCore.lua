local eventSoundHandler = require "EHE_sounds"

local announcerCore = {}

announcerCore.announcers = {}


function announcerCore:registerVoice(ID,data)
	announcerCore.announcers[ID] = data
end


---Sets eHelicopter's announcer voice
---@param specificVoice string|table can be string for specific voice or table to be picked from
function announcerCore.chooseVoice(heli, specificVoice)
	specificVoice = specificVoice or heli.announcerVoice

	local voiceSelectionOptions = {}

	if type(specificVoice) == "table" then
		voiceSelectionOptions = specificVoice
		specificVoice = false
	else
		for voiceID,voiceData in pairs(announcerCore.announcers) do
			if not voiceData["LeaveOutOfRandomSelection"] then
				table.insert(voiceSelectionOptions,voiceID)
			end
		end
	end

	if (not specificVoice) or (specificVoice==true) then
		if #voiceSelectionOptions > 0 then
			local randAnn = ZombRand(1, #voiceSelectionOptions+1)
			specificVoice = voiceSelectionOptions[randAnn]
		end
	end

	if not specificVoice then
		print("EHE: ERR: Unable to initiate voice: "..specificVoice)
		heli.announcerVoice = false
		return
	end
	heli.announcerVoice = announcerCore.announcers[specificVoice]
end


---Announces random line if none is provided
---@param specificLine string
function announcerCore.announce(heli, specificLine)

	if type(heli.announcerVoice)=="boolean" then
		return
	end

	local timeStamp = getTimeInMillis()
	if (heli.timeUntilCanAnnounce > timeStamp) or (heli.lastAttackTime > timeStamp) or (#heli.hostilesToFireOn > 0) then
		return
	end

	if not specificLine then

		if heli.announcerVoice and not heli.announcerVoice["LineCount"] then
			local line_length = 0
			--for each entry in announcer's lines list
			if heli.announcerVoice["Lines"] then
				for _,_ in pairs(heli.announcerVoice["Lines"]) do
					line_length = line_length+1
				end
			end
			--line count is stored
			heli.announcerVoice["LineCount"]=line_length
		end

		local ann_num = ZombRand(1,heli.announcerVoice["LineCount"])

		for k,_ in pairs(heli.announcerVoice["Lines"]) do
			ann_num = ann_num-1
			if ann_num <= 0 then
				specificLine = k
				break
			end
		end
	end

	local line = heli.announcerVoice["Lines"][specificLine]
	local announcePick = line[ZombRand(2,#line+1)]
	local lineDelay = line[1]

	heli.timeUntilCanAnnounce = timeStamp+lineDelay

	if heli.lastAnnouncedLine then
		eventSoundHandler:playEventSound(heli, heli.lastAnnouncedLine,nil, nil, true)
	end
	heli.lastAnnouncedLine = announcePick
	eventSoundHandler:playEventSound(heli, announcePick)
end

return announcerCore