eHelicopter_announcers = eHelicopter_announcers or {}

--[[

eHelicopter_announcers["name of announcer"] = {
	 ["Lines"] = {
		 ["lineID1"] = {0, "variation1"",
		 -- For the sake of organization It is recommended you write out some of the spoken audio for "LineID"
		 -- The first entry within each line is the delay added as it is spoken, the second is the sound file
		 -- File names have to match scripted sounds found in sounds_EHE.txt for those scripts to be loaded
	 } }

]]


eHelicopter_announcers["IRS"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["IRS1"] = {4550, "IRS1"},
		["IRS2"] = {4500, "IRS2"},
		["IRS3"] = {6000, "IRS3"},
		["IRS4"] = {6500, "IRS4"},
		["IRS5"] = {4000, "IRS5"},
		["IRS6"] = {7500, "IRS6"},
		["IRS7"] = {5500, "IRS7"},
		["IRS8"] = {5500, "IRS8"},
		["IRS9"] = {11500, "IRS9"},
		["IRS10"] = {9000, "IRS10"},
	} }