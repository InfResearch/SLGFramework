--- DungeonUtil.lua
--- 副本相关的共享工具函数

local DungeonUtil = {}

--- 根据副本类型字符串解析对应的模式 ID
---@param dungeonId   string  副本配置 id
---@param dungeonType string  "normal" | "room"
function DungeonUtil.enterDungeon(dungeonId, dungeonType)
    local NormalDungeonMode = require("Modes.NormalDungeonMode")
    local RoomDungeonMode   = require("Modes.RoomDungeonMode")
    local targetId = (dungeonType == RoomDungeonMode.TYPE)
        and RoomDungeonMode.ID
        or  NormalDungeonMode.ID
    G_ModeManager:switchTo(targetId, { dungeonId = dungeonId })
end

return DungeonUtil
