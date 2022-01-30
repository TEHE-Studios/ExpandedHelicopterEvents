eHelicopter_announcers = eHelicopter_announcers or {}

--[[

eHelicopter_announcers["name of announcer"] = {
	 ["Lines"] = {
		 ["lineID1"] = {0, "variation1"},
		 -- For the sake of organization It is recommended you write out some of the spoken audio for "LineID"
		 -- The first entry within each line is the delay added as it is spoken, the second is the sound file
		 -- File names have to match scripted sounds found in sounds_EHE.txt for those scripts to be loaded

		 -- ["LeaveOutOfRandomSelection"] = true,
		 -- ["DoNotDisplayOnOptions"] = true,
	 } }

]]

eHelicopter_announcers["Raven Male"] = {
	["Lines"] = {
		["PleaseReturnToYourHomes"] = {7500, "eHeli_lineM_1"},
		["TheSituationIsUnderControl"] = {7500, "eHeli_lineM_2"},
		["ThisAreaIsNowInQuarantine"] = {8000, "eHeli_lineM_3"},
		["DoNotTryToLeaveTheArea"] = {7500, "eHeli_lineM_5"},
		["LockAllEntrances"] = {8000, "eHeli_lineM_7"},
		["AvoidContact"] = {7500, "eHeli_lineM_8"},
		["DoNotTryToReachOut"] = {8000, "eHeli_lineM_9"},
		["AnyCriminalActivity"] = {9500, "eHeli_lineM_10"},
		["AnyPersonsTryingToLeave"] = {9500, "eHeli_lineM_6"},
	} }

eHelicopter_announcers["Gabby Female"] = {
	["Lines"] = {
		["PleaseReturnToYourHomes"] = {6750, "eHeli_lineF_1"},
		["TheSituationIsUnderControl"] = {7200, "eHeli_lineF_2"},
		["ThisAreaIsNowInQuarantine"] = {7500, "eHeli_lineF_3"},
		["DoNotTryToLeaveTheArea"] = {7500, "eHeli_lineF_5"},
		["LockAllEntrances"] = {7500, "eHeli_lineF_7"},
		["AvoidContact"] = {6750, "eHeli_lineF_8"},
		["DoNotTryToReachOut"] = {7750, "eHeli_lineF_9"},
		["AnyCriminalActivity"] = {9750, "eHeli_lineF_10"},
		["AnyPersonsTryingToLeave"] = {8500, "eHeli_lineF_6"},
	} }

eHelicopter_announcers["Jade Male A"] = {
	["LineCount"] = 0,
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {9500*2, "eHeli_Jade_1a"},
		["ForTheSafetyOfYourSelf"] = {10500*2, "eHeli_Jade_2a"},
		["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3a"},
	} }

eHelicopter_announcers["Jade Male B"] = {
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {10500*2, "eHeli_Jade_1b"},
		["ForTheSafetyOfYourSelf"] = {11500*2, "eHeli_Jade_2b"},
		["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3b"},
	} }

eHelicopter_announcers["Jade Male C"] = {
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {10500*2, "eHeli_Jade_1c"},
		["ForTheSafetyOfYourSelf"] = {11500*2, "eHeli_Jade_2c"},
		["RepeatedAttemptsAtBreaching"] = {9250*2, "eHeli_Jade_3c"},
	} }

eHelicopter_announcers["FlyerChoppers"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["FlyerChoppers"] = {10500*2, "eHeli_lineM_11"},
	} }


eHelicopter_announcers["Police"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["PoliceLines"] = {8500, "eHeli_police_lines"},
	} }