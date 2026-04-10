# SLGFramework

基于 **Unity + xLua** 的 SLG 类型游戏玩法框架。

C# 层仅提供通用工具接口，游戏逻辑在 Lua 层实现。

---

## 目录结构

```
Assets/
├── Scripts/
│   └── Framework/
│       ├── Core/
│       │   ├── GameEntry.cs       # Unity 入口组件（挂载到场景）
│       │   └── LuaManager.cs      # xLua 虚拟机生命周期管理
│       └── Utility/
│           └── CSharpUtil.cs      # 注入 Lua 的 C# 工具函数
└── Lua/
    ├── Framework/
    │   ├── Core/
    │   │   ├── Class.lua          # 轻量级 Lua OOP 基础类
    │   │   ├── EventBus.lua       # 事件总线（订阅/发布）
    │   │   └── Logger.lua         # 分级日志工具
    │   └── Mode/
    │       ├── ModeBase.lua       # 游戏模式抽象基类
    │       └── ModeManager.lua    # 模式切换管理器（栈结构）
    ├── Modes/
    │   ├── CityMode.lua           # 内城模式
    │   ├── WorldMode.lua          # 大地图模式
    │   ├── CampaignMode.lua       # 主线关卡战斗模式
    │   ├── NormalDungeonMode.lua  # 普通副本模式
    │   ├── RoomDungeonMode.lua    # 房间副本模式
    │   ├── RoomDungeonBattleMode.lua  # 房间副本内战斗模式
    │   └── ArenaMode.lua          # 竞技场战斗模式
    └── Main.lua                   # 框架启动入口（注册模式、启动初始模式）
```

---

## 核心概念

### 游戏模式（Mode）

同一时刻只有 **一个模式** 处于激活状态。所有游戏玩法上下文（内城、大地图、战斗等）均抽象为模式。

| 模式 ID               | 类文件                     | 说明                         | retain |
|-----------------------|----------------------------|------------------------------|--------|
| `city`                | CityMode                   | 内城经营管理                 | true   |
| `world`               | WorldMode                  | 大地图探索                   | true   |
| `campaign`            | CampaignMode               | 主线关卡战斗                 | false  |
| `normal_dungeon`      | NormalDungeonMode          | 普通副本（按关卡进入战斗）   | false  |
| `room_dungeon`        | RoomDungeonMode            | 房间副本（探索 + 战斗）      | true   |
| `room_dungeon_battle` | RoomDungeonBattleMode      | 房间副本内的单场战斗         | false  |
| `arena`               | ArenaMode                  | 竞技场 PvP 战斗              | false  |

### 模式生命周期

```
IDLE ──enter()──► ACTIVE ──suspend()──► SUSPENDED
                     │                      │
                  exit()                resume()
                     │                      │
                   IDLE ◄────────────────── ACTIVE
```

- **enter** / **exit**：模式进入与永久退出（exit 后实例可能被销毁）。
- **suspend** / **resume**：暂时让位给另一个模式，自身保留在内存中（`retain = true`）。

### 模式保留（retain）

注册模式时可通过 `retain = true` 配置：
- 切换离开时调用 `suspend()`，实例**缓存**在 ModeManager 中。
- 下次进入时调用 `resume()`，省去重新创建和初始化的开销。
- 适用于需要快速来回切换的模式（内城 ↔ 大地图）。

`retain = false`（默认）时：
- 切换离开时调用 `exit()` 并销毁实例。
- 下次进入时重新创建并调用 `enter()`。

---

## 模式切换流程

### 基本切换：`ModeManager:switchTo(id, params, options)`

```
ModeManager:switchTo("campaign", { level = 3 })
```

```
当前模式（city）──suspend()──► 压入栈
新模式（campaign）──enter({ level=3 })──► 成为当前模式
```

### 返回上一模式：`ModeManager:exitCurrent(params, targetId?)`

```
ModeManager:exitCurrent()  -- 从 campaign 返回 city
```

```
当前模式（campaign）──exit()──► 销毁
栈顶模式（city）──resume()──► 成为当前模式
```

