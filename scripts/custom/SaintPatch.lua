local SaintLogger = require('custom.SaintLogger')

local logger = SaintLogger:CreateLogger('SaintPatch')
local Methods = {}

local scriptConfig = {
    ImproperMoveMessage = "Something went wrong as you moved locations. We have placed you back at the previous location you were.",
    AttemptedSaving = "You were stuck in hell, so we brought you to Caius' house.",
}

local PreviousPlayerPositions = {}

---@param eventStatus EventStatus
---@param pid number
---@return EventStatus
Methods.OnPlayerCellChangeValidator = function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then return eventStatus end
    logger:Verbose("Player location before moving: " .. Players[pid].data.location.cell)
    if Players[pid].data.location.cell == "$Transitional Void" then
        logger:Info("Player trapped in the void at the moment...")
        return eventStatus -- never have a player in the void
    end
    PreviousPlayerPositions[pid] = {
        cell = Players[pid].data.location.cell,
        posX = Players[pid].data.location.posX,
        posY = Players[pid].data.location.posY,
        posZ = Players[pid].data.location.posZ,
        rotX = Players[pid].data.location.rotX,
        rotZ = Players[pid].data.location.rotZ,
    }
    return eventStatus
end

-- TODO: This seems to still have bugs?
---NOTE: I think this is due to the asynchronous of the server and client
---      It looked like the client failed to load some anims and just sorta spun out?
---      Might need to add a fix me command or something
---@param eventStatus EventStatus
---@param pid number
---@return EventStatus
Methods.OnPlayerCellChangeHandler = function(eventStatus, pid)
    if not eventStatus.validCustomHandlers then return eventStatus end
    logger:Verbose("Player location after moving: " .. Players[pid].data.location.cell)
    if Players[pid].data.location.cell == "$Transitional Void" then
        local message = scriptConfig.ImproperMoveMessage
        if PreviousPlayerPositions[pid] == nil or PreviousPlayerPositions[pid].cell == "$Transitional Void" then
            PreviousPlayerPositions[pid] = {
                cell = "Balmora, Caius Cosades' House",
                posX = 180,
                posY = -200,
                posZ = 100,
                rotX = 0,
                rotZ = 0,
            }
            message = scriptConfig.AttemptedSaving
        end
        logger:Info("Bringing a player back from the void...")
        tes3mp.LogAppend(enumerations.log.INFO, "Previous cell '"..PreviousPlayerPositions[pid].cell.."'")
        tes3mp.SetCell(pid, PreviousPlayerPositions[pid].cell)
        tes3mp.SetPos(pid, PreviousPlayerPositions[pid].posX, PreviousPlayerPositions[pid].posY, PreviousPlayerPositions[pid].posZ)
        tes3mp.SetRot(pid, PreviousPlayerPositions[pid].rotX, PreviousPlayerPositions[pid].rotZ)
        tes3mp.SendCell(pid)
        tes3mp.SendPos(pid)
        tes3mp.CustomMessageBox(pid, config.customMenuIds.improperMove, message, "Ok")
    end
    return eventStatus
end

customEventHooks.registerValidator("OnPlayerCellChange", Methods.OnPlayerCellChangeValidator)
customEventHooks.registerHandler("OnPlayerCellChange", Methods.OnPlayerCellChangeHandler)
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus) 
    logger:Info("Starting SaintPatch...")
    return eventStatus
end)

return Methods