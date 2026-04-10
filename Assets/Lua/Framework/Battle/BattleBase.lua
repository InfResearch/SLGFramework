local Class     = require("Framework.Core.Class")
local BattleDef = require("Framework.Battle.BattleDef")

---@class BattleBase
---Abstract base class for all battle types.
---Provides a common lifecycle: init → start → (pause/resume) → finish.
local BattleBase = Class("BattleBase")

function BattleBase:ctor()
    self._state  = BattleDef.State.IDLE
    self._config = nil
    self._result = nil
    self._onFinish = nil  -- callback(result)
end

----------------------------------------------------------------
-- Lifecycle
----------------------------------------------------------------

---Initialize the battle with configuration data.
---@param config table  battle-specific configuration
---@param onFinish? function  callback(result) when battle finishes
function BattleBase:init(config, onFinish)
    assert(config, "battle config is required")
    self._config   = config
    self._onFinish = onFinish
    self._state    = BattleDef.State.IDLE
    self._result   = nil
    self:onInit(config)
end

---Start the battle.
function BattleBase:start()
    assert(self._state == BattleDef.State.IDLE, "battle must be in IDLE state to start")
    self._state = BattleDef.State.RUNNING
    self:onStart()
end

---Pause the battle.
function BattleBase:pause()
    if self._state ~= BattleDef.State.RUNNING then return end
    self._state = BattleDef.State.PAUSED
    self:onPause()
end

---Resume the battle.
function BattleBase:resume()
    if self._state ~= BattleDef.State.PAUSED then return end
    self._state = BattleDef.State.RUNNING
    self:onResume()
end

---Finish the battle with a result.
---@param result table  created via BattleDef.makeResult
function BattleBase:finish(result)
    if self._state == BattleDef.State.FINISHED then return end
    self._state  = BattleDef.State.FINISHED
    self._result = result
    self:onFinish(result)
    if self._onFinish then
        self._onFinish(result)
    end
end

---Clean up the battle.
function BattleBase:destroy()
    self:onDestroy()
    self._config   = nil
    self._result   = nil
    self._onFinish = nil
end

----------------------------------------------------------------
-- Queries
----------------------------------------------------------------

---@return number  BattleDef.State value
function BattleBase:getState()
    return self._state
end

---@return table|nil
function BattleBase:getResult()
    return self._result
end

---@return table|nil
function BattleBase:getConfig()
    return self._config
end

---@return boolean
function BattleBase:isRunning()
    return self._state == BattleDef.State.RUNNING
end

----------------------------------------------------------------
-- Hooks — override in subclass
----------------------------------------------------------------

function BattleBase:onInit(config) end
function BattleBase:onStart() end
function BattleBase:onPause() end
function BattleBase:onResume() end
---@param result table
function BattleBase:onFinish(result) end
function BattleBase:onDestroy() end
---@param dt number
function BattleBase:onUpdate(dt) end

return BattleBase
