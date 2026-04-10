---=============================================================
--- test_framework.lua
--- Standalone tests for the SLG Framework Lua layer.
--- Run with: lua test_framework.lua  (from the Assets/Lua directory)
---=============================================================

-- Setup package path to find modules
local scriptDir = debug.getinfo(1, "S").source:match("@(.*/)")
if scriptDir then
    package.path = scriptDir .. "../?.lua;" .. package.path
end

local passed, failed = 0, 0

local function assert_eq(a, b, msg)
    if a == b then
        passed = passed + 1
    else
        failed = failed + 1
        print(string.format("  FAIL: %s — expected %s, got %s", msg or "?", tostring(b), tostring(a)))
    end
end

local function assert_true(v, msg)
    assert_eq(v, true, msg)
end

local function assert_false(v, msg)
    assert_eq(v, false, msg)
end

local function assert_nil(v, msg)
    assert_eq(v, nil, msg)
end

local function section(name)
    print(string.format("\n=== %s ===", name))
end

----------------------------------------------------------------
-- Stub global G_ModeManager (needed by mode implementations)
----------------------------------------------------------------
G_ModeManager  = nil
G_UIManager    = nil
G_SceneManager = nil

----------------------------------------------------------------
-- Test: Class system
----------------------------------------------------------------
section("Class")

local Class = require("Framework.Core.Class")

local Animal = Class("Animal")
function Animal:ctor(name)
    self.name = name
end
function Animal:speak()
    return "..."
end

local Dog = Class("Dog", Animal)
function Dog:ctor(name)
    Dog.super.ctor(self, name)
end
function Dog:speak()
    return "Woof"
end

local a = Animal.new("cat")
assert_eq(a.name, "cat", "Animal.name")
assert_eq(a:speak(), "...", "Animal:speak()")

local d = Dog.new("rex")
assert_eq(d.name, "rex", "Dog.name via super ctor")
assert_eq(d:speak(), "Woof", "Dog:speak() override")

assert_true(Animal.isInstance(a), "Animal.isInstance(a)")
assert_true(Dog.isInstance(d), "Dog.isInstance(d)")
assert_false(Dog.isInstance(a), "Dog.isInstance(a) should be false")

----------------------------------------------------------------
-- Test: EventDispatcher
----------------------------------------------------------------
section("EventDispatcher")

local EventDispatcher = require("Framework.Core.EventDispatcher")
local ed = EventDispatcher.new()

local received = {}
local function handler(val)
    table.insert(received, val)
end

ed:on("test", handler)
ed:emit("test", 42)
assert_eq(received[1], 42, "event received value")

