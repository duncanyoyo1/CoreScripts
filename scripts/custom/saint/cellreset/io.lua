local tes3mpConfig   = require('config')
local SaintUtilities = require('custom.saint.common.utilities.main')

local IO = {}

--- NOTE: This is expensive. Need to find a cacheable and less expensive way to do this
IO.QueryKnownCellNamesFromFile = function()
    local fileNames = SaintUtilities.GetFileNamesInFolder(tes3mpConfig.dataPath .. '/cell')
    local cleanedFiles = {}
    for _, fileName in pairs(fileNames) do
        if string.find(fileName, '%.json') then
            local cleanedName = fileName:gsub('%.json', '')
            table.insert(cleanedFiles, cleanedName)
        end
    end
    return cleanedFiles
end

return IO
