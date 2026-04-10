local Class          = require("Framework.Core.Class")
local ModeBase       = require("Framework.Mode.ModeBase")
local BattleDef      = require("Framework.Battle.BattleDef")
local CampaignBattle = require("Framework.Battle.Battles.CampaignBattle")

---@class NormalDungeonMode : ModeBase
---普通副本玩法 — stage-based dungeon battles.
---Entered from City or World with { dungeonId, stageId }.
---On win: retry / next stage / exit.
---On lose: retry / exit.
local NormalDungeonMode = Class("NormalDungeonMode", ModeBase)

local MODE_ID  = "normal_dungeon"
local SCENE_ID = "scene_battle"

function NormalDungeonMode:getModeId()  return MODE_ID  end
function NormalDungeonMode:getSceneId() return SCENE_ID end
function NormalDungeonMode:isRetained() return false     end

function NormalDungeonMode:onEnter(params)
    ModeBase.onEnter(self, params)
    self._params    = params or {}
    self._dungeonId = self._params.dungeonId or 1
    self._stageId   = self._params.stageId or 1
    self._battle    = nil
    self:_startBattle()
end

function NormalDungeonMode:onLeave()
    self:_destroyBattle()
    ModeBase.onLeave(self)
end

function NormalDungeonMode:onDestroy()
    ModeBase.onDestroy(self)
end

function NormalDungeonMode:onUpdate(dt)
    if self._battle and self._battle:isRunning() then
        self._battle:onUpdate(dt)
    end
end

----------------------------------------------------------------
-- Battle management
----------------------------------------------------------------

function NormalDungeonMode:_startBattle()
    self._battle = CampaignBattle.new()
    self._battle:init({
        stageId   = self._stageId,
        dungeonId = self._dungeonId,
    }, function(result) self:_onBattleFinish(result) end)
    self._battle:start()
end

function NormalDungeonMode:_destroyBattle()
    if self._battle then
        self._battle:destroy()
        self._battle = nil
    end
end

function NormalDungeonMode:_onBattleFinish(result)
    self._lastResult = result
end

----------------------------------------------------------------
-- Public actions
----------------------------------------------------------------

function NormalDungeonMode:retry()
    G_ModeManager:replaceMode(MODE_ID, {
        dungeonId = self._dungeonId,
        stageId   = self._stageId,
    })
end

function NormalDungeonMode:nextStage()
    G_ModeManager:replaceMode(MODE_ID, {
        dungeonId = self._dungeonId,
        stageId   = self._stageId + 1,
    })
end

function NormalDungeonMode:exit()
    G_ModeManager:popMode(self._lastResult)
end

return NormalDungeonMode
