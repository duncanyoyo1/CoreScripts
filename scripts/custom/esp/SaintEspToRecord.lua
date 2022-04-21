-------------------------------------------------------------------------------
--- SaintEspToRecord
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Creates records from reading esp's
--- Ref: https://www.mwmythicmods.com/tutorials/MorrowindESPFormat.html
-------------------------------------------------------------------------------

---TODO: Currently have an issue where certain records are _underfilled_
---TODO: causing the next subsequent reads to fail

local io = require('io')
local tableHelper = require('tableHelper')
local config = require('config')

local SaintLogger = require('custom.SaintLogger')
local SaintUtilities = require('custom.SaintUtilities')
local RecordEnums = require('custom.esp.RecordTypesEnum')
local SupportedRecordStores = require('custom.esp.SupportedRecordStores')
local BinaryStringReader = require('custom.io.BinaryStringReader')

local logger = SaintLogger:CreateLogger('SaintEspToRecord')

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
---@return integer
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
    local recordSize = SaintEspToRecord.ConvertBinaryToInteger(binaryReader:Read(CONSTS.INTEGER))
    local unusedRecord = binaryReader:Read(CONSTS.INTEGER)
    local recordFlags = binaryReader:Read(CONSTS.INTEGER)
    local fieldBinaryReader = BinaryStringReader(binaryReader:Read(recordSize))
    local fields = {}
    while fieldBinaryReader:HasData() do
        local field = SaintEspToRecord.ReadField(fieldBinaryReader)
        table.insert(fields, field)
    end
    return {
        name = recordName,
        size = recordSize,
        unused = unusedRecord,
        flags = recordFlags,
        fields = fields,
    }
end

---@param binaryReader BinaryStringReader
SaintEspToRecord.ReadField = function (binaryReader)
    local fieldName = binaryReader:Read(CONSTS.INTEGER)
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
    local headerSize = binaryReader:Read(CONSTS.INTEGER)
    local reserved = binaryReader:Read(CONSTS.LONG)
    local HEADER = binaryReader:Read(CONSTS.INTEGER)
    local headerSize2 = binaryReader:Read(CONSTS.INTEGER)
    local versionNumber = binaryReader:Read(CONSTS.INTEGER)
    local unknown1 = binaryReader:Read(CONSTS.INTEGER)
    local authorName = binaryReader:Read(32)
    local description = binaryReader:Read(260)

    local requiredFiles = {} ---@type string[]
    while true do
        local nextTag = binaryReader:Peak(CONSTS.INTEGER)
        if nextTag ~= RecordEnums.RECORD_TYPES.MASTER then
            break
        end
        local MasterFileField = SaintEspToRecord.ReadField(binaryReader)
        print(MasterFileField.name, MasterFileField.size, MasterFileField.data)
        local DataField = SaintEspToRecord.ReadField(binaryReader)
        table.insert(requiredFiles, MasterFileField.name)
    end
    return {
        masterFiles = requiredFiles
    }
end

SaintEspToRecord.ReadEsp = function(filePath)
    local dataFile, err = io.open(filePath, 'rb')
    if err then
        error(err)
    end
    local binaryData = dataFile:read('*a')
    dataFile:close()
    local binaryStringReader = BinaryStringReader(binaryData);
    local header = SaintEspToRecord.ReadEspHeader(binaryStringReader)
    local records = {}
    while binaryStringReader:HasData() do
        local record = SaintEspToRecord.ReadRecord(binaryStringReader)
        table.insert(records, record)
    end
    return records
end

local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/esp')
for _, fileName in pairs(fileNames) do
    local records = SaintEspToRecord.ReadEsp(config.dataPath .. '/esp/' .. fileName)
    local unsupportedRecordCount = 0
    for _, record in pairs(records) do
        local isSupportedRecordType = tableHelper.containsValue(SupportedRecordStores, record.name)
        if isSupportedRecordType then
        else
            logger:Warn('Found an unsupported record: ' .. record.name)
            unsupportedRecordCount = unsupportedRecordCount + 1
        end
    end
    if unsupportedRecordCount > 0 then
        logger:Warn('There are ' .. unsupportedRecordCount .. ' unsupported record types within this mod')
        logger:Warn('This mod (' .. fileName .. ') will likely not run properly')
    end
end

return SaintEspToRecord
