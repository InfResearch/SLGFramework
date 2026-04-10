--- RoomDungeonMode.lua
--- 房间副本模式（房间探索 + 战斗）
---
--- 流程:
---   进入副本 → 进入房间场景进行探索
---   遇到怪物 → 切换到 RoomDungeonBattleMode（当前模式 suspended 保留）
---   战斗结束（无论胜负）→ 返回本模式 resume → 将战斗结果反馈给房间对象
---   探索完成或主动退出 → 返回上一模式（城内/大地图）
---
--- retain = true：战斗结束后需要恢复房间状态，必须保留实例。

local ModeBase = require("Framework.Mode.ModeBase")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("RoomDungeonMode")

---@class RoomDungeonMode : ModeBase
local RoomDungeonMode = ModeBase:extend()

RoomDungeonMode.ID   = "room_dungeon"
RoomDungeonMode.TYPE = "room"  -- 供其他模式通过类型字符串引用

function RoomDungeonMode:init(config)
    config        = config or {}
    config.id     = RoomDungeonMode.ID
    config.name   = "RoomDungeon"
    -- 必须 retain=true，以便战斗结束后能恢复房间状态
    config.retain = true
    RoomDungeonMode.super.init(self, config)
    self.dungeonId  = nil
    self._roomState = nil  -- 房间运行时状态（由具体副本逻辑管理）
end

--- 进入房间副本
---@param fromMode ModeBase|nil
---@param params   table|nil  { dungeonId:string }
function RoomDungeonMode:enter(fromMode, params)
    RoomDungeonMode.super.enter(self, fromMode, params)
    params = params or {}
    assert(params.dungeonId, "RoomDungeonMode.enter: params.dungeonId is required")
    self.dungeonId  = params.dungeonId
    self._roomState = {}  -- 初始化房间状态
    log:info("enter dungeon=%s from [%s]", self.dungeonId, fromMode and fromMode.id or "none")

    -- TODO: 加载房间场景
    -- SceneManager:load("RoomScene", { dungeonId = self.dungeonId })
    -- RoomSystem:init(self.dungeonId, self._roomState)
    -- UIManager:show("RoomHUD")
end

--- 退出房间副本（探索完成或主动退出）
---@param toMode ModeBase|nil
function RoomDungeonMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    self._roomState = nil
    -- TODO: 卸载房间场景
    -- UIManager:hide("RoomHUD")
    -- SceneManager:unload("RoomScene")
    RoomDungeonMode.super.exit(self, toMode)
end

--- 暂停（进入战斗时）
---@param toMode ModeBase
function RoomDungeonMode:suspend(toMode)
    log:info("suspend to [%s]", toMode.id)
    -- TODO: 隐藏房间 UI，暂停房间逻辑（但保留场景）
    -- UIManager:hide("RoomHUD")
    -- RoomSystem:pause()
    RoomDungeonMode.super.suspend(self, toMode)
end

--- 从战斗返回恢复
---@param fromMode ModeBase
---@param params   table|nil  { battleResult: RoomDungeonBattleMode.Result, monsterId:string }
function RoomDungeonMode:resume(fromMode, params)
    RoomDungeonMode.super.resume(self, fromMode, params)
    log:info("resume from [%s]", fromMode and fromMode.id or "none")

    -- TODO: 恢复房间 UI 和逻辑
    -- UIManager:show("RoomHUD")
    -- RoomSystem:resume()

    -- 将战斗结果反馈给房间对象
    if params and params.battleResult then
        self:_applyBattleResult(params.battleResult, params.monsterId)
    end
end

--- 触发房间内怪物战斗
---@param monsterId  string  房间内怪物对象 id
---@param battleCfg  table   战斗配置
function RoomDungeonMode:startBattle(monsterId, battleCfg)
    log:info("start battle monsterId=%s", monsterId)
    G_ModeManager:switchTo(
        require("Modes.RoomDungeonBattleMode").ID,
        { monsterId = monsterId, battleCfg = battleCfg }
    )
end

--- 玩家主动退出房间副本
function RoomDungeonMode:quit()
    G_ModeManager:exitCurrent()
end

-- ─── 私有 ──────────────────────────────────────────────────────────────────

--- 将战斗结果应用到房间内的对象
---@param result    string  RoomDungeonBattleMode.Result
---@param monsterId string
function RoomDungeonMode:_applyBattleResult(result, monsterId)
    local RoomDungeonBattleMode = require("Modes.RoomDungeonBattleMode")
    log:info("apply battle result=%s monsterId=%s", result, monsterId or "?")

    if result == RoomDungeonBattleMode.Result.VICTORY then
        -- TODO: 标记怪物已击败，更新房间状态，触发掉落等
        -- RoomSystem:onMonsterDefeated(monsterId, self._roomState)
    elseif result == RoomDungeonBattleMode.Result.DEFEAT then
        -- TODO: 玩家失败，可能触发减少探索资源等惩罚
        -- RoomSystem:onPlayerDefeated(monsterId, self._roomState)
    end
end

return RoomDungeonMode
