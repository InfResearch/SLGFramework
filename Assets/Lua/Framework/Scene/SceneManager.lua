local Class = require("Framework.Core.Class")

---@class SceneManager
---Independent scene management. Delegates actual loading to C# SceneLoader.
local SceneManager = Class("SceneManager")

function SceneManager:ctor()
    self._currentSceneId = nil
    self._loading = false
end

---Load a scene by ID. Calls the C# SceneLoader asynchronously.
---@param sceneId string|nil
---@param onComplete? function  callback(success)
function SceneManager:loadScene(sceneId, onComplete)
    if sceneId == nil then
        if onComplete then onComplete(true) end
        return
    end
    if sceneId == self._currentSceneId then
        if onComplete then onComplete(true) end
        return
    end
    self._loading = true
    local prevSceneId = self._currentSceneId
    self._currentSceneId = sceneId
    -- Delegate to C# SceneLoader via xLua bridge
    local ok, loader = pcall(function()
        return CS.SLGFramework.SceneLoader.Instance
    end)
    if ok and loader then
        loader:LoadSceneAsync(sceneId, function(success)
            self._loading = false
            if not success then
                self._currentSceneId = prevSceneId
            end
            if onComplete then onComplete(success) end
        end)
    else
        -- Fallback: simulate immediate load when C# layer is unavailable
        self._loading = false
        if onComplete then onComplete(true) end
    end
end

---Unload a scene by ID.
---@param sceneId string
---@param onComplete? function
function SceneManager:unloadScene(sceneId, onComplete)
    if sceneId == nil then
        if onComplete then onComplete(true) end
        return
    end
    local ok, loader = pcall(function()
        return CS.SLGFramework.SceneLoader.Instance
    end)
    if ok and loader then
        loader:UnloadSceneAsync(sceneId, function(success)
            if success and self._currentSceneId == sceneId then
                self._currentSceneId = nil
            end
            if onComplete then onComplete(success) end
        end)
    else
        if self._currentSceneId == sceneId then
            self._currentSceneId = nil
        end
        if onComplete then onComplete(true) end
    end
end

---@return string|nil
function SceneManager:getCurrentSceneId()
    return self._currentSceneId
end

---@return boolean
function SceneManager:isLoading()
    return self._loading
end

return SceneManager
