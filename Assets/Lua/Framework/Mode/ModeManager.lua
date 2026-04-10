--- ModeManager.lua
--- 游戏模式管理器
---
--- 职责:
---   - 注册/注销模式类
---   - 基于栈结构的模式切换（switchTo / exitCurrent）
---   - 可配置的模式保留（retain）：切换离开时暂停而非销毁，回来时快速恢复
---   - 发布模式切换事件，供 UI/场景等系统响应
---
--- 典型流程:
---   ModeManager:switchTo("campaign", {level=1})
---     → CityMode:suspend()        [city 在栈中等待]
---     → CampaignMode:enter()
---   ModeManager:exitCurrent()
---     → CampaignMode:exit()
---     → CityMode:resume()         [城市界面自动恢复]

local EventBus = require("Framework.Core.EventBus")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("ModeManager")

---@class ModeManager
local ModeManager = {}
ModeManager.__index = ModeManager

--- ModeManager 发出的事件常量
ModeManager.Events = {
    BEFORE_SWITCH = "mode.beforeSwitch",  -- (fromMode, toMode)
    AFTER_SWITCH  = "mode.afterSwitch",   -- (fromMode, toMode)
    MODE_ENTER    = "mode.enter",         -- (mode, fromMode)
    MODE_EXIT     = "mode.exit",          -- (mode, toMode)
    MODE_SUSPEND  = "mode.suspend",       -- (mode, toMode)
    MODE_RESUME   = "mode.resume",        -- (mode, fromMode)
}

--- 创建一个新的 ModeManager 实例
---@return ModeManager
function ModeManager.new()
    local self    = setmetatable({}, ModeManager)
    self._registry = {}   -- id -> { class, retain }
    self._cache    = {}   -- id -> retained mode instance
    self._stack    = {}   -- 暂停模式的 id 栈（栈顶 = 最近被暂停的模式）
    self._current  = nil  -- 当前激活的模式实例
    self._events   = EventBus()
    return self
end

--- 注册一个模式类
---@param id         string     模式唯一标识
---@param modeClass  table      ModeBase 的子类
---@param config     table|nil  { retain:boolean }
---                             retain=true  切换离开时暂停实例，保留在内存以便快速恢复
---                             retain=false 切换离开时退出并销毁实例（默认）
function ModeManager:register(id, modeClass, config)
    assert(id and id ~= "", "ModeManager.register: id is required")
    assert(modeClass, "ModeManager.register: modeClass is required")
    config = config or {}
    self._registry[id] = {
        class  = modeClass,
        retain = config.retain or false,
    }
    log:debug("registered mode [%s] retain=%s", id, tostring(config.retain or false))
end

--- 注销一个模式（同时销毁其缓存实例）
---@param id string
function ModeManager:unregister(id)
    if self._cache[id] then
        self._cache[id]:destroy()
        self._cache[id] = nil
    end
    self._registry[id] = nil
end

--- 切换到指定模式
--- 当前模式若为 retain=true 则暂停（suspended），否则退出（exit）
---
---@param id      string      目标模式 id
---@param params  table|nil   传递给目标模式 enter/resume 的参数
---@param options table|nil   {
---                             noReturn  = bool,  -- 不将当前模式压栈（无法自动返回）
---                             clearStack = bool, -- 清空历史栈（切换后无法返回任何旧模式）
---                           }
function ModeManager:switchTo(id, params, options)
    assert(self._registry[id], "ModeManager.switchTo: mode not registered: " .. tostring(id))
    options = options or {}

    local fromMode = self._current
    local toMode   = self:_getOrCreate(id)

    log:info("switchTo [%s] -> [%s]", fromMode and fromMode.id or "none", id)
    self._events:emit(ModeManager.Events.BEFORE_SWITCH, fromMode, toMode)

    -- 处理当前模式
    if fromMode then
        if options.clearStack then
            self:_clearStack()
        elseif not options.noReturn then
            table.insert(self._stack, fromMode.id)
        end

        local reg = self._registry[fromMode.id]
        if reg and reg.retain then
            fromMode:suspend(toMode)
            self._events:emit(ModeManager.Events.MODE_SUSPEND, fromMode, toMode)
            log:debug("[%s] suspended", fromMode.id)
        else
            fromMode:exit(toMode)
            self._events:emit(ModeManager.Events.MODE_EXIT, fromMode, toMode)
            fromMode:destroy()
            log:debug("[%s] exited", fromMode.id)
        end
    end

    -- 激活目标模式
    self._current = toMode
    toMode:_setPrevMode(fromMode)

    if toMode:isSuspended() then
        toMode:resume(fromMode, params)
        self._events:emit(ModeManager.Events.MODE_RESUME, toMode, fromMode)
        log:debug("[%s] resumed", id)
    else
        toMode:enter(fromMode, params)
        self._events:emit(ModeManager.Events.MODE_ENTER, toMode, fromMode)
        log:debug("[%s] entered", id)
    end

    self._events:emit(ModeManager.Events.AFTER_SWITCH, fromMode, toMode)
