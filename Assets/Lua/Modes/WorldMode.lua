--- WorldMode.lua
--- 大地图模式（世界地图探索）
---
--- 玩家在大地图上移动、占领领地、探索资源点、发现副本入口等。
--- 从大地图可进入内城、主线关卡战斗、副本、竞技场等。
---
--- retain = true：保留实例，切回时快速恢复地图状态。

local ModeBase     = require("Framework.Mode.ModeBase")
local Logger       = require("Framework.Core.Logger")
local DungeonUtil  = require("Modes.DungeonUtil")

local log = Logger.get("WorldMode")

---@class WorldMode : ModeBase
local WorldMode = ModeBase:extend()

WorldMode.ID = "world"

function WorldMode:init(config)
    config        = config or {}
    config.id     = WorldMode.ID
    config.name   = "World"
    if config.retain == nil then config.retain = true end
    WorldMode.super.init(self, config)
end

--- 进入大地图模式
---@param fromMode ModeBase|nil
---@param params   table|nil   { focusPos: {x,y} }  进入后聚焦到的坐标（可选）
function WorldMode:enter(fromMode, params)
    WorldMode.super.enter(self, fromMode, params)
    log:info("enter from [%s]", fromMode and fromMode.id or "none")

    -- TODO: 加载大地图场景
    -- SceneManager:load("WorldScene")

    -- TODO: 显示大地图 HUD
    -- UIManager:show("WorldHUD")
    -- if params and params.focusPos then
    --     WorldCamera:focusOn(params.focusPos)
    -- end
end

--- 离开大地图
---@param toMode ModeBase|nil
function WorldMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    -- TODO: 隐藏大地图 UI，卸载场景
    -- UIManager:hideAll("WorldHUD")
    WorldMode.super.exit(self, toMode)
end

--- 暂停大地图（切换到其他模式）
---@param toMode ModeBase
function WorldMode:suspend(toMode)
    log:info("suspend to [%s]", toMode.id)
    -- TODO: 隐藏大地图 UI（保留场景状态）
    -- UIManager:hide("WorldHUD")
    WorldMode.super.suspend(self, toMode)
end

--- 恢复大地图
---@param fromMode ModeBase
---@param params   table|nil
function WorldMode:resume(fromMode, params)
    WorldMode.super.resume(self, fromMode, params)
    log:info("resume from [%s]", fromMode and fromMode.id or "none")
    -- TODO: 重新显示大地图 UI
    -- UIManager:show("WorldHUD")
end

--- 切换到内城
function WorldMode:enterCity()
    G_ModeManager:switchTo(require("Modes.CityMode").ID)
end

--- 从大地图进入主线关卡
---@param level number
function WorldMode:enterCampaign(level)
    G_ModeManager:switchTo(require("Modes.CampaignMode").ID, { level = level })
end

--- 从大地图进入副本
---@param dungeonId   string
---@param dungeonType string  "normal" | "room"
function WorldMode:enterDungeon(dungeonId, dungeonType)
    DungeonUtil.enterDungeon(dungeonId, dungeonType)
end

--- 从大地图进入竞技场
function WorldMode:enterArena()
    G_ModeManager:switchTo(require("Modes.ArenaMode").ID)
end

return WorldMode
