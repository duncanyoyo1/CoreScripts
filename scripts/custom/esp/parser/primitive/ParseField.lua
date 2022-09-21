local Size  = require('custom.esp.parser.primitive.Size')
local Types = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
return function(binaryReader)
    local fieldName = binaryReader:Read(Size.INTEGER)
    local fieldDataSize = binaryReader:Read(Size.INTEGER, Types.UINT32) ---@type integer
    local fieldData = binaryReader:Read(fieldDataSize)
    return {
        name = fieldName,
        size = fieldDataSize,
        data = fieldData,
    }
end