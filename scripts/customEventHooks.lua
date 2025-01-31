---@class EventStatus
---@field validDefaultHandler boolean
---@field validCustomHandlers boolean

---@class CustomEventHooks
local customEventHooks = {}

customEventHooks.validators = {}
customEventHooks.handlers = {}

---@return EventStatus
function customEventHooks.makeEventStatus(validDefaultHandler, validCustomHandlers)
    return {
        validDefaultHandler = validDefaultHandler,
        validCustomHandlers = validCustomHandlers
    }
end

---@return EventStatus
function customEventHooks.updateEventStatus(oldStatus, newStatus)
    if newStatus == nil then
        return oldStatus
    end
    local result = {}
    if newStatus.validDefaultHandler ~= nil then
        result.validDefaultHandler = newStatus.validDefaultHandler
    else
        result.validDefaultHandler = oldStatus.validDefaultHandler
    end
    
    if newStatus.validCustomHandlers ~= nil then
        result.validCustomHandlers = newStatus.validCustomHandlers
    else
        result.validCustomHandlers = oldStatus.validCustomHandlers
    end
    
    return result
end

---@param event string
---@param callback fun(event: EventStatus, ...): EventStatus
function customEventHooks.registerValidator(event, callback)
    if customEventHooks.validators[event] == nil then
        customEventHooks.validators[event] = {}
    end
    table.insert(customEventHooks.validators[event], callback)
end

---@param event string
---@param callback fun(event: EventStatus, ...): EventStatus
function customEventHooks.registerHandler(event, callback)
    if customEventHooks.handlers[event] == nil then
        customEventHooks.handlers[event] = {}
    end
    table.insert(customEventHooks.handlers[event], callback)
end

---@return EventStatus
function customEventHooks.triggerValidators(event, args)
    local eventStatus = customEventHooks.makeEventStatus(true, true)
    if customEventHooks.validators[event] ~= nil then
        for _, callback in ipairs(customEventHooks.validators[event]) do
            eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
        end
    end
    return eventStatus
end

function customEventHooks.triggerHandlers(event, eventStatus, args)
    if customEventHooks.handlers[event] ~= nil then
        for _, callback in ipairs(customEventHooks.handlers[event]) do
             eventStatus = customEventHooks.updateEventStatus(eventStatus, callback(eventStatus, unpack(args)))
        end
    end
end

return customEventHooks
