local Class      = require("Framework.Core.Class")
local BattleBase = require("Framework.Battle.BattleBase")

---@class ArenaBattle : BattleBase
---Battle used in Arena (竞技场) PvP mode.
---Config: { opponentId, opponentData, ... }
local ArenaBattle = Class("ArenaBattle", BattleBase)

function ArenaBattle:onInit(config)
    self._opponentId = config.opponentId
    -- Load opponent data, prepare PvP-specific rules
end

function ArenaBattle:onStart()
    -- Begin PvP battle
end

function ArenaBattle:onUpdate(dt)
    -- Tick PvP battle simulation
end

function ArenaBattle:onDestroy()
    -- Clean up
end

return ArenaBattle
