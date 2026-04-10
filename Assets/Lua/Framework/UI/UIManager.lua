local Class = require("Framework.Core.Class")

---@class UIManager
---Independent UI management. Provides open/close/hide/show and group operations.
---Not coupled to the Mode system; Modes call UIManager in their lifecycle hooks.
local UIManager = Class("UIManager")

function UIManager:ctor()
    self._openUIs  = {}  -- { [uiId] = { params=..., groupId=..., visible=true/false } }
    self._groups   = {}  -- { [groupId] = { uiId1, uiId2, ... } }
end

----------------------------------------------------------------
-- Single UI operations
----------------------------------------------------------------

---Open a UI panel.
---@param uiId string
---@param params? table
---@param groupId? string  optional group for batch operations
function UIManager:openUI(uiId, params, groupId)
    if self._openUIs[uiId] then
        self:showUI(uiId)
        return
    end
    self._openUIs[uiId] = {
        params  = params,
        groupId = groupId,
        visible = true,
    }
    if groupId then
        if not self._groups[groupId] then
            self._groups[groupId] = {}
        end
        table.insert(self._groups[groupId], uiId)
    end
    -- Delegate to C# UIHelper for actual instantiation
    local ok, helper = pcall(function()
        return CS.SLGFramework.UIHelper.Instance
    end)
    if ok and helper then
        helper:OpenUI(uiId, params)
    end
end

---Close (destroy) a UI panel.
---@param uiId string
function UIManager:closeUI(uiId)
    local info = self._openUIs[uiId]
    if not info then return end
    -- Remove from group
    if info.groupId and self._groups[info.groupId] then
        local grp = self._groups[info.groupId]
        for i = #grp, 1, -1 do
            if grp[i] == uiId then
                table.remove(grp, i)
                break
            end
        end
    end
    self._openUIs[uiId] = nil
    local ok, helper = pcall(function()
        return CS.SLGFramework.UIHelper.Instance
    end)
    if ok and helper then
        helper:CloseUI(uiId)
    end
end

---Hide a UI panel (keep instance alive).
---@param uiId string
function UIManager:hideUI(uiId)
    local info = self._openUIs[uiId]
    if not info then return end
    info.visible = false
    local ok, helper = pcall(function()
        return CS.SLGFramework.UIHelper.Instance
    end)
    if ok and helper then
        helper:HideUI(uiId)
    end
end

---Show a previously hidden UI panel.
---@param uiId string
function UIManager:showUI(uiId)
    local info = self._openUIs[uiId]
    if not info then return end
    info.visible = true
    local ok, helper = pcall(function()
        return CS.SLGFramework.UIHelper.Instance
    end)
    if ok and helper then
        helper:ShowUI(uiId)
    end
end

---@param uiId string
---@return boolean
function UIManager:isUIOpen(uiId)
    return self._openUIs[uiId] ~= nil
end

----------------------------------------------------------------
-- Group operations
----------------------------------------------------------------

---Hide all UIs in a group.
---@param groupId string
function UIManager:hideGroup(groupId)
    local grp = self._groups[groupId]
    if not grp then return end
    for _, uiId in ipairs(grp) do
        self:hideUI(uiId)
    end
end

---Show all UIs in a group.
---@param groupId string
function UIManager:showGroup(groupId)
    local grp = self._groups[groupId]
    if not grp then return end
    for _, uiId in ipairs(grp) do
        self:showUI(uiId)
    end
end

---Close all UIs in a group.
---@param groupId string
function UIManager:closeGroup(groupId)
    local grp = self._groups[groupId]
    if not grp then return end
    -- Iterate in reverse because closeUI modifies the group array
    for i = #grp, 1, -1 do
        self:closeUI(grp[i])
    end
    self._groups[groupId] = nil
end

---Close all open UIs.
function UIManager:closeAll()
    for uiId, _ in pairs(self._openUIs) do
        self:closeUI(uiId)
    end
    self._groups = {}
end

return UIManager
