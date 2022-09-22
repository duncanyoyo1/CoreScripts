local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseFNAM = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseRADT = function(binaryReader)
    return {
        skillbonues = (function()
            local list = {}
            for i = 0, 7 - 1, 1 do
                list[i] = {
                    skillId = binaryReader:Read(Size.INTEGER, Types.INT32),
                    bonus = binaryReader:Read(Size.INTEGER, Types.UINT32),
                }
            end
            return list
        end)(),
        attributes = (function()
            local list = {}
            for i = 0, 8 - 1, 1 do
                list[i] = {
                    binaryReader:Read(Size.INTEGER, Types.UINT32),
                    binaryReader:Read(Size.INTEGER, Types.UINT32),
                }
            end
            return list
        end)(),
        height = {
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
        },
        weight = {
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
            binaryReader:Read(Size.INTEGER, Types.FLOAT),
        },
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseNPCS = function(binaryReader)
    return binaryReader:Read(32)
end

---@param binaryReader BinaryStringReader
local ParseDESC = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['NAME'] = ParseNAME,
    ['FNAM'] = ParseFNAM,
    ['RADT'] = ParseRADT,
    ['NPCS'] = ParseNPCS,
    ['DESC'] = ParseDESC,
}

local compositeGroup = {
}

local arrayType = {
    ['NPCS'] = 'NPCS',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'RACE')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
