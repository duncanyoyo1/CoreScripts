local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
local ParseINTV = function(binaryReader)
    return {
        x = binaryReader:Read(Size.INTEGER, Types.INT32),
        y = binaryReader:Read(Size.INTEGER, Types.INT32),
    }
end

---@param binaryReader BinaryStringReader
local ParseDATA = function(binaryReader)
    return binaryReader:Read(Size.INTEGER, Types.UINT32)
end

---@param binaryReader BinaryStringReader
local ParseVNML = function(binaryReader)
    local VNML = {}
    for i = 0,65-1, 1 do
        local arr = {}
        for j = 0, 65-1, 1 do
            arr[j] = {
                x = binaryReader:Read(Size.BYTE, Types.INT8),
                y = binaryReader:Read(Size.BYTE, Types.INT8),
                z = binaryReader:Read(Size.BYTE, Types.INT8),
            }
        end
        VNML[i] = arr
    end
    return VNML
end

---@param binaryReader BinaryStringReader
local ParseVHGT = function(binaryReader)
    return {
        heightOffset = binaryReader:Read(Size.INTEGER, Types.FLOAT),
        heightData = (
            function()
                local result = {}
                for i = 0,65-1, 1 do
                    local arr = {}
                    for j = 0, 65-1, 1 do
                        arr[j] = binaryReader:Read(Size.BYTE, Types.INT8)
                    end
                    result[i] = arr
                end
                return result
            end
        )(),
        junk = {
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
            binaryReader:Read(Size.BYTE, Types.UINT8),
        }
    }
end

---@param binaryReader BinaryStringReader
local ParseWNAM = function(binaryReader)
    local WNAM = {}
    for i = 0,9-1, 1 do
        local arr = {}
        for j = 0, 9-1, 1 do
            arr[j] = binaryReader:Read(Size.BYTE, Types.UINT8)
        end
        WNAM[i] = arr
    end
    return WNAM
end

---@param binaryReader BinaryStringReader
local ParseVCLR = function(binaryReader)
    local VCLR = {}
    for i = 0,65-1, 1 do
        local arr = {}
        for j = 0, 65-1, 1 do
            arr[j] = {
                r = binaryReader:Read(Size.BYTE, Types.INT8),
                g = binaryReader:Read(Size.BYTE, Types.INT8),
                b = binaryReader:Read(Size.BYTE, Types.INT8),
            }
        end
        VCLR[i] = arr
    end
    return VCLR
end

---@param binaryReader BinaryStringReader
local ParseVTEX = function(binaryReader)
    local VTEX = {}
    for i = 0,16-1, 1 do
        local arr = {}
        for j = 0, 16-1, 1 do
            arr[j] = binaryReader:Read(Size.HALFWORD, Types.UINT16)
        end
        VTEX[i] = arr
    end
    return VTEX
end

local funcMap = {
    ['INTV'] = ParseINTV,
    ['DATA'] = ParseDATA,
    ['VNML'] = ParseVNML,
    ['VHGT'] = ParseVHGT,
    ['WNAM'] = ParseWNAM,
    ['VCLR'] = ParseVCLR,
    ['VTEX'] = ParseVTEX,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'LAND')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
