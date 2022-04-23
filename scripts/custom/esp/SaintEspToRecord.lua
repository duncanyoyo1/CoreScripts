-------------------------------------------------------------------------------
--- SaintEspToRecord
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Creates records from reading esp's
--- Ref: https://www.mwmythicmods.com/tutorials/MorrowindESPFormat.html
--- Ref: https://en.uesp.net/wiki/Morrowind_Mod:Mod_File_Format
-------------------------------------------------------------------------------
local io                 = require('io')
local config             = require('config')
local ParseRecord        = require('custom.esp.parser.primitive.ParseRecord')
local SaintLogger        = require('custom.SaintLogger')
local SaintUtilities     = require('custom.SaintUtilities')
local BinaryStringReader = require('custom.io.BinaryStringReader')
local TES3Parser         = require('custom.esp.parser.TES3Parser')
local ACTIParser         = require('custom.esp.parser.ACTIParser')
local ALCHParser         = require('custom.esp.parser.ALCHParser')
local APPAParser         = require('custom.esp.parser.APPAParser')
local ARMOParser         = require('custom.esp.parser.ARMOParser')
local BODYParser         = require('custom.esp.parser.BODYParser')
local BOOKParser         = require('custom.esp.parser.BOOKParser')
local BSGNParser         = require('custom.esp.parser.BSGNParser')
local CELLParser         = require('custom.esp.parser.CELLParser')
local CLASParser         = require('custom.esp.parser.CLASParser')
local CLOTParser         = require('custom.esp.parser.CLOTParser')
local CONTParser         = require('custom.esp.parser.CONTParser')
local CREAParser         = require('custom.esp.parser.CREAParser')
local DIALParser         = require('custom.esp.parser.DIALParser')
local DOORParser         = require('custom.esp.parser.DOORParser')
local ENCHParser         = require('custom.esp.parser.ENCHParser')
local FACTParser         = require('custom.esp.parser.FACTParser')
local GLOBParser         = require('custom.esp.parser.GLOBParser')
local GMSTParser         = require('custom.esp.parser.GMSTParser')
local INFOParser         = require('custom.esp.parser.INFOParser')
local Size               = require('custom.esp.parser.primitive.Size')

local logger = SaintLogger:CreateLogger('SaintEspToRecord')

---@alias BINARY string

---@class SaintEspToRecord
local SaintEspToRecord = {}

local Parsers = {
    ['ACTI'] = ACTIParser,
    ['ALCH'] = ALCHParser,
    ['APPA'] = APPAParser,
    ['ARMO'] = ARMOParser,
    ['BODY'] = BODYParser,
    ['BOOK'] = BOOKParser,
    ['BSGN'] = BSGNParser,
    ['CELL'] = CELLParser,
    ['CLAS'] = CLASParser,
    ['CLOT'] = CLOTParser,
    ['CONT'] = CONTParser,
    ['CREA'] = CREAParser,
    ['DIAL'] = DIALParser,
    ['DOOR'] = DOORParser,
    ['ENCH'] = ENCHParser,
    ['FACT'] = FACTParser,
    ['GLOB'] = GLOBParser,
    ['GMST'] = GMSTParser,
    ['INFO'] = INFOParser,

    ['TES3'] = TES3Parser,
}

SaintEspToRecord.ReadEsp = function(filePath)
    local dataFile, err = io.open(filePath, 'rb')
    if err then
        error(err)
    end
    local binaryData = dataFile:read('*a')
    dataFile:close()
    local binaryStringReader = BinaryStringReader(binaryData);
    local records = {}
    while binaryStringReader:HasData() do
        local nextRecordType = binaryStringReader:Peak(Size.INTEGER)
        local record
        if Parsers[nextRecordType] then
            record = Parsers[nextRecordType](binaryStringReader)
        else
            record = ParseRecord(binaryStringReader)
        end
        table.insert(records, record)
    end
    return records
end

function PrintFields(fields)
    for _, field in pairs(fields) do
        print(field.name, field.size, field.data)
    end
end

local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/esp')
for _, fileName in pairs(fileNames) do
    logger:Verbose('Reading: ' .. fileName)
    local esp = SaintEspToRecord.ReadEsp(config.dataPath .. '/esp/' .. fileName)
    print()
    print()
    print(tableHelper.getPrintableTable(esp))
    print()
    print()
end

return SaintEspToRecord
