# SLG游戏玩法框架 - 需求文档

## 1. 项目概述

基于Unity引擎 + xLua实现的SLG类型游戏玩法框架。核心逻辑在Lua层实现，C#层仅提供通用工具接口。
框架对不同游戏玩法进行统一抽象和管理，支持玩法间切换、挂起恢复、UI与场景独立管理。

---

## 2. 核心概念

| 术语 | 英文 | 说明 |
|------|------|------|
| 玩法 | Mode | 一种独立的游戏玩法单元，同一时刻仅运行一个 |
| 内城 | City | 主城经营玩法 |
| 大地图 | World | 世界地图探索玩法 |
| 主线关卡 | Campaign | 主线关卡战斗玩法 |
| 普通副本 | NormalDungeon | 按关卡直接进入战斗的副本 |
| 房间副本 | RoomDungeon | 先进入房间探索，再触发战斗的副本 |
| 房间副本战斗 | RoomBattle | 房间副本中的战斗 |
| 竞技场 | Arena | PvP竞技场战斗 |
| 战斗 | Battle | 战斗系统的抽象基类 |
| 保留 | Retain | 切换玩法时保留旧玩法实例以加快恢复速度 |

---

## 3. 玩法系统 (Mode System)

### 3.1 基本规则

- 同一时刻只能运行一个玩法（栈顶玩法为当前活跃玩法）
- 玩法间通过**栈结构**管理切换关系
- 支持以下切换操作：
  - **push**: 将新玩法压栈，当前玩法挂起
  - **pop**: 弹出当前玩法，恢复栈中上一个玩法
  - **replace**: 替换栈顶玩法（不影响栈中其他玩法）
  - **popTo**: 连续弹出直到指定玩法成为栈顶

### 3.2 玩法生命周期

```
onEnter(params)  → 进入玩法时调用
onPause()        → 被新玩法压入时调用（挂起）
onResume(result) → 上层玩法弹出后恢复时调用
onLeave()        → 离开玩法时调用
onUpdate(dt)     → 每帧更新（仅栈顶活跃玩法）
onDestroy()      → 玩法实例销毁时调用
```

### 3.3 保留机制 (Retain)

- 每个玩法可配置 `retain` 属性（默认false）
- `retain = true`：挂起时保留实例，恢复时直接调用 `onResume`
- `retain = false`：挂起时销毁实例，恢复时重新创建并调用 `onEnter`
- 典型保留玩法：City、World、RoomDungeon（加载重，频繁切换）

### 3.4 UI管理规则

- 玩法挂起时：关联UI隐藏（或销毁，由具体玩法决定）
- 玩法恢复时：关联UI恢复显示
- UIManager独立管理UI，不与玩法强绑定；玩法通过生命周期回调操作UI

### 3.5 场景管理规则

- 每个玩法可关联一个场景ID（可选）
- 场景由独立的SceneManager管理，不与玩法强绑定
- 玩法在 `onEnter` / `onResume` 中请求加载场景
- 保留玩法恢复时可跳过场景加载（若场景未变化）

---

## 4. 玩法流程定义

### 4.1 内城 (City)

- 入口：游戏启动默认玩法
- 可跳转至：World、Campaign、NormalDungeon、RoomDungeon、Arena
- retain = true

### 4.2 大地图 (World)

- 入口：从City进入
- 可跳转至：Campaign、NormalDungeon、RoomDungeon、Arena
- retain = true

### 4.3 主线关卡 (Campaign)

- 入口：从City或World进入，参数包含关卡ID
- 进入后直接进入战斗
- 战斗胜利：可选择挑战下一关（replace当前Campaign）或退出（pop回父玩法）
- 战斗失败：可选择重试（replace当前Campaign）或退出（pop回父玩法）
- retain = false

### 4.4 普通副本 (NormalDungeon)

- 入口：从City或World进入，参数包含副本ID和关卡ID
- 进入后直接进入战斗
- 战斗胜利：可选择挑战下一关（replace）或退出（pop）
- 战斗失败：可选择重试（replace）或退出（pop）
- retain = false
- 可扩展：后续新增副本类型只需继承基类

