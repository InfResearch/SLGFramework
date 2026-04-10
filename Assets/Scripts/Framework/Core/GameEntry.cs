// GameEntry.cs
// Unity 游戏入口点，负责初始化 Lua 环境并启动框架。
// C# 层保持最小化，仅提供 Lua 层所需的通用工具接口。

using UnityEngine;

namespace SLGFramework
{
    /// <summary>
    /// 游戏入口组件，挂载在场景中第一个加载的 GameObject 上（如 "GameEntry"）。
    /// </summary>
    public class GameEntry : MonoBehaviour
    {
        private static GameEntry _instance;

        /// <summary>全局单例</summary>
        public static GameEntry Instance => _instance;

        private LuaManager _luaManager;

        private void Awake()
        {
            if (_instance != null && _instance != this)
            {
                Destroy(gameObject);
                return;
            }
            _instance = this;
            DontDestroyOnLoad(gameObject);

            _luaManager = new LuaManager();
            _luaManager.Init();
        }

        private void Start()
        {
            _luaManager.StartGame();
        }

        private void Update()
        {
            // xLua GC 定期执行（建议每帧或固定间隔调用）
            _luaManager?.Tick();
        }

        private void OnApplicationQuit()
        {
            _luaManager?.Dispose();
            _luaManager = null;
        }

        private void OnDestroy()
        {
            if (_instance == this)
            {
                _luaManager?.Dispose();
                _instance = null;
            }
        }

        /// <summary>获取 LuaManager（供其他 C# 组件访问 Lua 环境）</summary>
        public LuaManager LuaManager => _luaManager;
    }
}
