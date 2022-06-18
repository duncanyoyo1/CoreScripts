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
local tableHelper = require('tableHelper')

local SaintTicks = require('custom.SaintTicks')
local SaintCellReset = require('custom.SaintCellReset')
local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')
local SaintScriptSave = require('custom.SaintScriptSave')

local scriptConfig = {
    ResetTime = time.toSeconds(time.days(3)),
    periodicCellCheckTimer = time.toSeconds(time.minutes(5)),
    blackList = {
        'Fake cell'
    }
}
-- Internal Use
local logger = SaintLogger:CreateLogger('SaintCellResetManager')
local DataManager = SaintScriptSave('SaintCellResetManager')
local adjustedBlackList = {}
---@class SaintCellResetManager
local SaintCellResetManager = {}
---@class Internal
local Internal = {}

---@param cellDescription string cell name
Internal.IsCellResetValid = function(cellDescription)
    local result, error = SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        local nowTime = os.time()
        local creationTime = cell.data.entry.creationTime
        local timeDiference = nowTime - creationTime
        if timeDiference < scriptConfig.ResetTime then
            return false, 'Not enough time has passed'
        end

        --- Never attempt to augment or operate on the void
        if cellDescription == '$Transitional Void' then
            logger:Warn('A player is checking the void...')
            return false, 'Player is in the void'
        end

        if tableHelper.containsValue(adjustedBlackList, cellDescription) then
            return false, 'Blacklisted cell'
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
        local isValid, reason = Internal.IsCellResetValid(cellDescription)
        if not isValid then
            return false, reason
        end
        if Internal.DoesCellContainVisitors(cellDescription) then
            return false, 'Contains visitors'
        end
        return true, nil
    end)
end

Internal.PeriodicCellsReset = function(cellDescriptions)
    local cellsToReset = {}
    for _, cellDescription in pairs(cellDescriptions) do
        SaintUtilities.TempLoadCellCallback(cellDescription, function()
            local isValid, reason = Internal.IsCellPeriodicCellResetValid(cellDescription)
            if isValid then
                table.insert(cellsToReset, cellDescription)
            else
                logger:Verbose('Skipping \'' .. cellDescription .. '\' for reason: '.. reason)
            end
        end)
    end
    local cellCount = tableHelper.getCount(cellDescriptions)
    if not tableHelper.isEmpty(cellsToReset) then
        SaintCellReset.ResetCells(cellsToReset)
        logger:Info('Resetting ' .. cellCount .. ' cells')
    else
        logger:Info('Found no cells to reset out of ' .. cellCount)
    end
end

Internal.GetCellNames = function()
    local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/cell')
    for index, fileName in pairs(fileNames) do
        fileNames[index] = fileName:gsub('%.json', '')
    end
    return fileNames
end

Internal.PeriodicCellTimer = function()
    logger:Info('Timer ticking...')
    local cellNames = Internal.GetCellNames()
    Internal.PeriodicCellsReset(cellNames)
end

customEventHooks.registerHandler('OnServerPostInit', function(eventStatus) 
    local data = DataManager:GetData() or {}
    tableHelper.merge(adjustedBlackList, scriptConfig.blackList)
    tableHelper.merge(adjustedBlackList, data)
    SaintTicks.RegisterTick(Internal.PeriodicCellTimer, time.seconds(300))
    logger:Info('Starting SaintCellResetManager...')
    return eventStatus
end)

customEventHooks.registerHandler('OnServerExit', function(eventStatus)
    DataManager:SetData(adjustedBlackList)
    DataManager:Save()
    logger:Info('Saving data')
    return eventStatus
end)

customCommandHooks.registerCommand('SCRMRegisterBlackCell', function(pid)
    local player = Players[pid]
    local cell = player.data.location.cell
    table.insert(adjustedBlackList, cell)
    DataManager:SetData(adjustedBlackList)
    DataManager:Save()
end)

return SaintCellResetManager