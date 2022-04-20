-------------------------------------------------------------------------------
--- SaintRevive
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- A stripped down adpatation of Atkana's Revive. Works well enough but I'd
--- like to tailor it to be more direct. Kana's allowed for a lot of
--- customization that I don't need or have a desire to complexify this.
--- Ref: https://github.com/Atkana/tes3mp-scripts/blob/master/0.7/kanaRevive/kanaRevive.lua
-------------------------------------------------------------------------------
local tableHelper = require('tableHelper')

local config = require('config')
local contentFixer = require('contentFixer')
local customEventHooks = require('customEventHooks')
local customCommandHooks = require('customCommandHooks')
local logicHandler = require('logicHandler')

---@class SaintReviveScriptConfig
---@field health number
---@field fatigue number|'preserve'
---@field magicka number|'preserve'
local ScriptConfig = {
    bleedoutTime = 30,
    recordRefId = "saintrevivemarker",
    model = "o/contain_corpse20.nif",
    objectType = "miscellaneous", -- tied to above value
    health = 0.1, -- set to 0 - 1 for percentage, other
    fatigue = 0.0,
    magicka = "preserve",
}

local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')

local logger = SaintLogger:CreateLogger('SaintRevive')
local lang = {
	["awaitingReviveMessage"] = "You are awaiting revival.",
	["awaitingReviveOtherMessage"] = "%name has been downed! Activate them to revive them.",
	["bleedingOutMessage"] = "You have %seconds seconds before you bleed out.",
	["giveInPrompt"] = "Type /die to give in.",
	["revivedReceiveMessage"] = "You have been revived by %name.",
	["revivedGiveMessage"] = "You have revived %name.",
	["revivedOtherMessage"] = "%receive has been revived by %give.",
	["bleedoutPlayerMessage"] = "You have died.",
	["bleedoutOtherMessage"] = "%name has bled out.",
	["defaultSuicide"] = "%name committed suicide.",
	["defaultKilledByPlayer"] = "%name was killed by player %killer.",
	["defaultKilledByOther"] = "%name was killed by %killer.",
	["reviveMarkerName"] = "Player corpse - Use to revive!",
}

---@class SaintRevive
---@field config SaintReviveScriptConfig
---@field pidMarkerLookup table<number, string>
---@field reviveMarkers table<string, MarkerData>
local SaintRevive = {}

---- Intermediate Types -------------------------

---@class MarkerData
---@field playerName string
---@field cellDescription string
---@field pid number

---@class ActivatedObjectsContainer
---@field uniqueIndex string
---@field refId string
---@field activatingPid number

---@class ActivatedPlayersContainer
---@field pid number

-------------------------------------------------

---@param config SaintReviveScriptConfig
function SaintRevive.__init(config)
    SaintRevive.reviveMarkers = {}
    SaintRevive.pidMarkerLookup = {}
    SaintRevive.config = tableHelper.deepCopy(config)
end

-------------------------------------------------------------------------------
--- Meat and Potatoes
-------------------------------------------------------------------------------

---@param pidForMarker number
function SaintRevive.CreateReviveMarker(pidForMarker)
    logger:Info("Creating revive marker for player PID '" .. pidForMarker .. "'")
    local playerName = Players[pidForMarker].accountName
	local cellDescription = Players[pidForMarker].data.location.cell
	local location = {
		posX = tes3mp.GetPosX(pidForMarker),
		posY = tes3mp.GetPosY(pidForMarker),
		posZ = tes3mp.GetPosZ(pidForMarker) + 10,
		rotX = 0,
		rotY = 0,
		rotZ = tes3mp.GetRotZ(pidForMarker)
	}
    local objectData = {
        refId = SaintRevive.config.recordRefId,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        scale = 1
    }

	SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
		local uniqueIndex = logicHandler.CreateObjectAtLocation(cellDescription, location, objectData, "place")

        SaintRevive.reviveMarkers[uniqueIndex] = {
            playerName = playerName,
            cellDescription = cellDescription,
            pid = pidForMarker
        }
        SaintRevive.pidMarkerLookup[pidForMarker] = uniqueIndex

        --Saint Note: These next few lines may need to be brought into another function

        -- Delete the marker for the downed player, and anyone who was in the cell
        for _, pid in pairs(cell.visitors) do
            logicHandler.DeleteObjectForPlayer(pid, cellDescription, uniqueIndex)
        end
	end)
