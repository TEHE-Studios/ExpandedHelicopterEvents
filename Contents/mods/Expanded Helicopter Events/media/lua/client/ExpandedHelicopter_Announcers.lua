eHelicopter_announcerCount = 0--calculated automatically
eHelicopter_announcers = {
	--name of announcer
	["Raven_Male1"] = {
		-- ["LineCount"] is calculated automatically
		["LineCount"] = 0,
		["Lines"] = {
			--["lineID"] = {"soundScript1", "soundScript2"},
			-- "LineID" has to be the written out audio for the delay in between lines to be properly calculated
			-- File names have to match scripted sounds found in sounds_world.txt
			["PleaseReturnToYourHomes"] = { "eHeli_lineM_1a", "eHeli_lineM_1b", "eHeli_lineM_1d" },
			["TheSituationIsUnderControl"] = { "eHeli_lineM_2b", "eHeli_lineM_2c", "eHeli_lineM_2d" },
			["ThisAreaIsNowInQuarantine"] = { "eHeli_lineM_3a", "eHeli_lineM_3b", "eHeli_lineM_3c", "eHeli_lineM_3d" },
			["ACurfewIsNowInEffect"] = { "eHeli_lineM_4a", "eHeli_lineM_4b", "eHeli_lineM_4c", "eHeli_lineM_4d" },
			["DoNotTryToLeaveTheArea"] = { "eHeli_lineM_5a", "eHeli_lineM_5b", "eHeli_lineM_5c", "eHeli_lineM_5d" },
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = { "eHeli_lineM_6a", "eHeli_lineM_6b", "eHeli_lineM_6c", "eHeli_lineM_6d" },
			["LockAllEntrancesAndRemainInDoors"] = { "eHeli_lineM_7b", "eHeli_lineM_7c", "eHeli_lineM_7d" },
			["AvoidContactWithOthers"] = { "eHeli_lineM_8b", "eHeli_lineM_8c", "eHeli_lineM_8d" },
			["DoNotTryToReachOutToFamilyOrRelatives"] = { "eHeli_lineM_9a", "eHeli_lineM_9b", "eHeli_lineM_9c", "eHeli_lineM_9d" },
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = { "eHeli_lineM_10a", "eHeli_lineM_10b" }
		}
	},


	["Jade_Male_a"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {"eHeli_Jade_1a"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {"eHeli_Jade_2a"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {"eHeli_Jade_3a"},
		}
	},


	["Jade_Male_b"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {"eHeli_Jade_1b"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {"eHeli_Jade_2b"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {"eHeli_Jade_3b"},
		}
	},


	["Jade_Male_c"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantineIRepeatThisAreaIsUnderQuarantine"] = {"eHeli_Jade_1c"},
			["ForTheSafetyOfYourSelfAndYourLovedOnesYouAreAdvisedToRemainInsideAtAllTimesUnlessAbsolutelyNecessary"] = {"eHeli_Jade_2c"},
			["RepeatedAttemptsAtBreachingTheQuarantineZoneMayBeMetWithHostileResponse"] = {"eHeli_Jade_3c"},
		}
	},


	["Jade_Female1"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {"eHeli_lineF_1"},
			["TheSituationIsUnderControl"] = {"eHeli_lineF_2"},
			["ThisAreaIsNowInQuarantine"] = {"eHeli_lineF_3"},
			["ACurfewIsNowInEffect"] = {"eHeli_lineF_4"},
			["DoNotTryToLeaveTheArea"] = {"eHeli_lineF_5"},
			["AnyPersonsTryingToLeaveTheDesignatedAreaWillBeShot"] = {"eHeli_lineF_6"},
			["LockAllEntrancesAndRemainInDoors"] = {"eHeli_lineF_7"},
			["AvoidContactWithOthers"] = {"eHeli_lineF_8"},
			["DoNotTryToReachOutToFamilyOrRelatives"] = {"eHeli_lineF_9"},
			["AnyCriminalActivityOrLootingWillBePunishedToTheFullestExtentOfTheLaw"] = {"eHeli_lineF_10"}
		}
	},

}

function setAnnouncementLength()
	if eHelicopter_announcerCount > 0 then return end

	local annCount = 0
	for k,_ in pairs(eHelicopter_announcers) do
		annCount = annCount+1
		local line_length = 0
		for _,_ in pairs(eHelicopter_announcers[k]["Lines"]) do
			line_length = line_length+1
		end
		eHelicopter_announcers[k]["LineCount"]=line_length
	end
	eHelicopter_announcerCount = annCount
end

Events.OnGameStart.Add(setAnnouncementLength)
