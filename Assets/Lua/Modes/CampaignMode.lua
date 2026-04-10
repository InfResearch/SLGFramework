--- CampaignMode.lua
--- 主线关卡战斗模式
---
--- 玩家从内城或大地图进入，按关卡顺序挑战主线战斗。
---   - 战斗失败：弹出失败界面，可选择 [重试本关] 或 [返回]
---   - 战斗胜利：弹出胜利界面，可选择 [挑战下一关] 或 [返回]
---
--- retain = false：战斗结束后不保留，每次进入重新初始化。

local ModeBase = require("Framework.Mode.ModeBase")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("CampaignMode")

---@class CampaignMode : ModeBase
local CampaignMode = ModeBase:extend()

CampaignMode.ID = "campaign"

--- 战斗结果枚举
CampaignMode.Result = {
    VICTORY = "victory",
    DEFEAT  = "defeat",
}

function CampaignMode:init(config)
    config        = config or {}
    config.id     = CampaignMode.ID
    config.name   = "Campaign"
    if config.retain == nil then config.retain = false end
    CampaignMode.super.init(self, config)
    self.currentLevel = 0
end

--- 进入主线关卡战斗
---@param fromMode ModeBase|nil
---@param params   table|nil   { level:number }  关卡编号（必须）
function CampaignMode:enter(fromMode, params)
    CampaignMode.super.enter(self, fromMode, params)
    params = params or {}
    assert(params.level, "CampaignMode.enter: params.level is required")
    log:info("enter level=%d from [%s]", params.level, fromMode and fromMode.id or "none")
    self:_startLevel(params.level)
end

--- 退出关卡战斗模式（返回上一模式）
---@param toMode ModeBase|nil
function CampaignMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    -- TODO: 卸载战斗场景，清理战斗逻辑
    -- SceneManager:unload("BattleScene")
    -- BattleSystem:cleanup()
    CampaignMode.super.exit(self, toMode)
end

-- ─── 私有 ──────────────────────────────────────────────────────────────────

--- 加载并开始指定关卡
---@param level number
function CampaignMode:_startLevel(level)
    self.currentLevel = level
    log:info("start level %d", level)

    -- TODO: 加载关卡配置
    -- local cfg = CampaignConfig:get(level)
    -- assert(cfg, "campaign level not found: " .. level)

    -- TODO: 加载战斗场景，初始化战斗逻辑
    -- SceneManager:load("BattleScene", { levelId = cfg.sceneId })
    -- BattleSystem:start(cfg, function(result) self:_onBattleResult(result) end)
end

--- 战斗结果回调（由战斗系统调用）
---@param result string  CampaignMode.Result.VICTORY | DEFEAT
function CampaignMode:_onBattleResult(result)
    log:info("battle result=%s level=%d", result, self.currentLevel)
    if result == CampaignMode.Result.VICTORY then
        self:_onVictory()
    else
        self:_onDefeat()
    end
end

--- 胜利处理：显示胜利 UI，提供"下一关"或"返回"选项
function CampaignMode:_onVictory()
    -- TODO:
    -- UIManager:show("CampaignVictoryPanel", {
    --     level    = self.currentLevel,
    --     onNext   = function() self:_startLevel(self.currentLevel + 1) end,
    --     onReturn = function() G_ModeManager:exitCurrent() end,
    -- })
end

--- 失败处理：显示失败 UI，提供"重试"或"返回"选项
function CampaignMode:_onDefeat()
    -- TODO:
    -- UIManager:show("CampaignDefeatPanel", {
    --     level   = self.currentLevel,
    --     onRetry = function() self:_startLevel(self.currentLevel) end,
    --     onQuit  = function() G_ModeManager:exitCurrent() end,
    -- })
end

return CampaignMode