end

---@param uniqueIndex string
---@param cellDescription string|nil
function SaintRevive.RemoveReviveMarker(uniqueIndex, cellDescription)
	if uniqueIndex then
		-- The OnObjectActivate call for this function provides a cell description in case the revive marker is from an old session
		-- Use that if provided, otherwise it's safe to get it from looking up its information

        --Saint Note: I don't like the above or this logic, but whatever
        local reviveMarker = SaintRevive.reviveMarkers[uniqueIndex]
        cellDescription = cellDescription or reviveMarker.cellDescription

		SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
			logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
			cell:DeleteObjectData(uniqueIndex)
		end)

		if reviveMarker then
			SaintRevive.pidMarkerLookup[reviveMarker.pid] = nil
		end

		SaintRevive.reviveMarkers[uniqueIndex] = nil
    else
        local safeValue = tostring(uniqueIndex)
        logger:Warn("Attempted to clean up a revive marker with no index! Index: " .. safeValue)
	end
end

---@param downedPid number
---@param reviverPid number
function SaintRevive.OnPlayerRevive(downedPid, reviverPid)
    local newHealth, newMagicka, newFatigue = SaintRevive.CalculateRevivedPlayerStats(downedPid)
    -- Inform players about the revival
	local exemptPids = {downedPid, reviverPid}
	local downedPlayerName = Players[downedPid].accountName
	local reviverPlayerName = Players[reviverPid].accountName
	local broadcastMessage = SaintRevive.GetLangText("revivedOtherMessage", {receive = downedPlayerName, give = reviverPlayerName})
	
	-- ...Inform the player being revived
	tes3mp.SendMessage(downedPid, SaintRevive.GetLangText("revivedReceiveMessage", {name = reviverPlayerName}) .. "\n")
	
	-- ...Inform the reviver
	tes3mp.SendMessage(reviverPid, SaintRevive.GetLangText("revivedGiveMessage", {name = downedPlayerName}) .. "\n")
	
    SaintRevive.SendMessageToAllOnServer(broadcastMessage, exemptPids)
	
    SaintRevive._SetPlayerDowned(downedPid, false)
	contentFixer.UnequipDeadlyItems(downedPid) -- Morrowind mega mind workaround
	tes3mp.Resurrect(downedPid, 0)
	tes3mp.SetHealthCurrent(downedPid, newHealth)
	tes3mp.SetMagickaCurrent(downedPid, newMagicka)
	tes3mp.SetFatigueCurrent(downedPid, newFatigue)
	tes3mp.SendStatsDynamic(downedPid)
	
    SaintRevive.RemoveReviveMarker(SaintRevive.pidMarkerLookup[downedPid])
end

---@param pid number
function SaintRevive.OnPlayerBleedout(pid)
    SaintRevive._SetPlayerDowned(pid, false)
	
	-- Inform the player
    tes3mp.SendMessage(pid, SaintRevive.GetLangText("bleedoutPlayerMessage") .. "\n")
	
	-- Inform others if configured
	local exemptPids = {pid}
	local pname = Players[pid].accountName
	local message = SaintRevive.GetLangText("bleedoutOtherMessage", {name = pname})

    SaintRevive.SendMessageToAllOnServer(message, exemptPids)

    OnDeathTimeExpiration(pid, pname)
	
    SaintRevive.RemoveReviveMarker(SaintRevive.pidMarkerLookup[pid])
end

