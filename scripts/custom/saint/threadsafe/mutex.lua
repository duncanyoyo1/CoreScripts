local effil = require('effil')
local classy = require('classy')

---@class Mutex
---@overload fun(): Mutex
local Mutex = classy('Mutex')

---@private
function Mutex:__init()
    ---@private
    self.channel = effil.channel(1)
    self.channel:push(true) -- don't initialize the mutex locked
end

---@generic T
---@param cb fun(a...: any): T?
---@return T
function Mutex:Lock(cb)
    self.channel:pop()
    local _, res = pcall(cb)
    self.channel:push(true)
    return res
end

return Mutex
