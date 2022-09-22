local customCommandHooks = require('customCommandHooks')
local SaintRevive        = require('custom.saint.revive.SaintRevive')

customCommandHooks.registerCommand("die", function(pid)
    SaintRevive.OnDieCommand(pid)
end)


