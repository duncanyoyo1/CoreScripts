local ScriptConfig = require('custom.saint.revive.config')

---@param pid number
---@return number NewHealth
---@return number NewMagicka
---@return number NewFatigue
local function CalculateRevivedPlayerStats(pid)
    local healthBase = tes3mp.GetHealthBase(pid)
    local fatigueCurrent = tes3mp.GetFatigueCurrent(pid)
    local fatigueBase = tes3mp.GetFatigueBase(pid)
    local magickaCurrent = tes3mp.GetMagickaCurrent(pid)
    local magickaBase = tes3mp.GetMagickaBase(pid)

    local newHealth, newMagicka, newFatigue

    if ScriptConfig.health < 1.0 then
        newHealth = math.floor((healthBase * ScriptConfig.health) + 0.5)
    else
        newHealth = ScriptConfig.health
    end

    if ScriptConfig.magicka == "preserve" then
        newMagicka = magickaCurrent
    elseif ScriptConfig.magicka < 1.0 then
        newMagicka = math.floor((magickaBase * ScriptConfig.magicka) + 0.5)
    else
        newMagicka = ScriptConfig.magicka ---@type number
    end

    if ScriptConfig.fatigue == "preserve" then
        newFatigue = fatigueCurrent
    elseif ScriptConfig.fatigue < 1.0 then
        newFatigue = math.floor((fatigueBase * ScriptConfig.fatigue) + 0.5)
    else
        newFatigue = ScriptConfig.fatigue ---@type number
    end

    newHealth = math.max(math.min(newHealth, healthBase), 1) -- gotta be one if we are ressing
    newMagicka = math.max(math.min(newMagicka, magickaBase), 0)
    newFatigue = math.max(math.min(newFatigue, fatigueBase), 0)
    return newHealth, newMagicka, newFatigue
end

return {
    CalculateRevivedPlayerStats = CalculateRevivedPlayerStats,
}
