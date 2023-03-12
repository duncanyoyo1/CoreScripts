local classy          = require('classy')
local enumerations    = require('enumerations')

local SaintCellReset  = require('custom.saint.cellreset.api')
local SaintLogger     = require('custom.saint.common.logger.main')

local logger          = SaintLogger:GetLogger('SaintInstance')

---@class InstanceManager
---@overload fun(config: InstanceManagerConfig?): InstanceManager
local InstanceManager = classy('CellInstanceManager')

function InstanceManager:__init(config)
    self.cache = {}
end

---Saint Note: Possible issue w/ pids already having record?
---@param cellDescription string cell name to create instance of
---@param pids integer[] list of player pids to have the cell added
function InstanceManager:CreateInstanceOfCellForPlayers(cellDescription, pids)
    logger:Info('Creating instance of: "' .. cellDescription .. '" for pids: ')
    for _, pid in ipairs(pids) do
        logger:Append(pid)
    end

    local newId = cellDescription .. ' - Instanced'

    tes3mp.ClearRecords()
    tes3mp.SetRecordType(enumerations.recordType.CELL)
    packetBuilder.AddCellRecord(newId, self:_CreateCellRecordCopy(cellDescription))
    for _, pid in ipairs(pids) do
        tes3mp.SendRecordDynamic(pid)
    end
end

---Cell records cannot be removed (as of yet). This will clear the data for that
---cell for each PID
---@param cellDescription string cell name to delete the instance of
---@param pids integer[] list of player pids to have the cell deleted
function InstanceManager:DeleteInstanceOfCellForPlayers(cellDescription, pids)
    logger:Info('Deleting instance of: "' .. cellDescription .. '" for pids: ')
    for _, pid in ipairs(pids) do
        logger:Append(pid)
    end

    local cellId = cellDescription .. ' - Instanced'

    SaintCellReset.ResetCell(cellId, pids)
end

---@private
---Creates a duplicate record of cell (Or tells tes3 to at least)
---@param cellDescription string
---@return table
function InstanceManager:_CreateCellRecordCopy(cellDescription)
    return {
        baseId = cellDescription
    }
end

return InstanceManager
