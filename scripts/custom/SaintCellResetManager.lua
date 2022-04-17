-------------------------------------------------------------------------------
--- SaintCellResetManager
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Manager class for SaintCellReset. Periodically resets cells.
--- Note: Cells don't reset well when players are in them. We only reset EMPTY
--- cells
-------------------------------------------------------------------------------
---Saint Note: Convert to classes
local customEventHooks = require('customEventHooks')
local time = require('time')

local SaintTicks = require('custom.SaintTicks')
local SaintCellReset = require('custom.SaintCellReset')
local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')

local scriptConfig = {
    ResetTime = time.days(3),
    version = '1',
    periodicCellCheckTimer = 60 * 5, -- 5 minutes
}
-- Internal Use
local logger = SaintLogger:CreateLogger('SaintCellResetManager')
---@class SaintCellResetManager
local SaintCellResetManager = {}
---@class Internal
local Internal = {}

---@param cellDescription string cell name
SaintCellResetManager.IsCellResetValid = function(cellDescription)
    local result, error = SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        local nowTime = os.time()
        local creationTime = cell.data.entry.creationTime
        local timeDiference = nowTime - creationTime
        if timeDiference < scriptConfig.ResetTime then
            return false, "Not enough time has passed"
        end

        --- Never attempt to augment or operate on the void
        if cellDescription == "$Transitional Void" then
            logger:Warn("A player is checking the void...")
            return false, "Player is in the void"
        end

        return true
    end)
    return result, error
end

Internal.DoesCellContainVisitors = function(cellDescription)
    return SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        return cell:GetVisitorCount() > 0
    end)
end

Internal.IsCellPeriodicCellResetValid = function(cellDescription)
    return SaintUtilities.TempLoadCellCallback(cellDescription, function()
        if not SaintCellResetManager.IsCellResetValid(cellDescription) then
            return false
        end
        if Internal.DoesCellContainVisitors(cellDescription) then
            return false
        end
        return true
    end)
end

Internal.PeriodicCellsReset = function(cellDescriptions)
    local cellsToReset = {}
    for _, cellDescription in pairs(cellDescriptions) do
        SaintUtilities.TempLoadCellCallback(cellDescription, function()
            if Internal.IsCellPeriodicCellResetValid(cellDescription) then
                table.insert(cellsToReset, cellDescription)
            end
        end)
    end
    if not tableHelper.isEmpty(cellsToReset) then
        SaintCellReset.ResetCells(cellsToReset)
    end
end

Internal.GetCellNames = function()
    local fileNames = SaintUtilities.GetFileNamesInFolder('./server/data/cell')
    for index, fileName in pairs(fileNames) do
        fileNames[index] = fileName:gsub("%.json", "")
    end
    return fileNames
end

Internal.PeriodicCellTimer = function()
    logger:Info("Timer ticking...")
    local cellNames = Internal.GetCellNames()
    Internal.PeriodicCellsReset(cellNames)
end


customEventHooks.registerHandler("OnServerPostInit", function(eventStatus) 
    logger:Info("Starting SaintCellResetManager...")
    SaintTicks.RegisterTick(Internal.PeriodicCellTimer, time.seconds(10))
    return eventStatus
end)

return SaintCellResetManager