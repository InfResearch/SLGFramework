---=============================================================
--- Main.lua — Application entry point.
--- Initializes framework managers, registers all modes,
--- and starts the default game mode (City).
---=============================================================

-- Adjust the Lua package path so that require("Framework.X.Y") works.
-- In the actual project this would be configured by LuaManager/xLua.

----------------------------------------------------------------
-- 1. Require core modules
----------------------------------------------------------------
local ModeManager    = require("Framework.Mode.ModeManager")
local SceneManager   = require("Framework.Scene.SceneManager")
local UIManager      = require("Framework.UI.UIManager")

----------------------------------------------------------------
-- 2. Require mode classes
----------------------------------------------------------------
local CityMode          = require("Framework.Mode.Modes.CityMode")
local WorldMode         = require("Framework.Mode.Modes.WorldMode")
local CampaignMode      = require("Framework.Mode.Modes.CampaignMode")
local NormalDungeonMode  = require("Framework.Mode.Modes.NormalDungeonMode")
local RoomDungeonMode    = require("Framework.Mode.Modes.RoomDungeonMode")
local RoomBattleMode     = require("Framework.Mode.Modes.RoomBattleMode")
local ArenaMode          = require("Framework.Mode.Modes.ArenaMode")

----------------------------------------------------------------
-- 3. Create global manager instances
----------------------------------------------------------------
G_SceneManager = SceneManager.new()
G_UIManager    = UIManager.new()
G_ModeManager  = ModeManager.new()

-- Wire dependencies
G_ModeManager:setSceneManager(G_SceneManager)
G_ModeManager:setUIManager(G_UIManager)

----------------------------------------------------------------
-- 4. Register all modes
----------------------------------------------------------------
G_ModeManager:register("city",           CityMode)
G_ModeManager:register("world",          WorldMode)
G_ModeManager:register("campaign",       CampaignMode)
G_ModeManager:register("normal_dungeon", NormalDungeonMode)
G_ModeManager:register("room_dungeon",   RoomDungeonMode)
G_ModeManager:register("room_battle",    RoomBattleMode)
G_ModeManager:register("arena",          ArenaMode)

----------------------------------------------------------------
-- 5. Start the default mode
----------------------------------------------------------------
G_ModeManager:pushMode("city")

print("[Main] SLG Framework initialized. Current mode: " .. tostring(G_ModeManager:currentModeId()))

----------------------------------------------------------------
-- 6. Frame update (called by C# GameManager each frame)
----------------------------------------------------------------
function LuaUpdate(dt)
    G_ModeManager:update(dt)
end

---Called by C# when the application is quitting.
function LuaOnDestroy()
    -- Pop all modes to ensure orderly cleanup
    while G_ModeManager:stackDepth() > 0 do
        G_ModeManager:popMode()
    end
    G_ModeManager  = nil
    G_UIManager    = nil
    G_SceneManager = nil
end
