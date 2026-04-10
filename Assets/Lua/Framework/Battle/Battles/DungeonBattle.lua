local Class      = require("Framework.Core.Class")
local BattleBase = require("Framework.Battle.BattleBase")

---@class DungeonBattle : BattleBase
---Battle used in RoomDungeon (房间副本) combat encounters.
---Config: { encounterId, enemyData, roomContext, ... }
local DungeonBattle = Class("DungeonBattle", BattleBase)

function DungeonBattle:onInit(config)
    self._encounterId = config.encounterId
    -- Initialize encounter-specific data
end

function DungeonBattle:onStart()
    -- Begin dungeon encounter battle
end

function DungeonBattle:onUpdate(dt)
    -- Tick battle simulation
end

function DungeonBattle:onDestroy()
    -- Clean up
end

return DungeonBattle
