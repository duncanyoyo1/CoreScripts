local classy = require('classy')
local time = require('time')
local SaintTicks = require('custom.saint.common.ticks.main')
local ScriptConfig = require('custom.saint.revive.config')

---@class BleedoutManager
---@field bleeders any[]
---@overload fun(): BleedoutManager
local BleedoutManager = classy('BleedoutManager')

function BleedoutManager:__init()
    self.bleeders = {}
    self.timerRef = nil
end

function BleedoutManager:Start()
    local this = self
    self.timerRef = SaintTicks.RegisterTick(function()
        this:CheckBleeders()
    end, time.seconds(1))
end

function BleedoutManager:Stop()
    SaintTicks.RemoveTick(self.timerRef)
end

function BleedoutManager:CheckBleeders()
    for pid, used in pairs(self.bleeders) do
        if used then
            self:CheckBleeder(pid)
        end
    end
end

-- INCOMPLETE
function BleedoutManager:CheckBleeder(pid)
    local player = Players[pid]
    if player and Players[pid]:IsLoggedIn() then
        if SaintRevive._GetPlayerDowned(pid) then
            SaintRevive._SetPlayerBleedoutTicks(pid, SaintRevive._GetPlayerBleedoutTicks(pid) + 1)

            if SaintRevive._GetPlayerBleedoutTicks(pid) >= ScriptConfig.bleedoutTime then
                return SaintRevive.OnPlayerBleedout(pid)
            else
                tes3mp.SendMessage(pid, tostring(ScriptConfig.bleedoutTime - SaintRevive._GetPlayerBleedoutTicks(pid)) .. '...\n')
                local timerId = SaintRevive._GetBleedoutTimerId(pid)
                return tes3mp.RestartTimer(timerId, time.seconds(1))
            end
        end
    end
end

function BleedoutManager:AddBleeder(pid)
    self.bleeders[pid] = true
end

function BleedoutManager:RemoveBleeder(pid)
    self.bleeders[pid] = nil
end

function BleedoutManager:GetPlayerDownedStatus()
end

function BleedoutManager:SetPlayerDownedStatus(status)
end

function BleedoutManager:GetPlayerBleedoutDuration(pid)
end

return BleedoutManager
