local BaseRecordParser = require('custom.saint.record.parser.BaseRecordParser')
local Size             = require('custom.saint.record.parser.primitive.Size')
local Types            = require('custom.saint.record.parser.primitive.Types')

---@param binaryReader BinaryStringReader
---@param context table
local ParseDATA = function(binaryReader, context)
    local data = {
        gridX = binaryReader:Read(Size.INTEGER, Types.INT32),
        gridY = binaryReader:Read(Size.INTEGER, Types.INT32),
        flags = binaryReader:Read(Size.HALFWORD, Types.UINT16),
        pointCount = binaryReader:Read(Size.HALFWORD, Types.UINT16),
    }

    -- Build the context
    context['Path Point Count'] = data.pointCount

    return data
end

---@param binaryReader BinaryStringReader
local ParseNAME = function(binaryReader)
    return binaryReader:Read(binaryReader.length)
end

---@param binaryReader BinaryStringReader
---@param context table
local ParsePGRP = function(binaryReader, context)
    local pointCount = context['Path Point Count']
    assert(pointCount ~= nil, 'Context not properly built! Cannot parse PGRP field')
    local connectionCount = 0
    local points = {}
    for i = 0, pointCount - 1, 1 do
        local pathPoint = {
            x = binaryReader:Read(Size.INTEGER, Types.INT32),
            y = binaryReader:Read(Size.INTEGER, Types.INT32),
            z = binaryReader:Read(Size.INTEGER, Types.INT32),
            flags = binaryReader:Read(Size.BYTE, Types.UINT8),
            connectionCount = binaryReader:Read(Size.BYTE, Types.UINT8),
            unknown = binaryReader:Read(Size.HALFWORD, Types.INT16),
        }
        connectionCount = connectionCount + pathPoint.connectionCount
        points[i] = pathPoint
    end
    context['Connections Count'] = connectionCount
    return points
end

---@param binaryReader BinaryStringReader
---@param context table
local ParsePGRC = function(binaryReader, context)
    local connectionCount = context['Connections Count']
    assert(connectionCount ~= nil, 'Context not properly built! Cannot parse PGRC field')
    local connections = {}
    for i = 0, connectionCount - 1, 1 do
        connections[i] = binaryReader:Read(Size.INTEGER, Types.UINT32)
    end
    return connections
end

local funcMap = {
    ['DATA'] = ParseDATA,
    ['NAME'] = ParseNAME,
    ['PGRP'] = ParsePGRP,
    ['PGRC'] = ParsePGRC,
}

local compositeGroup = {
}

local arrayType = {
}

---@param binaryReader BinaryStringReader
return function(binaryReader)
    assert(binaryReader:Peak(Size.INTEGER) == 'PGRD')
    return BaseRecordParser(binaryReader, funcMap, compositeGroup, arrayType)
end
