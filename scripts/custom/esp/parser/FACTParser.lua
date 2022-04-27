local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local BaseFieldsParser = require('custom.esp.parser.BaseFieldsParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseRNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFADT = function(binaryReader)
    return {
        attributes = {
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        rankData = {
            attributeModifiers = {
                binaryReader:Read(Size.INTEGER, Types.UINT32),
                binaryReader:Read(Size.INTEGER, Types.UINT32),
            },
            primarySkillModifier = binaryReader:Read(Size.INTEGER, Types.UINT32),
            favoredSkillModifier = binaryReader:Read(Size.INTEGER, Types.UINT32),
            factionReactionModifier = binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        skills = {
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
            binaryReader:Read(Size.INTEGER, Types.INT32),
        },
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseANAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseINTV = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.INT32)
end

---@param binaryReader BinaryStringReader
local ParseCompositeName = function(binaryReader, context)
    local followFields = {
        ['ANAM'] = ParseANAM,
        ['INTV'] = ParseINTV,
    }
    local followComposities = {
    }
    local followArrays = {
    }
    return BaseFieldsParser(binaryReader, followFields, followComposities, followArrays, context)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['RNAM'] = ParseRNAM,
    ['FADT'] = ParseFADT,
}

local compositeGroup = {
    ['ANAM'] = ParseCompositeName,
}

local arrayType = {
    ['RNAM'] = 'RNAM',
    ['ANAM'] = 'FactionName'
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'FACT')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
