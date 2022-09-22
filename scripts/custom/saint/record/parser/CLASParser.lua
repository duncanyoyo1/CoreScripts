local Types              = require('custom.saint.record.parser.primitive.Types')
local Size               = require('custom.saint.record.parser.primitive.Size')
local BaseRecordParser   = require('custom.saint.record.parser.BaseRecordParser')
local BaseFieldsParser   = require('custom.saint.record.parser.BaseFieldsParser')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCLDT = function(binaryReader)
    return {
        primaryAttributes = {
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        specialization = binaryReader:Read(Size.INTEGER, Types.UINT32),
        majorSkills = {
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        minorSkills = {
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
            binaryReader:Read(Size.INTEGER, Types.UINT32),
        },
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
        autoCalcFlags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseDESC = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['CLDT'] = ParseCLDT,
    ['DESC'] = ParseDESC,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'CLAS')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
