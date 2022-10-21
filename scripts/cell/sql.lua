Database = require("database")
local BaseCell = require("cell.base")

---@class SqlCell : BaseCell
---@overload fun(cellDescription: string): SqlCell
local Cell = class("Cell", BaseCell)

---@param cellDescription string
function Cell:__init(cellDescription)
    BaseCell.__init(self, cellDescription)

    if self.hasEntry == nil then

        -- Not implemented yet
    end
end

function Cell:CreateEntry()
    -- Not implemented yet
end

function Cell:SaveToDrive()
    -- Not implemented yet
end

function Cell:LoadFromDrive()
    -- Not implemented yet
end

return Cell
