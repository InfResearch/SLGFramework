using UnityEngine;

namespace SLGFramework
{
    /// <summary>
    /// Game entry point. Drives the Unity lifecycle and delegates to Lua.
    /// Attach this to a persistent GameObject in the boot scene.
    /// </summary>
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        [SerializeField] private bool autoInitLua = true;

        private void Awake()
        {
            if (Instance != null)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        private void Start()
        {
            // LuaManager should be on the same or a sibling GameObject.
            // It auto-initializes in its own Awake, so by Start the Lua
            // environment is ready.
            Debug.Log("[GameManager] Game started.");
        }

        private void Update()
        {
            float dt = Time.deltaTime;
            // Forward frame tick to Lua
            LuaManager.Instance?.CallGlobalFunction("LuaUpdate", dt);
        }

        private void OnApplicationQuit()
        {
            Debug.Log("[GameManager] Application quitting.");
        }
    }
}
