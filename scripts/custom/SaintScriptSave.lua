local jsonInterface = require('jsonInterface')
local classy = require('classy')
local customEventHooks = require('customEventHooks')
local SaintUtilities = require('custom.SaintUtilities')
local SaintLogger = require('custom.SaintLogger')

local logger = SaintLogger:CreateLogger('SaintScriptSave')

---@class SaintScriptSave
local SaintScriptSave = classy('SaintScriptSave')

---@param saveFilePath string Path to file you want to store changes to
function SaintScriptSave:__init(saveFilePath)
    SaintUtilities.EnsureProperIOLibrary(jsonInterface)
    self.saveFilePath = saveFilePath:gsub('%.json', '') .. '.json'
    logger:Info('Using "' .. self.saveFilePath .. '" as a save file')
    self.data = jsonInterface.load(self.saveFilePath)
    self:_StartListeners()
end

---@param data any
function SaintScriptSave:SetData(data)
    self.data = data
end

function SaintScriptSave:Save()
    jsonInterface.quicksave(self.saveFilePath, self.data)
end

function SaintScriptSave:_StartListeners()
    customEventHooks.registerHandler("OnServerExit", function()
        self:Save()
    end)
end

---@type fun(saveFilePath: string): SaintScriptSave
local SSS = SaintScriptSave
return SSS
