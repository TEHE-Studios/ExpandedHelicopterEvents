--Automatically sets respective announcer's line count to use in randomized selection
--This is needed to avoid constant length checks due to the fact Lua does not recognize #length of non-numerated lists
function setAnnouncementLength()
	--for each entry found in announcer list
	for k,_ in pairs(eHelicopter_announcers) do
		local line_length = 0

		--for each entry in announcer's lines list
		for _,_ in pairs(eHelicopter_announcers[k]["Lines"]) do
			line_length = line_length+1
		end
		--line count is stored
		eHelicopter_announcers[k]["LineCount"]=line_length
	end
end
--run at Lua loading
setAnnouncementLength()


---Sets eHelicopter's announcer voice
---@param specificVoice string|table can be string for specific voice or table to be picked from
function eHelicopter:chooseVoice(specificVoice)
	if #eHelicopter_announcersLoaded < 1 then
		return
	end

	local voiceSelectionMaxIndex = #eHelicopter_announcersLoaded
	local voiceSelectionOptions = eHelicopter_announcersLoaded

	if type(specificVoice) == "table" then
		voiceSelectionMaxIndex = #specificVoice
		voiceSelectionOptions = specificVoice
		specificVoice = false
	end

	if not specificVoice then
		local randAnn = ZombRand(1, voiceSelectionMaxIndex+1)
		specificVoice = voiceSelectionOptions[randAnn]
	end

	if not specificVoice then
		print("EHE: ERR: Unable to initiate voice: "..specificVoice)
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

	local timeStamp = getTimestampMs()
	if (self.timeUntilCanAnnounce > timeStamp) or (self.lastAttackTime > timeStamp) or (#self.hostilesToFireOn > 0) then
		return
	end

	if not specificLine then

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
	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.timeUntilCanAnnounce = getTimestampMs()+lineDelay
	self.announceEmitter = self.announceEmitter or getWorld():getFreeEmitter()

	if self.announceEmitter and self.lastAnnouncedLine then
		self.announceEmitter:stopSoundByName(self.lastAnnouncedLine)
	end
	self.lastAnnouncedLine = announcePick
	self.announceEmitter:playSound(announcePick, ehX, ehY, ehZ)
end