local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseMODL = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseBYDT = function(binaryReader)
    return {
        part = binaryReader:Read(Size.BYTE, Types.UINT8),
        vampire = binaryReader:Read(Size.BYTE, Types.UINT8),
        flags = binaryReader:Read(Size.BYTE, Types.UINT8),
        partType = binaryReader:Read(Size.BYTE, Types.UINT8),
    }
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['FNAM'] = ParseFNAM,
    ['BYDT'] = ParseBYDT,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'BODY')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
