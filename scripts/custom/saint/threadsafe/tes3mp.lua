---Saint Note: Known limitation is that threaded messages need
---Saint Note: to be processd on the main thread. The current
---Saint Note: way is to process messages as "in order" as
---Saint Note: possible, but needs the main thread to process
---Saint Note: any queued messages from other threads.

---Saint Note: So, this just straight up won't work. Certain actions
---Saint Note: need to happen in a certain order and the current
---Saint Note: implmentation will not be able to accomodate that

---@type Effil
local effil = require('effil')

---@class SafeTES3MPMetaTable
---@field package idCache string[]

---@class MailBox
---@field inbox Channel
---@field outbox Channel

---@type table<string, MailBox>
local mailboxes = effil.table({})
local threadIds = effil.channel()

---@type TES3MP
local safe_tes3mp = {
    idCache = {}
}
---@type SafeTES3MPMetaTable
safe_tes3mp.mt = {}

function safe_tes3mp.mt:__index(key)
    if (tes3mp) then
        while threadIds:size() > 0 do
            local threadId = threadIds:pop()
            self.idCache[threadId] = threadId
        end
        for _, threadId in pairs(self.idCache) do
            local mailbox = mailboxes[threadId]
            local inbox = mailbox.inbox
            local outbox = mailbox.outbox

            while inbox:size() > 0 do
                local mail = inbox:pop()
                local convertedMail = {}
                local i = 1
                while mail[i] ~= nil do
                    convertedMail[i] = mail[i]
                    i = i + 1
                end
                local success, res = pcall(tes3mp[key], unpack(convertedMail))
                if not success then
                    print('Error occurred when running: ' .. key)
                end
                outbox:push(res)
            end
        end

        return function(...)
            local success, res = pcall(tes3mp[key], ...)
            if not success then
                print('Error occurred when running: ' .. key)
            end
            return res
        end
    end

    return function(...)
        local mailbox = mailboxes[effil.thread_id()]
        if not mailbox then
            mailbox = {
                inbox = effil.channel(),
                outbox = effil.channel()
            }
            mailboxes[effil.thread_id()] = mailbox
            threadIds:push(effil.thread_id())
        end
        local inbox = mailbox.inbox
        local outbox = mailbox.outbox
        inbox:push({...})
        return outbox:pop()
    end
end

setmetatable(safe_tes3mp, safe_tes3mp.mt)

return safe_tes3mp
