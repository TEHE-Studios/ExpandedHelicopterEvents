--TODO: REMOVE THIS DEAD FILE  2/3/24
--[[

local function onCommand(_arg1, _arg2, _arg3, _arg4)
    local _player, _module, _command, _data = nil, _arg1, _arg2, _arg3
    if _arg4 then _player, _module, _command, _data = _arg1, _arg2, _arg3, _arg4 end
    if _module ~= "twitchIntegration" then return end
    _data = _data or {}
    --if _command == "" then
    --end
end
--Events.OnServerCommand.Add(onCommand)--/server/ to client

--]]