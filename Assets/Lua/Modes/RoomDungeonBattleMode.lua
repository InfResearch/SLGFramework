--- RoomDungeonBattleMode.lua
--- 房间副本内的战斗模式
---
--- 由 RoomDungeonMode 在遭遇怪物时触发切换。
--- 战斗结束（胜利或失败）都自动返回 RoomDungeonMode，并将结果作为参数传回。
---
--- retain = false：战斗结束后立即销毁，不保留实例。

local ModeBase = require("Framework.Mode.ModeBase")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("RoomDungeonBattleMode")

---@class RoomDungeonBattleMode : ModeBase
local RoomDungeonBattleMode = ModeBase:extend()

RoomDungeonBattleMode.ID = "room_dungeon_battle"

--- 战斗结果枚举
RoomDungeonBattleMode.Result = {
    VICTORY = "victory",
    DEFEAT  = "defeat",
}

function RoomDungeonBattleMode:init(config)
    config        = config or {}
    config.id     = RoomDungeonBattleMode.ID
    config.name   = "RoomDungeonBattle"
    config.retain = false
    RoomDungeonBattleMode.super.init(self, config)
    self.monsterId = nil
    self.battleCfg = nil
end

--- 进入战斗
---@param fromMode ModeBase|nil  通常是 RoomDungeonMode
---@param params   table|nil     { monsterId:string, battleCfg:table }
function RoomDungeonBattleMode:enter(fromMode, params)
    RoomDungeonBattleMode.super.enter(self, fromMode, params)
    params = params or {}
    assert(params.monsterId, "RoomDungeonBattleMode.enter: params.monsterId is required")
    self.monsterId = params.monsterId
    self.battleCfg = params.battleCfg
    log:info("enter battle monsterId=%s from [%s]", self.monsterId, fromMode and fromMode.id or "none")

    -- TODO: 加载战斗场景（通常是叠加在房间场景上的）
    -- SceneManager:load("BattleScene", { cfg = self.battleCfg })
    -- BattleSystem:start(self.battleCfg, function(result)
    --     self:_onBattleResult(result)
    -- end)
end

--- 退出战斗
---@param toMode ModeBase|nil
function RoomDungeonBattleMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    -- TODO: 卸载战斗场景
    -- SceneManager:unload("BattleScene")
    RoomDungeonBattleMode.super.exit(self, toMode)
end

-- ─── 私有 ──────────────────────────────────────────────────────────────────

--- 战斗系统调用此接口报告结果，然后返回房间
---@param result string  RoomDungeonBattleMode.Result.VICTORY | DEFEAT
function RoomDungeonBattleMode:_onBattleResult(result)
    log:info("battle result=%s monsterId=%s", result, self.monsterId)
    -- 无论胜败都返回房间，将结果作为 params 传回 RoomDungeonMode:resume
    G_ModeManager:exitCurrent({
        battleResult = result,
        monsterId    = self.monsterId,
    })
end

return RoomDungeonBattleMode
