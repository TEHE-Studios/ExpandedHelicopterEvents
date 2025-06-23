require "EHE_announcers"

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

eHelicopter_announcers["Spiffo"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["Spiffo1"] = {7500, "Spiffo1"},
		["Spiffo2"] = {5500, "Spiffo2"},
		["Spiffo3"] = {4750, "Spiffo3"},
		["Spiffo4"] = {3300, "Spiffo4"},
		["Spiffo5"] = {3500, "Spiffo5"},
		["Spiffo6"] = {3700, "Spiffo6"},
		["Spiffo7"] = {3500, "Spiffo7"},
		["Spiffo8"] = {3000, "Spiffo8"},
		["Spiffo9"] = {3500, "Spiffo9"},
		["Spiffo10"] = {5500, "Spiffo10"},
		["Spiffo11"] = {3500, "Spiffo11"},
		["Spiffo12"] = {4500, "Spiffo12"},
		["Spiffo13"] = {3700, "Spiffo13"},
		["Spiffo14"] = {3700, "Spiffo14"},
		["Spiffo15"] = {12500, "Spiffo15"},
		["Spiffo16"] = {4000, "Spiffo16"},
		["Spiffo17"] = {4500, "Spiffo17"},
		["Spiffo18"] = {14500, "Spiffo18"},
		["Spiffo19"] = {4400, "Spiffo19"},
		["Spiffo20"] = {4500, "Spiffo20"},
		["Spiffo21"] = {4000, "Spiffo21"},
		["Spiffo22"] = {4000, "Spiffo22"},
	} }

eHelicopter_announcers["IRS"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["IRS1"] = {6550, "IRS1"},
		["IRS2"] = {6500, "IRS2"},
		["IRS3"] = {8000, "IRS3"},
		["IRS4"] = {8500, "IRS4"},
		["IRS5"] = {6000, "IRS5"},
		["IRS6"] = {9500, "IRS6"},
		["IRS7"] = {7500, "IRS7"},
		["IRS8"] = {7500, "IRS8"},
		["IRS9"] = {13500, "IRS9"},
		["IRS10"] = {11000, "IRS10"},
	} }

eHelicopter_announcers["Aliens"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["AlienAck"] = {10500, "AlienAck"},
	} }

eHelicopter_announcers["FratAliens"] = {
	["LeaveOutOfRandomSelection"] = true,
	["Lines"] = {
		["AlienFratAck"] = {10500, "AlienFratAck"},
	} }