---@param pid number
---@param timeRemaining number|nil
function SaintRevive.DownPlayer(pid, timeRemaining)
    SaintRevive._SetPlayerDowned(pid, true)

    local secondsLeft
	if not timeRemaining then
		secondsLeft = SaintRevive.config.bleedoutTime
        SaintRevive._SetPlayerBleedoutTicks(pid, 0)
	else
		secondsLeft = SaintRevive.config.bleedoutTime - timeRemaining
        SaintRevive._SetPlayerBleedoutTicks(pid, secondsLeft)
	end
	
	-- Send the first basic messages
	tes3mp.SendMessage(pid, SaintRevive.GetLangText("awaitingReviveMessage") .. "\n")
	local downedPlayerName = Players[pid].accountName
	local exemptPids = {pid}
	local downBroadcastMessage = SaintRevive.GetLangText("awaitingReviveOtherMessage", {name = downedPlayerName})
    SaintRevive.SendMessageToAllOnServer(downBroadcastMessage, exemptPids)
    tes3mp.SendMessage(pid, SaintRevive.GetLangText("bleedingOutMessage", {seconds = secondsLeft}) .. "\n")


    local timerId = tes3mp.CreateTimerEx("BleedoutTick", time.seconds(1), "ii", pid, SaintRevive.config.bleedoutTime)
    SaintRevive._SetBleedoutTimerId(pid, timerId)
    tes3mp.StartTimer(timerId)
    logger:Info("Creating timer with ID: '" .. timerId .. "' for player PID '" .. pid .. "'")

    SaintRevive.CreateReviveMarker(pid)

	tes3mp.SendMessage(pid, SaintRevive.GetLangText("giveInPrompt") .. "\n")
end

---@param pid number
---@return number NewHealth
---@return number NewMagicka
---@return number NewFatigue
function SaintRevive.CalculateRevivedPlayerStats(pid)
    local healthBase = tes3mp.GetHealthBase(pid)
	local fatigueCurrent = tes3mp.GetFatigueCurrent(pid)
	local fatigueBase = tes3mp.GetFatigueBase(pid)
	local magickaCurrent = tes3mp.GetMagickaCurrent(pid)
	local magickaBase = tes3mp.GetMagickaBase(pid)
	
	local newHealth, newMagicka, newFatigue
	
	if SaintRevive.config.health < 1.0 then
        newHealth = math.floor((healthBase * SaintRevive.config.health) + 0.5 )
	else
		newHealth = SaintRevive.config.health
	end
	
	if SaintRevive.config.magicka == "preserve" then
		newMagicka = magickaCurrent
	elseif SaintRevive.config.magicka < 1.0 then
		newMagicka = math.floor((magickaBase * SaintRevive.config.magicka) + 0.5 )
	else
		newMagicka = SaintRevive.config.magicka
	end
	
	if SaintRevive.config.fatigue == "preserve" then
		newFatigue = fatigueCurrent
	elseif SaintRevive.config.fatigue < 1.0 then
		newFatigue = math.floor((fatigueBase * SaintRevive.config.fatigue) + 0.5 )
	else
		newFatigue = SaintRevive.config.fatigue
	end

    newHealth = math.max(math.min(newHealth, healthBase), 1) -- gotta be one if we are ressing
	newMagicka = math.max(math.min(newMagicka, magickaBase), 0)
	newFatigue = math.max(math.min(newFatigue, fatigueBase), 0)

    return newHealth, newMagicka, newFatigue
end

