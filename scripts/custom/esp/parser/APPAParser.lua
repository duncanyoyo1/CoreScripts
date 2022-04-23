local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')
local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')

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
local ParseSCRI = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseAADT = function(binaryReader)
    return {
        type = binaryReader:Read(Size.INTEGER, Types.UINT32),
        quality = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        weight = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        value = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseITEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['FNAM'] = ParseFNAM,
    ['SCRI'] = ParseSCRI,
    ['AADT'] = ParseAADT,
    ['ITEX'] = ParseITEX,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'APPA')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
