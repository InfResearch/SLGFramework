--- ArenaMode.lua
--- 竞技场战斗模式
---
--- 玩家从内城或大地图进入竞技场，与其他玩家（或 AI）进行 PvP 战斗。
---   - 战斗结束后显示结算界面（胜/负/平），之后返回上一模式
---   - 可连续进行多场对战，直到玩家主动离开
---
--- retain = false：竞技场会话结束后不保留实例。

local ModeBase = require("Framework.Mode.ModeBase")
local Logger   = require("Framework.Core.Logger")

local log = Logger.get("ArenaMode")

---@class ArenaMode : ModeBase
local ArenaMode = ModeBase:extend()

ArenaMode.ID = "arena"

--- 战斗结果枚举
ArenaMode.Result = {
    WIN  = "win",
    LOSE = "lose",
    DRAW = "draw",
}

function ArenaMode:init(config)
    config        = config or {}
    config.id     = ArenaMode.ID
    config.name   = "Arena"
    if config.retain == nil then config.retain = false end
    ArenaMode.super.init(self, config)
    self.matchCount = 0  -- 本次会话内进行的对战场数
end

--- 进入竞技场
---@param fromMode ModeBase|nil
---@param params   table|nil  { seasonId:string?, arenaType:string? }
function ArenaMode:enter(fromMode, params)
    ArenaMode.super.enter(self, fromMode, params)
    self.matchCount = 0
    log:info("enter from [%s]", fromMode and fromMode.id or "none")

    -- TODO: 加载竞技场场景，显示竞技场大厅
    -- SceneManager:load("ArenaScene")
    -- UIManager:show("ArenaHUD")
    -- ArenaSystem:init(params)
    self:_showLobby()
end

--- 退出竞技场
---@param toMode ModeBase|nil
function ArenaMode:exit(toMode)
    log:info("exit after %d match(es), to [%s]", self.matchCount, toMode and toMode.id or "none")
    -- TODO: 清理场景和逻辑
    -- UIManager:hide("ArenaHUD")
    -- SceneManager:unload("ArenaScene")
    ArenaMode.super.exit(self, toMode)
end

--- 玩家发起一场对战
---@param opponentId string  对手 id（玩家或 AI）
function ArenaMode:startMatch(opponentId)
    log:info("start match vs %s", opponentId)
    -- TODO:
    -- ArenaSystem:startMatch(opponentId, function(result)
    --     self:_onMatchResult(result, opponentId)
    -- end)
end

--- 玩家主动离开竞技场
function ArenaMode:quit()
    G_ModeManager:exitCurrent()
end

-- ─── 私有 ──────────────────────────────────────────────────────────────────

--- 显示竞技场大厅
function ArenaMode:_showLobby()
    -- TODO:
    -- UIManager:show("ArenaLobbyPanel", {
    --     onMatch  = function(opponentId) self:startMatch(opponentId) end,
    --     onReturn = function() self:quit() end,
    -- })
end

--- 对战结果回调
---@param result     string  ArenaMode.Result
---@param opponentId string
function ArenaMode:_onMatchResult(result, opponentId)
    self.matchCount = self.matchCount + 1
    log:info("match result=%s vs %s (total=%d)", result, opponentId, self.matchCount)
    -- TODO: 显示结算界面
    -- UIManager:show("ArenaResultPanel", {
    --     result      = result,
    --     opponentId  = opponentId,
    --     onNextMatch = function() self:_showLobby() end,
    --     onReturn    = function() self:quit() end,
    -- })
end

return ArenaMode
