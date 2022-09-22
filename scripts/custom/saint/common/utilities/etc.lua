-------------------------------------------------------------------------------
--- SaintUtilities
--- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--- Collection of utility methods for bespoke and common uses.
-------------------------------------------------------------------------------

local logicHandler = require('logicHandler')

local SaintUtilities = {}

---Load a cell temporarily if not loaded, and clean up for you
---@generic T
---@param cellDescription string Cell name
---@param callback fun(cell: BaseCell): T Callback with cell that was loaded passed in
---@return T ... results of the above function
SaintUtilities.TempLoadCellCallback = function(cellDescription, callback)
    local tempLoad = false
    if LoadedCells[cellDescription] == nil then
        tempLoad = true
        logicHandler.LoadCell(cellDescription)
    end
    local result = {callback(LoadedCells[cellDescription])}
    if tempLoad then
        logicHandler.UnloadCell(cellDescription)
    end
    return unpack(result)
end

---Lovingly stolen from SO
---https://stackoverflow.com/questions/5303174/how-to-get-list-of-directories-in-lua
---@param folder string Folder to scan
---@return string[] fileNames List of file names and folders
SaintUtilities.GetFileNamesInFolder = function(folder)
    local cmd = 'ls -a "'..folder..'"'
    if tes3mp.GetOperatingSystemType() == "Windows" then
        cmd = 'dir "'..folder..'" /b'
    end
    local fileNames, popen = {}, io.popen
    local pfile = popen(cmd)
    if pfile == nil then
        return {}
    end
    for filename in pfile:lines() do
        table.insert(fileNames, filename)
    end
    pfile:close()
    return fileNames
end

---@param jsonInterface any JsonInterface used in TES3MP
SaintUtilities.EnsureProperIOLibrary = function(jsonInterface)
    --- NOTE: Taken from servercore.lua
    if tes3mp.GetOperatingSystemType() == "Windows" then
        jsonInterface.setLibrary(require("io2"))
    else
        jsonInterface.setLibrary(io)
    end
end

---Parse a unique index
---@param uniqueIndex string
---@return number? refNum
---@return number? mpNum
SaintUtilities.ParseUniqueIndex = function(uniqueIndex)
    local splitIndex = uniqueIndex:split("-")
    local refNum = tonumber(splitIndex[1])
    local mpNum = tonumber(splitIndex[2])
    return refNum, mpNum
end

return SaintUtilities
