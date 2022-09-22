local customEventHooks = require('customEventHooks')
local SaintRevive      = require('custom.saint.revive.manager')

customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
    local didRevive = SaintRevive.OnPlayerDeath(pid)
    local doDefault = not didRevive
    return customEventHooks.makeEventStatus(false, doDefault)
end)
customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
    SaintRevive.OnPlayerDisconnect(pid)
    return eventStatus
end)
customEventHooks.registerHandler("OnPlayerFinishLogin", function(eventStatus, pid)
    SaintRevive.OnPlayerFinishLogin(pid)
    return eventStatus
end)
customEventHooks.registerHandler("OnObjectActivate", function(eventStatus, pid, cellDescription, objects, players)
    SaintRevive.OnObjectActivate(pid, cellDescription, objects, players)
    return eventStatus
end)
customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    SaintRevive.OnServerPostInit()
    return eventStatus
end)


