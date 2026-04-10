--- EventBus.lua
--- 轻量级事件总线，支持订阅/发布、优先级和一次性监听
---
--- 用法示例:
---   local bus = EventBus()
---   local function onHp(hp) print("hp=" .. hp) end
---   bus:on("hp_changed", onHp)
---   bus:emit("hp_changed", 50)   --> "hp=50"
---   bus:off("hp_changed", onHp)

local Class = require("Framework.Core.Class")

local EventBus = Class:extend()

function EventBus:init()
    self._listeners = {}  -- event -> { {fn, priority, once}, ... }
end

--- 订阅事件
---@param event string        事件名
---@param fn function         回调函数
---@param priority number?    优先级（越大越先执行，默认 0）
---@param once boolean?       是否只触发一次（默认 false）
function EventBus:on(event, fn, priority, once)
    priority = priority or 0
    once     = once or false
    if not self._listeners[event] then
        self._listeners[event] = {}
    end
    table.insert(self._listeners[event], { fn = fn, priority = priority, once = once })
    table.sort(self._listeners[event], function(a, b) return a.priority > b.priority end)
end

--- 订阅事件，仅触发一次后自动取消
---@param event string
---@param fn function
---@param priority number?
function EventBus:once(event, fn, priority)
    self:on(event, fn, priority, true)
end

--- 取消订阅
---@param event string
---@param fn function
function EventBus:off(event, fn)
    local list = self._listeners[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i].fn == fn then
            table.remove(list, i)
            break
        end
    end
end

--- 发布事件，所有监听者按优先级顺序被调用
---@param event string
---@param ... any  传递给监听者的参数
function EventBus:emit(event, ...)
    local list = self._listeners[event]
    if not list or #list == 0 then return end
    -- 拷贝一份，防止回调中修改列表导致迭代异常
    local snapshot = {}
    for i = 1, #list do snapshot[i] = list[i] end
    for _, entry in ipairs(snapshot) do
        entry.fn(...)
        if entry.once then
            self:off(event, entry.fn)
        end
    end
end

--- 清除指定事件的所有监听，或清除全部
---@param event string?  不传则清除全部
function EventBus:clear(event)
    if event then
        self._listeners[event] = nil
    else
        self._listeners = {}
    end
end

--- 返回指定事件当前的监听者数量
---@param event string
---@return number
function EventBus:listenerCount(event)
    local list = self._listeners[event]
    return list and #list or 0
end

return EventBus
