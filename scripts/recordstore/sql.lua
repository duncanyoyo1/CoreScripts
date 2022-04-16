local Database = require("database")
local BaseRecordStore = require("recordstore.base")

---@class SqlRecordStore : BaseRecordStore
local RecordStore = class("RecordStore", BaseRecordStore)

function RecordStore:__init()
    BaseRecordStore.__init(self)

    if self.hasEntry == nil then

        -- Not implemented yet
    end
end

function RecordStore:CreateEntry()
    -- Not implemented yet
end

function RecordStore:SaveToDrive()
    -- Not implemented yet
end

function RecordStore:LoadFromDrive()
    -- Not implemented yet
end

return RecordStore
