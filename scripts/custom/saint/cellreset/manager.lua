-------------------------------------------------------------------------------
--- SaintCellResetManager
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Manager class for SaintCellReset. Periodically resets cells.
--- Note: Cells don't reset well when players are in them. We only reset EMPTY
--- cells
-------------------------------------------------------------------------------

local tableHelper     = require('tableHelper')
local SaintCellReset  = require('custom.saint.cellreset.api')
local Config          = require('custom.saint.cellreset.config')
local SaintCellIo     = require('custom.saint.cellreset.io')
local ValidityRules   = require('custom.saint.cellreset.validityRules')
local SaintUtilities  = require('custom.saint.common.utilities.main')
local SaintLogger     = require('custom.saint.common.logger.main')
local SaintScriptSave = require('custom.saint.common.data.main')

-- Internal Use

local logger = SaintLogger:GetLogger('SaintCellReset')

---@class SaintCellResetManager
local SaintCellResetManager = {}
---@class SaintCellResetManagerInternal
local Internal = {
    CurrentResetIndex = 1,
    CellNames = {},
    PrioritizedCellsToClear = {},
    Blacklist = {}
}

Internal.ResetCellSlice = function(cellDescriptions, startIndex, endIndex)
    local cellsToReset = {}
    for index = startIndex, endIndex, 1 do
        local cellDescription = cellDescriptions[index]
        if cellDescription ~= nil then
            SaintUtilities.TempLoadCellCallback(cellDescription, function()
                local isValid, reason = ValidityRules.IsCellResetValid(cellDescription, Internal.Blacklist)
                if isValid then
                    table.insert(cellsToReset, cellDescription)
                else
                    logger:Verbose('Skipping \'' .. cellDescription .. '\' for reason: ' .. reason)
                end
            end)
        else
            logger:Warn('Attempting to go out of bounds! Index: ' .. index)
        end
    end
    SaintCellReset.ResetCells(cellsToReset)
    return cellsToReset
end

Internal.ResetPrioritizedCells = function()
    local cellsToReset = {}
    local cellNotaries = {}
    for cellDescription, notories in pairs(Internal.PrioritizedCellsToClear) do
        if cellDescription ~= nil then
            if ValidityRules.IsCellSafeToReset(cellDescription) then
                logger:Verbose('Skipping \'' .. cellDescription .. '\' because it has visitors')
            else
                table.insert(cellsToReset, cellDescription)
                cellNotaries[cellDescription] = notories
                Internal.PrioritizedCellsToClear[cellDescription] = nil
            end
        end
    end
    SaintCellReset.ResetCells(cellsToReset)
    return cellsToReset, cellNotaries
end

---Setup SCRM
SaintCellResetManager.Initizalize = function()
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData() or {
        blacklistedCells = {},
        cachedCellList = {}
    }
    tableHelper.merge(Internal.Blacklist, Config.Blacklist, true)
    tableHelper.merge(Internal.Blacklist, data.blacklistedCells, true)
    data.cachedCellList = SaintCellIo.QueryKnownCellNamesFromFile()
    DataManager:SetData(data)
    DataManager:Save()
    Internal.CellNames = data.cachedCellList
end

---Add a cell to internal cache
---@param cellDescription string
SaintCellResetManager.AddCellToCache = function(cellDescription)
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData()
    if data.cachedCellList[cellDescription] == nil then
        table.insert(data.cachedCellList, cellDescription)
    end
    DataManager:SetData(data)
    DataManager:Save()
end

---Set interal cell names to all known cell names
SaintCellResetManager.LoadCellNamesFromFiles = function()
    Internal.CellNames = SaintCellIo.QueryKnownCellNamesFromFile()
    logger:Info('There are now ' .. tableHelper.getCount(Internal.CellNames) .. ' cells to reset')
end

---Cycle through the current cell resets
SaintCellResetManager.ProcessCellResets = function()
    logger:Info('Resetting prioritized cells (if any)...')
    local _, cellNotaries = Internal.ResetPrioritizedCells()
    ---NOTE: Perhaps break into new function
    for cellDescription, notories in pairs(cellNotaries) do
        for _, pid in pairs(notories) do
            tes3mp.SendMessage(pid, "Cell '" .. cellDescription .. "' has been reset\n")
        end
    end

    local count = tableHelper.getCount(Internal.CellNames)
    local sliceAmount = math.floor(count / Config.SliceAmount)
    local nextIndex = math.min(Internal.CurrentResetIndex + sliceAmount, count)

    logger:Info('Resetting regular cells...')
    Internal.ResetCellSlice(Internal.CellNames, Internal.CurrentResetIndex, nextIndex)

    if nextIndex > count then
        Internal.CurrentResetIndex = 1
    else
        Internal.CurrentResetIndex = nextIndex
    end
end

---Queue a reset by a certain player
---@param pid any
---@param cellDescription string
SaintCellResetManager.AddCellResetToQueue = function(pid, cellDescription)
    local notaries = Internal.PrioritizedCellsToClear[cellDescription]
    if notaries == nil then
        notaries = {}
        Internal.PrioritizedCellsToClear[cellDescription] = notaries
    end
    table.insert(notaries, pid)
end

---Register a cell to be black listed
---@param cellDescription string
SaintCellResetManager.BlacklistCell = function(cellDescription)
    table.insert(Internal.Blacklist, cellDescription)
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData()
    table.insert(data.blacklistedCells, cellDescription)
    DataManager:SetData(data)
    DataManager:Save()
end

return SaintCellResetManager
