local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')

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

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['FNAM'] = ParseFNAM,
    ['SCRI'] = ParseSCRI,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'ACTI')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
