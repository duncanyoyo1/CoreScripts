-------------------------------------------------------------------------------
--- SaintRevive
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- A stripped down adpatation of Atkana's Revive. Works well enough but I'd
--- like to tailor it to be more direct. Kana's allowed for a lot of
--- customization that I don't need or have a desire to complexify this.
-------------------------------------------------------------------------------
local classy = require('classy')
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
local SaintRevive = classy('SaintRevive')

---- Intermediate Types -------------------------

---@class MarkerData
---@field playerName string
---@field cellDescription string
---@field pid number

---@class ObjectActiveObjectsContainer
---@field uniqueIndex string
---@field refId string

-------------------------------------------------

---@param config SaintReviveScriptConfig
function SaintRevive:__init(config)
    self.reviveMarkers = {}
    self.pidMarkerLookup = {}
    self.config = tableHelper.deepCopy(config)
end

-------------------------------------------------------------------------------
--- Meat and Potatoes
-------------------------------------------------------------------------------

---@param pidForMarker number
function SaintRevive:CreateReviveMarker(pidForMarker)
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
        refId = self.config.recordRefId,
        count = 1,
        charge = -1,
        enchantmentCharge = -1,
        soul = "",
        scale = 1
    }

	SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
		local uniqueIndex = logicHandler.CreateObjectAtLocation(cellDescription, location, objectData, "place")

        self.reviveMarkers[uniqueIndex] = {
            playerName = playerName,
            cellDescription = cellDescription,
            pid = pidForMarker
        }
        self.pidMarkerLookup[pidForMarker] = uniqueIndex

        --Saint Note: These next few lines may need to be brought into another function

        -- Delete the marker for the downed player, and anyone who was in the cell
        for _, pid in cell.visitors do
            logicHandler.DeleteObjectForPlayer(pid, cellDescription, uniqueIndex)
        end

        -- A little bit extra to maybe ensure that the player whose marker it is doesn't see it
        logicHandler.DeleteObjectForPlayer(pidForMarker, cellDescription, uniqueIndex)
	end)
end

---@param uniqueIndex string
---@param cellDescription string|nil
function SaintRevive:RemoveReviveMarker(uniqueIndex, cellDescription)
	if uniqueIndex then
		local cellDescription = nil
		-- The OnObjectActivate call for this function provides a cell description in case the revive marker is from an old session
		-- Use that if provided, otherwise it's safe to get it from looking up its information

        --Saint Note: I don't like the above or this logic, but whatever
        local reviveMarker = self.reviveMarkers[uniqueIndex]
        cellDescription = cellDescription or reviveMarker.cellDescription

		SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
			logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
			cell:DeleteObjectData(uniqueIndex)
		end)

		if reviveMarker then
			self.pidMarkerLookup[reviveMarker.pid] = nil
		end

		self.reviveMarkers[uniqueIndex] = nil
    else
        logger:Warn("Attempted to clean up a revive marker with no index!")
	end
end

---@param downedPid number
---@param reviverPid number
function SaintRevive:OnPlayerRevive(downedPid, reviverPid)
    local newHealth, newMagicka, newFatigue = self:CalculateRevivedPlayerStats(downedPid)
    -- Inform players about the revival
	local exemptPids = {downedPid, reviverPid}
	local downedPlayerName = Players[downedPid].accountName
	local reviverPlayerName = Players[reviverPid].accountName
	local broadcastMessage = self:GetLangText("revivedOtherMessage", {receive = downedPlayerName, give = reviverPlayerName})
	
	-- ...Inform the player being revived
	tes3mp.SendMessage(downedPid, self:GetLangText("revivedReceiveMessage", {name = reviverPlayerName}) .. "\n")
	
	-- ...Inform the reviver
	tes3mp.SendMessage(reviverPid, self:GetLangText("revivedGiveMessage", {name = downedPlayerName}) .. "\n")
	
    self:SendMessageToAllOnServer(broadcastMessage, exemptPids)
	
    self:_SetPlayerDowned(downedPid, false)
	contentFixer.UnequipDeadlyItems(downedPid) -- Morrowind mega mind workaround
	tes3mp.Resurrect(downedPid, 0)
	tes3mp.SetHealthCurrent(downedPid, newHealth)
	tes3mp.SetMagickaCurrent(downedPid, newMagicka)
	tes3mp.SetFatigueCurrent(downedPid, newFatigue)
	tes3mp.SendStatsDynamic(downedPid)
	
    self:RemoveReviveMarker(self.pidMarkerLookup[downedPid])
