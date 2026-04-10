--- Logger.lua
--- 分级日志工具
--- 日志级别: DEBUG < INFO < WARN < ERROR，可通过 Logger.level 控制最低输出级别
---
--- 用法:
---   local log = Logger.get("ModeManager")
---   log:info("switched to %s", modeId)
---   log:warn("mode not found: %s", id)

local Logger = {}

--- 日志级别枚举
Logger.Level = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
    NONE  = 5,  -- 关闭所有输出
}

--- 全局最低输出级别（可在运行时修改）
Logger.level = Logger.Level.DEBUG

local LEVEL_NAMES = { [1] = "DEBUG", [2] = "INFO", [3] = "WARN", [4] = "ERROR" }

local function output(tag, lvl, fmt, ...)
    if lvl < Logger.level then return end
    local msg = string.format(fmt, ...)
    local label = LEVEL_NAMES[lvl] or "LOG"
    -- 优先使用 Unity 的 print（C# 层注入），回退到标准 print
    local printer = rawget(_G, "UnityLog") or print
    printer(string.format("[%s][%s] %s", label, tag, msg))
end

--- 获取一个带 tag 的 Logger 实例
---@param tag string  标签，通常为模块名
---@return table
function Logger.get(tag)
    tag = tag or "Global"
    return {
        debug = function(_, fmt, ...) output(tag, Logger.Level.DEBUG, fmt, ...) end,
        info  = function(_, fmt, ...) output(tag, Logger.Level.INFO,  fmt, ...) end,
        warn  = function(_, fmt, ...) output(tag, Logger.Level.WARN,  fmt, ...) end,
        error = function(_, fmt, ...) output(tag, Logger.Level.ERROR, fmt, ...) end,
    }
end

return Logger
