local Class           = require("Framework.Core.Class")
local EventDispatcher = require("Framework.Core.EventDispatcher")

---@class ModeManager : EventDispatcher
---Manages the mode stack and mode lifecycle.
---Events emitted:
---  "mode_enter"   (modeId, params)
---  "mode_leave"   (modeId)
---  "mode_pause"   (modeId)
---  "mode_resume"  (modeId, result)
local ModeManager = Class("ModeManager", EventDispatcher)

function ModeManager:ctor()
    EventDispatcher.ctor(self)
    self._stack       = {}      -- array of mode instances, index 1 = bottom
    self._registry    = {}      -- { [modeId] = classRef }
    self._retainCache = {}      -- { [modeId] = modeInstance } for retained modes
    self._sceneManager = nil
    self._uiManager    = nil
end

----------------------------------------------------------------
-- Dependency injection
----------------------------------------------------------------

---@param sceneManager SceneManager
function ModeManager:setSceneManager(sceneManager)
    self._sceneManager = sceneManager
end

---@param uiManager UIManager
function ModeManager:setUIManager(uiManager)
    self._uiManager = uiManager
end

----------------------------------------------------------------
-- Registration
----------------------------------------------------------------

---Register a mode class under a modeId.
---@param modeId string
---@param modeClass table  must be a subclass of ModeBase
function ModeManager:register(modeId, modeClass)
    assert(type(modeId) == "string", "modeId must be a string")
    assert(type(modeClass) == "table" and modeClass.new, "modeClass must be a Class")
    self._registry[modeId] = modeClass
end

----------------------------------------------------------------
-- Stack operations
----------------------------------------------------------------

---Push a new mode onto the stack. The current top mode is paused.
---@param modeId string
---@param params? table
function ModeManager:pushMode(modeId, params)
    local top = self:_top()
    if top then
        self:_pauseMode(top)
    end
    local mode = self:_createOrRestore(modeId)
    table.insert(self._stack, mode)
    self:_enterMode(mode, params)
end

---Pop the current top mode. The previous mode in the stack is resumed.
---@param result? table  data to pass to the resumed mode
function ModeManager:popMode(result)
    local top = self:_top()
    if not top then return end
    self:_leaveMode(top)
    table.remove(self._stack)
    local newTop = self:_top()
    if newTop then
        self:_resumeMode(newTop, result)
    end
end

---Replace the current top mode with a different mode.
---Does not affect the rest of the stack.
---@param modeId string
---@param params? table
function ModeManager:replaceMode(modeId, params)
    local top = self:_top()
    if top then
        self:_leaveMode(top)
        table.remove(self._stack)
    end
    local mode = self:_createOrRestore(modeId)
    table.insert(self._stack, mode)
    self:_enterMode(mode, params)
end

---Pop modes until the specified modeId is at the top.
---If the modeId is not in the stack, does nothing.
---@param modeId string
---@param result? table
function ModeManager:popToMode(modeId, result)
    while #self._stack > 0 do
        local top = self:_top()
        if top:getModeId() == modeId then
            -- target reached; resume it
            self:_resumeMode(top, result)
            return
        end
        self:_leaveMode(top)
        table.remove(self._stack)
    end
end

---Pop the current mode and then push a new mode (instead of resuming the parent).
---@param modeId string
---@param params? table
function ModeManager:popAndPush(modeId, params)
    local top = self:_top()
    if top then
        self:_leaveMode(top)
        table.remove(self._stack)
    end
    -- Do NOT resume the new top; instead push a fresh mode on top
    local mode = self:_createOrRestore(modeId)
    table.insert(self._stack, mode)
    self:_enterMode(mode, params)
end

----------------------------------------------------------------
-- Query
----------------------------------------------------------------

---@return table|nil  the current active mode instance
function ModeManager:currentMode()
    return self:_top()
end

---@return string|nil
function ModeManager:currentModeId()
    local top = self:_top()
    return top and top:getModeId() or nil
end

---@return number
function ModeManager:stackDepth()
    return #self._stack
end

---Check if a modeId exists anywhere in the stack.
---@param modeId string
---@return boolean
function ModeManager:isInStack(modeId)
    for _, m in ipairs(self._stack) do
        if m:getModeId() == modeId then
            return true
        end
    end
    return false
end

----------------------------------------------------------------
-- Update (call from game loop)
----------------------------------------------------------------

---@param dt number
function ModeManager:update(dt)
    local top = self:_top()
    if top and top:isActive() then
        top:onUpdate(dt)
    end
end

----------------------------------------------------------------
-- Internal helpers
----------------------------------------------------------------

---@return table|nil
function ModeManager:_top()
    return self._stack[#self._stack]
end

---Create a new mode instance or restore a retained one from cache.
---@param modeId string
---@return table  mode instance
function ModeManager:_createOrRestore(modeId)
    -- Try retain cache first
    local cached = self._retainCache[modeId]
    if cached then
        self._retainCache[modeId] = nil
        return cached
    end
    local cls = self._registry[modeId]
    assert(cls, "Mode not registered: " .. tostring(modeId))
    local inst = cls.new()
    return inst
end

---@param mode table
---@param params? table
function ModeManager:_enterMode(mode, params)
    local sceneId = mode:getSceneId()
    if self._sceneManager and sceneId then
        self._sceneManager:loadScene(sceneId, function(_success)
            mode:onEnter(params)
            self:emit("mode_enter", mode:getModeId(), params)
        end)
    else
        mode:onEnter(params)
        self:emit("mode_enter", mode:getModeId(), params)
    end
end

---@param mode table
function ModeManager:_pauseMode(mode)
    mode:onPause()
    -- Hide the mode's UI group
    if self._uiManager then
        self._uiManager:hideGroup(mode:getUIGroup())
    end
    self:emit("mode_pause", mode:getModeId())
end

---@param mode table
---@param result? table
function ModeManager:_resumeMode(mode, result)
    -- Restore scene if needed
    local sceneId = mode:getSceneId()
    if self._sceneManager and sceneId then
        self._sceneManager:loadScene(sceneId, function(_success)
            mode:onResume(result)
            -- Show the mode's UI group
            if self._uiManager then
                self._uiManager:showGroup(mode:getUIGroup())
            end
            self:emit("mode_resume", mode:getModeId(), result)
        end)
    else
        mode:onResume(result)
        if self._uiManager then
            self._uiManager:showGroup(mode:getUIGroup())
        end
        self:emit("mode_resume", mode:getModeId(), result)
    end
end

---@param mode table
function ModeManager:_leaveMode(mode)
    mode:onLeave()
    -- Close or cache the mode's UI group
    if self._uiManager then
        if mode:isRetained() then
            self._uiManager:hideGroup(mode:getUIGroup())
        else
            self._uiManager:closeGroup(mode:getUIGroup())
        end
    end
    self:emit("mode_leave", mode:getModeId())
    if mode:isRetained() then
        self._retainCache[mode:getModeId()] = mode
    else
        mode:onDestroy()
    end
end

return ModeManager
