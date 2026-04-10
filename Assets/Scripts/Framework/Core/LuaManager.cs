// LuaManager.cs
// xLua 环境管理器：初始化 LuaEnv、注入自定义 Loader、启动 Lua 框架。
// Lua 脚本存放在 Resources/Lua/ 目录，通过 . 分隔的路径映射到文件系统。

using System;
using UnityEngine;
using XLua;

namespace SLGFramework
{
    /// <summary>
    /// 管理 xLua 虚拟机生命周期，并将 C# 工具方法注入到 Lua 全局环境。
    /// </summary>
    public class LuaManager : IDisposable
    {
        private LuaEnv _luaEnv;
        private bool   _disposed;

        // xLua GC 调用间隔（秒）
        private const float GcInterval = 1f;
        private float _gcTimer;

        /// <summary>底层 LuaEnv 实例（供需要直接操作 Lua 的 C# 组件使用）</summary>
        public LuaEnv LuaEnv => _luaEnv;

        /// <summary>
        /// 初始化 xLua 环境，注册自定义 Loader 和内置工具。
        /// </summary>
        public void Init()
        {
            _luaEnv = new LuaEnv();

            // 注册自定义脚本加载器（从 Resources/Lua/ 加载）
            _luaEnv.AddLoader(CustomLoader);

            // 向 Lua 注入 C# 工具函数
            CSharpUtil.Register(_luaEnv);
        }

        /// <summary>
        /// 启动 Lua 框架（执行 Main.lua）。
        /// </summary>
        public void StartGame()
        {
            _luaEnv.DoString("require('Main')", "LuaManager.StartGame");
        }

        /// <summary>
        /// 每帧调用，执行 xLua 的增量 GC。
        /// </summary>
        public void Tick()
        {
            if (_luaEnv == null) return;

            _gcTimer += Time.deltaTime;
            if (_gcTimer >= GcInterval)
            {
                _gcTimer = 0f;
                _luaEnv.Tick();
            }
        }

        /// <summary>
        /// 在 Lua 全局环境中执行一段代码片段（调试/测试用）。
        /// </summary>
        public void DoString(string code, string chunkName = "DoString")
        {
            _luaEnv?.DoString(code, chunkName);
        }

        /// <summary>
        /// 释放 xLua 环境。
        /// </summary>
        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            _luaEnv?.Dispose();
            _luaEnv = null;
        }

        // ─── 私有方法 ──────────────────────────────────────────────────────────

        /// <summary>
        /// 自定义 Lua 模块加载器：将 "A.B.C" 映射到 Resources/Lua/A/B/C.lua。
        /// </summary>
        private byte[] CustomLoader(ref string filePath)
        {
            // 将 . 替换为路径分隔符
            string resourcePath = "Lua/" + filePath.Replace('.', '/');
            TextAsset textAsset = Resources.Load<TextAsset>(resourcePath);
            if (textAsset != null)
            {
                return textAsset.bytes;
            }

#if UNITY_EDITOR
            // 编辑器下也尝试从 Assets/Lua/ 直接读取（热重载支持）
            string fullPath = Application.dataPath + "/Lua/" + filePath.Replace('.', '/') + ".lua";
            if (System.IO.File.Exists(fullPath))
            {
                return System.Text.Encoding.UTF8.GetBytes(System.IO.File.ReadAllText(fullPath));
            }
#endif
            return null;
        }
    }
}
