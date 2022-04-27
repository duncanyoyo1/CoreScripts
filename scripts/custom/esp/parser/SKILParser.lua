local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseINDX = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseSKDT = function(binaryReader)
    return {
        attribute = binaryReader:Read(Size.INTEGER, Types.UINT32),
        specialization = binaryReader:Read(Size.INTEGER, Types.UINT32),
        useValues = {
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
        }
    }
end

---@param binaryReader BinaryStringReader
local ParseDESC = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['INDX'] = ParseINDX,
    ['SKDT'] = ParseSKDT,
    ['DESC'] = ParseDESC,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'SKIL')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
