-------------------------------------------------------------------------------
--- SaintRevive
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- A stripped down adpatation of Atkana's Revive. Works well enough but I'd
--- like to tailor it to be more direct. Kana's allowed for a lot of
--- customization that I don't need or have a desire to complexify this.
--- Ref: https://github.com/Atkana/tes3mp-scripts/blob/master/0.7/kanaRevive/kanaRevive.lua
-------------------------------------------------------------------------------
local Tes3mpConfig    = require('config')
local contentFixer    = require('contentFixer')
local logicHandler    = require('logicHandler')
local tableHelper     = require('tableHelper')
local SaintLogger     = require('custom.saint.common.logger.main')
local ScriptConfig    = require('custom.saint.revive.config')
local Lang            = require('custom.saint.revive.lang')
local MarkerManager   = require('custom.saint.revive.markerManager')
local ReviveUtilities = require('custom.saint.revive.utilities')

local logger = SaintLogger:CreateLogger('SaintRevive')

---@class SaintRevive
local SaintRevive = {
    markerManager = MarkerManager(),
}

---- Intermediate Types -------------------------

---@class ActivatedObjectsContainer
---@field uniqueIndex string
---@field refId string
---@field activatingPid number

---@class ActivatedPlayersContainer
---@field pid number

-------------------------------------------------------------------------------
--- Meat and Potatoes
-------------------------------------------------------------------------------

---@param downedPid number
---@param reviverPid number
function SaintRevive.OnPlayerRevive(downedPid, reviverPid)
    local newHealth, newMagicka, newFatigue = ReviveUtilities.CalculateRevivedPlayerStats(downedPid)
    local exemptPids = { downedPid, reviverPid }
    local downedPlayerName = Players[downedPid].accountName
    local reviverPlayerName = Players[reviverPid].accountName
    local broadcastMessage = Lang.GetLangText("revivedOtherMessage", { receive = downedPlayerName, give = reviverPlayerName })

    tes3mp.SendMessage(downedPid, Lang.GetLangText("revivedReceiveMessage", { name = reviverPlayerName }) .. "\n")
    tes3mp.SendMessage(reviverPid, Lang.GetLangText("revivedGiveMessage", { name = downedPlayerName }) .. "\n")
    SaintRevive.SendMessageToAllOnServer(broadcastMessage, exemptPids)

    SaintRevive._SetPlayerDowned(downedPid, false)
    contentFixer.UnequipDeadlyItems(downedPid) -- Morrowind mega mind workaround
    tes3mp.Resurrect(downedPid, 0)
    tes3mp.SetHealthCurrent(downedPid, newHealth)
    tes3mp.SetMagickaCurrent(downedPid, newMagicka)
    tes3mp.SetFatigueCurrent(downedPid, newFatigue)
    tes3mp.SendStatsDynamic(downedPid)

    SaintRevive.markerManager:RemoveMarkerFromPid(downedPid)
end

---@param pid number
function SaintRevive.OnPlayerBleedout(pid)
    SaintRevive._SetPlayerDowned(pid, false)

    -- Inform the player
    tes3mp.SendMessage(pid, Lang.GetLangText("bleedoutPlayerMessage") .. "\n")

    -- Inform others if configured
    local exemptPids = { pid }
    local pname = Players[pid].accountName
    local message = Lang.GetLangText("bleedoutOtherMessage", { name = pname })

    SaintRevive.SendMessageToAllOnServer(message, exemptPids)

    OnDeathTimeExpiration(pid, pname)

    SaintRevive.markerManager:RemoveMarkerFromPid(pid)
end

