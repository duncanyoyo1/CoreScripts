local customCommandHooks = require('customCommandHooks')
local SaintCellReset     = require('custom.saint.cellreset.api')
local SaintCellManager   = require('custom.saint.cellreset.manager')

local Commands = {}

Commands.MarkCellForResetCommand = function(pid)
    SaintCellReset.MarkCellForReset(Players[pid].data.location.cell)
    Players[pid]:Message("Marking '" .. Players[pid].data.location.cell .. "' for reset\n")
end

Commands.MarkAllCellsForResetCommand = function(pid)
    for _, cellDescription in pairs(Players[pid].cellsLoaded) do
        SaintCellReset.MarkCellForReset(cellDescription)
        Players[pid]:Message("Marking '" .. cellDescription .. "' for reset\n")
    end
end

Commands.QueueCellReset = function(pid)
    local playerCell = Players[pid].data.location.cell
    SaintCellManager.AddCellResetToQueue(pid, playerCell)
    tes3mp.SendMessage(pid, "Queueing '" .. playerCell .. "' for a reset\n")
end

Commands.BlacklistCell = function(pid)
    local player = Players[pid]
    local cellDescription = player.data.location.cell
    tes3mp.SendMessage(pid, 'Registering current cell to black list: ' .. cellDescription)
    SaintCellManager.BlacklistCell(cellDescription)
end

customCommandHooks.registerCommand("MarkCellForReset", Commands.MarkCellForResetCommand)
customCommandHooks.registerCommand("MarkAllCellsForReset", Commands.MarkAllCellsForResetCommand)
customCommandHooks.registerCommand('QueueCellReset', Commands.QueueCellReset)
customCommandHooks.registerCommand('SCRMRegisterBlackCell', Commands.BlacklistCell)

return Commands
