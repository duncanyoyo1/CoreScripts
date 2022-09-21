local customEventHooks = require('customEventHooks')
local logicHandler = require('logicHandler')

local SaintLogger = require('custom.SaintLogger')

local logger = SaintLogger:CreateLogger('SaintPartyKills')

customEventHooks.registerHandler("OnWorldKillCount", function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then return end

    local player = Players[pid]
    local allies = player.data.alliedPlayers

    for _, allyName in pairs(allies) do
        ---@type BasePlayer
        local allyPlayer = logicHandler.GetPlayerByName(allyName)
        if allyPlayer ~= nil and allyPlayer:IsLoggedIn() then
            logger:Verbose("Updating player '" .. allyName .. " with new kill")
            allyPlayer:SaveKills()
            allyPlayer:LoadKills()
        end
    end
end)

customEventHooks.registerHandler("OnServerPostInit", function()
    logger:Info("Starting SaintPartyKills...")
end)

return {}
