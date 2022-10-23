local customCommandHooks = require('customCommandHooks')
local SaintRevive        = require('custom.saint.revive.reviveManager')

customCommandHooks.registerCommand("die", function(pid)
    SaintRevive.OnDieCommand(pid)
end)


