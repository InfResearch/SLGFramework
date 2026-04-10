using System.Collections.Generic;
using UnityEngine;

namespace SLGFramework
{
    /// <summary>
    /// Provides basic UI management utilities for the Lua UIManager.
    /// Manages Canvas layers, UI instantiation, and visibility toggling.
    /// Singleton — attach to a persistent GameObject.
    /// </summary>
    public class UIHelper : MonoBehaviour
    {
        public static UIHelper Instance { get; private set; }

        [SerializeField] private Transform uiRoot;

        /// <summary>
        /// Cache of instantiated UI GameObjects keyed by uiId.
        /// </summary>
        private readonly Dictionary<string, GameObject> _uiCache = new Dictionary<string, GameObject>();

        private void Awake()
        {
            if (Instance != null)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
            DontDestroyOnLoad(gameObject);

            if (uiRoot == null)
            {
                uiRoot = transform;
            }
        }

        /// <summary>
        /// Open (instantiate or activate) a UI panel.
        /// In production this would load a prefab from asset bundles.
        /// </summary>
        /// <param name="uiId">Unique UI identifier / prefab name.</param>
        /// <param name="paramsObj">Optional parameters (passed from Lua).</param>
        public void OpenUI(string uiId, object paramsObj = null)
        {
            if (_uiCache.TryGetValue(uiId, out var existing))
            {
                existing.SetActive(true);
                return;
            }

            // Placeholder: in a real project, load prefab from Resources or AssetBundle
            var prefab = Resources.Load<GameObject>($"UI/{uiId}");
            if (prefab != null)
            {
                var go = Instantiate(prefab, uiRoot);
                go.name = uiId;
                _uiCache[uiId] = go;
            }
            else
            {
                Debug.LogWarning($"[UIHelper] UI prefab not found: {uiId}");
            }
        }

        /// <summary>
        /// Close (destroy) a UI panel.
        /// </summary>
        public void CloseUI(string uiId)
        {
            if (_uiCache.TryGetValue(uiId, out var go))
            {
                Destroy(go);
                _uiCache.Remove(uiId);
            }
        }

        /// <summary>
        /// Hide a UI panel (deactivate without destroying).
        /// </summary>
        public void HideUI(string uiId)
        {
            if (_uiCache.TryGetValue(uiId, out var go))
            {
                go.SetActive(false);
            }
        }

        /// <summary>
        /// Show a previously hidden UI panel.
        /// </summary>
        public void ShowUI(string uiId)
        {
            if (_uiCache.TryGetValue(uiId, out var go))
            {
                go.SetActive(true);
            }
        }

        /// <summary>
        /// Check if a UI is currently open (instantiated).
        /// </summary>
        public bool IsUIOpen(string uiId)
        {
            return _uiCache.ContainsKey(uiId);
        }
    }
}
