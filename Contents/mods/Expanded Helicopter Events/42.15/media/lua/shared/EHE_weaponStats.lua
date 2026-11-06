local weaponStats = {}

---EHE damage per point of in-game weapon damage (zombies take damage*3/50 in heliEventAttackHitOnIsoGameCharacter)
weaponStats.damageScale = 50/3

weaponStats.defaults = {
	minDamage = 0.6,
	maxDamage = 0.9,
	hitChance = 85,
	delay = 60,
	scope = 1,
	spread = 3,
	splash = 0,
	projectileCount = 1,
	fireSound = "eHeli_machine_gun_fire_single",
	loopedSound = "eHeli_machine_gun_fire_looped",
	impactSound = "eHeli_fire_impact",
	soundRadius = 75,
	explosive = false,
	scatter = 0,
	blastRadius = 0,
	firePower = 0,
	cooldown = 0,
	magazine = 0,
	reloadDelay = 0,
	reloadSound = false,
	minThreat = 0,
}

---threat each target type adds to a cluster, anything else counts as 1
weaponStats.threat = { IsoPlayer = 2 }

---minThreat given to script weapons that can fire automatic
weaponStats.autoMinThreat = 2

---ms added between shots for bolt and pump actions
weaponStats.rackDelay = 600

---Event-only weapons, registered by ID with weaponStats.register
weaponStats.templates = {}

---Resolved stats by ID, script weapons are only read once
weaponStats.cache = {}


---@param ID string
---@param stats table any keys from weaponStats.defaults, missing keys are filled from defaults; base = item script full type to start from that weapon's stats
function weaponStats.register(ID, stats)
	weaponStats.templates[ID] = stats
	weaponStats.cache[ID] = nil
end


function weaponStats.fillDefaults(stats, defaults)
	local filled = {}
	for k,v in pairs(defaults or weaponStats.defaults) do filled[k] = v end
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
	local magazine = weapon:getMaxAmmo()
	local fireModes = weapon:getFireModePossibilities()
	local automatic = fireModes and fireModes:contains("Auto")
	local reloadDelay = weapon:getMagazineType() and (weapon:getReloadTime()*100) or (weapon:getReloadTime()*40*magazine)

	return weaponStats.fillDefaults({
		minDamage = weapon:getMinDamage(),
		maxDamage = weapon:getMaxDamage(),
		hitChance = weapon:getHitChance(),
		delay = math.floor((weapon:getRecoilDelay()*1000)/60)+(weapon:isRackAfterShoot() and weaponStats.rackDelay or 0),
		magazine = magazine,
		reloadDelay = reloadDelay,
		reloadSound = weapon:getInsertAmmoSound(),
		minThreat = automatic and weaponStats.autoMinThreat or 0,
		projectileCount = math.max(1, weapon:getProjectileCount()),
		fireSound = weapon:getSwingSound(),
		loopedSound = weapon:getSwingSound(),
		impactSound = (blastRadius > 0) and weapon:getExplosionSound() or nil,
		soundRadius = weapon:getSoundRadius(),
		explosive = blastRadius > 0,
		blastRadius = blastRadius,
		firePower = (weapon:getFireRange() > 0) and weapon:getFireStartingChance() or 0,
	})
end


---@param ID string template ID or item script full type
---@return table|boolean
function weaponStats.get(ID)
	if weaponStats.cache[ID] == nil then
		local template = weaponStats.templates[ID]
		if template then
			local base = template.base and weaponStats.get(template.base)
			weaponStats.cache[ID] = weaponStats.fillDefaults(template, base or nil)
		else
			weaponStats.cache[ID] = weaponStats.fromScript(ID)
		end
		if weaponStats.cache[ID] then weaponStats.cache[ID].ID = ID end
	end
	return weaponStats.cache[ID]
end


---@param weaponArray table|string single ID, or IDs each optionally followed by a weight
---@param cooldowns table|nil ID = timestamp when available again
---@param maxThreat number|nil only pick weapons whose minThreat is at or below this, returns nil if there are none
---@return table stats, falls back to EHE_Default
function weaponStats.pick(weaponArray, cooldowns, maxThreat)
	if type(weaponArray) == "string" then weaponArray = {weaponArray} end

	local now = getTimeInMillis()
	local pool = {}
	for key,entry in ipairs(weaponArray or {}) do
		if type(entry) == "string" then
			local weight = weaponArray[key+1]
			if type(weight) ~= "number" then weight = 1 end
			local stats = maxThreat and weaponStats.get(entry)
			local allowed = (not maxThreat) or (stats and stats.minThreat <= maxThreat)
			if allowed and ((not cooldowns) or (not cooldowns[entry]) or (cooldowns[entry] <= now)) then
				for i=1, weight do table.insert(pool, entry) end
			end
		end
	end

	local ID = (#pool > 0) and pool[ZombRand(#pool)+1]
	if maxThreat and not ID then return end
	local stats = ID and weaponStats.get(ID)
	if not stats then return weaponStats.get("EHE_Default") end
	if cooldowns and stats.cooldown > 0 then cooldowns[ID] = now+stats.cooldown end

	return stats
end


---@return number the furthest any weapon in the array can reach, used for attackDistance
function weaponStats.reach(weaponArray)
	if type(weaponArray) == "string" then weaponArray = {weaponArray} end
	local reach = 0
	for _,entry in ipairs(weaponArray or {"EHE_Default"}) do
		local stats = (type(entry) == "string") and weaponStats.get(entry)
		if stats then reach = math.max(reach, ((stats.scope*2)+1)*((stats.spread*2)+1)) end
	end
	return reach
end


weaponStats.register("EHE_Default", {})

weaponStats.register("EHE_M60", {
	minDamage = 6, maxDamage = 9, hitChance = 70,
	delay = 110, spread = 5, splash = 2,
	magazine = 100, reloadDelay = 6000, minThreat = 3,
})

weaponStats.register("EHE_PoliceRifles", {
	minDamage = 4.8, maxDamage = 7.2, hitChance = 95,
	delay = 1700, spread = 4,
	fireSound = "eHeliAlternatingShots", loopedSound = "eHeliAlternatingShots",
})

weaponStats.register("EHE_DeserterRifles", {
	minDamage = 4.2, maxDamage = 6.3, hitChance = 7,
	delay = 650, spread = 5,
	fireSound = "eHeliAlternatingShots", loopedSound = "eHeliAlternatingShots",
})
-- Unguided rockets -- for small groups
weaponStats.register("EHE_Hydra70", {
	minDamage = 6, maxDamage = 9, hitChance = 100,
	delay = 50, spread = 5,
	fireSound = "eHeliLightRockets", impactSound = "eBomb", soundRadius = 150,
	explosive = true, scatter = 2, blastRadius = 10, firePower = 10, cooldown = 800, minThreat = 5,
})
-- Laser guided bomb - for large groups
weaponStats.register("EHE_GBU12", {
	minDamage = 6, maxDamage = 9, hitChance = 100,
	delay = 1000, spread = 5,
	fireSound = "eHeliLightRockets", impactSound = "eBomb", soundRadius = 150,
	explosive = true, scatter = 1, blastRadius = 300, firePower = 300, cooldown = 4000, minThreat = 2,
})
-- Napalm pods -- for areas
weaponStats.register("EHE_Mk77", {
	minDamage = 6, maxDamage = 9, hitChance = 100,
	delay = 1000, spread = 5,
	fireSound = "eHeliLightRockets", impactSound = "eBomb", soundRadius = 150,
	explosive = true, scatter = 1, blastRadius = 300, firePower = 300, cooldown = 30, minThreat = 2,
})

return weaponStats
