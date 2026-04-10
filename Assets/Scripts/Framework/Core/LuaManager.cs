using UnityEngine;
using XLua;

namespace SLGFramework
{
    /// <summary>
    /// Manages the xLua virtual machine lifecycle.
    /// Provides script loading and global function invocation.
    /// </summary>
    public class LuaManager : MonoBehaviour
    {
        public static LuaManager Instance { get; private set; }

        private LuaEnv _luaEnv;

        /// <summary>Lua package search path root (relative to StreamingAssets or Resources).</summary>
        [SerializeField] private string luaRoot = "Lua";

        private void Awake()
        {
            if (Instance != null)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
            InitLuaEnv();
        }

        private void InitLuaEnv()
        {
            _luaEnv = new LuaEnv();

            // Add a custom loader so that require("Framework.Core.Class") finds the correct file.
            _luaEnv.AddLoader((ref string filename) =>
            {
                string path = filename.Replace('.', '/');
                string fullPath = System.IO.Path.Combine(Application.dataPath, luaRoot, path + ".lua");
                if (System.IO.File.Exists(fullPath))
                {
                    return System.IO.File.ReadAllBytes(fullPath);
                }
                return null;
            });

            // Execute the main entry script
            _luaEnv.DoString("require('Main')", "LuaManager");
            Debug.Log("[LuaManager] Lua environment initialized.");
        }

        private void Update()
        {
            if (_luaEnv != null)
            {
                _luaEnv.Tick();
            }
        }

        private void OnDestroy()
        {
            if (_luaEnv != null)
            {
                CallGlobalFunction("LuaOnDestroy");
                _luaEnv.Dispose();
                _luaEnv = null;
            }
            if (Instance == this)
            {
                Instance = null;
            }
        }

        /// <summary>
        /// Call a global Lua function by name with optional arguments.
        /// </summary>
        public object[] CallGlobalFunction(string funcName, params object[] args)
        {
            if (_luaEnv == null) return null;
            var func = _luaEnv.Global.Get<LuaFunction>(funcName);
            if (func != null)
            {
                var results = func.Call(args);
                func.Dispose();
                return results;
            }
            return null;
        }

        /// <summary>
        /// Get the underlying LuaEnv for advanced usage.
        /// </summary>
        public LuaEnv GetLuaEnv()
        {
            return _luaEnv;
        }
    }
}