### 4.5 房间副本 (RoomDungeon)

- 入口：从City或World进入，参数包含副本ID
- 进入后加载房间场景进行探索
- 遇到怪物时：push RoomBattle
- 战斗结束后：pop回RoomDungeon，通过 `onResume(result)` 获取战斗结果
- 战斗结果反馈到房间对象上（如怪物消失、宝箱解锁等）
- retain = true

### 4.6 房间副本战斗 (RoomBattle)

- 入口：从RoomDungeon进入，参数包含战斗配置
- 战斗结束（无论胜负）：pop回RoomDungeon，携带战斗结果
- retain = false

### 4.7 竞技场 (Arena)

- 入口：从City或World进入，参数包含对手信息
- 战斗结束：pop回父玩法，携带战斗结果
- retain = false

---

## 5. 战斗系统 (Battle System)

### 5.1 战斗基类 (BattleBase)

提供通用战斗流程：

```
init(config)     → 初始化战斗配置
start()          → 开始战斗
pause() / resume() → 暂停/恢复
finish(result)   → 战斗结束，result包含胜负和详细数据
```

### 5.2 战斗类型

| 类型 | 类名 | 特点 |
|------|------|------|
| 主线战斗 | CampaignBattle | 按关卡配置，支持重试和下一关 |
| 副本战斗 | DungeonBattle | 与主线类似，按副本关卡配置 |
| 竞技场战斗 | ArenaBattle | PvP对战，独立的匹配和结算逻辑 |

### 5.3 战斗结果定义

```lua
BattleResult = {
    win = true/false,    -- 胜负
    stageId = number,    -- 关卡ID
    rewards = {},        -- 奖励列表
    stats = {},          -- 战斗统计数据
}
```

---

## 6. 场景管理 (Scene Management)

- SceneManager独立于玩法系统
- 提供接口：loadScene(sceneId, callback)、unloadScene(sceneId)
- 支持异步加载与加载进度回调
- 不与玩法强绑定，由玩法在生命周期中调用

---

## 7. UI管理 (UI Management)

- UIManager独立于玩法系统
- 提供接口：openUI(uiId, params)、closeUI(uiId)、hideUI(uiId)、showUI(uiId)
- 支持按分组管理：hideGroup(groupId)、showGroup(groupId)、closeGroup(groupId)
- 玩法在挂起时隐藏/销毁相关UI组，恢复时重新显示
- 不与玩法强绑定

---

## 8. C#层接口

C#层仅提供通用工具接口，不包含业务逻辑：

| 模块 | 类名 | 职责 |
|------|------|------|
| Lua引擎 | LuaManager | xLua虚拟机管理、Lua脚本加载执行 |
| 游戏入口 | GameManager | Unity生命周期驱动、初始化流程 |
| 场景工具 | SceneLoader | Unity场景异步加载/卸载封装 |
| UI工具 | UIHelper | UI层级管理、Canvas管理等 |

---

## 9. 扩展性设计

- 新增玩法：继承 `ModeBase`，实现生命周期方法，在 `ModeManager` 注册
- 新增副本类型：继承 `ModeBase`（或现有副本Mode），实现特定逻辑
- 新增战斗类型：继承 `BattleBase`，实现战斗流程
- 玩法注册表与工厂模式解耦，支持运行时动态注册

---

## 10. 架构总览

```
┌─────────────────────────────────────────┐
│                Main.lua                 │
│          (入口 & 初始化注册)              │
├─────────────────────────────────────────┤
│            ModeManager                  │
│     (玩法栈管理 & 生命周期调度)            │
├──────────┬──────────┬───────────────────┤
│ CityMode │WorldMode │ CampaignMode ...  │
│          │          │  (具体玩法实现)     │
├──────────┴──────────┴───────────────────┤
│  BattleBase / BattleManager             │
│     (战斗系统，被战斗类玩法使用)           │
├─────────────────────────────────────────┤
│   SceneManager    │    UIManager        │
│  (独立场景管理)    │   (独立UI管理)       │
├─────────────────────────────────────────┤
│              C# Layer                   │
│  LuaManager / GameManager / SceneLoader │
└─────────────────────────────────────────┘
```
