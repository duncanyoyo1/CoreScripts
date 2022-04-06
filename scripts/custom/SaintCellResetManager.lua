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
local Methods = {}
local Internal = {}

---@param cellDescription string cell name
Methods.IsCellResetValid = function(cellDescription)
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
    return SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        if not Methods.IsCellResetValid(cellDescription) then
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
    tes3mp.RestartTimer(GlobalCellResetTimer, time.seconds(scriptConfig.periodicCellCheckTimer))
end


GlobalCellResetTimerUpdate = Internal.PeriodicCellTimer
GlobalCellResetTimer = tes3mp.CreateTimer("GlobalCellResetTimerUpdate", time.seconds(20))
tes3mp.StartTimer(GlobalCellResetTimer)
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus) 
    logger:Info("Starting SaintCellResetManager...")
    return eventStatus
end)

return Methods