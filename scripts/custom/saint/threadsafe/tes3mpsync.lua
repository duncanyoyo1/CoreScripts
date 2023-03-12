---@type Effil
local effil = require('effil')

local tes3mpsync = {}

local workChannel = effil.channel()

---Create a chunk of work for tes3mp
---@param tes3mp_cb fun(t: TES3MP)
function tes3mpsync:syncblock(tes3mp_cb)
    if tes3mp then
        while workChannel:size() > 0 do
            pcall(workChannel:pop(), tes3mp)
        end
        pcall(tes3mp_cb, tes3mp)
    else
        workChannel:push(tes3mp_cb)
    end
end

return tes3mpsync
