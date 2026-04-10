local Class         = require("Framework.Core.Class")
local ModeBase      = require("Framework.Mode.ModeBase")
local BattleDef     = require("Framework.Battle.BattleDef")
local DungeonBattle = require("Framework.Battle.Battles.DungeonBattle")

---@class RoomBattleMode : ModeBase
---房间副本战斗玩法 — combat triggered from a room dungeon encounter.
---Always pops back to RoomDungeonMode with the battle result.
local RoomBattleMode = Class("RoomBattleMode", ModeBase)

local MODE_ID  = "room_battle"
local SCENE_ID = "scene_battle"

function RoomBattleMode:getModeId()  return MODE_ID  end
function RoomBattleMode:getSceneId() return SCENE_ID end
function RoomBattleMode:isRetained() return false     end

function RoomBattleMode:onEnter(params)
    ModeBase.onEnter(self, params)
    self._params      = params or {}
    self._encounterId = self._params.encounterId
    self._battle      = nil
    self:_startBattle()
end

function RoomBattleMode:onLeave()
    self:_destroyBattle()
    ModeBase.onLeave(self)
end

function RoomBattleMode:onDestroy()
    ModeBase.onDestroy(self)
end

function RoomBattleMode:onUpdate(dt)
    if self._battle and self._battle:isRunning() then
        self._battle:onUpdate(dt)
    end
end

----------------------------------------------------------------
-- Battle management
----------------------------------------------------------------

function RoomBattleMode:_startBattle()
    self._battle = DungeonBattle.new()
    self._battle:init({
        encounterId = self._encounterId,
        enemyData   = self._params.enemyData,
    }, function(result) self:_onBattleFinish(result) end)
    self._battle:start()
end

function RoomBattleMode:_destroyBattle()
    if self._battle then
        self._battle:destroy()
        self._battle = nil
    end
end

---@param result table
function RoomBattleMode:_onBattleFinish(result)
    -- Attach encounter id so the room can identify which encounter was resolved
    result.encounterId = self._encounterId
    -- Always pop back to the room dungeon, regardless of win/lose
    G_ModeManager:popMode(result)
end

return RoomBattleMode
