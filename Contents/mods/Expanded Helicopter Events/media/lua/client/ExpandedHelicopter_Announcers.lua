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
			["PleaseReturnToYourHomes"] = {2.5, "eHeli_lineM_1a", "eHeli_lineM_1b", "eHeli_lineM_1d"},
			["TheSituationIsUnderControl"] = {3, "eHeli_lineM_2b", "eHeli_lineM_2c", "eHeli_lineM_2d"},
			["ACurfewIsNowInEffect"] = {2.5, "eHeli_lineM_4a", "eHeli_lineM_4b", "eHeli_lineM_4c", "eHeli_lineM_4d"},
			["ThisAreaIsNowInQuarantine"] = {3, "eHeli_lineM_3a", "eHeli_lineM_3b", "eHeli_lineM_3c", "eHeli_lineM_3d"},
			["DoNotTryToLeaveTheArea"] = {2.5, "eHeli_lineM_5a", "eHeli_lineM_5b", "eHeli_lineM_5c", "eHeli_lineM_5d"},
			["LockAllEntrancesAndRemainInDoors"] = {3.5, "eHeli_lineM_7b", "eHeli_lineM_7c", "eHeli_lineM_7d"},
			["AvoidContactWithOthers"] = {2, "eHeli_lineM_8b", "eHeli_lineM_8c", "eHeli_lineM_8d"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {3, "eHeli_lineM_9a", "eHeli_lineM_9b", "eHeli_lineM_9c", "eHeli_lineM_9d"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {5, "eHeli_lineM_10a", "eHeli_lineM_10b"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {5, "eHeli_lineM_6a", "eHeli_lineM_6b", "eHeli_lineM_6c", "eHeli_lineM_6d"},
		}
	},


	["Jade_Female1"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {2.5, "eHeli_lineF_1"},
			["TheSituationIsUnderControl"] = {2.5, "eHeli_lineF_2"},
			["ACurfewIsNowInEffect"] = {2, "eHeli_lineF_4"},
			["ThisAreaIsNowInQuarantine"] = {2.5, "eHeli_lineF_3"},
			["DoNotTryToLeaveTheArea"] = {2.5, "eHeli_lineF_5"},
			["LockAllEntrancesAndRemainInDoors"] = {3, "eHeli_lineF_7"},
			["AvoidContactWithOthers"] = {2, "eHeli_lineF_8"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {3.5, "eHeli_lineF_9"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {5, "eHeli_lineF_10"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {4, "eHeli_lineF_6"},
		}
	},


	["Jade_Male_A"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {5.5, "eHeli_Jade_1a"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {7.5, "eHeli_Jade_2a"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {4.5, "eHeli_Jade_3a"},
		}
	},


	["Jade_Male_B"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {5.5, "eHeli_Jade_1b"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {7.5, "eHeli_Jade_2b"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {4, "eHeli_Jade_3b"},
		}
	},


	["Jade_Male_C"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {5.5, "eHeli_Jade_1c"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {7.5, "eHeli_Jade_2c"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {4, "eHeli_Jade_3c"},
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
