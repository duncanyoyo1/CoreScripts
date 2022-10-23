local SaintUtilities = require('custom.saint.common.utilities.main')
local Config         = require('custom.saint.cellreset.config')

local ValidityRules = {}
local Internal = {}

---@param cellDescription string cell name
---@param blacklist table hack to get black list into black list check. Could add it as custom var on cell
ValidityRules.IsCellResetValid = function(cellDescription, blacklist)
    if Internal.IsCellFresh(cellDescription) then
        return false, 'Not enough time has passed'
    end

    if Internal.IsCellBlacklisted(cellDescription, blacklist) then
        return false, 'Blacklisted cell'
    end

    if Internal.DoesCellContainVisitors(cellDescription) then
        return false, 'Contains visitors'
    end

    return true, nil
end

ValidityRules.IsCellSafeToReset = function(cellDescription)
    return Internal.DoesCellContainVisitors(cellDescription)
end

Internal.IsCellFresh = function(cellDescription)
    return SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        local nowTime = os.time()
        local creationTime = cell.data.entry.creationTime
        local timeDiference = nowTime - creationTime
        return timeDiference < Config.ResetTime
    end)
end

Internal.IsCellBlacklisted = function(cellDescription, blacklist)
    return tableHelper.containsValue(blacklist, cellDescription)
end

Internal.DoesCellContainVisitors = function(cellDescription)
    return SaintUtilities.TempLoadCellCallback(cellDescription, function(cell)
        return cell:GetVisitorCount() > 0
    end)
end

return ValidityRules
