local Size  = require('custom.saint.record.parser.primitive.Size')
local Types = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
return function(binaryReader)
    local recordName = binaryReader:Read(Size.INTEGER)
    local recordDataSize = binaryReader:Read(Size.INTEGER, Types.UINT32)
    local recordUnused = binaryReader:Read(Size.INTEGER, Types.UINT32)
    local recordFlags = binaryReader:Read(Size.INTEGER, Types.UINT32)
    local recordData = binaryReader:Read(recordDataSize)
    return {
        name = recordName,
        size = recordDataSize,
        unused = recordUnused,
        flags = recordFlags,
        data = recordData,
    }
end
