-------------------------------------------------------------------------------
--- SaintCellReset
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- API for resetting of cells. Not a smart API, and does not contain
--- validation logic for resetting. This is not meant to be used DIRECTLY for
--- the resetting of cells. Users of this script should implement their own
--- validation logic to determine if a cell can and should be reset.
-------------------------------------------------------------------------------

local tableHelper    = require('tableHelper')
local SaintUtilities = require('custom.saint.common.utilities.main')
local SaintLogger    = require('custom.saint.common.logger.main')

local logger = SaintLogger:GetLogger('SaintCellReset')
---@class SaintCellReset
local SaintCellReset = {}
---@class SaintCellResetInternal
local Internal = {}

--- THIS IS A COPY PASTE OF "logicHandler.ResetCell" MINUS SOME LOGGING
Internal.ResetCellReImpl = function(cellDescription)
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

---@param cellDescription string cell name
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
        tableHelper.merge(cell.data.objectData, cellChanges.objectData)
        tableHelper.merge(cell.data.packets.cellChangeTo, cellChanges.packets.cellChangeTo)
        tableHelper.merge(cell.data.packets.cellChangeFrom, cellChanges.packets.cellChangeFrom)
    end)
end

--- Reset cell, no checks
---@param cellDescription string cell name for cell to be affected
---@param pids string[]? optional list of pids to reset cells for
SaintCellReset.ResetCell = function(cellDescription, pids)
    SaintCellReset.ResetCells({ cellDescription }, pids)
end

--- Reset multiple cells Note: This is somewhat of a reimpl of logicHandler.ResetCell
---@param cellDescriptions string[] list of cell names
---@param pids number[]? optional list of players to reset cells for
SaintCellReset.ResetCells = function(cellDescriptions, pids)
    local cellChanges = {}
    tes3mp.ClearCellsToReset()

    for _, cellDescription in pairs(cellDescriptions) do
        cellChanges[cellDescription] = Internal.CaptureCellChanges(cellDescription)
        Internal.ResetCellReImpl(cellDescription)
        tes3mp.AddCellToReset(cellDescription)
        logger:Info("Resetting cell '" .. cellDescription .. "'")
    end

    if pids then
        for _, pid in pairs(pids) do
            tes3mp.SendCellReset(pid, false)
        end
    else
        for pid, _ in pairs(Players) do
            tes3mp.SendCellReset(pid, false)
        end
    end

    for cellDescription, changes in pairs(cellChanges) do
        Internal.ApplyCellChanges(cellDescription, changes)
    end

end

--- Reset cell, no checks
---@param cellDescription string cell name for cell to be affected
SaintCellReset.MarkCellForReset = function(cellDescription)
    SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        cell.data.entry.creationTime = 0
    end)
end

return SaintCellReset