end

--- 退出当前模式，返回栈顶的上一个模式
--- 若栈为空则直接退出，不激活任何模式
---
---@param params   table|nil   传递给恢复模式 resume 的参数（如战斗结果）
---@param targetId string|nil  可选：指定返回到的模式 id，而不是自动使用栈顶
---                            若 targetId 不在栈中，则直接 switchTo（不清栈）
function ModeManager:exitCurrent(params, targetId)
    local fromMode = self._current
    assert(fromMode, "ModeManager.exitCurrent: no active mode")

    -- 确定返回目标
    local returnId
    if targetId then
        returnId = targetId
        -- 如果在栈中，清理到该位置
        self:_popStackTo(targetId)
    elseif #self._stack > 0 then
        returnId = table.remove(self._stack)
    end

    log:info("exitCurrent [%s] -> [%s]", fromMode.id, returnId or "none")
    self._events:emit(ModeManager.Events.BEFORE_SWITCH, fromMode, returnId and self:_getOrCreate(returnId) or nil)

    -- 退出当前模式
    local toMode = returnId and self:_getOrCreate(returnId) or nil
    fromMode:exit(toMode)
    self._events:emit(ModeManager.Events.MODE_EXIT, fromMode, toMode)
    local reg = self._registry[fromMode.id]
    if not (reg and reg.retain) then
        fromMode:destroy()
        -- 非 retain 模式不缓存，置为 nil 让 GC 回收
    end
    self._current = nil

    if toMode then
        self._current = toMode
        toMode:_setPrevMode(fromMode)

        if toMode:isSuspended() then
            toMode:resume(fromMode, params)
            self._events:emit(ModeManager.Events.MODE_RESUME, toMode, fromMode)
            log:debug("[%s] resumed", toMode.id)
        else
            toMode:enter(fromMode, params)
            self._events:emit(ModeManager.Events.MODE_ENTER, toMode, fromMode)
            log:debug("[%s] entered", toMode.id)
        end

        self._events:emit(ModeManager.Events.AFTER_SWITCH, fromMode, toMode)
    end
end

--- 获取当前激活模式
---@return ModeBase|nil
function ModeManager:getCurrent()
    return self._current
end

--- 获取模式栈快照（从底到顶的 id 列表，用于调试）
---@return string[]
function ModeManager:getStack()
    local result = {}
    for i, id in ipairs(self._stack) do result[i] = id end
    return result
end

--- 销毁指定模式的缓存实例（若当前激活则先退出）
---@param id string
function ModeManager:destroyMode(id)
    if self._current and self._current.id == id then
        self:exitCurrent()
    end
    if self._cache[id] then
        self._cache[id]:destroy()
        self._cache[id] = nil
    end
end

--- 订阅模式切换事件
---@param event    string    ModeManager.Events 中的常量
---@param listener function
function ModeManager:on(event, listener)
    self._events:on(event, listener)
end

--- 取消订阅
---@param event    string
---@param listener function
function ModeManager:off(event, listener)
    self._events:off(event, listener)
end

--- 销毁全部模式，重置管理器
function ModeManager:destroyAll()
    if self._current then
        self._current:exit(nil)
        self._current:destroy()
        self._current = nil
    end
    for _, instance in pairs(self._cache) do
        instance:destroy()
    end
    self._cache   = {}
    self._stack   = {}
    self._events:clear()
end

-- ─── 私有方法 ──────────────────────────────────────────────────────────────

--- 获取或创建模式实例
function ModeManager:_getOrCreate(id)
    local reg = self._registry[id]
    assert(reg, "ModeManager: mode not registered: " .. tostring(id))

    if reg.retain and self._cache[id] then
        return self._cache[id]
    end

    local instance = reg.class({ id = id, retain = reg.retain })
    if reg.retain then
        self._cache[id] = instance
    end
    return instance
end

--- 清空模式栈（同时销毁被暂停的非 retain 实例）
function ModeManager:_clearStack()
    for i = #self._stack, 1, -1 do
        local sid = self._stack[i]
        local reg = self._registry[sid]
        if self._cache[sid] and not (reg and reg.retain) then
            self._cache[sid]:destroy()
            self._cache[sid] = nil
        end
    end
    self._stack = {}
end

--- 弹出栈直到 targetId（含），丢弃中间的模式
function ModeManager:_popStackTo(targetId)
    for i = #self._stack, 1, -1 do
        local sid = table.remove(self._stack)
        if sid == targetId then
            return
        end
        -- 销毁被跳过的暂停模式
        local reg = self._registry[sid]
        if self._cache[sid] and not (reg and reg.retain) then
            self._cache[sid]:destroy()
            self._cache[sid] = nil
        end
    end
end

return ModeManager
