local Class = require("Framework.Core.Class")

---@class EventDispatcher
---Simple event system: register, unregister, and dispatch named events.
local EventDispatcher = Class("EventDispatcher")

function EventDispatcher:ctor()
    self._listeners = {} -- { [event] = { {fn, ctx}, ... } }
end

---Register a listener for an event.
---@param event string
---@param fn function
---@param ctx? table  optional context (self)
function EventDispatcher:on(event, fn, ctx)
    assert(type(event) == "string", "event must be a string")
    assert(type(fn) == "function", "fn must be a function")
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    table.insert(self._listeners[event], { fn = fn, ctx = ctx })
end

---Unregister a listener.
---@param event string
---@param fn function
---@param ctx? table
function EventDispatcher:off(event, fn, ctx)
    local list = self._listeners[event]
    if not list then return end
    for i = #list, 1, -1 do
        local entry = list[i]
        if entry.fn == fn and entry.ctx == ctx then
            table.remove(list, i)
        end
    end
end

---Dispatch an event with optional arguments.
---@param event string
---@vararg any
function EventDispatcher:emit(event, ...)
    local list = self._listeners[event]
    if not list then return end
    -- iterate over a snapshot to allow modifications during dispatch
    local snapshot = { table.unpack(list) }
    for _, entry in ipairs(snapshot) do
        if entry.ctx then
            entry.fn(entry.ctx, ...)
        else
            entry.fn(...)
        end
    end
end

---Remove all listeners for an event, or all events if event is nil.
---@param event? string
function EventDispatcher:offAll(event)
    if event then
        self._listeners[event] = nil
    else
        self._listeners = {}
    end
end

return EventDispatcher
