local heatMap = require("EHE_heatMap.lua")
Events.OnInitGlobalModData.Add(heatMap.initModData)
Events.EveryHours.Add(heatMap.coolOff)
Events.EHE_OnActivateFlare.Add(heatMap.EHE_OnActivateFlare)
Events.OnHitZombie.Add(heatMap.OnHitZombie)
Events.OnZombieDead.Add(heatMap.OnZombieDead)
Events.OnPlayerMove.Add(heatMap.OnPlayerMove)
Events.OnPlayerDeath.Add(heatMap.OnPlayerDeath)
Events.OnWeaponSwing.Add(heatMap.OnWeaponSwing)

local eHeliScheduler = require("EHE_eventScheduler.lua")
if not isClient() then Events.OnTick.Add(eHeliScheduler.OnHour) end
if not isClient() then Events.OnGameStart.Add(eHeliScheduler.OnGameStart) end
if isServer() then Events.OnServerStarted.Add(eHeliScheduler.OnGameStart) end
