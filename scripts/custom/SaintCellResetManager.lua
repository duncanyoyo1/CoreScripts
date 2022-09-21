-------------------------------------------------------------------------------
--- SaintCellResetManager
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Manager class for SaintCellReset. Periodically resets cells.
--- Note: Cells don't reset well when players are in them. We only reset EMPTY
--- cells
-------------------------------------------------------------------------------
---Saint Note: Convert to classes
local customEventHooks = require('customEventHooks')
local customCommandHooks = require('customCommandHooks')
local time = require('time')
local tableHelper = require('tableHelper')

local SaintTicks = require('custom.SaintTicks')
local SaintCellReset = require('custom.SaintCellReset')
local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')
local SaintScriptSave = require('custom.SaintScriptSave')

local scriptConfig = {
    ResetTime = time.toSeconds(time.days(1)),
    periodicCellCheckTimer = time.toSeconds(time.minutes(5)),
    blackList = {
        -- You can add cells here or via the command, which is saved/laoded via SSS
    },
}
-- Internal Use
local logger = SaintLogger:CreateLogger('SaintCellResetManager')
local prioritizedCellsToClear = {}
local adjustedBlackList = {}
---@class SaintCellResetManager
local SaintCellResetManager = {}
---@class SCRMInternal
local Internal = {
    CurrentResetIndex = 1,
    CellNames = {}
}

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

--- NOTE: Remove slicing login here and propogate up to the timer
Internal.PeriodicCellsReset = function(cellDescriptions, startIndex, endIndex)
    local cellsToReset = {}
    for index=startIndex, endIndex, 1 do
        local cellDescription = cellDescriptions[index]
        if cellDescription ~= nil then
            SaintUtilities.TempLoadCellCallback(cellDescription, function()
                local isValid, reason = Internal.IsCellPeriodicCellResetValid(cellDescription)
                if isValid then
                    table.insert(cellsToReset, cellDescription)
                else
                    logger:Verbose('Skipping \'' .. cellDescription .. '\' for reason: '.. reason)
                end
            end)
        else
            logger:Warn('Attempting to go out of bounds! Index: ' .. index)
        end
    end
    local cellCount = (endIndex - startIndex) + 1
    if not tableHelper.isEmpty(cellsToReset) then
        SaintCellReset.ResetCells(cellsToReset)
        logger:Verbose('Resetting ' .. cellCount .. ' cells')
    else
        logger:Verbose('Found no cells to reset out of ' .. cellCount)
    end
end

Internal.PrioritizedCellReset = function(cellDescriptions)
    local cellsToReset = {}
    for cellDescription, notories in pairs(cellDescriptions) do
        if cellDescription ~= nil then
            SaintUtilities.TempLoadCellCallback(cellDescription, function()
                if Internal.DoesCellContainVisitors(cellDescription) then
                    logger:Verbose('Skipping \'' .. cellDescription .. '\' because it has visitors')
                else
                    table.insert(cellsToReset, cellDescription)
                end
            end)
        end
    end
    local cellCount = #cellsToReset
    if not tableHelper.isEmpty(cellsToReset) then
        SaintCellReset.ResetCells(cellsToReset)
        logger:Verbose('Resetting ' .. cellCount .. ' cells')
    else
        logger:Verbose('Found no cells to reset out of ' .. cellCount)
    end
    return cellsToReset
end

--- NOTE: This is expense. Need to find a caheable and less expensive way to do this
Internal.GetCellNames = function()
    local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/cell')
    local cleanedFiles = {}
    for index, fileName in pairs(fileNames) do
        if string.find(fileName, '%.json') then
            local cleanedName = fileName:gsub('%.json', '')
            table.insert(cleanedFiles, cleanedName)
        end
    end
    return cleanedFiles
end

Internal.GetCellNamesTimer = function()
    Internal.CellNames = Internal.GetCellNames()
    logger:Info('There are now ' .. tableHelper.getCount(Internal.CellNames) .. ' cells to reset')
end

Internal.PeriodicCellTimer = function()
    local count = tableHelper.getCount(Internal.CellNames)
    local sliceAmount = math.floor(count / 30)
    local nextIndex = math.min(Internal.CurrentResetIndex + sliceAmount, count)

    logger:Info('Resetting prioritized cells (if any)...')
    local resetCells = Internal.PrioritizedCellReset(prioritizedCellsToClear)
    for _, cellDescription in pairs(resetCells) do
        local notories = prioritizedCellsToClear[cellDescription]
        for _, pid in pairs(notories) do
            tes3mp.SendMessage(pid, "Cell '" .. cellDescription .. "' has been reset\n")
        end
        prioritizedCellsToClear[cellDescription] = nil
    end

    logger:Info('Resetting regular cells...')
    Internal.PeriodicCellsReset(Internal.CellNames, Internal.CurrentResetIndex, nextIndex)

    if nextIndex > count then
        Internal.CurrentResetIndex = 1
    else
        Internal.CurrentResetIndex = nextIndex
    end
end

customEventHooks.registerHandler('OnServerPostInit', function(eventStatus) 
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData() or {
        blacklistedCells = {},
        cachedCellList = {}
    }
    tableHelper.merge(adjustedBlackList, scriptConfig.blackList, true)
    tableHelper.merge(adjustedBlackList, data.blacklistedCells, true)
    data.cachedCellList = Internal.GetCellNames()
    DataManager:SetData(data)
    DataManager:Save()
    Internal.CellNames = data.cachedCellList

    SaintTicks.RegisterTick(Internal.GetCellNamesTimer, time.hours(1))
    SaintTicks.RegisterTick(Internal.PeriodicCellTimer, time.minutes(1))
    logger:Info('Starting SaintCellResetManager...')
    return eventStatus
end)

customEventHooks.registerHandler('OnCellLoad', function(eventStatus, pid, cellDescription)
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData()
    if data.cachedCellList[cellDescription] == nil then
        table.insert(data.cachedCellList, cellDescription)
    end
    DataManager:SetData(data)
    DataManager:Save()
end)

--- NOTE: it'd be nice to notify players when the cell reset
customCommandHooks.registerCommand('QueueCellReset', function(pid)
    local playerCell = Players[pid].data.location.cell
    local queuedNotories = prioritizedCellsToClear[playerCell]
    if queuedNotories == nil then
        queuedNotories = {}
        prioritizedCellsToClear[playerCell] = queuedNotories
    end
    table.insert(prioritizedCellsToClear[playerCell], pid)
    tes3mp.SendMessage(pid, "Queueing '" .. playerCell .. "' for a reset\n")
end)

customCommandHooks.registerCommand('SCRMRegisterBlackCell', function(pid)
    local player = Players[pid]
    local cell = player.data.location.cell
    tes3mp.SendMessage(pid, 'Registering current cell to black list: ' .. cell)
    logger:Info('Registering current cell to black list: ' .. cell)
    table.insert(adjustedBlackList, cell)
    local DataManager = SaintScriptSave('SaintCellResetManager')
    local data = DataManager:GetData()
    table.insert(data.blacklistedCells, cell)
    DataManager:SetData(data)
    DataManager:Save()
end)

return SaintCellResetManager