eHelicopter_announcersLoaded = {}
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


	["Raven Male"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {5500, "eHeli_lineM_1a", "eHeli_lineM_1b", "eHeli_lineM_1d"},
			["TheSituationIsUnderControl"] = {5500, "eHeli_lineM_2b", "eHeli_lineM_2c", "eHeli_lineM_2d"},
			["ACurfewIsNowInEffect"] = {6000, "eHeli_lineM_4a", "eHeli_lineM_4b", "eHeli_lineM_4c", "eHeli_lineM_4d"},
			["ThisAreaIsNowInQuarantine"] = {6000, "eHeli_lineM_3a", "eHeli_lineM_3b", "eHeli_lineM_3c", "eHeli_lineM_3d"},
			["DoNotTryToLeaveTheArea"] = {5500, "eHeli_lineM_5a", "eHeli_lineM_5b", "eHeli_lineM_5c", "eHeli_lineM_5d"},
			["LockAllEntrancesAndRemainInDoors"] = {6000, "eHeli_lineM_7b", "eHeli_lineM_7c", "eHeli_lineM_7d"},
			["AvoidContactWithOthers"] = {5500, "eHeli_lineM_8b", "eHeli_lineM_8c", "eHeli_lineM_8d"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {6000, "eHeli_lineM_9a", "eHeli_lineM_9b", "eHeli_lineM_9c", "eHeli_lineM_9d"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {7500, "eHeli_lineM_10a", "eHeli_lineM_10b"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {7500, "eHeli_lineM_6a", "eHeli_lineM_6b", "eHeli_lineM_6c", "eHeli_lineM_6d"},
		}
	},


	["Gabby Female"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {4750, "eHeli_lineF_1"},
			["TheSituationIsUnderControl"] = {5200, "eHeli_lineF_2"},
			["ACurfewIsNowInEffect"] = {5500, "eHeli_lineF_4"},
			["ThisAreaIsNowInQuarantine"] = {5500, "eHeli_lineF_3"},
			["DoNotTryToLeaveTheArea"] = {5500, "eHeli_lineF_5"},
			["LockAllEntrancesAndRemainInDoors"] = {5500, "eHeli_lineF_7"},
			["AvoidContactWithOthers"] = {4750, "eHeli_lineF_8"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {5750, "eHeli_lineF_9"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {7750, "eHeli_lineF_10"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {6500, "eHeli_lineF_6"},
		}
	},


	["Jade Male A"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7500, "eHeli_Jade_1a"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8500, "eHeli_Jade_2a"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6250, "eHeli_Jade_3a"},
		}
	},


	["Jade Male B"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7500, "eHeli_Jade_1b"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8500, "eHeli_Jade_2b"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6250, "eHeli_Jade_3b"},
		}
	},


	["Jade Male C"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {7500, "eHeli_Jade_1c"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {8500, "eHeli_Jade_2c"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {6250, "eHeli_Jade_3c"},
		}
	},


}


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
---@param specificVoice string
function eHelicopter:chooseVoice(specificVoice)
	if #eHelicopter_announcersLoaded < 1 then
		return
	end

	if not specificVoice then
		local randAnn = ZombRand(1, #eHelicopter_announcersLoaded)
		specificVoice = eHelicopter_announcersLoaded[randAnn]
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
	local announcePick = line[ZombRand(2,#line)]
	local lineDelay = line[1]
	local ehX, ehY, ehZ = self:getXYZAsInt()

	self.timeUntilCanAnnounce = getTimestampMs()+lineDelay

	--stop old emitter to prevent occasional "phantom" announcements
	if self.announceEmitter then
		self.announceEmitter:stopAll()
	end
	--store new emitter to use
	self.announceEmitter = getWorld():getFreeEmitter()
	self.announceEmitter:playSound(announcePick, ehX, ehY, ehZ)
end