local Size             = require('custom.esp.parser.primitive.Size')
local Types            = require('custom.esp.parser.primitive.Types')
local BaseFieldsParser = require('custom.esp.parser.BaseFieldsParser')
local BaseRecordParser = require('custom.esp.parser.BaseRecordParser')

---@param binaryReader BinaryStringReader
local ParseHEDR = function(binaryReader)
    local data = {
        version = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        flags = binaryReader:Read(Size.INTEGER),
        author = binaryReader:Read(32),
        description = binaryReader:Read(256),
        recordCount = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
    print('Records:', data.recordCount)
    return data
end

---@param binaryReader BinaryStringReader
local ParseMAST = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseDATA = function(binaryReader)
    return binaryReader:Read(Size.LONG, Types.UINT64)
end

---@param binaryReader BinaryStringReader
local ParseCompositeMasterFileList = function(binaryReader, context)
    local followFields = {
        ['MAST'] = ParseMAST,
        ['DATA'] = ParseDATA,
    }
    local followComposities = {
    }
    local followArrays = {
    }
    return BaseFieldsParser(binaryReader, followFields, followComposities, followArrays, context)
end

local funcMap = {
    ['HEDR'] = ParseHEDR,
}

local compositeGroup = {
    ['MAST'] = ParseCompositeMasterFileList,
}

local arrayType = {
    ['MAST'] = 'MasterFiles',
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'TES3')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
