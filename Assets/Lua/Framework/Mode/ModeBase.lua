--- ModeBase.lua
--- 所有游戏模式的抽象基类
---
--- 游戏模式（Mode）代表一种独立的游戏玩法上下文，例如内城、大地图、战斗等。
--- 同一时刻只有一个模式处于激活状态。
---
--- 生命周期:
---   IDLE  --enter()-->  ACTIVE  --suspend()-->  SUSPENDED
---                          |                        |
---                       exit()                  resume()
---                          |                        |
---                        IDLE  <---<---<---<---  ACTIVE
---
--- 子类应覆盖 enter / exit / suspend / resume 以实现各自的场景/UI 管理逻辑。

local Class = require("Framework.Core.Class")

---@class ModeBase
local ModeBase = Class:extend()

--- 模式状态枚举
ModeBase.State = {
    IDLE      = "idle",       -- 尚未启动（或已清理）
    ACTIVE    = "active",     -- 当前激活模式
    SUSPENDED = "suspended",  -- 暂停中（保留在内存，等待恢复）
}

--- 构造函数
---@param config table  { id:string, name:string, retain:boolean }
---   id      : 唯一标识符（与 ModeManager 注册时一致）
---   name    : 可读名称，用于日志/调试
---   retain  : true 表示切换离开时保留实例，以便快速恢复；false 表示退出后销毁
function ModeBase:init(config)
    config = config or {}
    assert(config.id and config.id ~= "", "ModeBase: id is required")
    self.id      = config.id
    self.name    = config.name or config.id
    self.retain  = config.retain ~= nil and config.retain or false
    self.state   = ModeBase.State.IDLE
    -- 由 ModeManager 在切换时设置，指向切换前的模式（用于回退）
    self._prevMode = nil
end

--- 进入本模式（从 IDLE 状态变为 ACTIVE）
--- 子类覆盖时应先调用 ModeBase.enter(self, fromMode, params)
---@param fromMode ModeBase|nil  切换前的模式
---@param params   table|nil     入口参数（由 switchTo 传入）
function ModeBase:enter(fromMode, params)
    self.state = ModeBase.State.ACTIVE
end

--- 退出本模式（ACTIVE → IDLE），通常伴随销毁
--- 子类覆盖时应最后调用 ModeBase.exit(self, toMode)
---@param toMode ModeBase|nil  即将激活的模式
function ModeBase:exit(toMode)
    self.state = ModeBase.State.IDLE
end

--- 暂停本模式（ACTIVE → SUSPENDED），模式实例保留在内存
--- 常用于：本模式被另一个模式临时覆盖，稍后还会恢复
--- 子类覆盖时应最后调用 ModeBase.suspend(self, toMode)
---@param toMode ModeBase  即将激活的模式
function ModeBase:suspend(toMode)
    self.state = ModeBase.State.SUSPENDED
end

--- 从暂停中恢复（SUSPENDED → ACTIVE）
--- 子类覆盖时应先调用 ModeBase.resume(self, fromMode, params)
---@param fromMode ModeBase  刚刚退出的模式
---@param params   table|nil 由 exitCurrent 传入的结果参数
function ModeBase:resume(fromMode, params)
    self.state = ModeBase.State.ACTIVE
end

--- 最终销毁（清理资源）。由 ModeManager 在确认不再需要此实例时调用。
function ModeBase:destroy()
    self.state = ModeBase.State.IDLE
end

--- 是否处于激活状态
---@return boolean
function ModeBase:isActive()
    return self.state == ModeBase.State.ACTIVE
end

--- 是否处于暂停状态
---@return boolean
function ModeBase:isSuspended()
    return self.state == ModeBase.State.SUSPENDED
end

--- 设置前一个模式（由 ModeManager 调用，子类无需直接操作）
---@param mode ModeBase|nil
function ModeBase:_setPrevMode(mode)
    self._prevMode = mode
end

--- 获取前一个模式
---@return ModeBase|nil
function ModeBase:getPrevMode()
    return self._prevMode
end

return ModeBase
