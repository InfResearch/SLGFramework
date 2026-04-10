local Class          = require("Framework.Core.Class")
local ModeBase       = require("Framework.Mode.ModeBase")
local BattleDef      = require("Framework.Battle.BattleDef")
local CampaignBattle = require("Framework.Battle.Battles.CampaignBattle")

---@class CampaignMode : ModeBase
---主线关卡战斗玩法.
---Entered from City or World with { stageId = N }.
---On win: player can retry, advance to next stage, or exit.
---On lose: player can retry or exit.
local CampaignMode = Class("CampaignMode", ModeBase)

local MODE_ID  = "campaign"
local SCENE_ID = "scene_battle"

function CampaignMode:getModeId()  return MODE_ID  end
function CampaignMode:getSceneId() return SCENE_ID end
function CampaignMode:isRetained() return false     end

function CampaignMode:onEnter(params)
    ModeBase.onEnter(self, params)
    self._params  = params or {}
    self._stageId = self._params.stageId or 1
    self._battle  = nil
    self:_startBattle()
end

function CampaignMode:onLeave()
    self:_destroyBattle()
    ModeBase.onLeave(self)
end

function CampaignMode:onDestroy()
    ModeBase.onDestroy(self)
end

function CampaignMode:onUpdate(dt)
    if self._battle and self._battle:isRunning() then
        self._battle:onUpdate(dt)
    end
end

----------------------------------------------------------------
-- Battle management
----------------------------------------------------------------

function CampaignMode:_startBattle()
    self._battle = CampaignBattle.new()
    self._battle:init({
        stageId = self._stageId,
    }, function(result) self:_onBattleFinish(result) end)
    self._battle:start()
end

function CampaignMode:_destroyBattle()
    if self._battle then
        self._battle:destroy()
        self._battle = nil
    end
end

---@param result table  BattleDef result
function CampaignMode:_onBattleFinish(result)
    -- This is where the result UI would be shown.
    -- The actual transition is triggered by player choice:
    --   retry  → self:retry()
    --   next   → self:nextStage()
    --   exit   → self:exit()
    -- Store result for external queries
    self._lastResult = result
end

----------------------------------------------------------------
-- Public actions (called from UI callbacks)
----------------------------------------------------------------

---Retry the current stage (replace self with a fresh instance).
function CampaignMode:retry()
    G_ModeManager:replaceMode(MODE_ID, { stageId = self._stageId })
end

---Advance to the next stage.
function CampaignMode:nextStage()
    local nextId = self._stageId + 1
    G_ModeManager:replaceMode(MODE_ID, { stageId = nextId })
end

---Exit campaign and return to the parent mode.
function CampaignMode:exit()
    G_ModeManager:popMode(self._lastResult)
end

return CampaignMode
