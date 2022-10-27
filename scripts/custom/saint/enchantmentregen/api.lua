-------------------------------------------------------------------------------
--- SaintEnchantmentRegeneration
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Regenerates enchanted items when a player logs back in after being logged
--- out.
-------------------------------------------------------------------------------

local time = require('time')

local SaintEnchantmentRegeneration = {}

local scriptConfig = {
    rechargeRate = 24 * 10 -- Charge recovered per DAY
}

---@param eventStatus EventStatus
---@param pid number
SaintEnchantmentRegeneration.OnPlayerFinishLoginHandler = function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then
        return eventStatus
    end

    SaintEnchantmentRegeneration.RegenerateEnchantedItems(Players[pid])
end

---@param player BasePlayer
SaintEnchantmentRegeneration.RegenerateEnchantedItems = function(player)
    -- Regenerate inventory, since equipment is included in that
    for index, item in ipairs(player.data.inventory) do
        local lastLogin = player.data.timestamps.lastDisconnect
        local now = os.time()
        local daysSinceLastLogin = time.toDays(now - lastLogin)
        if item.enchantmentCharge > 0 then
            local newCharge = item.enchantmentCharge + daysSinceLastLogin * scriptConfig.rechargeRate
            item.enchantmentCharge = newCharge
        end
    end
    --- Hack for re-equiping things
    ---TODO: Possible bug w/ this not loading condition
    player:LoadInventory()
    player:LoadEquipment()
end

return SaintEnchantmentRegeneration
