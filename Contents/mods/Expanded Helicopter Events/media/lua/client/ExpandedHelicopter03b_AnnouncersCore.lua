require "ExpandedHelicopter01b_MainSounds"

---Sets eHelicopter's announcer voice
---@param specificVoice string|table can be string for specific voice or table to be picked from
function eHelicopter:chooseVoice(specificVoice)

	local voiceSelectionOptions = {}

	if type(specificVoice) == "table" then
		voiceSelectionOptions = specificVoice
		specificVoice = false
	else
		for voiceID,voiceData in pairs(eHelicopter_announcers) do
			if (not voiceData["LeaveOutOfRandomSelection"]) and (eHelicopterSandbox.config[voiceID] == true) then
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
		self.announcerVoice = false
		return
	end
	self.announcerVoice = eHelicopter_announcers[specificVoice]
end


---Announces random line if none is provided
---@param specificLine string
function eHelicopter:announce(specificLine)

	if type(self.announcerVoice)=="boolean" then
		return
	end

	local timeStamp = getTimeInMillis()
	if (self.timeUntilCanAnnounce > timeStamp) or (self.lastAttackTime > timeStamp) or (#self.hostilesToFireOn > 0) then
		return
	end

	if not specificLine then

		if self.announcerVoice and not self.announcerVoice["LineCount"] then
			local line_length = 0
			--for each entry in announcer's lines list
			if self.announcerVoice["Lines"] then
				for _,_ in pairs(self.announcerVoice["Lines"]) do
					line_length = line_length+1
				end
			end
			--line count is stored
			self.announcerVoice["LineCount"]=line_length
		end

		local ann_num = ZombRand(1,self.announcerVoice["LineCount"])

		for k,_ in pairs(self.announcerVoice["Lines"]) do
			ann_num = ann_num-1
			if ann_num <= 0 then
				specificLine = k
				break
			end
		end
	end

	local line = self.announcerVoice["Lines"][specificLine]
	local announcePick = line[ZombRand(2,#line+1)]
	local lineDelay = line[1]

	self.timeUntilCanAnnounce = timeStamp+lineDelay

	if self.lastAnnouncedLine then
		eventSoundHandler:playEventSound(self, self.lastAnnouncedLine,nil, nil, true)
	end
	self.lastAnnouncedLine = announcePick
	eventSoundHandler:playEventSound(self, announcePick)
end