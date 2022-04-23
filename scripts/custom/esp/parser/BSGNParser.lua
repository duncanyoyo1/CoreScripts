local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseNPCS = function(binaryReader)
    ---Saint Note: Should always be 32
    assert(binaryReader.length == 32)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseTNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseDESC = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['NPCS'] = ParseNPCS,
    ['TNAM'] = ParseTNAM,
    ['DESC'] = ParseDESC,
}

local compositeGroup = {
}

local arrayType = {
    ['NPCS'] = 'NPCS',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'BSGN')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
