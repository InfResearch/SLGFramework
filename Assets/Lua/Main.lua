--- Main.lua
--- 框架启动入口
---
--- 由 C# LuaManager 在游戏启动时调用: require("Main")
---
--- 职责:
---   1. 创建全局 ModeManager 单例（G_ModeManager）
---   2. 注册所有游戏模式
---   3. 启动初始模式（内城）

local ModeManager           = require("Framework.Mode.ModeManager")
local Logger                = require("Framework.Core.Logger")

local CityMode              = require("Modes.CityMode")
local WorldMode             = require("Modes.WorldMode")
local CampaignMode          = require("Modes.CampaignMode")
local NormalDungeonMode     = require("Modes.NormalDungeonMode")
local RoomDungeonMode       = require("Modes.RoomDungeonMode")
local RoomDungeonBattleMode = require("Modes.RoomDungeonBattleMode")
local ArenaMode             = require("Modes.ArenaMode")

local log = Logger.get("Main")

-- ─── 创建全局模式管理器 ────────────────────────────────────────────────────
---@type ModeManager
G_ModeManager = ModeManager.new()

-- ─── 注册游戏模式 ──────────────────────────────────────────────────────────
--
-- retain=true  : 切换离开时保留实例（suspend），回来时快速恢复
-- retain=false : 切换离开时销毁（exit），下次进入重新创建
--
G_ModeManager:register(CityMode.ID,              CityMode,              { retain = true  })
G_ModeManager:register(WorldMode.ID,             WorldMode,             { retain = true  })
G_ModeManager:register(CampaignMode.ID,          CampaignMode,          { retain = false })
G_ModeManager:register(NormalDungeonMode.ID,     NormalDungeonMode,     { retain = false })
G_ModeManager:register(RoomDungeonMode.ID,       RoomDungeonMode,       { retain = true  })
G_ModeManager:register(RoomDungeonBattleMode.ID, RoomDungeonBattleMode, { retain = false })
G_ModeManager:register(ArenaMode.ID,             ArenaMode,             { retain = false })

-- ─── 监听模式切换（示例：可在此接入场景/UI 全局管理） ─────────────────────
G_ModeManager:on(ModeManager.Events.BEFORE_SWITCH, function(from, to)
    log:info(">>> switch [%s] -> [%s]",
        from and from.id or "none",
        to   and to.id   or "none")
end)

G_ModeManager:on(ModeManager.Events.AFTER_SWITCH, function(from, to)
    log:info("<<< switch done, current=[%s]", to and to.id or "none")
end)

-- ─── 启动初始模式 ──────────────────────────────────────────────────────────
log:info("framework starting ...")
G_ModeManager:switchTo(CityMode.ID)
log:info("framework started, initial mode=[%s]", G_ModeManager:getCurrent().id)
