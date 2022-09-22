local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseSPDT = function(binaryReader)
    return {
        type = binaryReader:Read(Size.INTEGER, Types.UINT32),
        spellCost = binaryReader:Read(Size.INTEGER, Types.UINT32),
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseENAM = function(binaryReader)
    return {
        effectIndex = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        skill = binaryReader:Read(Size.BYTE, Types.INT8),
        attribute = binaryReader:Read(Size.BYTE, Types.INT8),
        range = binaryReader:Read(Size.INTEGER, Types.UINT32),
        area = binaryReader:Read(Size.INTEGER, Types.UINT32),
        duration = binaryReader:Read(Size.INTEGER, Types.UINT32),
        magnitudeMin = binaryReader:Read(Size.INTEGER, Types.UINT32),
        magnitudeMax = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['SPDT'] = ParseSPDT,
    ['ENAM'] = ParseENAM,
}

local compositeGroup = {
}

local arrayType = {
    ['ENAM'] = 'ENAM',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'SPEL')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
