-------------------------------------------------------------------------------
--- SaintEspToRecord
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Creates records from reading esp's
--- Ref: https://www.mwmythicmods.com/tutorials/MorrowindESPFormat.html
--- Ref: https://en.uesp.net/wiki/Morrowind_Mod:Mod_File_Format
-------------------------------------------------------------------------------
local io                 = require('io')
local config             = require('config')
local SaintLogger        = require('custom.SaintLogger')
local SaintScriptSave    = require('custom.SaintScriptSave')
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
local INGRParser         = require('custom.esp.parser.INGRParser')
local LANDParser         = require('custom.esp.parser.LANDParser')
local LEVCParser         = require('custom.esp.parser.LEVCParser')
local LEVIParser         = require('custom.esp.parser.LEVIParser')
local LIGHParser         = require('custom.esp.parser.LIGHParser')
local LOCKParser         = require('custom.esp.parser.LOCKParser')
local LTEXParser         = require('custom.esp.parser.LTEXParser')
local MGEFParser         = require('custom.esp.parser.MGEFParser')
local MISCParser         = require('custom.esp.parser.MISCParser')
local NPC_Parser         = require('custom.esp.parser.NPC_Parser')
local PGRDParser         = require('custom.esp.parser.PGRDParser')
local PROBParser         = require('custom.esp.parser.PROBParser')
local RACEParser         = require('custom.esp.parser.RACEParser')
local REGNParser         = require('custom.esp.parser.REGNParser')
local REPAParser         = require('custom.esp.parser.REPAParser')
local SCPTParser         = require('custom.esp.parser.SCPTParser')
local SKILParser         = require('custom.esp.parser.SKILParser')
local SNDGParser         = require('custom.esp.parser.SNDGParser')
local SOUNParser         = require('custom.esp.parser.SOUNParser')
local SPELParser         = require('custom.esp.parser.SPELParser')
local SSCRParser         = require('custom.esp.parser.SSCRParser')
local STATParser         = require('custom.esp.parser.STATParser')
local WEAPParser         = require('custom.esp.parser.WEAPParser')
local Size               = require('custom.esp.parser.primitive.Size')
local SupportedRecordStores = require('custom.esp.SupportedRecordStores')

local logger = SaintLogger:CreateLogger('SaintEspToRecord')
local loadOrderSSS = SaintScriptSave('SaintEspToRecordLoadOrder')

loadOrderSSS:SetData({
    loadOrder = {
        'delete-test.esp',
        'morrowind.esm',
    }
})

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
    ['INGR'] = INGRParser,
    ['LAND'] = LANDParser,
    ['LEVC'] = LEVCParser,
    ['LEVI'] = LEVIParser,
    ['LIGH'] = LIGHParser,
    ['LOCK'] = LOCKParser,
    ['LTEX'] = LTEXParser,
    ['MGEF'] = MGEFParser,
    ['MISC'] = MISCParser,
    ['NPC_'] = NPC_Parser,
    ['PGRD'] = PGRDParser,
    ['PROB'] = PROBParser,
    ['RACE'] = RACEParser,
    ['REGN'] = REGNParser,
    ['REPA'] = REPAParser,
    ['SCPT'] = SCPTParser,
    ['SKIL'] = SKILParser,
    ['SNDG'] = SNDGParser,
    ['SOUN'] = SOUNParser,
    ['SPEL'] = SPELParser,
    ['SSCR'] = SSCRParser,
    ['STAT'] = STATParser,
    ['WEAP'] = WEAPParser,

    ['TES3'] = TES3Parser,
}

SaintEspToRecord.ReadEsp = function(filePath, recordHandler)
    local dataFile, err = io.open(filePath, 'rb')
    if dataFile == nil then
        error('Failed to open: ' .. filePath)
        return -- calms lua plugin
    end
    if err then
        error(err)
    end
    local binaryData = dataFile:read('*a')
    dataFile:close()
    local binaryStringReader = BinaryStringReader(binaryData);
    while binaryStringReader:HasData() do
        local nextRecordType = binaryStringReader:Peak(Size.INTEGER)
        local record = Parsers[nextRecordType](binaryStringReader)
        recordHandler(record)
    end
end

SaintEspToRecord.GetEspsInFolder = function()
    local fileNames = SaintUtilities.GetFileNamesInFolder(config.dataPath .. '/esp')
    local filteredFileNames = {}
    for _, fileName in pairs(fileNames) do
        if string.match(string.lower(fileName), "%.es[mp]") then
            table.insert(filteredFileNames, fileName)
        end
    end
    return filteredFileNames
end

SaintEspToRecord.CreateLoadOrderForFiles = function()
    local filteredDataFiles = {}
    local dataFiles = SaintEspToRecord.GetEspsInFolder()
    local loadOrder = loadOrderSSS:GetData().loadOrder
    for _, loadOrderFile in ipairs(loadOrder) do
        local foundFile = false

        for _, dataFile in pairs(dataFiles) do
            if string.lower(dataFile) == string.lower(loadOrderFile) then
                foundFile = true
                table.insert(filteredDataFiles, dataFile)
                break
            end
        end

        if foundFile == false then
            error('Failed to find specified data file in load order: ' .. loadOrderFile)
        end
    end
    return filteredDataFiles
end

SaintEspToRecord.Execute = function(handler)
    local fileNames = SaintEspToRecord.CreateLoadOrderForFiles()
    for _, fileName in pairs(fileNames) do
        logger:Verbose('Reading: ' .. fileName)
        SaintEspToRecord.ReadEsp(config.dataPath .. '/esp/' .. fileName, handler)
    end
end

SaintEspToRecord.Execute(function(record)
    if SupportedRecordStores[record.name] then
        -- 
    else
        print('Unsupported Record type: ' .. record.name)
    end
end)

return SaintEspToRecord
