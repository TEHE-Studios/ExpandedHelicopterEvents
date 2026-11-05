local weaponStats = {}

---EHE damage per point of in-game weapon damage (zombies take damage*3/50 in heliEventAttackHitOnIsoGameCharacter)
weaponStats.damageScale = 50/3

weaponStats.defaults = {
	minDamage = 1,
	maxDamage = 1,
	hitChance = 85,
	fireSound = false,
	soundRadius = 75,
	projectileCount = 1,
	explosive = false,
	spread = 0,
	blastRadius = 0,
	firePower = 0,
	impactSound = false,
	cooldown = 0,
}

---Event-only weapons, registered by ID with weaponStats.register
weaponStats.templates = {}

---Resolved stats by ID, script weapons are only read once
weaponStats.cache = {}


---@param ID string
---@param stats table any keys from weaponStats.defaults, missing keys are filled from defaults
function weaponStats.register(ID, stats)
	weaponStats.templates[ID] = stats
	weaponStats.cache[ID] = nil
end


function weaponStats.fillDefaults(stats)
	local filled = {}
	for k,v in pairs(weaponStats.defaults) do filled[k] = v end
	for k,v in pairs(stats) do filled[k] = v end
	return filled
end


---@param ID string item script full type
function weaponStats.fromScript(ID)
	local weapon = instanceItem(ID)
	if not weapon or not instanceof(weapon, "HandWeapon") then
		print("EHE: weaponStats: "..tostring(ID).." is not a weapon.")
		return false
	end

	local blastRadius = math.max(weapon:getExplosionRange(), weapon:getFireRange())

	return weaponStats.fillDefaults({
		minDamage = weapon:getMinDamage(),
		maxDamage = weapon:getMaxDamage(),
		hitChance = weapon:getHitChance(),
		fireSound = weapon:getSwingSound(),
		soundRadius = weapon:getSoundRadius(),
		projectileCount = math.max(1, weapon:getProjectileCount()),
		explosive = blastRadius > 0,
		blastRadius = blastRadius,
		firePower = (weapon:getFireRange() > 0) and weapon:getFireStartingChance() or 0,
		impactSound = weapon:getExplosionSound(),
	})
end


---@param ID string template ID or item script full type
---@return table|boolean
function weaponStats.get(ID)
	if weaponStats.cache[ID] == nil then
		local template = weaponStats.templates[ID]
		weaponStats.cache[ID] = template and weaponStats.fillDefaults(template) or weaponStats.fromScript(ID)
	end
	return weaponStats.cache[ID]
end


---@param weaponArray table|string single ID, or IDs each optionally followed by a weight; "default" uses the preset's attackDamage/attackHitChance
---@param cooldowns table|nil ID = timestamp when available again
---@return string|nil ID, table|nil stats
function weaponStats.pick(weaponArray, cooldowns)
	if not weaponArray then return end
	if type(weaponArray) == "string" then weaponArray = {weaponArray} end

	local now = getTimeInMillis()
	local pool = {}
	for key,entry in ipairs(weaponArray) do
		if type(entry) == "string" then
			local weight = weaponArray[key+1]
			if type(weight) ~= "number" then weight = 1 end
			if (not cooldowns) or (not cooldowns[entry]) or (cooldowns[entry] <= now) then
				for i=1, weight do table.insert(pool, entry) end
			end
		end
	end

	local ID = pool[ZombRand(#pool)+1]
	if not ID or ID == "default" then return end

	local stats = weaponStats.get(ID)
	if not stats then return end
	if cooldowns and stats.cooldown > 0 then cooldowns[ID] = now+stats.cooldown end

	return ID, stats
end


weaponStats.register("EHE_Hydra70", {
	minDamage = 6,
	maxDamage = 9,
	hitChance = 100,
	fireSound = "eHeliLightRockets",
	soundRadius = 150,
	explosive = true,
	spread = 2,
	blastRadius = 2,
	firePower = 6,
	impactSound = "eBomb",
	cooldown = 6000,
})


return weaponStats