---@param pid number
---@param timeRemaining number|nil
function SaintRevive.DownPlayer(pid, timeRemaining)
    SaintRevive._SetPlayerDowned(pid, true)

    local secondsLeft
    if not timeRemaining then
        secondsLeft = ScriptConfig.bleedoutTime
        SaintRevive._SetPlayerBleedoutTicks(pid, 0)
    else
        secondsLeft = ScriptConfig.bleedoutTime - timeRemaining
        SaintRevive._SetPlayerBleedoutTicks(pid, secondsLeft)
    end

    -- Send the first basic messages
    tes3mp.SendMessage(pid, Lang.GetLangText("awaitingReviveMessage") .. "\n")
    local downedPlayerName = Players[pid].accountName
    local exemptPids = { pid }
    local downBroadcastMessage = Lang.GetLangText("awaitingReviveOtherMessage", { name = downedPlayerName })
    SaintRevive.SendMessageToAllOnServer(downBroadcastMessage, exemptPids)
    tes3mp.SendMessage(pid, Lang.GetLangText("bleedingOutMessage", { seconds = secondsLeft }) .. "\n")


    local timerId = tes3mp.CreateTimerEx("BleedoutTick", time.seconds(1), "ii", pid, ScriptConfig.bleedoutTime)
    SaintRevive._SetBleedoutTimerId(pid, timerId)
    tes3mp.StartTimer(timerId)
    logger:Info("Creating timer with ID: '" .. timerId .. "' for player PID '" .. pid .. "'")

    SaintRevive.markerManager:CreateMarkerAtPidPositiom(pid)

    tes3mp.SendMessage(pid, Lang.GetLangText("giveInPrompt") .. "\n")
end

function SaintRevive.TrySetPlayerDowned(pid)
    if SaintRevive._GetPlayerLoggedOutDowned(pid) then
        local remaining = ScriptConfig.bleedoutTime - Players[pid].data.customVariables.bleedoutTicks
        SaintRevive._SetPlayerLoggedOutDowned(pid, nil)

        SaintRevive.DownPlayer(pid, remaining)
    elseif not SaintRevive._GetPlayerDowned(pid) then
        SaintRevive._SetPlayerDowned(pid)
        SaintRevive.DownPlayer(pid)
    end
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- Getters and Setters
-------------------------------------------------------------------------------

