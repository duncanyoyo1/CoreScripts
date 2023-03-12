---@meta
-------------------------------------------------------------------------------
--- effil types
-------------------------------------------------------------------------------

---@alias ThreadStatus 'completed'|'cancelled'|'running'|'paused'|'failed'

---@class Channel
---@field push fun(self: Channel, a: any)
---@field pop fun(self: Channel, t: number?, m: string?): any
---@field size fun(self: Channel): number

---@class Thread
---@field get fun(self: Thread, t: number?, m: string?): any
---@field wait fun(self: Thread, t: number?, m: string?): ThreadStatus
---@field status fun(self: Thread): ThreadStatus, string, string
---@field pause fun(self: Thread, t: number?, m: string?)
---@field cancel fun(self: Thread, t: number?, m: string?)
---@field resume fun(self: Thread)

---@class ThreadRunner
---@overload fun(): Thread
---@field path string
---@field cpath string
---@field step number

---@class EffilGarbageCollector
---@field collect fun()
---@field count fun(): number
---@field step fun(c: number): number
---@field pause fun()
---@field resume fun()
---@field enabled fun(): boolean

---@class Effil
---@field thread_id fun(): string
---@field sleep fun(t: number?, m: string?)
---@field hardware_threads fun(): number
---@field pcall fun(f: fun(...), ...): boolean, ...
---@field table fun(t: table<`K`, `V`>): table<`K`, `V`> Userdata effil table
---@field thread fun(): ThreadRunner
---@field channel fun(capacity: number?): Channel
---@field gc EffilGarbageCollector
---@field size fun(t: table): number
---@field type fun(t: any): string

---@type Effil
---@module 'effil'
