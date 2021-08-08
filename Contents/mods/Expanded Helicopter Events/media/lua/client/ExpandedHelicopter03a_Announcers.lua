eHelicopter_announcers = eHelicopter_announcers or {}

--[[

eHelicopter_announcers["name of announcer"] = {
	 ["Lines"] = {
		 ["lineID1"] = {0, "variation1"},
		 -- For the sake of organization It is recommended you write out some of the spoken audio for "LineID"
		 -- The first entry within each line is the delay added as it is spoken, the second is the sound file
		 -- File names have to match scripted sounds found in sounds_EHE.txt for those scripts to be loaded
	 } }

]]

eHelicopter_announcers["Raven Male"] = {
	["Lines"] = {
		["PleaseReturnToYourHomes"] = {6500, "eHeli_lineM_1"},
		["TheSituationIsUnderControl"] = {6500, "eHeli_lineM_2"},
		["ThisAreaIsNowInQuarantine"] = {7000, "eHeli_lineM_3"},
		["DoNotTryToLeaveTheArea"] = {6500, "eHeli_lineM_5"},
		["LockAllEntrances"] = {7000, "eHeli_lineM_7"},
		["AvoidContact"] = {6500, "eHeli_lineM_8"},
		["DoNotTryToReachOut"] = {7000, "eHeli_lineM_9"},
		["AnyCriminalActivity"] = {8500, "eHeli_lineM_10"},
		["AnyPersonsTryingToLeave"] = {8500, "eHeli_lineM_6"},
	} }

eHelicopter_announcers["Gabby Female"] = {
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
	} }

eHelicopter_announcers["Jade Male A"] = {
	["LineCount"] = 0,
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {7500, "eHeli_Jade_1a"},
		["ForTheSafetyOfYourSelf"] = {8500, "eHeli_Jade_2a"},
		["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3a"},
	} }

eHelicopter_announcers["Jade Male B"] = {
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {8500, "eHeli_Jade_1b"},
		["ForTheSafetyOfYourSelf"] = {9500, "eHeli_Jade_2b"},
		["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3b"},
	} }

eHelicopter_announcers["Jade Male C"] = {
	["Lines"] = {
		["ThisAreaIsUnderQuarantine"] = {8500, "eHeli_Jade_1c"},
		["ForTheSafetyOfYourSelf"] = {9500, "eHeli_Jade_2c"},
		["RepeatedAttemptsAtBreaching"] = {7250, "eHeli_Jade_3c"},
	} }

eHelicopter_announcers["Police"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["PoliceLines"] = {8500, "eHeli_police_lines"},
	} }
