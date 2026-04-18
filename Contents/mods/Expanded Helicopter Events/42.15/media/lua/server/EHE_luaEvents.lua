local heatMap = require "EHE_heatMap"
Events.OnInitGlobalModData.Add(heatMap.initModData)
Events.EveryHours.Add(heatMap.coolOff)
Events.EHE_OnActivateFlare.Add(heatMap.EHE_OnActivateFlare)
Events.OnHitZombie.Add(heatMap.OnHitZombie)
Events.OnZombieDead.Add(heatMap.OnZombieDead)
Events.OnPlayerMove.Add(heatMap.OnPlayerMove)
Events.OnPlayerDeath.Add(heatMap.OnPlayerDeath)
Events.OnWeaponSwing.Add(heatMap.OnWeaponSwing)