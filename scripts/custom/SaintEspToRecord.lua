-------------------------------------------------------------------------------
--- SaintEspToRecord
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Creates records from reading esp's
--- Ref: https://www.mwmythicmods.com/tutorials/MorrowindESPFormat.html
-------------------------------------------------------------------------------

local io = require('io')
local config = require('config')

local SaintUtilities = require('custom.SaintUtilities')
local BinaryStringReader = require('custom.io.BinaryStringReader')

---@alias BINARY string

---@class SaintEspToRecord
local SaintEspToRecord = {}

local HexMap = {
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
}

local CONSTS = {
    BYTE = 1,
    INTEGER = 4,
    LONG = 8
}

---@param num integer
---@return string
SaintEspToRecord.Convert256NumberToHexCode = function(num)
    local backNum = HexMap[(num % 16) + 1]
    local frontNum = HexMap[math.floor(num / 16) + 1]
    return tostring(frontNum) .. tostring(backNum)
end

---@param binary BINARY
---@return integer[]
SaintEspToRecord.ConvertBinaryToInteger = function(binary)
    local arr = {string.byte(binary, 1, #binary)}
    local str = ''
    for _, v in pairs(arr) do
        local hexNum = SaintEspToRecord.Convert256NumberToHexCode(v)
        str = hexNum .. str
    end
    return tonumber(str, 16)
end

---@param binaryReader BinaryStringReader
SaintEspToRecord.ReadRecord = function(binaryReader)
    local recordName = binaryReader:Read(CONSTS.INTEGER)
    if recordName == nil then
        return nil
    end
    local recordSize = SaintEspToRecord.ConvertBinaryToInteger(binaryReader:Read(CONSTS.INTEGER))
    local unusedRecord = binaryReader:Read(CONSTS.INTEGER)
    local recordFlags = binaryReader:Read(CONSTS.INTEGER)
    local recordData = binaryReader:Read(recordSize)
    return {
        name = recordName,
        size = recordSize,
        unused = unusedRecord,
        flags = recordFlags,
        data = recordData
    }
end

---@param binaryReader BinaryStringReader
SaintEspToRecord.ReadField = function (binaryReader)
    local fieldName = binaryReader:Read(CONSTS.INTEGER)
    if fieldName == nil then
        return nil
    end
    print(fieldName)
    local fieldDataSize = SaintEspToRecord.ConvertBinaryToInteger(binaryReader:Read(CONSTS.INTEGER))
    local fieldData = binaryReader:Read(fieldDataSize)
    return {
        name = fieldName,
        size = fieldDataSize,
        data = fieldData
    }
end

---@param binaryReader BinaryStringReader
SaintEspToRecord.ReadEspHeader = function(binaryReader)
    local FILESIGNATURE = binaryReader:Read(CONSTS.INTEGER)
    print(FILESIGNATURE)
    local headerSize = binaryReader:Read(CONSTS.INTEGER)
    local reserved = binaryReader:Read(CONSTS.LONG)
    local HEADER = binaryReader:Read(CONSTS.INTEGER)
    print(HEADER)
    local headerSize2 = binaryReader:Read(CONSTS.INTEGER)
    local versionNumber = binaryReader:Read(CONSTS.INTEGER)
    local unknown1 = binaryReader:Read(CONSTS.INTEGER)
    local authorName = binaryReader:Read(32)
    local description = binaryReader:Read(260)
    ---Saint Note: This is not always true, their could be more than 1 master file
    local MasterFileField = SaintEspToRecord.ReadField(binaryReader)
    local DataField = SaintEspToRecord.ReadField(binaryReader)
end

SaintEspToRecord.ReadEsp = function(filePath)
    print(config.dataPath .. filePath)
    local dataFile, err = io.open(config.dataPath .. filePath, "r")
    if err then
        error(err)
    end
    local binaryData = dataFile:read("*a")
    dataFile:close()
    local binaryStringReader = BinaryStringReader(binaryData);
    SaintEspToRecord.ReadEspHeader(binaryStringReader)
    print('past header')
    while true do
        local record = SaintEspToRecord.ReadRecord(binaryStringReader)
        if record == nil then
            break
        end
        print('RECORD', record.name, record.size)
        print('R_DATA', record.data)
        print()
        print()
    end
end

local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/esp')
for _, fileName in pairs(fileNames) do
    print(fileName)
    SaintEspToRecord.ReadEsp('/esp/' .. fileName)
end

return SaintEspToRecord
