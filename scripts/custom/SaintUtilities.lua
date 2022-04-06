local Methods = {}

---Load a cell temporarily if not loaded, and clean up for you
---@generic T
---@param cellDescription string Cell name
---@param callback fun(cell: Cell): T Callback with cell that was loaded passed in
---@return T results results of the above function
Methods.TempLoadCellCallback = function(cellDescription, callback)
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
---@return string[] fileNames List of file names
Methods.GetFileNamesInFolder = function(folder)
    local cmd = 'ls -a "'..folder..'"'
    if tes3mp.GetOperatingSystemType() == "Windows" then
        cmd = 'dir "'..folder..'" /b'
    end
    local fileNames, popen = {}, io.popen
    local pfile = popen(cmd)
    for filename in pfile:lines() do
        table.insert(fileNames, filename)
    end
    pfile:close()
    return fileNames
end

return Methods
