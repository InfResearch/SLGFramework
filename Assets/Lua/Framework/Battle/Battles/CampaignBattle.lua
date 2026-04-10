local Class      = require("Framework.Core.Class")
local BattleBase = require("Framework.Battle.BattleBase")

---@class CampaignBattle : BattleBase
---Battle used in Campaign (主线关卡) and NormalDungeon modes.
---Config: { stageId, enemyData, ... }
local CampaignBattle = Class("CampaignBattle", BattleBase)

function CampaignBattle:onInit(config)
    self._stageId = config.stageId
    -- Load stage-specific enemy data, terrain, etc.
end

function CampaignBattle:onStart()
    -- Begin turn-based or real-time battle logic
end

function CampaignBattle:onUpdate(dt)
    -- Tick battle simulation
end

function CampaignBattle:onDestroy()
    -- Clean up battle resources
end

return CampaignBattle
