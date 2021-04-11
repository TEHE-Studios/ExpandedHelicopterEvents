eHelicopter_announcerCount = 0 -- calculated automatically
eHelicopter_announcers = {

	-- ["name of announcer"] = {
		-- ["LineCount"] = -- calculated automatically
		-- ["Lines"] = {
			-- ["lineID1"] = {0, "variation1", "variation2"},
		   --- The first entry within each line is the delay added after, every variation shares the same delay
			-- For the sake of organization It is recommended you write out the audio for "LineID"
			-- File names have to match scripted sounds found in sounds_world.txt to be loaded
		-- }
	-- },


	["Raven_Male1"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {5.5, "eHeli_lineM_1a", "eHeli_lineM_1b", "eHeli_lineM_1d"},
			["TheSituationIsUnderControl"] = {5.5, "eHeli_lineM_2b", "eHeli_lineM_2c", "eHeli_lineM_2d"},
			["ACurfewIsNowInEffect"] = {6, "eHeli_lineM_4a", "eHeli_lineM_4b", "eHeli_lineM_4c", "eHeli_lineM_4d"},
			["ThisAreaIsNowInQuarantine"] = {6, "eHeli_lineM_3a", "eHeli_lineM_3b", "eHeli_lineM_3c", "eHeli_lineM_3d"},
			["DoNotTryToLeaveTheArea"] = {5.5, "eHeli_lineM_5a", "eHeli_lineM_5b", "eHeli_lineM_5c", "eHeli_lineM_5d"},
			["LockAllEntrancesAndRemainInDoors"] = {6, "eHeli_lineM_7b", "eHeli_lineM_7c", "eHeli_lineM_7d"},
			["AvoidContactWithOthers"] = {5.5, "eHeli_lineM_8b", "eHeli_lineM_8c", "eHeli_lineM_8d"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {6, "eHeli_lineM_9a", "eHeli_lineM_9b", "eHeli_lineM_9c", "eHeli_lineM_9d"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {7.5, "eHeli_lineM_10a", "eHeli_lineM_10b"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {7.5, "eHeli_lineM_6a", "eHeli_lineM_6b", "eHeli_lineM_6c", "eHeli_lineM_6d"},
		}
	},


	["Jade_Female1"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {4.75, "eHeli_lineF_1"},
			["TheSituationIsUnderControl"] = {5.2, "eHeli_lineF_2"},
			["ACurfewIsNowInEffect"] = {5.5, "eHeli_lineF_4"},
			["ThisAreaIsNowInQuarantine"] = {5.5, "eHeli_lineF_3"},
			["DoNotTryToLeaveTheArea"] = {5, "eHeli_lineF_5"},
			["LockAllEntrancesAndRemainInDoors"] = {5.5, "eHeli_lineF_7"},
			["AvoidContactWithOthers"] = {4.75, "eHeli_lineF_8"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {5.75, "eHeli_lineF_9"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {7.75, "eHeli_lineF_10"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {6.5, "eHeli_lineF_6"},
		}
	},


	["Jade_Male_A"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7.5, "eHeli_Jade_1a"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8.5, "eHeli_Jade_2a"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6.25, "eHeli_Jade_3a"},
		}
	},


	["Jade_Male_B"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7.5, "eHeli_Jade_1b"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8.5, "eHeli_Jade_2b"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6.25, "eHeli_Jade_3b"},
		}
	},


	["Jade_Male_C"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7.5, "eHeli_Jade_1c"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8.5, "eHeli_Jade_2c"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6.25, "eHeli_Jade_3c"},
		}
	},


}


--Automatically sets announcer count and respective announcer's line count to use in randomized selection
--This is needed to avoid constant length checks due to the fact Lua does not recognize #length of non-numerated lists
function setAnnouncementLength()
	if eHelicopter_announcerCount > 0 then return end
	
	--total announcers
	local annCount = 0
	
	--for each entry found in announcer list
	for k,_ in pairs(eHelicopter_announcers) do
		annCount = annCount+1
		local line_length = 0
		
		--for each entry in announcer's lines list
		for _,_ in pairs(eHelicopter_announcers[k]["Lines"]) do
			line_length = line_length+1
		end
		--line count is stored
		eHelicopter_announcers[k]["LineCount"]=line_length
	end
	--total announcercount is stored
	eHelicopter_announcerCount = annCount
end

Events.OnGameStart.Add(setAnnouncementLength)


---Sets eHelicopter's announcer voice
---@param specificVoice string
function eHelicopter:chooseVoice(specificVoice)

	if not specificVoice then
		local randAnn = ZombRand(1, eHelicopter_announcerCount)
		for k,_ in pairs(eHelicopter_announcers) do
			randAnn = randAnn-1
			if randAnn <= 0 then
				specificVoice = k
				break
			end
		end
	end

	self.announcerVoice = eHelicopter_announcers[specificVoice]
end


---Announces random line if none is provided
---@param specificLine string
function eHelicopter:announce(specificLine)

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
	local announcePick = line[ZombRand(2,#line)]
	local lineDelay = line[1]
	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.timeUntilCanAnnounce = getTimestamp()+lineDelay

	--stop old emitter to prevent occasional "phantom" announcements
	if self.announceEmitter then
		self.announceEmitter:stopAll()
	end
	--store new emitter to use
	self.announceEmitter = getWorld():getFreeEmitter()
	self.announceEmitter:playSound(announcePick, ehX, ehY, ehZ)
end