### 参数传递（战斗结果回传）

```lua
-- 房间副本战斗结束后，将结果传回房间模式
G_ModeManager:exitCurrent({
    battleResult = RoomDungeonBattleMode.Result.VICTORY,
    monsterId    = "mob_001",
})

-- RoomDungeonMode:resume 接收结果
function RoomDungeonMode:resume(fromMode, params)
    if params and params.battleResult then
        self:_applyBattleResult(params.battleResult, params.monsterId)
    end
end
```

---

## 典型流程示例

### 主线关卡流程

```
[内城] ──enterCampaign(1)──► [主线关卡]
    战斗胜利 → onNext → _startLevel(2)
    战斗失败 → onRetry → _startLevel(1)
    主动退出 → exitCurrent() → [内城] resume
```

### 普通副本流程

```
[大地图] ──switchTo("normal_dungeon")──► [普通副本大厅]
    选择关卡 → _startLevel(lv)
    战斗胜利 → 显示胜利UI → [下一关] / [返回大厅] / [退出]
    战斗失败 → 显示失败UI → [重试]   / [返回大厅] / [退出]
    退出 → exitCurrent() → [大地图] resume
```

### 房间副本流程

```
[内城] ──switchTo("room_dungeon")──► [房间探索]
    遭遇怪物 → switchTo("room_dungeon_battle")
        [房间探索] suspended (retain=true)
        战斗（无论胜负）→ exitCurrent({ battleResult, monsterId })
        [房间探索] resume → _applyBattleResult(...)
    探索完毕 → exitCurrent() → [内城] resume
```

---

## 快速接入

### 1. 导入 xLua 插件

将 xLua 插件放入 `Assets/XLua/`（官方渠道获取）。

### 2. 挂载 GameEntry

在游戏启动场景创建空 GameObject，挂载 `GameEntry` 组件。

### 3. Lua 脚本路径

将 `Assets/Lua/` 下所有 `.lua` 文件设置为 `TextAsset`（放入 `Resources/Lua/` 或配置自定义 AssetBundle 加载器）。

### 4. 扩展新模式

```lua
-- 1. 创建新模式文件 Assets/Lua/Modes/MyMode.lua
local ModeBase = require("Framework.Mode.ModeBase")
local MyMode = ModeBase:extend()
MyMode.ID = "my_mode"

function MyMode:init(config)
    config.id = MyMode.ID
    MyMode.super.init(self, config)
end

function MyMode:enter(fromMode, params) ... end
function MyMode:exit(toMode)           ... end
function MyMode:suspend(toMode)        ... end
function MyMode:resume(fromMode, params) ... end

return MyMode

-- 2. 在 Main.lua 注册
local MyMode = require("Modes.MyMode")
G_ModeManager:register(MyMode.ID, MyMode, { retain = false })

-- 3. 切换到新模式
G_ModeManager:switchTo(MyMode.ID, { key = "value" })
```

### 5. UI / 场景管理

UI 和场景由各自的管理系统独立维护，**不与模式强绑定**。  
模式通过 `enter` / `suspend` / `resume` / `exit` 回调驱动 UIManager 和 SceneManager，解耦后可灵活替换。

---

## 事件系统

```lua
local EventBus = require("Framework.Core.EventBus")
local bus = EventBus()

-- 订阅
bus:on("player_died", function(playerId)
    print("player died: " .. playerId)
end)

-- 一次性订阅
bus:once("level_loaded", function() print("level ready") end)

-- 发布
bus:emit("player_died", "player_001")

-- 取消订阅
bus:off("player_died", myHandler)
```

---

## 日志

```lua
local Logger = require("Framework.Core.Logger")
local log = Logger.get("MyModule")

log:debug("detail: %s", value)
log:info("started level %d", level)
log:warn("config missing: %s", key)
log:error("fatal error: %s", err)

-- 全局控制输出级别
Logger.level = Logger.Level.WARN  -- 只输出 WARN 及以上
```

---

## 许可

MIT
