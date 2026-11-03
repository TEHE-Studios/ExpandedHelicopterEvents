--[[
if not isClient() then
    local _ll = getFileReader("babyGate.lua", false)
    if not _ll then if isClient() then getCore():quitToDesktop() else local m, lCF = nil, getCoroutineCallframeStack(getCurrentCoroutine(),0) local fD = lCF ~= nil and lCF and getFilenameOfCallframe(lCF) m = fD and getModInfo(fD:match("(.-)media/")) toggleModActive(m, false) end return end
end
--]]