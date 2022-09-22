local customEventHooks      = require('customEventHooks')
local Config                = require('custom.saint.cellreset.config')
local SaintCellResetManager = require('custom.saint.cellreset.manager')
local SaintTicks            = require('custom.saint.common.ticks.main')

customEventHooks.registerHandler('OnServerPostInit', function(eventStatus)
    if eventStatus.validCustomHandlers then
        SaintCellResetManager.Initizalize()
        SaintTicks.RegisterTick(SaintCellResetManager.LoadCellNamesFromFiles, Config.CellNameLoadPeriod)
        SaintTicks.RegisterTick(SaintCellResetManager.ProcessCellResets, Config.CellResetCheckPeriod)
    end
    return eventStatus
end)

customEventHooks.registerHandler('OnCellLoad', function(eventStatus, pid, cellDescription)
    if eventStatus.validCustomHandlers then
        SaintCellResetManager.AddCellToCache(cellDescription)
    end
    return eventStatus
end)

return {}