function SaintRevive.TrySetPlayerDowned(pid)
	if SaintRevive._GetPlayerLoggedOutDowned(pid) then
		local remaining = SaintRevive.config.bleedoutTime - Players[pid].data.customVariables.bleedoutTicks
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
---@param value boolean
function SaintRevive._SetPlayerDowned(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to down a player that was not logged in!')
        return
    end
    player.data.customVariables.isDowned = value
end

---@param pid number
---@param value boolean
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
function SaintRevive.GetLangText(key, data)
	local function replacer(wildcard)
		if data[wildcard] then
			return data[wildcard]
		else
			return ""
		end
	end
	
	local text = lang[key] or ""
	text = text:gsub("%%(%w+)", replacer)
	
	return text
end

function SaintRevive.SendMessageToAllWithCellLoaded(cellDescription, message, exceptionPids)
	for pid, player in pairs(Players) do
		if tableHelper.containsValue(player.cellsLoaded, cellDescription) and not tableHelper.containsValue(exceptionPids or {}, pid) then
			tes3mp.SendMessage(pid, message .. "\n")
		end
	end
end

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

    for uniqueIndex, objectContainer in pairs(objects) do
        if objectContainer.refId == SaintRevive.config.recordRefId then
            if SaintRevive.reviveMarkers[uniqueIndex] and SaintRevive._GetPlayerDowned(SaintRevive.reviveMarkers[uniqueIndex].pid) then
                SaintRevive.OnPlayerRevive(SaintRevive.reviveMarkers[uniqueIndex].pid, pid)
            else
                --OnPlayerRevive already removes the marker, this is a weird situation
                SaintRevive.RemoveReviveMarker(uniqueIndex, cellDescription)
            end
            return
        end
    end
end

function SaintRevive.OnServerPostInit()
    if RecordStores[SaintRevive.config.objectType].data.permanentRecords[SaintRevive.config.recordRefId] == nil then
		local data = {
            model = SaintRevive.config.model,
            name = SaintRevive.GetLangText("reviveMarkerName"),
            script = "nopickup"
        }
		
		RecordStores[SaintRevive.config.objectType].data.permanentRecords[SaintRevive.config.recordRefId] = data
		
		RecordStores[SaintRevive.config.objectType]:SaveToDrive()
        logger:Info("Created record for custom marker")
    else
        logger:Info("Custom record already exists, skipping")
	end
end

---@param pid number
function SaintRevive.OnPlayerDisconnect(pid)
    if SaintRevive._GetPlayerDowned(pid) then
        SaintRevive.RemoveReviveMarker(SaintRevive.pidMarkerLookup[pid])
    end
end

---@param pid number
---@return boolean DidPlayerGetDowned
function SaintRevive.OnPlayerDeath(pid)
    local message
	if tes3mp.DoesPlayerHavePlayerKiller(pid) and tes3mp.GetPlayerKillerPid(pid) ~= pid then
		local killerPid = tes3mp.GetPlayerKillerPid(pid)
		message = SaintRevive.GetLangText("defaultKilledByPlayer", {name = logicHandler.GetChatName(pid), killer = logicHandler.GetChatName(killerPid)})
	elseif tes3mp.GetPlayerKillerName(pid) ~= "" then
		message = SaintRevive.GetLangText("defaultKilledByOther", {name = logicHandler.GetChatName(pid), killer = tes3mp.GetPlayerKillerName(pid)})
	else
		message = SaintRevive.GetLangText("defaultSuicide", {name = logicHandler.GetChatName(pid)})
	end

	tes3mp.SendMessage(pid, message .. "\n", true)

    ---Saint Note: This seems unnecessary? Or something, idk, dont like
	if config.playersRespawn then
		SaintRevive.TrySetPlayerDowned(pid)
        return true
	else
		tes3mp.SendMessage(pid, SaintRevive.GetLangText("defaultPermanentDeath") .. "\n", false)
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
                tes3mp.SendMessage(pid, tostring(SaintRevive._GetPlayerBleedoutTicks(pid)) .. '...\n')
				local timerId = SaintRevive._GetBleedoutTimerId(pid)
				return tes3mp.RestartTimer(timerId, time.seconds(1))
			end
		end
	end
end

function SaintRevive.Init()
    customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
        local didRevive = SaintRevive.OnPlayerDeath(pid)
        local doDefault = not didRevive
        return customEventHooks.makeEventStatus(false, doDefault)
    end)
    customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
        SaintRevive.OnPlayerDisconnect(pid)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnPlayerFinishLogin",  function(eventStatus, pid)
        SaintRevive.OnPlayerFinishLogin(pid)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
        SaintRevive.OnObjectActivate(pid, cellDescription, objects, players)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
        SaintRevive.OnServerPostInit()
        return eventStatus
    end)
    customCommandHooks.registerCommand("die", function(pid)
        SaintRevive.OnDieCommand(pid)
    end)
end

---@type SaintRevive
SaintRevive.__init(ScriptConfig)
SaintRevive.Init()
return SaintRevive