ed:off("test", handler)
ed:emit("test", 99)
assert_eq(#received, 1, "event not received after off()")

-- offAll
ed:on("a", handler)
ed:on("b", handler)
ed:offAll()
ed:emit("a", 1)
ed:emit("b", 2)
assert_eq(#received, 1, "no events after offAll()")

----------------------------------------------------------------
-- Test: UIManager
----------------------------------------------------------------
section("UIManager")

local UIManager = require("Framework.UI.UIManager")
local ui = UIManager.new()

ui:openUI("hud", nil, "group1")
ui:openUI("minimap", nil, "group1")
ui:openUI("chat", nil, "group2")

assert_true(ui:isUIOpen("hud"), "hud is open")
assert_true(ui:isUIOpen("minimap"), "minimap is open")
assert_true(ui:isUIOpen("chat"), "chat is open")

ui:hideGroup("group1")
-- Still open but hidden
assert_true(ui:isUIOpen("hud"), "hud still exists after hide")

ui:closeGroup("group1")
assert_false(ui:isUIOpen("hud"), "hud closed after closeGroup")
assert_false(ui:isUIOpen("minimap"), "minimap closed after closeGroup")
assert_true(ui:isUIOpen("chat"), "chat unaffected")

ui:closeUI("chat")
assert_false(ui:isUIOpen("chat"), "chat closed")

----------------------------------------------------------------
-- Test: SceneManager
----------------------------------------------------------------
section("SceneManager")

local SceneManager = require("Framework.Scene.SceneManager")
local sm = SceneManager.new()

assert_nil(sm:getCurrentSceneId(), "initial scene nil")
assert_false(sm:isLoading(), "not loading initially")

-- Load (fallback path since no C# runtime)
sm:loadScene("scene_city", function(ok)
    assert_true(ok, "loadScene callback ok")
end)
assert_eq(sm:getCurrentSceneId(), "scene_city", "current scene after load")

-- Load same scene — should be instant / no-op
sm:loadScene("scene_city", function(ok)
    assert_true(ok, "same scene no-op")
end)

-- Load different scene
sm:loadScene("scene_battle")
assert_eq(sm:getCurrentSceneId(), "scene_battle", "scene changed to battle")

-- Unload
sm:unloadScene("scene_battle")
assert_nil(sm:getCurrentSceneId(), "scene nil after unload")

----------------------------------------------------------------
-- Test: BattleDef
----------------------------------------------------------------
section("BattleDef")

local BattleDef = require("Framework.Battle.BattleDef")

local r = BattleDef.makeResult(true, 5, { gold = 100 })
assert_true(r.win, "result.win")
assert_eq(r.status, BattleDef.Result.WIN, "result.status WIN")
assert_eq(r.stageId, 5, "result.stageId")
assert_eq(r.rewards.gold, 100, "result.rewards.gold")

local r2 = BattleDef.makeResult(false, 3)
assert_false(r2.win, "lose result.win")
assert_eq(r2.status, BattleDef.Result.LOSE, "lose status")

----------------------------------------------------------------
-- Test: BattleBase lifecycle
----------------------------------------------------------------
section("BattleBase")

local BattleBase = require("Framework.Battle.BattleBase")

local b = BattleBase.new()
assert_eq(b:getState(), BattleDef.State.IDLE, "initial state IDLE")

local finishResult = nil
b:init({ stageId = 1 }, function(res) finishResult = res end)
assert_eq(b:getState(), BattleDef.State.IDLE, "still IDLE after init")

b:start()
assert_eq(b:getState(), BattleDef.State.RUNNING, "RUNNING after start")
assert_true(b:isRunning(), "isRunning true")

b:pause()
assert_eq(b:getState(), BattleDef.State.PAUSED, "PAUSED after pause")

b:resume()
assert_eq(b:getState(), BattleDef.State.RUNNING, "RUNNING after resume")

local res = BattleDef.makeResult(true, 1)
b:finish(res)
assert_eq(b:getState(), BattleDef.State.FINISHED, "FINISHED after finish")
assert_true(finishResult.win, "onFinish callback received result")

b:destroy()
assert_nil(b:getConfig(), "config nil after destroy")

----------------------------------------------------------------
-- Test: ModeBase
----------------------------------------------------------------
section("ModeBase")

local ModeBase = require("Framework.Mode.ModeBase")

-- ModeBase is abstract, create a concrete subclass for testing
local TestMode = Class("TestMode", ModeBase)
function TestMode:getModeId() return "test" end
function TestMode:getSceneId() return nil end
function TestMode:isRetained() return false end

local tm = TestMode.new()
assert_false(tm:isActive(), "not active before onEnter")
tm:onEnter()
assert_true(tm:isActive(), "active after onEnter")
tm:onPause()
assert_true(tm:isPaused(), "paused after onPause")
assert_false(tm:isActive(), "not active while paused")
tm:onResume()
assert_false(tm:isPaused(), "not paused after onResume")
assert_true(tm:isActive(), "active after onResume")
tm:onLeave()
assert_false(tm:isActive(), "not active after onLeave")

----------------------------------------------------------------
-- Test: ModeManager — basic stack operations
----------------------------------------------------------------
section("ModeManager — push / pop / replace")

local ModeManager = require("Framework.Mode.ModeManager")

-- Create concrete test modes
local ModeA = Class("ModeA", ModeBase)
function ModeA:getModeId() return "modeA" end
function ModeA:isRetained() return true end

local ModeB = Class("ModeB", ModeBase)
function ModeB:getModeId() return "modeB" end
function ModeB:isRetained() return false end

local ModeC = Class("ModeC", ModeBase)
function ModeC:getModeId() return "modeC" end
function ModeC:isRetained() return false end

local mm = ModeManager.new()
-- Stub as global for mode implementations
G_ModeManager = mm

mm:register("modeA", ModeA)
mm:register("modeB", ModeB)
mm:register("modeC", ModeC)

-- Push A
mm:pushMode("modeA")
assert_eq(mm:currentModeId(), "modeA", "current is modeA")
assert_eq(mm:stackDepth(), 1, "stack depth 1")

-- Push B on top of A
mm:pushMode("modeB")
assert_eq(mm:currentModeId(), "modeB", "current is modeB")
assert_eq(mm:stackDepth(), 2, "stack depth 2")
assert_true(mm:isInStack("modeA"), "modeA in stack")

-- Pop B → back to A
mm:popMode({ score = 100 })
assert_eq(mm:currentModeId(), "modeA", "back to modeA after pop")
assert_eq(mm:stackDepth(), 1, "stack depth 1 after pop")

-- Replace A with C
mm:replaceMode("modeC")
assert_eq(mm:currentModeId(), "modeC", "replaced with modeC")
assert_eq(mm:stackDepth(), 1, "stack depth still 1 after replace")

-- Pop C → empty
mm:popMode()
assert_nil(mm:currentModeId(), "no mode after final pop")
assert_eq(mm:stackDepth(), 0, "stack empty")

----------------------------------------------------------------
-- Test: ModeManager — retain cache
----------------------------------------------------------------
section("ModeManager — retain cache")

local mm2 = ModeManager.new()
G_ModeManager = mm2
mm2:register("modeA", ModeA)
mm2:register("modeB", ModeB)

mm2:pushMode("modeA")
local instA = mm2:currentMode()
assert_eq(instA:getModeId(), "modeA", "instA is modeA")

-- Push B → A is retained
mm2:pushMode("modeB")
assert_true(instA:isPaused(), "instA paused after push")

-- Pop B → A should be the SAME instance (retained)
mm2:popMode()
local instA2 = mm2:currentMode()
assert_eq(instA2, instA, "same instance after retain+resume (not recreated)")

-- Clean up
mm2:popMode()

----------------------------------------------------------------
-- Test: ModeManager — popAndPush
----------------------------------------------------------------
section("ModeManager — popAndPush")

local mm3 = ModeManager.new()
G_ModeManager = mm3
mm3:register("modeA", ModeA)
mm3:register("modeB", ModeB)
mm3:register("modeC", ModeC)

mm3:pushMode("modeA")
mm3:pushMode("modeB")
assert_eq(mm3:stackDepth(), 2, "depth 2 before popAndPush")

-- Pop B and push C (instead of resuming A)
mm3:popAndPush("modeC")
assert_eq(mm3:currentModeId(), "modeC", "current is modeC after popAndPush")
assert_eq(mm3:stackDepth(), 2, "depth 2 — A still under C")
assert_true(mm3:isInStack("modeA"), "modeA still in stack")

mm3:popMode()
assert_eq(mm3:currentModeId(), "modeA", "back to modeA")
mm3:popMode()

----------------------------------------------------------------
-- Test: ModeManager — popToMode
----------------------------------------------------------------
section("ModeManager — popToMode")

local mm4 = ModeManager.new()
G_ModeManager = mm4
mm4:register("modeA", ModeA)
mm4:register("modeB", ModeB)
mm4:register("modeC", ModeC)

mm4:pushMode("modeA")
mm4:pushMode("modeB")
mm4:pushMode("modeC")
assert_eq(mm4:stackDepth(), 3, "depth 3")

mm4:popToMode("modeA", { info = "jumped" })
assert_eq(mm4:currentModeId(), "modeA", "popToMode lands on modeA")
assert_eq(mm4:stackDepth(), 1, "depth 1 after popToMode")

mm4:popMode()

----------------------------------------------------------------
-- Test: ModeManager — events
----------------------------------------------------------------
section("ModeManager — events")

local mm5 = ModeManager.new()
G_ModeManager = mm5
mm5:register("modeA", ModeA)
mm5:register("modeB", ModeB)

local events = {}
mm5:on("mode_enter", function(id) table.insert(events, "enter:" .. id) end)
mm5:on("mode_pause", function(id) table.insert(events, "pause:" .. id) end)
mm5:on("mode_resume", function(id) table.insert(events, "resume:" .. id) end)
mm5:on("mode_leave", function(id) table.insert(events, "leave:" .. id) end)

mm5:pushMode("modeA")
mm5:pushMode("modeB")
mm5:popMode()
mm5:popMode()

assert_eq(events[1], "enter:modeA", "event 1")
assert_eq(events[2], "pause:modeA", "event 2")
assert_eq(events[3], "enter:modeB", "event 3")
assert_eq(events[4], "leave:modeB", "event 4")
assert_eq(events[5], "resume:modeA", "event 5")
assert_eq(events[6], "leave:modeA", "event 6")

----------------------------------------------------------------
-- Test: Full gameplay flow simulation
----------------------------------------------------------------
section("Gameplay Flow — City → Campaign → retry → next → exit")

-- Reset globals
local UIManager2 = require("Framework.UI.UIManager")
G_UIManager = UIManager2.new()

local ModeManager2 = require("Framework.Mode.ModeManager")
G_ModeManager = ModeManager2.new()
G_ModeManager:setUIManager(G_UIManager)

-- Register real mode classes
local CityMode2     = require("Framework.Mode.Modes.CityMode")
local CampaignMode2 = require("Framework.Mode.Modes.CampaignMode")
G_ModeManager:register("city", CityMode2)
G_ModeManager:register("campaign", CampaignMode2)

-- Enter city
G_ModeManager:pushMode("city")
assert_eq(G_ModeManager:currentModeId(), "city", "flow: in city")

-- Enter campaign stage 1 from city
G_ModeManager:pushMode("campaign", { stageId = 1 })
assert_eq(G_ModeManager:currentModeId(), "campaign", "flow: in campaign")
assert_eq(G_ModeManager:stackDepth(), 2, "flow: depth 2")

-- Simulate battle lose → retry (replaceMode)
local camp = G_ModeManager:currentMode()
camp._lastResult = BattleDef.makeResult(false, 1)
camp:retry()
assert_eq(G_ModeManager:currentModeId(), "campaign", "flow: still campaign after retry")
assert_eq(G_ModeManager:stackDepth(), 2, "flow: depth 2 after retry")

-- Simulate battle win → next stage
camp = G_ModeManager:currentMode()
camp._lastResult = BattleDef.makeResult(true, 1)
camp:nextStage()
assert_eq(G_ModeManager:currentModeId(), "campaign", "flow: campaign next stage")

-- Exit campaign → back to city
camp = G_ModeManager:currentMode()
camp._lastResult = BattleDef.makeResult(true, 2)
camp:exit()
assert_eq(G_ModeManager:currentModeId(), "city", "flow: back to city")
assert_eq(G_ModeManager:stackDepth(), 1, "flow: depth 1")

G_ModeManager:popMode()

----------------------------------------------------------------
-- Test: Room Dungeon flow
----------------------------------------------------------------
section("Gameplay Flow — City → RoomDungeon → Battle → back")

G_ModeManager = ModeManager2.new()
G_ModeManager:setUIManager(G_UIManager)

local RoomDungeonMode2 = require("Framework.Mode.Modes.RoomDungeonMode")
local RoomBattleMode2  = require("Framework.Mode.Modes.RoomBattleMode")

G_ModeManager:register("city", CityMode2)
G_ModeManager:register("room_dungeon", RoomDungeonMode2)
G_ModeManager:register("room_battle", RoomBattleMode2)

G_ModeManager:pushMode("city")
G_ModeManager:pushMode("room_dungeon", { dungeonId = 10 })
assert_eq(G_ModeManager:currentModeId(), "room_dungeon", "room: in dungeon")

-- Encounter a monster → push battle
local rd = G_ModeManager:currentMode()
rd:enterBattle({ encounterId = 42, enemyData = {} })
assert_eq(G_ModeManager:currentModeId(), "room_battle", "room: in battle")
assert_eq(G_ModeManager:stackDepth(), 3, "room: depth 3")

-- Simulate battle finish → pops back to room
local rb = G_ModeManager:currentMode()
local battleResult = BattleDef.makeResult(true, nil)
rb._battle:finish(battleResult)

assert_eq(G_ModeManager:currentModeId(), "room_dungeon", "room: back in dungeon")
assert_eq(G_ModeManager:stackDepth(), 2, "room: depth 2")

-- Check battle result was applied to room state
local rdAfter = G_ModeManager:currentMode()
assert_true(rdAfter._roomState[42] ~= nil, "room: encounter 42 recorded")
assert_true(rdAfter._roomState[42].cleared, "room: encounter 42 cleared")

-- Exit dungeon → back to city
rdAfter:exit()
assert_eq(G_ModeManager:currentModeId(), "city", "room: back to city")

G_ModeManager:popMode()

----------------------------------------------------------------
-- Summary
----------------------------------------------------------------
print(string.format("\n========================================"))
print(string.format("  Results: %d passed, %d failed", passed, failed))
print(string.format("========================================"))

if failed > 0 then
    os.exit(1)
end
