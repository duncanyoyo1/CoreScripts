local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseDATA = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['DATA'] = ParseDATA,
    ['NAME'] = ParseNAME,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'SSCR')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
