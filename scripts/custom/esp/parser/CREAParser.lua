local Types              = require('custom.esp.parser.primitive.Types')
local Size               = require('custom.esp.parser.primitive.Size')
local BaseRecordParser   = require('custom.esp.parser.BaseRecordParser')
local BaseFieldsParser   = require('custom.esp.parser.BaseFieldsParser')
local ParseField         = require('custom.esp.parser.primitive.ParseField')
local BinaryStringReader = require('custom.io.BinaryStringReader')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseMODL = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCNAM = function(binaryReader)
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
local ParseNPDT = function(binaryReader)
    return {
        type = binaryReader:Read(Size.INTEGER, Types.UINT32),
        level = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attributes = {
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        health = binaryReader:Read(Size.INTEGER, Types.UINT32),
        spellPts = binaryReader:Read(Size.INTEGER, Types.UINT32),
        fatigue = binaryReader:Read(Size.INTEGER, Types.UINT32),
        soul = binaryReader:Read(Size.INTEGER, Types.UINT32),
        combat = binaryReader:Read(Size.INTEGER, Types.UINT32),
        magic = binaryReader:Read(Size.INTEGER, Types.UINT32),
        stealth = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMin1 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMax1 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMin2 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMax2 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMin3 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        attackMax3 = binaryReader:Read(Size.INTEGER, Types.UINT32),
        gold = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseFLAG = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseXSCL = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.FLOAT)
end

---@param binaryReader BinaryStringReader
local ParseNPCO = function(binaryReader)
    return {
        objectCount = binaryReader:Read(Size.INTEGER, Types.INT32),
        objectName = binaryReader:Read(32),
    }
end

---@param binaryReader BinaryStringReader
local ParseNPCS = function(binaryReader)
    return binaryReader:Read(32)
end

---@param binaryReader  BinaryStringReader
local ParseAIDT = function(binaryReader)
    return {
        hello = binaryReader:Read(Size.BYTE, Types.UINT8),
        unknown1 = binaryReader:Read(Size.BYTE, Types.UINT8),
        fight = binaryReader:Read(Size.BYTE, Types.UINT8),
        flee = binaryReader:Read(Size.BYTE, Types.UINT8),
        alarm = binaryReader:Read(Size.BYTE, Types.UINT8),
        unknown2 = binaryReader:Read(Size.BYTE, Types.UINT8),
        unknown3 = binaryReader:Read(Size.BYTE, Types.UINT8),
        unknown4 = binaryReader:Read(Size.BYTE, Types.UINT8),
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseDODT = function(binaryReader)
    return {
        posX = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        posY = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        posZ = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        rotX = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        rotY = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        rotZ = binaryReader:Read(Size.INTEGER, Types.FLOAT),
    }
end

---@param binaryReader BinaryStringReader
local ParseDNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCompositeDestination = function(binaryReader)
    local followFields = {
        ['DODT'] = ParseDODT,
        ['DNAM'] = ParseDNAM,
    }
    local followComposities = {
    }
    local followArrays = {
    }
    return BaseFieldsParser(binaryReader, followFields, followComposities, followArrays)
end

---@param binaryReader BinaryStringReader
local ParseAI_A = function(binaryReader)
    return {
        name = binaryReader:Read(32),
        unknown = binaryReader:Read(Size.BYTE, Types.UINT8),
    }
end

---@param binaryReader BinaryStringReader
local ParseAI_EF = function(binaryReader)
    return {
        x = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        y = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        z = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        duration = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        id = binaryReader:Read(32),
        unknown = binaryReader:Read(Size.BYTE, Types.UINT8),
        unused = binaryReader:Read(Size.BYTE, Types.UINT8),
    }
end

---@param binaryReader BinaryStringReader
local ParseCNDT = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseAI_T = function(binaryReader)
    return {
        x = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        y = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        z = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        unknown = binaryReader:Read(Size.BYTE, Types.UINT8),
        unused = {
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
        }
    }
end

---@param binaryReader BinaryStringReader
local ParseAI_W = function(binaryReader)
    return {
        distance = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        duration = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        timeOfDay = binaryReader:Read(Size.BYTE, Types.UINT8),
        idles = {
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
        },
        unknown = binaryReader:Read(Size.BYTE, Types.UINT8),
    }
end

---@param binaryReader BinaryStringReader
local ParseCompositeAI = function(binaryReader)
    local fieldsRemaining = 5
    local aiFields = {
        ['AI_A'] = ParseAI_A,
        ['AI_E'] = ParseAI_EF,
        ['AI_F'] = ParseAI_EF,
        ['AI_T'] = ParseAI_T,
        ['AI_W'] = ParseAI_W,
    }
    local aiComposite = {}
    local previousField = ''
    while fieldsRemaining > 0 do
        local field = ParseField(binaryReader)
        local fieldName = field.name
        if fieldName == 'CNDT' then
            aiComposite[previousField .. fieldName] = ParseCNDT(BinaryStringReader(field.data))
        else
            aiComposite[fieldName] = aiFields[fieldName](BinaryStringReader(field.data))
            fieldsRemaining = fieldsRemaining - 1
        end
    end
    return aiComposite
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['MODL'] = ParseMODL,
    ['CNAM'] = ParseCNAM,
    ['FNAM'] = ParseFNAM,
    ['SCRI'] = ParseSCRI,
    ['NPDT'] = ParseNPDT,
    ['FLAG'] = ParseFLAG,
    ['XSCL'] = ParseXSCL,
    ['NPCO'] = ParseNPCO,
    ['NPCS'] = ParseNPCS,
    ['AIDT'] = ParseAIDT,
}

local compositeGroup = {
    ['DODT'] = ParseCompositeDestination,
    ['AI_A'] = ParseCompositeAI,
    ['AI_E'] = ParseCompositeAI,
    ['AI_F'] = ParseCompositeAI,
    ['AI_T'] = ParseCompositeAI,
    ['AI_W'] = ParseCompositeAI,
}

local arrayType = {
    ['NPCO'] = 'NPCO',
    ['NPCS'] = 'NPCS',
    ['DODT'] = 'Destinations',
    ['AI_A'] = 'AI',
    ['AI_E'] = 'AI',
    ['AI_F'] = 'AI',
    ['AI_T'] = 'AI',
    ['AI_W'] = 'AI',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'CREA')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end