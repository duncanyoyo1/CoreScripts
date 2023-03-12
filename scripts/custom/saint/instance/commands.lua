local customCommandHooks = require('customCommandHooks')
local manager            = require('custom.saint.instance.singleton')

customCommandHooks.registerCommand("createInstance", function(pid, parameters)
    manager:CreateInstanceOfCellForPlayers(parameters[2], {pid})
end)

customCommandHooks.registerCommand("clearInstance", function(pid, parameters)
    manager:DeleteInstanceOfCellForPlayers(parameters[2], {pid})
end)
