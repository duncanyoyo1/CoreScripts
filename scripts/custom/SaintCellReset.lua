local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')

local logger = SaintLogger:CreateLogger('SaintCellReset')
local Methods = {}
local Internal = {}

--- THIS IS A COPY PASTE OF "logicHandler.ResetCell" MINUS SOME LOGGING
Internal._ResetCellReImpl = function(cellDescription)
    SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        cell.isResetting = true
        cell.data.objectData = {}
        cell.data.packets = {}
        cell:EnsurePacketTables()
        cell.data.loadState.hasFullActorList = false
        cell.data.loadState.hasFullContainerData = false
        cell:ClearRecordLinks()

        -- addition
        cell.data.entry.creationTime = os.time()
    end)
end

Internal._SendCellReset = function(pid, cellDescription)
    tes3mp.ClearCellsToReset()
    tes3mp.AddCellToReset(cellDescription)
    tes3mp.SendCellReset(pid, false) --- all players are already getting sent the reset where this is called
end

---@param cellDescription string sell name
---@return table result A partial of cell.data
Internal.CaptureCellChanges = function(cellDescription)
    return SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        local preservedObjectData = {}
        local changeToPackets = cell.data.packets.cellChangeTo
        local changeFromPackets = cell.data.packets.cellChangeFrom

        for _, id in pairs(changeToPackets) do
            logger:Verbose("Preserving cell change to ID: '" .. id .. "'")
            preservedObjectData[id] = cell.data.objectData[id]
        end

        for _, id in pairs(changeFromPackets) do
            logger:Verbose("Preserving cell change from ID: '" .. id .. "'")
            preservedObjectData[id] = cell.data.objectData[id]
        end

        return {
            objectData = preservedObjectData,
            packets = {
                cellChangeTo = changeToPackets,
                cellChangeFrom = changeFromPackets
            }
        }
    end)
end

---@param cellDescription string cell name
---@param cellChanges table partial of cell.data
Internal.ApplyCellChanges = function(cellDescription, cellChanges)
    SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        -- A table merge would be IDEAL if this gets cumbersome later, but I feel safer with this for now
        tableHelper.merge(cell.data.objectData, cellChanges.objectData)
        tableHelper.merge(cell.data.packets.cellChangeTo, cellChanges.packets.cellChangeTo)
        tableHelper.merge(cell.data.packets.cellChangeFrom, cellChanges.packets.cellChangeFrom)
    end)
end

--- Reset cell, no checks
---@param cellDescription string cell name for cell to be affected
Methods.ResetCell = function(cellDescription)
    SaintUtilities.TempLoadCellCallback(cellDescription, function() -- optimization, so we don't constantly load/unload
        local cellChanges = Internal.CaptureCellChanges(cellDescription)
        Internal._ResetCellReImpl(cellDescription)
        logger:Info("Resetting cell '" .. cellDescription .. "'")
        for pid, _ in pairs(Players) do
            logger:Append("Telling player: '" .. Players[pid].accountName .. "'")
            Internal._SendCellReset(pid, cellDescription)
        end
        Internal.ApplyCellChanges(cellDescription, cellChanges)
    end)
end

--- Reset multiple cells Note: This is somewhat of a reimpl of logicHandler.ResetCell
---@param cellDescriptions string[] list of cell names
Methods.ResetCells = function(cellDescriptions)
    local cellChanges = {}
    tes3mp.ClearCellsToReset()
    for _, cellDescription in ipairs(cellDescriptions) do
        SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
            cellChanges[cellDescription] = Internal.CaptureCellChanges(cellDescription)
            --- Copy Paste from Logic Handler
            cell.isResetting = true
            cell.data.objectData = {}
            cell.data.packets = {}
            cell:EnsurePacketTables()
            cell.data.loadState.hasFullActorList = false
            cell.data.loadState.hasFullContainerData = false
            cell:ClearRecordLinks()

            -- addition
            cell.data.entry.creationTime = os.time()
        end)
        tes3mp.AddCellToReset(cellDescription)
        logger:Info("Resetting cell '" .. cellDescription .. "'")
    end

    for _, pid in ipairs(Players) do
        tes3mp.SendCellReset(pid, false)
    end

    for cellDescription, changes in pairs(cellChanges) do
        Internal.ApplyCellChanges(cellDescription, changes)
    end
    
end

--- Reset cell, no checks
---@param cellDescription string cell name for cell to be affected
Methods.MarkCellForReset = function(cellDescription)
    SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        cell.data.entry.creationTime = 0
    end)
end

---Command for marking a cell for reset
---@param pid number player id
Internal.MarkCurrentCellForResetCommand = function(pid)
    Methods.MarkCellForReset(Players[pid].data.location.cell)
    Players[pid]:Message("Marking '"..Players[pid].data.location.cell.."' for reset\n")
end

---Command for marking all loaded cells of a player to be reset
---@param pid number player id
Internal.MarkAllCellsForResetCommand = function(pid)
    for _, cellDescription in ipairs(Players[pid].cellsLoaded) do
        Methods.MarkCellForReset(cellDescription)
        Players[pid]:Message("Marking '"..cellDescription.."' for reset\n")
    end
end

---Forcibly reset the current cell
---WARNING: players in cell get forcibly transferred to the '$Transitional Void'
---         and don't get beought back. This requires something like SaintPatch
---         to rememdy
---@param pid number player id
Internal.ResetCurrentCellCommand = function(pid)
    Methods.ResetCell(Players[pid].data.location.cell)
    Players[pid]:Message("Resetting cell '"..Players[pid].data.location.cell.."'\n")
end

customCommandHooks.registerCommand("MarkCurrentCellForReset", Internal.MarkCurrentCellForResetCommand)
customCommandHooks.registerCommand("MarkAllCellsForReset", Internal.MarkAllCellsForResetCommand)
customCommandHooks.registerCommand("ResetCurrentCell", Internal.ResetCurrentCellCommand)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    logger:Info("Starting SaintCellReset...")
    return eventStatus
end)

return Methods
