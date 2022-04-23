local BaseFieldsParser = require('custom.esp.parser.BaseFieldsParser')
local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseDATA = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseNNAM = function(binaryReader)
    return binaryReader:Read(Size.BYTE, Types.UINT8)
end

---@param binaryReader BinaryStringReader
local ParseINDX = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseINAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseINTV = function(binaryReader)
    return binaryReader:Read(Size.HALFWORD, Types.UINT16)
end

---@param binaryReader BinaryStringReader
local ParseCompositeCreatures = function(binaryReader)
    local followFields = {
        ['INAM'] = ParseINAM,
        ['INTV'] = ParseINTV,
    }
    local followComposities = {
    }
    local followArrays = {
    }
    return BaseFieldsParser(binaryReader, followFields, followComposities, followArrays)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['DATA'] = ParseDATA,
    ['NNAM'] = ParseNNAM,
    ['INDX'] = ParseINDX,
}

local compositeGroup = {
    ['INAM'] = ParseCompositeCreatures,
}

local arrayType = {
    ['INAM'] = 'Items',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'LEVI')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
