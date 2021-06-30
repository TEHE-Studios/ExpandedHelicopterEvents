eHelicopter_announcersLoaded = {}
eHelicopter_announcers = {

	-- ["name of announcer"] = {
		-- ["Lines"] = {
			-- ["lineID1"] = {0, "variation1", "variation2"},
			-- For the sake of organization It is recommended you write out some of the spoken audio for "LineID"
		   	-- The first entry within each line is the delay added as it is spoken, every entry after is a file variation and shares the same delay
			-- File names have to match scripted sounds found in sounds_EHE.txt for those scripts to be loaded
		-- }
	-- },


	["Raven Male"] = {
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {6500, "eHeli_lineM_1a", "eHeli_lineM_1b", "eHeli_lineM_1d"},
			["TheSituationIsUnderControl"] = {6500, "eHeli_lineM_2b", "eHeli_lineM_2c", "eHeli_lineM_2d"},
			["ThisAreaIsNowInQuarantine"] = {7000, "eHeli_lineM_3a", "eHeli_lineM_3b", "eHeli_lineM_3c", "eHeli_lineM_3d"},
			["DoNotTryToLeaveTheArea"] = {6500, "eHeli_lineM_5a", "eHeli_lineM_5b", "eHeli_lineM_5c", "eHeli_lineM_5d"},
			["LockAllEntrances"] = {7000, "eHeli_lineM_7b", "eHeli_lineM_7c", "eHeli_lineM_7d"},
			["AvoidContact"] = {6500, "eHeli_lineM_8b", "eHeli_lineM_8c", "eHeli_lineM_8d"},
			["DoNotTryToReachOut"] = {7000, "eHeli_lineM_9a", "eHeli_lineM_9b", "eHeli_lineM_9c", "eHeli_lineM_9d"},
			["AnyCriminalActivity"] = {8500, "eHeli_lineM_10a", "eHeli_lineM_10b"},
			["AnyPersonsTryingToLeave"] = {8500, "eHeli_lineM_6a", "eHeli_lineM_6b", "eHeli_lineM_6c", "eHeli_lineM_6d"},
		}
	},


	["Gabby Female"] = {
		["Lines"] = {
			["PleaseReturnToYourHomes"] = {5750, "eHeli_lineF_1"},
			["TheSituationIsUnderControl"] = {6200, "eHeli_lineF_2"},
			["ThisAreaIsNowInQuarantine"] = {6500, "eHeli_lineF_3"},
			["DoNotTryToLeaveTheArea"] = {6500, "eHeli_lineF_5"},
			["LockAllEntrances"] = {6500, "eHeli_lineF_7"},
			["AvoidContact"] = {5750, "eHeli_lineF_8"},
			["DoNotTryToReachOut"] = {6750, "eHeli_lineF_9"},
			["AnyCriminalActivity"] = {8750, "eHeli_lineF_10"},
			["AnyPersonsTryingToLeave"] = {7500, "eHeli_lineF_6"},
		}
	},


	["Jade Male A"] = {
		["LineCount"] = 0,
		["Lines"] = {
			["ThisAreaIsUnderQuarantine"] = {7500, "eHeli_Jade_1a"},
			["ForTheSafetyOfYourSelf"] = {8500, "eHeli_Jade_2a"},
			["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3a"},
		}
	},


	["Jade Male B"] = {
		["Lines"] = {
			["ThisAreaIsUnderQuarantine"] = {8500, "eHeli_Jade_1b"},
			["ForTheSafetyOfYourSelf"] = {9500, "eHeli_Jade_2b"},
			["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3b"},
		}
	},


	["Jade Male C"] = {
		["Lines"] = {
			["ThisAreaIsUnderQuarantine"] = {8500, "eHeli_Jade_1c"},
			["ForTheSafetyOfYourSelf"] = {9500, "eHeli_Jade_2c"},
			["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3c"},
		}
	},

	["Jade Airdrop"] = {
		["Lines"] = {
			["AttentionSurvivors"] = {8500, "eHeli_AirDrop_1a"},
			["StandbyForDrop"] = {9500, "eHeli_AirDrop_1b"},
		}
	},
	
}
