local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')
local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseINDX = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseMEDT = function(binaryReader)
    return {
        school = binaryReader:Read(Size.INTEGER, Types.UINT32),
        baseCost = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        flags = binaryReader:Read(Size.INTEGER, Types.UINT32),
        red = binaryReader:Read(Size.INTEGER, Types.UINT32),
        green = binaryReader:Read(Size.INTEGER, Types.UINT32),
        blue = binaryReader:Read(Size.INTEGER, Types.UINT32),
        speedX = binaryReader:Read(Size.INTEGER, Types.UINT32),
        sizeX = binaryReader:Read(Size.INTEGER, Types.UINT32),
        sizeCap = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseITEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseITEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParsePTEX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseBSND = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCSND = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseHSND = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseASND = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseCVFX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseBVFX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseHVFX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseAVFX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseDESC = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['INDX'] = ParseINDX,
    ['MEDT'] = ParseMEDT,
    ['ITEX'] = ParseITEX,
    ['PTEX'] = ParsePTEX,
    ['BSND'] = ParseBSND,
    ['CSND'] = ParseCSND,
    ['HSND'] = ParseHSND,
    ['ASND'] = ParseASND,
    ['BVFX'] = ParseBVFX,
    ['CVFX'] = ParseCVFX,
    ['HVFX'] = ParseHVFX,
    ['AVFX'] = ParseAVFX,
    ['DESC'] = ParseDESC,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'MGEF')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
