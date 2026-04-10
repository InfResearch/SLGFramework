local Class = require("Framework.Core.Class")

---@class ModeBase
---Abstract base class for all game modes (玩法).
---Subclasses must implement lifecycle methods and provide modeId/sceneId.
local ModeBase = Class("ModeBase")

---Constructor. Do NOT override; use onEnter for initialization.
function ModeBase:ctor()
    self._active = false
    self._paused = false
end

----------------------------------------------------------------
-- Properties — override in subclass
----------------------------------------------------------------

---Unique mode identifier. Must be overridden.
---@return string
function ModeBase:getModeId()
    error("getModeId() must be overridden in " .. self.__name)
end

---Optional scene associated with this mode. Return nil if none.
---@return string|nil
function ModeBase:getSceneId()
    return nil
end

---Whether this mode should be kept alive when paused (another mode pushed on top).
---Override to return true for heavy modes (City, World, RoomDungeon).
---@return boolean
function ModeBase:isRetained()
    return false
end

---Return the UI group id used by this mode, defaults to modeId.
---@return string
function ModeBase:getUIGroup()
    return self:getModeId()
end

----------------------------------------------------------------
-- Lifecycle — override in subclass as needed
----------------------------------------------------------------

---Called when entering this mode.
---@param params? table  arbitrary parameters passed during push/switch
function ModeBase:onEnter(params)
    self._active = true
    self._paused = false
end

---Called when this mode is paused because a new mode was pushed on top.
function ModeBase:onPause()
    self._paused = true
end

---Called when this mode resumes after the top mode was popped.
---@param result? table  data returned by the popped mode
function ModeBase:onResume(result)
    self._paused = false
end

---Called when leaving this mode (before potential destroy).
function ModeBase:onLeave()
    self._active = false
end

---Called when the mode instance is destroyed (not retained).
function ModeBase:onDestroy()
end

---Frame update — only called for the active (top) mode.
---@param dt number  delta time in seconds
function ModeBase:onUpdate(dt)
end

----------------------------------------------------------------
-- State queries
----------------------------------------------------------------

---@return boolean
function ModeBase:isActive()
    return self._active and not self._paused
end

---@return boolean
function ModeBase:isPaused()
    return self._paused
end

return ModeBase
