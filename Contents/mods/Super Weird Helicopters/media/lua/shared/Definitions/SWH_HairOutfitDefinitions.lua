HairOutfitDefinitions = HairOutfitDefinitions or {};
-- To Dos add more comments on hair colors. 

HairOutfitDefinitions.haircutOutfitDefinition = {};

local alien = { outfit = "AlienTourist", haircut = "Bald:100", beard = "None:100", haircutColor = "0.99,0.99,0.99:100" }
table.insert(HairOutfitDefinitions.haircutOutfitDefinition, alien)

local taxman = { outfit = "TaxMan", haircut = "Buzzcut:50;Short:50", beard = "None:100" }
table.insert(HairOutfitDefinitions.haircutOutfitDefinition, taxman)

local RJ = { outfit = "RobertJohnson", haircut = "Short:100", beard = "None:100", haircutColor = "0.16,0.08,0.02:100" }
table.insert(HairOutfitDefinitions.haircutOutfitDefinition, RJ)

local fili = { outfit = "Filibuster", haircut = "Short:100", beard = "None:100" }
table.insert(HairOutfitDefinitions.haircutOutfitDefinition, fili)

local SpiffoBoss = { outfit = "SpiffoBoss", haircut = "None:100", beard = "None:100", haircutColor = "0,0,0:0" }
table.insert(HairOutfitDefinitions.haircutOutfitDefinition, SpiffoBoss)
