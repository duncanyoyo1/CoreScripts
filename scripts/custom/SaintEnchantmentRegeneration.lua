-------------------------------------------------------------------------------
--- SaintEnchantmentRegeneration
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Regenerates enchanted items when a player logs back in after being logged
--- out.
-------------------------------------------------------------------------------

local customEventHooks = require('customEventHooks')
local SaintLogger = require('custom.SaintLogger')
local time = require('time')

local logger = SaintLogger:CreateLogger('SaintEnchantmentRegeneration')

local SaintEnchantmentRegeneration = {}

local scriptConfig = {
    rechargeRate = 1 -- Charge recovered per DAY
}

---@param eventStatus EventStatus
---@param pid number
SaintEnchantmentRegeneration.OnPlayerLoginHandler = function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then
        return eventStatus
    end

    SaintEnchantmentRegeneration.RegenerateEnchantedItems(Players[pid])
end

---@param player BasePlayer
SaintEnchantmentRegeneration.RegenerateEnchantedItems = function(player)
    tes3mp.ClearInventoryChanges(player.pid)
    -- Regenerate inventory, since equipment is included in that
    for index, item in ipairs(player.data.inventory) do
        local lastLogin = player.data.timestamps.lastDisconnect
        local now = os.time()
        local daysSinceLastLogin = time.toDays(now - lastLogin)
        local newCharge = item.charge + daysSinceLastLogin * scriptConfig.rechargeRate
        item.charge = math.min(item.enchantmentCharge, newCharge)
    end
    player:SaveToDrive()
    tes3mp.SendInventoryChanges(player.pid)
end

customEventHooks.registerHandler("OnPlayerConnect", SaintEnchantmentRegeneration.OnPlayerLoginHandler)
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus) 
    logger:Info("Starting SaintEnchantmentRegeneration...")
    return eventStatus
end)

return SaintEnchantmentRegeneration
