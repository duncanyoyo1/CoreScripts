local classy = require('classy')

---@class BinaryStringReader
local BinaryStringReader = classy('BinaryStringReader')

function BinaryStringReader:__init(binaryData)
    self.binaryString = binaryData
    self.index = 1
end

---@param byteCount integer
function BinaryStringReader:Read(byteCount)
    local offset = byteCount - 1 -- sub is inclusive and 1 based indexing sucks
    local start = self.index
    local finish = start + offset
    if finish > #self.binaryString then
        print(start, finish, #self.binaryString)
        error('Attempting to read beyond length')
    end
    local data = string.sub(self.binaryString, start, finish)
    self.index = start + byteCount
    return data
end

function BinaryStringReader:Unread(byteCount)
    self.index = self.index - byteCount
    if self.index < 1 then error('Attempting to unread to a negative index') end
end

local BinaryStringReaderConstructor = BinaryStringReader ---@type fun(str: string): BinaryStringReader
return BinaryStringReaderConstructor
