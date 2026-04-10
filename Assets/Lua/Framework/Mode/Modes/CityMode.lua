local Class    = require("Framework.Core.Class")
local ModeBase = require("Framework.Mode.ModeBase")

---@class CityMode : ModeBase
---内城玩法 — the main city management mode.
---Retained to avoid expensive reload when returning from other modes.
local CityMode = Class("CityMode", ModeBase)

local MODE_ID  = "city"
local SCENE_ID = "scene_city"

function CityMode:getModeId()  return MODE_ID  end
function CityMode:getSceneId() return SCENE_ID end
function CityMode:isRetained() return true      end

function CityMode:onEnter(params)
    ModeBase.onEnter(self, params)
    -- Open city UI panels
    -- G_UIManager:openUI("ui_city_main", nil, self:getUIGroup())
end

function CityMode:onPause()
    ModeBase.onPause(self)
end

function CityMode:onResume(result)
    ModeBase.onResume(self, result)
    -- Handle results from sub-modes (e.g. campaign victory rewards)
end

function CityMode:onLeave()
    ModeBase.onLeave(self)
end

function CityMode:onDestroy()
    ModeBase.onDestroy(self)
end

function CityMode:onUpdate(dt)
    -- City idle animations, build timers, etc.
end

return CityMode
