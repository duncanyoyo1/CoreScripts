local Types              = require('custom.esp.parser.primitive.Types')
local Size               = require('custom.esp.parser.primitive.Size')
local BaseRecordParser   = require('custom.esp.parser.BaseRecordParser')
local BaseFieldsParser   = require('custom.esp.parser.BaseFieldsParser')

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
local ParseAODT = function(binaryReader)
    return {
        type = binaryReader:Read(Size.INTEGER, Types.UINT32),
        weight = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        value = binaryReader:Read(Size.INTEGER, Types.UINT32),
        health = binaryReader:Read(Size.INTEGER, Types.UINT32),
        enchantmentPoints = binaryReader:Read(Size.INTEGER, Types.UINT32),
        armorRating = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseITEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseINDX = function(binaryReader)
    ---Saint Note: This could be an improper type, due to some strange language on UESP
    binaryReader:Read(binaryReader.length, Types.INT8)
end

---@param binaryReader BinaryStringReader
local ParseENAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseBNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCompositeBipedObject = function(binaryReader, context)
    local followFields = {
        ['INDX'] = ParseINDX,
        ['BNAM'] = ParseBNAM,
        ['CNAM'] = ParseCNAM,
    }
    local followComposities = {
    }
    local followArrays = {
    }
    return BaseFieldsParser(binaryReader, followFields, followComposities, followArrays, context)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['FNAM'] = ParseFNAM,
    ['SCRI'] = ParseSCRI,
    ['AODT'] = ParseAODT,
    ['ITEX'] = ParseITEX,
    ['ENAM'] = ParseENAM,
}

local compositeGroup = {
    ['INDX'] = ParseCompositeBipedObject,
}

local arrayType = {
    ['INDX'] = 'BIPED',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'ARMO')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
