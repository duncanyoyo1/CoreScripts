local Size       = require('custom.esp.parser.primitive.Size')
local Types      = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
return function (binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end