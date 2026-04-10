// CSharpUtil.cs
// C# 工具函数集合，注册到 Lua 全局环境供 Lua 层调用。
// 原则：只提供 Lua 层自身无法方便实现的功能（如平台 API、Unity API 封装）。

using System;
using UnityEngine;
using XLua;

namespace SLGFramework
{
    /// <summary>
    /// 将通用 C# 工具方法批量注入到 xLua 全局环境。
    /// Lua 层通过全局函数名直接调用，例如 UnityLog("hello")。
    /// </summary>
    public static class CSharpUtil
    {
        /// <summary>
        /// 向 LuaEnv 注册所有工具函数。由 LuaManager.Init() 调用。
        /// </summary>
        public static void Register(LuaEnv luaEnv)
        {
            var global = luaEnv.Global;

            // ── 日志 ──────────────────────────────────────────────────────────
            global.Set<Action<string>>("UnityLog",      msg => Debug.Log(msg));
            global.Set<Action<string>>("UnityLogWarn",  msg => Debug.LogWarning(msg));
            global.Set<Action<string>>("UnityLogError", msg => Debug.LogError(msg));

            // ── 时间 ──────────────────────────────────────────────────────────
            // Lua: local t = UnityTime()  → 返回 Time.time（秒，浮点）
            global.Set<Func<float>>("UnityTime",      () => Time.time);
            global.Set<Func<float>>("UnityDeltaTime", () => Time.deltaTime);
            global.Set<Func<int>>  ("UnityFrameCount",() => Time.frameCount);

            // ── 应用信息 ─────────────────────────────────────────────────────
            global.Set<Func<string>>("UnityPlatform",    () => Application.platform.ToString());
            global.Set<Func<string>>("UnityVersion",     () => Application.version);
            global.Set<Func<string>>("UnityProductName", () => Application.productName);

            // ── 事件调度（延迟执行）──────────────────────────────────────────
            // Lua: UnityNextFrame(function() ... end)
            // 实际调用需要 MonoBehaviour 协程支持，此处仅作桩位（由 GameEntry 补充实现）
            global.Set<Action<LuaFunction>>("UnityNextFrame", fn =>
            {
                if (GameEntry.Instance != null)
                    GameEntry.Instance.StartCoroutine(NextFrameCoroutine(fn));
            });

            // ── JSON（依赖 Unity JsonUtility 或第三方库）────────────────────
            // 如需完整 JSON 支持建议在 Lua 层引入 dkjson 或 rapidjson 绑定
            // 此处仅提供简单的 PlayerPrefs 序列化辅助
            global.Set<Action<string, string>>("PrefsSave",   (k, v) => PlayerPrefs.SetString(k, v));
            global.Set<Func<string, string>>  ("PrefsLoad",   k => PlayerPrefs.GetString(k, ""));
            global.Set<Action<string>>         ("PrefsDelete", k => PlayerPrefs.DeleteKey(k));
        }

        // ─── 私有辅助 ──────────────────────────────────────────────────────────

        private static System.Collections.IEnumerator NextFrameCoroutine(LuaFunction fn)
        {
            yield return null;
            try
            {
                fn.Call();
            }
            catch (Exception e)
            {
                Debug.LogError("[CSharpUtil] NextFrame callback error: " + e);
            }
        }
    }
}
