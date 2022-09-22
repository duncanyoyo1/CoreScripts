local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')
local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseMODL = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseTEXT = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseSCRI = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseALDT = function(binaryReader)
    return {
        weight = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        value = binaryReader:Read(Size.INTEGER, Types.UINT32),
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseENAM = function(binaryReader)
    return {
        effectIndex = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        skillsAffected = binaryReader:Read(Size.BYTE, Types.INT8),
        attributesAffected = binaryReader:Read(Size.BYTE, Types.INT8),
        range = binaryReader:Read(Size.INTEGER, Types.UINT32),
        area = binaryReader:Read(Size.INTEGER, Types.UINT32),
        duration = binaryReader:Read(Size.INTEGER, Types.UINT32),
        magnitudeMin = binaryReader:Read(Size.INTEGER, Types.UINT32),
        magnitudeMax = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['TEXT'] = ParseTEXT,
    ['SCRI'] = ParseSCRI,
    ['FNAM'] = ParseFNAM,
    ['ALDT'] = ParseALDT,
    ['ENAM'] = ParseENAM,
}

local compositeGroup = {
}

local arrayType = {
    ['ENAM'] = 'ENAM',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'ALCH')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
