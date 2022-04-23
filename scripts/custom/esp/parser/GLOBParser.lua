local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(Size.BYTE)
end

---@param binaryReader BinaryStringReader
local ParseFLTV = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.FLOAT)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['FLTV'] = ParseFLTV,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'GLOB')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
