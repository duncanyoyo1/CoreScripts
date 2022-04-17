local SaintLogger = require('custom.SaintLogger')

local SaintTicks = {}

local logger = SaintLogger:CreateLogger('SaintTicks')

---@class TimerRef
---@field index number
---@field interval number

---@class TimerContainer
---@field timers function[]
---@field timerId number

---@type TimerContainer[]
local Timers = {}

---Creates a 'ticking' function. Does NOT allow params in the callback
---@param callback fun()
---@param tickInterval number
---@return TimerRef
SaintTicks.RegisterTick = function(callback, tickInterval)
    logger:Info('Registering a tick')
    local ticks = Timers[tickInterval]
    if not ticks then
        ticks = {}
        Timers[tickInterval] = ticks
        ticks.timers = {}
        ticks.timerId = tes3mp.CreateTimerEx("GlobalSaintTick", tickInterval, "i", tickInterval)
        logger:Info('Tick registered an created, starting timer')
        tes3mp.StartTimer(ticks.timerId)
    end
    table.insert(ticks.timers, callback)
    return {
        index = #ticks,
        interval = tickInterval
    }
end

---Remove a ticking function from system
---@param timerRef TimerRef
SaintTicks.RemoveTick = function(timerRef)
    local ticks = Timers[timerRef.interval]
    if not ticks then
        logger:Error('Attempted to access and then remove a tick that likely doesn\'t exist!')
        return
    end
    local tick = table.remove(ticks, timerRef.index)
    if not tick then
        logger:Error('Attempted to remove a tick that doesn\'t exist!')
    end
end

---@param tickInterval number
function GlobalSaintTick(tickInterval)
    logger:Info('Ticking for ' .. tickInterval .. '...')
    local ticks = Timers[tickInterval]
    for _, callback in ipairs(ticks.timers) do
        callback()
    end
    tes3mp.RestartTimer(ticks.timerId, tickInterval)
end

return SaintTicks
