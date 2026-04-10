local Class    = require("Framework.Core.Class")
local ModeBase = require("Framework.Mode.ModeBase")

---@class WorldMode : ModeBase
---大地图玩法 — world map exploration and navigation.
---Retained for fast switching back.
local WorldMode = Class("WorldMode", ModeBase)

local MODE_ID  = "world"
local SCENE_ID = "scene_world"

function WorldMode:getModeId()  return MODE_ID  end
function WorldMode:getSceneId() return SCENE_ID end
function WorldMode:isRetained() return true      end

function WorldMode:onEnter(params)
    ModeBase.onEnter(self, params)
    -- Open world map UI
    -- G_UIManager:openUI("ui_world_main", nil, self:getUIGroup())
end

function WorldMode:onPause()
    ModeBase.onPause(self)
end

function WorldMode:onResume(result)
    ModeBase.onResume(self, result)
end

function WorldMode:onLeave()
    ModeBase.onLeave(self)
end

function WorldMode:onDestroy()
    ModeBase.onDestroy(self)
end

function WorldMode:onUpdate(dt)
    -- Map scrolling, troop movement, fog of war, etc.
end

return WorldMode
