# SLG游戏玩法框架 (SLGFramework)

基于 **Unity + xLua** 的SLG类型游戏玩法框架。核心逻辑在Lua层实现，C#层仅提供通用工具接口。

## 架构总览

```
┌──────────────────────────────────────────┐
│               Main.lua                   │
│          (入口 & 初始化注册)              │
├──────────────────────────────────────────┤
│             ModeManager                  │
│      (玩法栈管理 & 生命周期调度)          │
├──────────┬──────────┬────────────────────┤
│ CityMode │WorldMode │ CampaignMode ...   │
│          │          │   (具体玩法实现)    │
├──────────┴──────────┴────────────────────┤
│   BattleBase / BattleDef                 │
│      (战斗系统，被战斗类玩法使用)         │
├──────────────────────────────────────────┤
│    SceneManager    │     UIManager       │
│   (独立场景管理)    │   (独立UI管理)      │
├──────────────────────────────────────────┤
│               C# Layer                   │
│  LuaManager / GameManager / SceneLoader  │
└──────────────────────────────────────────┘
```

## 目录结构

```
Assets/
  Lua/
    Main.lua                              -- Lua入口
    Framework/
      Core/
        Class.lua                         -- OOP基类
        EventDispatcher.lua               -- 事件系统
      Mode/
        ModeBase.lua                      -- 玩法基类
        ModeManager.lua                   -- 玩法栈管理器
        Modes/
          CityMode.lua                    -- 内城
          WorldMode.lua                   -- 大地图
          CampaignMode.lua                -- 主线关卡战斗
          NormalDungeonMode.lua           -- 普通副本
          RoomDungeonMode.lua             -- 房间副本
          RoomBattleMode.lua              -- 房间副本战斗
          ArenaMode.lua                   -- 竞技场
      Battle/
        BattleDef.lua                     -- 战斗枚举/定义
        BattleBase.lua                    -- 战斗基类
        Battles/
          CampaignBattle.lua              -- 主线/副本战斗
          DungeonBattle.lua               -- 房间副本战斗
          ArenaBattle.lua                 -- 竞技场战斗
      Scene/
        SceneManager.lua                  -- 场景管理
      UI/
        UIManager.lua                     -- UI管理
    Tests/
      test_framework.lua                  -- 框架测试
  Scripts/
    Framework/
      Core/
        LuaManager.cs                     -- xLua虚拟机
        GameManager.cs                    -- Unity入口
      Scene/
        SceneLoader.cs                    -- 场景加载
      UI/
        UIHelper.cs                       -- UI工具
Docs/
  Requirements.md                         -- 完整需求文档
```

## 核心概念

| 术语 | 英文 | 说明 |
|------|------|------|
| 玩法 | Mode | 独立的游戏玩法单元，同一时刻仅运行一个 |
| 保留 | Retain | 切换玩法时保留旧实例以加速恢复 |

## 玩法列表

| 玩法 | Mode ID | retain | 说明 |
|------|---------|--------|------|
| 内城 | `city` | ✅ | 主城经营 |
| 大地图 | `world` | ✅ | 世界探索 |
| 主线关卡 | `campaign` | ❌ | 失败重试/胜利下一关 |
| 普通副本 | `normal_dungeon` | ❌ | 按关卡直接战斗 |
| 房间副本 | `room_dungeon` | ✅ | 房间探索，遇怪进战斗 |
| 房间副本战斗 | `room_battle` | ❌ | 胜负均返回房间 |
| 竞技场 | `arena` | ❌ | PvP战斗 |

## 玩法栈操作

```lua
G_ModeManager:pushMode(modeId, params)     -- 压入新玩法，挂起当前
G_ModeManager:popMode(result)              -- 弹出当前，恢复上一个
G_ModeManager:replaceMode(modeId, params)  -- 替换栈顶（重试/下一关）
G_ModeManager:popToMode(modeId, result)    -- 弹回指定玩法
G_ModeManager:popAndPush(modeId, params)   -- 弹出后压入新玩法
```

## 运行测试

```bash
cd Assets/Lua
lua5.3 Tests/test_framework.lua
```

## 扩展指南

**新增玩法**：继承 `ModeBase`，实现 `getModeId()` 和生命周期方法，在 `Main.lua` 中注册。

**新增副本类型**：继承 `ModeBase`（或已有副本Mode），实现特定逻辑。

**新增战斗类型**：继承 `BattleBase`，实现战斗流程钩子。
