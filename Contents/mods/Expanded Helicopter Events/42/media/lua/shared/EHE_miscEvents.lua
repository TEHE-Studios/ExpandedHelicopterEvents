---@param heli eHelicopter
function eHelicopter_dropCrewOff(heli)
	if not heli then
		return
	end

	local x, y, z = heli:getXYZAsInt()
	local xOffset = ZombRand(20,35)
	local yOffset = ZombRand(20,35)

	local trueTarget = heli.trueTarget
	if trueTarget then
		local tX, tY = trueTarget:getX(), trueTarget:getY()
		xOffset=math.max(0,xOffset-tX)
		yOffset=math.max(0,yOffset-tY)
	end

	if ZombRand(101) <= 50 then
		xOffset=0-xOffset
	end
	if ZombRand(101) <= 50 then
		yOffset=0-yOffset
	end

	x = x+xOffset
	y = y+yOffset

	--[[DEBUG]] print("EHE: DEBUG: eHelicopter_dropCrewOff: "..x..","..y)
	--for k,v in pairs(heli.crew) do print(" -- k:"..tostring(k).." -- ("..tostring(v)..")") end

	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/crew.png", 750, x, y, heli.markerColor)
	heli:spawnDeadCrew(x, y, 0)
	heli.addedFunctionsToEvents.OnHover = false
end


---@param crew table
function eHelicopter_crewSeek(crew)

	if not crew then
		return
	end

	local choice
	local location

	if crew:size() > 0 then
		location = crew:get(0):getSquare()
	end
	if not location then
		return
	end

	for character,_ in pairs(EHEIsoPlayers) do
		if (not choice) or (choice and character and (location:DistTo(choice) < location:DistTo(character)) ) then
			choice = character
		end
	end

	if choice then
		for i=0, crew:size()-1 do
			---@type IsoZombie
			local zombie = crew:get(i)
			if zombie then
				zombie:spotted(choice, true)
			end
		end
	end
end


