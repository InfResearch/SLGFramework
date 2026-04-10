--- CityMode.lua
--- 内城模式（城内经营/管理界面）
---
--- 内城是游戏的主要根基地，玩家在此进行建筑、招募、科研等操作。
--- 从内城可进入大地图、主线关卡战斗、副本、竞技场等。
---
--- retain = true：切换到其他模式时暂停保留，快速恢复不需要重新加载场景。

local ModeBase     = require("Framework.Mode.ModeBase")
local Logger       = require("Framework.Core.Logger")
local DungeonUtil  = require("Modes.DungeonUtil")

local log = Logger.get("CityMode")

---@class CityMode : ModeBase
local CityMode = ModeBase:extend()

CityMode.ID = "city"

function CityMode:init(config)
    config        = config or {}
    config.id     = CityMode.ID
    config.name   = "City"
    -- 内城默认保留（快速切回）
    if config.retain == nil then config.retain = true end
    CityMode.super.init(self, config)
end

--- 进入内城模式
---@param fromMode ModeBase|nil
---@param params   table|nil   { showTab:string }  指定打开哪个功能标签（可选）
function CityMode:enter(fromMode, params)
    CityMode.super.enter(self, fromMode, params)
    log:info("enter from [%s]", fromMode and fromMode.id or "none")

    -- TODO: 加载内城场景
    -- SceneManager:load("CityScene")

    -- TODO: 显示内城 HUD 及默认界面
    -- UIManager:show("CityHUD")
    -- if params and params.showTab then
    --     UIManager:show("CityPanel", { tab = params.showTab })
    -- end
end

--- 离开内城模式（永久退出，通常不会发生）
---@param toMode ModeBase|nil
function CityMode:exit(toMode)
    log:info("exit to [%s]", toMode and toMode.id or "none")
    -- TODO: 隐藏内城 UI，卸载场景
    -- UIManager:hideAll("CityHUD", "CityPanel")
    CityMode.super.exit(self, toMode)
end

--- 暂停内城（切换到其他模式，内城保留在内存）
---@param toMode ModeBase
function CityMode:suspend(toMode)
    log:info("suspend to [%s]", toMode.id)
    -- TODO: 隐藏内城 UI，但不卸载场景（保留状态）
    -- UIManager:hide("CityHUD")
    -- UIManager:hide("CityPanel")
    CityMode.super.suspend(self, toMode)
end

--- 从暂停中恢复内城
---@param fromMode ModeBase
---@param params   table|nil
function CityMode:resume(fromMode, params)
    CityMode.super.resume(self, fromMode, params)
    log:info("resume from [%s]", fromMode and fromMode.id or "none")
    -- TODO: 恢复内城 UI
    -- UIManager:show("CityHUD")
    -- UIManager:show("CityPanel")
end

--- 从内城进入大地图
function CityMode:enterWorld()
    G_ModeManager:switchTo(require("Modes.WorldMode").ID)
end

--- 从内城进入主线关卡
---@param level number  关卡编号
function CityMode:enterCampaign(level)
    G_ModeManager:switchTo(require("Modes.CampaignMode").ID, { level = level })
end

--- 从内城进入副本
---@param dungeonId   string  副本配置 id
---@param dungeonType string  "normal" | "room"
function CityMode:enterDungeon(dungeonId, dungeonType)
    DungeonUtil.enterDungeon(dungeonId, dungeonType)
end

--- 从内城进入竞技场
function CityMode:enterArena()
    G_ModeManager:switchTo(require("Modes.ArenaMode").ID)
end

return CityMode
