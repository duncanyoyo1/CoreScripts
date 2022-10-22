local classy         = require('classy')
local SaintUtilities = require('custom.saint.common.utilities.main')
local SaintLogger    = require('custom.saint.common.logger.main')
local ScriptConfig   = require('custom.saint.revive.config')

local logger = SaintLogger:CreateLogger('SaintRevive')

---@class MarkerData
---@field playerName string
---@field cellDescription string
---@field pid number

---@class MarkerManager
---@field reviveMarkers table<string, MarkerData>
---@field pidMarkerLookup table<number, string>
---@overload fun(): MarkerManager
local MarkerManager = classy('MarkerManager')

function MarkerManager:__init()
    self.reviveMarkers = {}
    self.pidMarkerLookup = {}
end

function MarkerManager:GetMarker(uniqueIndex)
    return self.reviveMarkers[uniqueIndex]
end

function MarkerManager:CreateMarkerAtPidPositiom(pidForMarker)
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
        refId = ScriptConfig.recordRefId,
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

        -- Delete the marker for the downed player, and anyone who was in the cell
        for _, pid in pairs(cell.visitors) do
            logicHandler.DeleteObjectForPlayer(pid, cellDescription, uniqueIndex)
        end
    end)
end

function MarkerManager:RemoveMarkerFromPid(pid)
    self:RemoveMarkerIfExists(self.pidMarkerLookup[pid])
end

function MarkerManager:RemoveMarkerIfExists(uniqueIndex)
    if uniqueIndex then
        local reviveMarker = self.reviveMarkers[uniqueIndex]

        if not reviveMarker then
            logger:Warn('Attempted to remove a revive marker that didnt exist with index: ' .. tostring(uniqueIndex))
            return
        end

        SaintUtilities.TempLoadCellCallback(reviveMarker.cellDescription, function(cell)
            logicHandler.DeleteObjectForEveryone(reviveMarker.cellDescription, uniqueIndex)
            cell:DeleteObjectData(uniqueIndex)
        end)

        self.pidMarkerLookup[reviveMarker.pid] = nil
        self.reviveMarkers[uniqueIndex] = nil
    else
        logger:Warn("Attempted to clean up a revive marker with no index! Index: " .. tostring(uniqueIndex))
    end
end

return MarkerManager
