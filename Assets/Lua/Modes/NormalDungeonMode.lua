--- NormalDungeonMode.lua
--- 普通副本模式（按关卡直接进入战斗）
---
--- 流程:
---   进入副本 → 展示副本选关界面 → 进入某关战斗
---   战斗失败 → 显示失败界面 → [重试] / [返回]
---   战斗胜利 → 显示胜利界面 → [挑战下一关] / [返回]
---
--- retain = false：每次进入重新初始化。

local ModeBase = require("Framework.Mode.ModeBase")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("NormalDungeonMode")

---@class NormalDungeonMode : ModeBase
local NormalDungeonMode = ModeBase:extend()

NormalDungeonMode.ID   = "normal_dungeon"
NormalDungeonMode.TYPE = "normal"  -- 供其他模式通过类型字符串引用

--- 战斗结果枚举
NormalDungeonMode.Result = {
    VICTORY = "victory",
    DEFEAT  = "defeat",
}

function NormalDungeonMode:init(config)
    config        = config or {}
    config.id     = NormalDungeonMode.ID
    config.name   = "NormalDungeon"
    if config.retain == nil then config.retain = false end
    NormalDungeonMode.super.init(self, config)
    self.dungeonId    = nil
    self.currentLevel = 0
end

--- 进入普通副本
---@param fromMode ModeBase|nil
---@param params   table|nil  { dungeonId:string, level:number? }
function NormalDungeonMode:enter(fromMode, params)
    NormalDungeonMode.super.enter(self, fromMode, params)
    params = params or {}
    assert(params.dungeonId, "NormalDungeonMode.enter: params.dungeonId is required")
    self.dungeonId = params.dungeonId
    log:info("enter dungeon=%s from [%s]", self.dungeonId, fromMode and fromMode.id or "none")

    if params.level then
        -- 直接进入指定关
        self:_startLevel(params.level)
    else
        -- 展示副本选关/大厅界面
        self:_showLobby()
    end
end

--- 退出普通副本
---@param toMode ModeBase|nil
function NormalDungeonMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    -- TODO: 清理战斗场景、副本逻辑
    NormalDungeonMode.super.exit(self, toMode)
end

-- ─── 私有 ──────────────────────────────────────────────────────────────────

--- 显示副本大厅/选关界面
function NormalDungeonMode:_showLobby()
    -- TODO:
    -- UIManager:show("DungeonLobbyPanel", {
    --     dungeonId  = self.dungeonId,
    --     onEnterLv  = function(lv) self:_startLevel(lv) end,
    --     onReturn   = function() G_ModeManager:exitCurrent() end,
    -- })
end

--- 开始指定关卡
---@param level number
function NormalDungeonMode:_startLevel(level)
    self.currentLevel = level
    log:info("start level %d in dungeon %s", level, self.dungeonId)
    -- TODO:
    -- UIManager:hide("DungeonLobbyPanel")
    -- local cfg = DungeonConfig:getLevel(self.dungeonId, level)
    -- SceneManager:load("BattleScene", { levelId = cfg.sceneId })
    -- BattleSystem:start(cfg, function(result) self:_onBattleResult(result) end)
end

--- 战斗结果回调
---@param result string
function NormalDungeonMode:_onBattleResult(result)
    log:info("battle result=%s level=%d", result, self.currentLevel)
    if result == NormalDungeonMode.Result.VICTORY then
        self:_onVictory()
    else
        self:_onDefeat()
    end
end

--- 胜利 → 提供"下一关"/"返回大厅"选项
function NormalDungeonMode:_onVictory()
    -- TODO:
    -- UIManager:show("DungeonVictoryPanel", {
    --     onNext   = function() self:_startLevel(self.currentLevel + 1) end,
    --     onLobby  = function() self:_showLobby() end,
    --     onReturn = function() G_ModeManager:exitCurrent() end,
    -- })
end

--- 失败 → 提供"重试"/"返回大厅"选项
function NormalDungeonMode:_onDefeat()
    -- TODO:
    -- UIManager:show("DungeonDefeatPanel", {
    --     onRetry  = function() self:_startLevel(self.currentLevel) end,
    --     onLobby  = function() self:_showLobby() end,
    --     onReturn = function() G_ModeManager:exitCurrent() end,
    -- })
end

return NormalDungeonMode