end

---@param pid number
function SaintRevive:OnPlayerBleedout(pid)
    self:_SetPlayerDowned(pid, false)
	
	-- Inform the player
    tes3mp.SendMessage(pid, self:GetLangText("bleedoutPlayerMessage") .. "\n")
	
	-- Inform others if configured
	local exemptPids = {pid}
	local pname = Players[pid].accountName
	local message = self:GetLangText("bleedoutOtherMessage", {name = pname})

    self:SendMessageToAllOnServer(message, exemptPids)

    OnDeathTimeExpiration(pid, pname)
	
    self:RemoveReviveMarker(self.pidMarkerLookup[pid])
end

---@param pid number
---@param timeRemaining number|nil
function SaintRevive:DownPlayer(pid, timeRemaining)
    self:_SetPlayerDowned(pid, true)

    local secondsLeft
	if not timeRemaining then
		secondsLeft = self.config.bleedoutTime
        self:_SetPlayerBleedoutTicks(pid, 0)
	else
		secondsLeft = timeRemaining
        self:_SetPlayerBleedoutTicks(pid, self.config.bleedoutTime - secondsLeft)
	end
	
	-- Send the first basic messages
	tes3mp.SendMessage(pid, self:GetLangText("awaitingReviveMessage") .. "\n")
	local downedPlayerName = Players[pid].accountName
	local exemptPids = {pid}
	local downBroadcastMessage = self:GetLangText("awaitingReviveOtherMessage", {name = downedPlayerName})
    self:SendMessageToAllOnServer(downBroadcastMessage, exemptPids)
    tes3mp.SendMessage(pid, self:GetLangText("bleedingOutMessage", {seconds = secondsLeft}) .. "\n")


    local timerId = tes3mp.CreateTimerEx("BleedoutTick", time.seconds(1), "ii", pid, self.config.bleedoutTime)
    self:_SetBleedoutTimerId(pid, timerId)
    tes3mp.StartTimer(timerId)
    logger:Info("Creating timer with ID: '" .. timerId .. "' for player PID '" .. pid .. "'")

    self:CreateReviveMarker(pid)

	tes3mp.SendMessage(pid, self:GetLangText("giveInPrompt") .. "\n")
end

---@param pid number
---@return number NewHealth
---@return number NewMagicka
---@return number NewFatigue
function SaintRevive:CalculateRevivedPlayerStats(pid)
    local healthBase = tes3mp.GetHealthBase(pid)
	local fatigueCurrent = tes3mp.GetFatigueCurrent(pid)
	local fatigueBase = tes3mp.GetFatigueBase(pid)
	local magickaCurrent = tes3mp.GetMagickaCurrent(pid)
	local magickaBase = tes3mp.GetMagickaBase(pid)
	
	local newHealth, newMagicka, newFatigue
	
	if self.config.health < 1.0 then
        newHealth = math.floor((healthBase * self.config.health) + 0.5 )
	else
		newHealth = self.config.health
	end
	
	if self.config.magicka == "preserve" then
		newMagicka = magickaCurrent
	elseif self.config.magicka < 1.0 then
		newMagicka = math.floor((magickaBase * self.config.magicka) + 0.5 )
	else
		newMagicka = self.config.magicka
	end
	
	if self.config.fatigue == "preserve" then
		newFatigue = fatigueCurrent
	elseif self.config.fatigue < 1.0 then
		newFatigue = math.floor((fatigueBase * self.config.fatigue) + 0.5 )
	else
		newFatigue = self.config.fatigue
	end

    newHealth = math.max(math.min(newHealth, healthBase), 1) -- gotta be one if we are ressing
	newMagicka = math.max(math.min(newMagicka, magickaBase), 0)
	newFatigue = math.max(math.min(newFatigue, fatigueBase), 0)

    return newHealth, newMagicka, newFatigue