--00_Hunters  f9e0dc17-95a0-4cb9-97f1-b04bfc448c96
--01_Rednecks  f6e2ca8c-311e-4ee2-9fe6-1c9e14dbcd11
--02_Sport  f06e063f-551c-4fd5-aa19-bc15185c2371
--03_Butchers  8db5a57f-b0a9-4b04-9228-beeadd2db2fa
--04_Criminals  1eb2f74a-8d09-4346-8ba4-3a02665647e5
--05_Spike  94d0c40a-539f-480a-883e-f3fdf15c703f
--06_Robbers  f8aa0e8c-92ee-4dce-99e8-e4cc3a5a8fbe
--07_Heretics  2681ecf5-d0d9-481d-b769-7c4fb626eb81
--08_Hikers  6e319aac-4480-4367-aa9a-5d4bf2ced9d1
--09_Leather  48b1d4b0-ca4e-4b02-ab56-e1fff39afe48
--10_Mafia  cf115969-1f01-425e-9f42-bc4aec99555a
--11_Cannibals  b7d3a430-e966-48e8-97fa-9078c8d848a4
--12_Medieval  bf5985eb-7cb0-44ba-8392-f656ffe421f4
--12_Militia  6e147770-2d41-4fd2-ab7d-05a8acf4157b
--13_Trash  fe1a8e07-7c73-466d-9ade-2e3e565dcb21
--14_Hermits  a5def10b-bab9-46b1-8e8c-d5152c86457e
--15_Legion  49facd22-4067-4ebd-9196-9bf6951a435c
--ArmyDesert  a2dec2f0-c76d-4640-8a71-733a547a1ebc
--ArmyGreen  d2860ee6-7e18-4132-ad42-8fb3a34ea499
--ArmyGreenMask  ce526bd8-a230-4d21-a1f8-5e30790b366f
--BabeFemale  a3bd90b9-aa08-44b2-8be3-a6dfcf15f9e1
--BabeMale  303cd279-a36a-4e4a-b448-ac1ef1c83b7d
--BanditsSpike  72fbcd15-a81b-476a-8c25-1b2caea694de
--BanditsStrong  bbe0c8c9-1135-4ced-abd2-73807e166a1e
--Baseball  c5c7f769-e5e8-44bb-ada6-cdf00ee2c234
--Bikers  f3ad89be-9368-4df7-a63b-0c315a96f23b
--CriminalsBlack  eacda00e-6f8f-4afa-a813-f847d54720d8
--CriminalsClassy  d6c3c644-42e7-466a-8ce4-c002ad29dd50
--CriminalsWhite  8736f2bd-3b08-4ae3-b5f2-1d6a3225e892
--Firemen  989f4faf-53f2-4f8f-9603-496fb3efcb6a
--Fossoil  25f86d1a-03f6-461a-ac46-a936587930d0
--Gardeners  76e0eb48-ee72-45ac-9b1b-56a66f597235
--Gas2Go  31e340cf-c773-4b1c-9e27-8317db82823f
--HammerBrothers  a3048300-2bca-4140-b256-b249da951b60
--Inmates  c15cc316-41f9-4c2c-b71a-3a3fb58c247d
--Janitors  e195497c-9a14-4c1f-b15a-b8227d15a682
--Karate  0dfc13d3-4ce6-4af8-aac6-326eb7514c36
--Kitchen  544f827c-cdb3-47d0-a895-3767b67a72c0
--MedicHazmats  cfccfa27-f256-47a0-bd7c-b2d12b369c6d
--Medics  f8c5c06b-2fd7-482d-8150-2be03d446927
--Mentals  51a68231-8870-4508-8c09-bd906b4411d2
--Office  affef50f-660a-4231-bc6d-e0054fcf3afd
--Officers  d7ba1cc0-de47-4162-b5bd-6295c47b890d
--Party  42364b66-ab03-4c38-b374-5575a0c24868
--PoliceBlue  c4e24888-70f9-43ea-80f8-1bb2f6b9bd88
--PoliceGray  33894253-b965-4eb3-94e1-4d642cadac88
--PoliceRiot  526e57b9-52cf-42a8-a17b-50e32e4d33f3
--Postal  e216b4ea-e57f-4b15-8cd8-140b82e7b5ea
--Priest  cfecc181-508e-4c5b-85ce-7a0d21ce8537
--Prison  8365593d-f3b2-4e93-a96f-29315f83c51f
--Rangers  3a424953-fa5b-418f-8f11-462e52bfd574
--Residents  f52b03f4-c5b1-4bbb-a110-b74038312fe2
--Runners  bd53300c-f715-4cf7-a91f-1836a2282944
--SWAT  b6c61446-ad6c-4529-9bac-751b9b64843f
--SecretLab  f89205ff-7f90-4360-8f84-1d8faa3650e7
--Security  dcc2a5e9-2670-42f9-8ac2-65566e8f2537
--Shahids  9699d022-eebb-4c80-9b39-f48f392f2823
--ShopAssistant  473e2db3-c751-4a09-9a1d-d780e148b6a1
--Students  5ce44f42-d5f5-4036-b408-26d42fd883ef
--Survivors  65218e00-bdf0-4d67-bcc1-75bcc86cb2c9
--Sweepers  9bf4882b-0622-4e77-82c1-feee90b566b4
--Teachers  784b6f20-87d5-48f7-8ac2-74466f7720ac
--Veterans  c4878ebb-c8e5-4932-8850-370ee9c77d61
--Waiters  7da39ab5-9ddc-4590-8009-f4c148bc5dd6
--Walkers  c167d1e0-c077-4ee5-b353-88b374de193d
--Wedding  e42fc351-dd10-4a0c-a154-b383cef3b987
require "BanditServerSpawner.lua"
function eHelicopter_spawnNPCs(heli)

	if not heli or not heli.crew then return end
	local x, y, z = heli:getXYZAsInt()
	z = 0

	if not (BanditServer and BanditServer.Spawner and BanditServer.Spawner.Clan) then self:spawnDeadCrew(x, y, z) return end

	local valid = 0
	for i=0, #heli.crew do if type(heli.crew[i]) == "string" then valid = valid + 1 end end
	if valid <=0 then return end

	local args = {
		x = x, y = y, z = z,
		size = valid,
		cid = "f3ad89be-9368-4df7-a63b-0c315a96f23b",
		program = "Bandit",--?
		pid = nil,--player,

	}

	--[[
	--- Paste this into console for printout of cids
	BanditCustom.Load()
	local clanData  = BanditCustom.ClanGetAllSorted()
	for cid, clan in pairs(clanData) do
		print(clan.general.name.."  "..cid)
	end
	--]]

	eventMarkerHandler.setOrUpdate(getRandomUUID(), "media/ui/bandits.png", 250, x, y, heli.markerColor)

	heli.crew = false
	--- BanditServer.Spawner.Clan(player, args)
	sendClientCommand("SpawnerAPI", "spawn", { funcType="NPCs", spawnThis=args, x=x, y=y, z=z, })
end