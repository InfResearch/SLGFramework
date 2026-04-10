---Battle definitions and enumerations.

local BattleDef = {}

---Battle result status
BattleDef.Result = {
    NONE    = 0,
    WIN     = 1,
    LOSE    = 2,
    DRAW    = 3,
    FLEE    = 4,
}

---Battle state
BattleDef.State = {
    IDLE     = 0,
    RUNNING  = 1,
    PAUSED   = 2,
    FINISHED = 3,
}

---Create a standard battle result table.
---@param win boolean
---@param stageId? number
---@param rewards? table
---@param stats? table
---@return table
function BattleDef.makeResult(win, stageId, rewards, stats)
    return {
        status  = win and BattleDef.Result.WIN or BattleDef.Result.LOSE,
        win     = win,
        stageId = stageId,
        rewards = rewards or {},
        stats   = stats or {},
    }
end

return BattleDef