end

function SaintRevive:TrySetPlayerDowned(pid)
	if self:_GetPlayerLoggedOutDowned(pid) then
		local remaining = self.config.bleedoutTime - Players[pid].data.customVariables.bleedoutTicks
        self:_SetPlayerLoggedOutDowned(pid, nil)
		
		self:DownPlayer(pid, remaining)
	elseif not self:_GetPlayerDowned(pid) then
		self:_SetPlayerDowned(pid)
	end
end

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--- Getters and Setters
-------------------------------------------------------------------------------

---@param pid number
---@param value number
function SaintRevive:_SetPlayerBleedoutTicks(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to bleedout a player that was not logged in!')
        return
    end
    player.data.customVariables.bleedoutTicks = value
end

function SaintRevive:_GetPlayerBleedoutTicks(pid)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to access a player that was not logged in!')
        return 0
    end
    return player.data.customVariables.bleedoutTicks
end

---@param pid number
function SaintRevive:_GetPlayerDowned(pid)
    local player = Players[pid]
    return player and player.data.customVariables.isDowned or false
end

---@param pid number
---@param value boolean
function SaintRevive:_SetPlayerDowned(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to down a player that was not logged in!')
        return
    end
    player.data.customVariables.isDowned = value
end

---@param pid number
---@param value boolean
function SaintRevive:_SetPlayerLoggedOutDowned(pid, value)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to logged-out down a player that was not logged in!')
        return
    end
    player.data.customVariables.loggedOutDowned =- value
end

---@param pid number
function SaintRevive:_GetPlayerLoggedOutDowned(pid)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to logged-out down a player that was not logged in!')
        return false
    end
    return player.data.customVariables.loggedOutDowned
end

---@param pid number
---@param timerId number
function SaintRevive:_SetBleedoutTimerId(pid, timerId)
    local player = Players[pid]
    if not player then
        logger:Warn('Attempted to set the bleedout timer of a player that was not logged in!')
        return
    end
    player.data.customVariables.bleedoutTimerId = timerId
end

function SaintRevive:_GetBleedoutTimerId(pid)
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
function SaintRevive:GetLangText(key, data)
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

function SaintRevive:SendMessageToAllWithCellLoaded(cellDescription, message, exceptionPids)
	for pid, player in pairs(Players) do
		if tableHelper.containsValue(player.cellsLoaded, cellDescription) and not tableHelper.containsValue(exceptionPids or {}, pid) then
			tes3mp.SendMessage(pid, message .. "\n")
		end
	end
end

function SaintRevive:SendMessageToAllOnServer(message, exceptionPids)
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

function SaintRevive:OnDieCommand(pid)
    if self:_GetPlayerDowned(pid) then
        self:OnPlayerBleedout(pid)
    end
end

function SaintRevive:OnPlayerFinishLogin(pid)
    if self:_GetPlayerDowned(pid) then
		Players[pid]:SetHealthCurrent(0)
		self:_SetPlayerLoggedOutDowned(pid, true)
	end
end

---@param pid number
---@param cellDescription string
---@param objects ObjectActiveObjectsContainer[]
function SaintRevive:OnObjectActivate(pid, cellDescription, objects)
    for _, object in pairs(objects) do
        local objectPid
        local activatorPid
        
        -- Detect if the object being activated is a player
        if tes3mp.IsObjectPlayer(object.uniqueIndex) then
            objectPid = tes3mp.GetObjectPid(object.uniqueIndex)
        end
        
        -- Detect if the object was activated by a player
        if tes3mp.DoesObjectHavePlayerActivating(object.uniqueIndex) then
            activatorPid = tes3mp.GetObjectActivatingPid(object.uniqueIndex)
        end
        
        if objectPid and activatorPid then
            if self:_GetPlayerDowned(objectPid) then
                self:OnPlayerRevive(objectPid, activatorPid)
            end
        elseif object.refId == self.config.recordRefId then
            if self.reviveMarkers[object.uniqueIndex] and self:_GetPlayerDowned(self.reviveMarkers[object.uniqueIndex].pid) then
                self:OnPlayerRevive(self.reviveMarkers[object.uniqueIndex].pid, activatorPid)
            else
                --OnPlayerRevive already removes the marker
                self:RemoveReviveMarker(object.uniqueIndex, cellDescription)
            end
            
        end
    end
end

function SaintRevive:OnServerPostInit()
    if RecordStores[self.config.objectType].data.permanentRecords[self.config.recordRefId] == nil then
		local data = {
            model = self.config.model,
            name = self:GetLangText("reviveMarkerName"),
            script = "nopickup"
        }
		
		RecordStores[self.config.objectType].data.permanentRecords[self.config.recordRefId] = data
		
		RecordStores[self.config.objectType]:SaveToDrive()
        logger:Info("Created record for custom marker")
    else
        logger:Info("Custom record already exists, skipping")
	end
end

---@param pid number
function SaintRevive:OnPlayerDisconnect(pid)
    if self:_GetPlayerDowned(pid) then
        self:RemoveReviveMarker(self.pidMarkerLookup[pid])
    end
end

---@param pid number
---@return boolean DidPlayerGetDowned
function SaintRevive:OnPlayerDeath(pid)
    local message
	if tes3mp.DoesPlayerHavePlayerKiller(pid) and tes3mp.GetPlayerKillerPid(pid) ~= pid then
		local killerPid = tes3mp.GetPlayerKillerPid(pid)
		message = self:GetLangText("defaultKilledByPlayer", {name = logicHandler.GetChatName(pid), killer = logicHandler.GetChatName(killerPid)})
	elseif tes3mp.GetPlayerKillerName(pid) ~= "" then
		message = self:GetLangText("defaultKilledByOther", {name = logicHandler.GetChatName(pid), killer = tes3mp.GetPlayerKillerName(pid)})
	else
		message = self:GetLangText("defaultSuicide", {name = logicHandler.GetChatName(pid)})
	end
	
	tes3mp.SendMessage(pid, message .. "\n", true)
	
    ---Saint Note: This seems unnecessary? Or something, idk, dont like
	if config.playersRespawn then
		self:TrySetPlayerDowned(pid)
	else
		tes3mp.SendMessage(pid, self:GetLangText("defaultPermanentDeath") .. "\n", false)
		return false
	end

	return true
end

-------------------------------------------------------------------------------

---Global Bleedout Tick for SaintRevive
---@param pid number
function BleedoutTick(pid, bleedoutTime)
    local player = Players[pid]
	if player and Players[pid]:IsLoggedIn() then
		if SaintRevive:_GetPlayerDowned(pid) then
            SaintRevive:_SetPlayerBleedoutTicks(pid, SaintRevive:_GetPlayerBleedoutTicks() or 1)
			
			if SaintRevive:_GetPlayerBleedoutTicks(pid) >= bleedoutTime then
				return SaintRevive:OnPlayerBleedout(pid)
			else
				local timerId = SaintRevive:_GetBleedoutTimerId(pid)
				return tes3mp.RestartTimer(timerId, time.seconds(1))
			end
		end
	end
end

function SaintRevive:Init()
    customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
        local result = self:OnPlayerDeath(pid)
        return customEventHooks.makeEventStatus(false, not result)
    end)
    customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
        self:OnPlayerDisconnect(pid)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnPlayerFinishLogin",  function(eventStatus, pid)
        self:OnPlayerFinishLogin(pid)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
        self:OnObjectActivate(pid, cellDescription, objects)
        return eventStatus
    end)
    customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
        self:OnServerPostInit()
        return eventStatus
    end)
    customCommandHooks.registerCommand("die", function(pid)
        self:OnDieCommand(pid)
    end)
end

---@type SaintRevive
local sr_instance = SaintRevive(ScriptConfig)
sr_instance:Init()
return sr_instance
