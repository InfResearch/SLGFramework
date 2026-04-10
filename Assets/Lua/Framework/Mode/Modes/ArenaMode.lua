local Class       = require("Framework.Core.Class")
local ModeBase    = require("Framework.Mode.ModeBase")
local BattleDef   = require("Framework.Battle.BattleDef")
local ArenaBattle = require("Framework.Battle.Battles.ArenaBattle")

---@class ArenaMode : ModeBase
---竞技场玩法 — PvP arena battles.
---Entered from City or World with opponent info.
---Pops back with battle result on completion.
local ArenaMode = Class("ArenaMode", ModeBase)

local MODE_ID  = "arena"
local SCENE_ID = "scene_battle"

function ArenaMode:getModeId()  return MODE_ID  end
function ArenaMode:getSceneId() return SCENE_ID end
function ArenaMode:isRetained() return false     end

function ArenaMode:onEnter(params)
    ModeBase.onEnter(self, params)
    self._params     = params or {}
    self._opponentId = self._params.opponentId
    self._battle     = nil
    self:_startBattle()
end

function ArenaMode:onLeave()
    self:_destroyBattle()
    ModeBase.onLeave(self)
end

function ArenaMode:onDestroy()
    ModeBase.onDestroy(self)
end

function ArenaMode:onUpdate(dt)
    if self._battle and self._battle:isRunning() then
        self._battle:onUpdate(dt)
    end
end

----------------------------------------------------------------
-- Battle management
----------------------------------------------------------------

function ArenaMode:_startBattle()
    self._battle = ArenaBattle.new()
    self._battle:init({
        opponentId   = self._opponentId,
        opponentData = self._params.opponentData,
    }, function(result) self:_onBattleFinish(result) end)
    self._battle:start()
end

function ArenaMode:_destroyBattle()
    if self._battle then
        self._battle:destroy()
        self._battle = nil
    end
end

---@param result table
function ArenaMode:_onBattleFinish(result)
    self._lastResult = result
    -- Arena always pops back to parent on finish
    G_ModeManager:popMode(result)
end

return ArenaMode
