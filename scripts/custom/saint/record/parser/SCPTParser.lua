local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseSCHD = function(binaryReader, context)
    local data = {
        name = binaryReader:Read(32),
        numShorts = binaryReader:Read(Size.INTEGER, Types.UINT32),
        numLongs = binaryReader:Read(Size.INTEGER, Types.UINT32),
        numFloats = binaryReader:Read(Size.INTEGER, Types.UINT32),
        scriptDataSize = binaryReader:Read(Size.INTEGER, Types.UINT32),
        localVarSize = binaryReader:Read(Size.INTEGER, Types.UINT32),
    }
    context['Variable Count'] = data.numShorts + data.numLongs + data.numFloats
    context['Script Size'] = data.scriptDataSize
    return data
end

---@param binaryReader BinaryStringReader
local ParseSCVR = function(binaryReader)
    ---Saint Note: I didn't feel like doing this
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseSCDT = function(binaryReader)
    ---Saint Note: I didn't feel like doing this
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
local ParseSCTX = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

local funcMap = {
    ['SCHD'] = ParseSCHD,
    ['SCVR'] = ParseSCVR,
    ['SCDT'] = ParseSCDT,
    ['SCTX'] = ParseSCTX,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'SCPT')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
