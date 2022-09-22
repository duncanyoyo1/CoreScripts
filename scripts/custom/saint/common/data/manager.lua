local jsonInterface = require('jsonInterface')
local classy = require('classy')

local SaintUtilities = require('custom.saint.common.utilities.main')
local SaintLogger = require('custom.saint.common.logger.main')

local logger = SaintLogger:CreateLogger('SaintScriptSave')

---@class SaintScriptSave
local SaintScriptSave = classy('SaintScriptSave')

---@param saveFilePath string Path to file you want to store changes to
function SaintScriptSave:__init(saveFilePath)
    SaintUtilities.EnsureProperIOLibrary(jsonInterface)
    self.saveFilePath = 'custom/' .. saveFilePath:gsub('%.json', '') .. '.json'
    logger:Info('Using "' .. self.saveFilePath .. '" as a save file')
    self.data = jsonInterface.load(self.saveFilePath)
    if self.data == nil then
        logger:Info('Creating save file at ' .. self.saveFilePath)
        jsonInterface.save(self.saveFilePath)
        self.data = jsonInterface.load(self.saveFilePath)
    end
end

---@param data any
function SaintScriptSave:SetData(data)
    self.data = data
end

---@return any
function SaintScriptSave:GetData()
    return self.data
end

function SaintScriptSave:Save()
    jsonInterface.quicksave(self.saveFilePath, self.data)
end

return SaintScriptSave
