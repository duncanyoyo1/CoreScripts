local classy = require('classy')
local ffi = require('ffi')

---@class BinaryStringReader
local BinaryStringReader = classy('BinaryStringReader')

function BinaryStringReader:__init(binaryData)
    self.binaryString = binaryData
    self.length = #binaryData
    self.index = 1
end

---NOTE: Not supported in LuaJIT
function BinaryStringReader:__gc()
    if self.index < self.length then
        error('All data not read!')
    end
end

---@param byteCount integer
---@param type nil|string optional
---@return string|integer|number
function BinaryStringReader:Read(byteCount, type)
    local result = self:_read(byteCount, true)
    if type then
        return ffi.cast(type .. '*', result)[0]
    end
    return result
end

---@param byteCount integer
---@return string|nil
function BinaryStringReader:Peak(byteCount)
    if self:HasData() then
        return self:_read(byteCount, false)
    end
    return nil
end

---@param byteCount integer
---@param increment boolean
---@return string
function BinaryStringReader:_read(byteCount, increment)
    local offset = byteCount - 1 -- sub is inclusive and 1 based indexing sucks
    local start = self.index
    local finish = start + offset
    if finish > self.length then
        error('Attempting to read beyond length')
    end
    local data = string.sub(self.binaryString, start, finish)
    if increment then
        self.index = start + byteCount
    end
    return data
end

---@param byteCount integer
function BinaryStringReader:Unread(byteCount)
    self.index = self.index - byteCount
    if self.index < 1 then error('Attempting to unread to a negative index') end
end

function BinaryStringReader:HasData()
    return self.index <= self.length
end

local BinaryStringReaderConstructor = BinaryStringReader ---@type fun(str: string): BinaryStringReader
return BinaryStringReaderConstructor