---@param pid number
---@param value number
function SaintRevive._SetPlayerBleedoutTicks(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to bleedout a player that was not logged in!')
        return
    end
    player.data.customVariables.bleedoutTicks = value
end

function SaintRevive._GetPlayerBleedoutTicks(pid)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to access a player that was not logged in!')
        return 0
    end
    return player.data.customVariables.bleedoutTicks
end

---@param pid number
function SaintRevive._GetPlayerDowned(pid)
    local player = Players[pid]
    return player and player.data.customVariables.isDowned or false
end

---@param pid number
---@param value boolean|nil
function SaintRevive._SetPlayerDowned(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to down a player that was not logged in!')
        return
    end
    player.data.customVariables.isDowned = value
end

---@param pid number
---@param value boolean|nil
function SaintRevive._SetPlayerLoggedOutDowned(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to logged-out down a player that was not logged in!')
        return
    end
    player.data.customVariables.loggedOutDowned = value
end

---@param pid number
function SaintRevive._GetPlayerLoggedOutDowned(pid)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to logged-out down a player that was not logged in!')
        return false
    end
    return player.data.customVariables.loggedOutDowned
end

---@param pid number
---@param timerId number
function SaintRevive._SetBleedoutTimerId(pid, timerId)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to set the bleedout timer of a player that was not logged in!')
        return
    end
    player.data.customVariables.bleedoutTimerId = timerId
end

function SaintRevive._GetBleedoutTimerId(pid)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to set the bleedout timer of a player that was not logged in!')
        return -1
    end
    return player.data.customVariables.bleedoutTimerId
end

-------------------------------------------------------------------------------
--- Language Functions
---Saint Note: I don't like this atm
-------------------------------------------

function SaintRevive.SendMessageToAllOnServer(message, exceptionPids)
    for pid, player in pairs(Players) do
        if not tableHelper.containsValue(exceptionPids or {}, pid) then
            tes3mp.SendMessage(pid, message .. "\n")
        end
    end
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- TES3MP Hooks and Registration
-------------------------------------------------------------------------------

function SaintRevive.OnDieCommand(pid)
    if SaintRevive._GetPlayerDowned(pid) then
        SaintRevive.OnPlayerBleedout(pid)
    end
end

function SaintRevive.OnPlayerFinishLogin(pid)
    if SaintRevive._GetPlayerDowned(pid) then
        Players[pid]:SetHealthCurrent(0)
        SaintRevive._SetPlayerLoggedOutDowned(pid, true)
    end
end

---@param pid number
---@param cellDescription string
---@param objects ActivatedObjectsContainer[]
---@param players ActivatedPlayersContainer[]
function SaintRevive.OnObjectActivate(pid, cellDescription, objects, players)
    for _, pidContainer in pairs(players) do
        if SaintRevive._GetPlayerDowned(pidContainer.pid) then
            SaintRevive.OnPlayerRevive(pidContainer.pid, pid)
            return
        end
    end

    for _, objectContainer in pairs(objects) do
        local uniqueIndex = objectContainer.uniqueIndex
        if objectContainer.refId == ScriptConfig.recordRefId then
            local reviveMarker = SaintRevive.markerManager:GetMarker(uniqueIndex)
            if reviveMarker and SaintRevive._GetPlayerDowned(reviveMarker.pid) then
                SaintRevive.OnPlayerRevive(reviveMarker.pid, pid)
            else
                --OnPlayerRevive already removes the marker, this is a weird situation
                SaintRevive.markerManager:RemoveMarkerIfExists(uniqueIndex)
            end
            return
        end
    end
end

function SaintRevive.OnServerPostInit()
    if RecordStores[ScriptConfig.objectType].data.permanentRecords[ScriptConfig.recordRefId] == nil then
        local data = {
            model = ScriptConfig.model,
            name = Lang.GetLangText("reviveMarkerName"),
            script = "nopickup"
        }

        RecordStores[ScriptConfig.objectType].data.permanentRecords[ScriptConfig.recordRefId] = data

        RecordStores[ScriptConfig.objectType]:SaveToDrive()
        logger:Info("Created record for custom marker")
    else
        logger:Info("Custom record already exists, skipping")
    end
end

---@param pid number
function SaintRevive.OnPlayerDisconnect(pid)
    if SaintRevive._GetPlayerDowned(pid) then
        SaintRevive.markerManager:RemoveMarkerFromPid(pid)
    end
end

---@param pid number
---@return boolean DidPlayerGetDowned
function SaintRevive.OnPlayerDeath(pid)
    local message
    if tes3mp.DoesPlayerHavePlayerKiller(pid) and tes3mp.GetPlayerKillerPid(pid) ~= pid then
        local killerPid = tes3mp.GetPlayerKillerPid(pid)
        message = Lang.GetLangText("defaultKilledByPlayer",
            { name = logicHandler.GetChatName(pid), killer = logicHandler.GetChatName(killerPid) })
    elseif tes3mp.GetPlayerKillerName(pid) ~= "" then
        message = Lang.GetLangText("defaultKilledByOther",
            { name = logicHandler.GetChatName(pid), killer = tes3mp.GetPlayerKillerName(pid) })
    else
        message = Lang.GetLangText("defaultSuicide", { name = logicHandler.GetChatName(pid) })
    end

    tes3mp.SendMessage(pid, message .. "\n", true)

    ---Saint Note: This seems unnecessary? Or something, idk, dont like
    if Tes3mpConfig.playersRespawn then
        SaintRevive.TrySetPlayerDowned(pid)
        return true
    else
        tes3mp.SendMessage(pid, Lang.GetLangText("defaultPermanentDeath") .. "\n", false)
        return false
    end
end

-------------------------------------------------------------------------------

---Global Bleedout Tick for SaintRevive
---@param pid number
function BleedoutTick(pid, bleedoutTime)
    local player = Players[pid]
    if player and Players[pid]:IsLoggedIn() then
        if SaintRevive._GetPlayerDowned(pid) then
            SaintRevive._SetPlayerBleedoutTicks(pid, SaintRevive._GetPlayerBleedoutTicks(pid) + 1)

            if SaintRevive._GetPlayerBleedoutTicks(pid) >= bleedoutTime then
                return SaintRevive.OnPlayerBleedout(pid)
            else
                tes3mp.SendMessage(pid,
                    tostring(ScriptConfig.bleedoutTime - SaintRevive._GetPlayerBleedoutTicks(pid)) .. '...\n')
                local timerId = SaintRevive._GetBleedoutTimerId(pid)
                return tes3mp.RestartTimer(timerId, time.seconds(1))
            end
        end
    end
end

return SaintRevive
