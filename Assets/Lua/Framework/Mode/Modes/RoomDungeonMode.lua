local Class    = require("Framework.Core.Class")
local ModeBase = require("Framework.Mode.ModeBase")

---@class RoomDungeonMode : ModeBase
---房间副本玩法 — enter a dungeon room for exploration.
---Encounters trigger a push to RoomBattleMode.
---Retained because the player frequently goes to battle and back.
local RoomDungeonMode = Class("RoomDungeonMode", ModeBase)

local MODE_ID  = "room_dungeon"
local SCENE_ID = "scene_room_dungeon"

function RoomDungeonMode:getModeId()  return MODE_ID  end
function RoomDungeonMode:getSceneId() return SCENE_ID end
function RoomDungeonMode:isRetained() return true      end

function RoomDungeonMode:onEnter(params)
    ModeBase.onEnter(self, params)
    self._params    = params or {}
    self._dungeonId = self._params.dungeonId or 1
    self._roomState = {}  -- track encounter results, chests, etc.
    -- Load room layout, spawn objects
    -- G_UIManager:openUI("ui_room_dungeon", nil, self:getUIGroup())
end

function RoomDungeonMode:onPause()
    ModeBase.onPause(self)
    -- Room exploration paused while in battle
end

function RoomDungeonMode:onResume(result)
    ModeBase.onResume(self, result)
    -- Apply battle result to room objects
    if result then
        self:_applyBattleResult(result)
    end
end

function RoomDungeonMode:onLeave()
    ModeBase.onLeave(self)
end

function RoomDungeonMode:onDestroy()
    ModeBase.onDestroy(self)
    self._roomState = nil
end

function RoomDungeonMode:onUpdate(dt)
    -- Room exploration logic, player movement, interactions
end

----------------------------------------------------------------
-- Room interactions
----------------------------------------------------------------

---Called when the player encounters a monster in the room.
---@param encounterConfig table  { encounterId, enemyData, ... }
function RoomDungeonMode:enterBattle(encounterConfig)
    G_ModeManager:pushMode("room_battle", encounterConfig)
end

---Exit the dungeon and return to the parent mode.
function RoomDungeonMode:exit()
    G_ModeManager:popMode({ dungeonId = self._dungeonId, roomState = self._roomState })
end

----------------------------------------------------------------
-- Internal
----------------------------------------------------------------

---Apply battle result to room state (e.g. remove defeated monster, unlock chest).
---@param result table
function RoomDungeonMode:_applyBattleResult(result)
    if not result then return end
    local encounterId = result.encounterId
    if encounterId then
        self._roomState[encounterId] = {
            cleared = result.win,
            result  = result,
        }
    end
    -- Subclasses or config-driven logic can extend this
end

return RoomDungeonMode
