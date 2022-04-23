local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFLTV = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.FLOAT)
end

---@param binaryReader BinaryStringReader
local ParseINTV = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.INT32)
end

---@param binaryReader BinaryStringReader
local ParseSTRV = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FLTV'] = ParseFLTV,
    ['INTV'] = ParseINTV,
    ['STRV'] = ParseSTRV,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'GMST')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
