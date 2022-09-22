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
local ParseWPDT = function(binaryReader)
    return {
        weight            = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        value             = binaryReader:Read(Size.INTEGER, Types.UINT32),
        type              = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        health            = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        speed             = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        reach             = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        enchantmentPoints = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        chopMin           = binaryReader:Read(Size.BYTE, Types.UINT8),
        chopMax           = binaryReader:Read(Size.BYTE, Types.UINT8),
        slashMin          = binaryReader:Read(Size.BYTE, Types.UINT8),
        slashMax          = binaryReader:Read(Size.BYTE, Types.UINT8),
        thrustMin         = binaryReader:Read(Size.BYTE, Types.UINT8),
        thrustMax         = binaryReader:Read(Size.BYTE, Types.UINT8),
        flags             = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseITEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseENAM = function(binaryReader)
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

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['FNAM'] = ParseFNAM,
    ['WPDT'] = ParseWPDT,
    ['ITEX'] = ParseITEX,
    ['ENAM'] = ParseENAM,
    ['SCRI'] = ParseSCRI,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'WEAP')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
