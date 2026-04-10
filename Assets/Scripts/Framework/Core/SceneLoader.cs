using System;
using System.Collections;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace SLGFramework
{
    /// <summary>
    /// Provides asynchronous scene loading/unloading for the Lua SceneManager.
    /// Singleton — attach to a persistent GameObject.
    /// </summary>
    public class SceneLoader : MonoBehaviour
    {
        public static SceneLoader Instance { get; private set; }

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

        /// <summary>
        /// Load a scene asynchronously in Additive mode.
        /// </summary>
        /// <param name="sceneName">Scene name or path.</param>
        /// <param name="onComplete">Callback invoked with true on success, false on failure.</param>
        public void LoadSceneAsync(string sceneName, Action<bool> onComplete)
        {
            StartCoroutine(LoadSceneCoroutine(sceneName, onComplete));
        }

        /// <summary>
        /// Unload a scene asynchronously.
        /// </summary>
        /// <param name="sceneName">Scene name or path.</param>
        /// <param name="onComplete">Callback invoked with true on success.</param>
        public void UnloadSceneAsync(string sceneName, Action<bool> onComplete)
        {
            StartCoroutine(UnloadSceneCoroutine(sceneName, onComplete));
        }

        private IEnumerator LoadSceneCoroutine(string sceneName, Action<bool> onComplete)
        {
            AsyncOperation op = null;
            try
            {
                op = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);
            }
            catch (Exception e)
            {
                Debug.LogError($"[SceneLoader] Failed to load scene '{sceneName}': {e.Message}");
                onComplete?.Invoke(false);
                yield break;
            }

            if (op == null)
            {
                onComplete?.Invoke(false);
                yield break;
            }

            yield return op;
            Debug.Log($"[SceneLoader] Scene '{sceneName}' loaded.");
            onComplete?.Invoke(true);
        }

        private IEnumerator UnloadSceneCoroutine(string sceneName, Action<bool> onComplete)
        {
            AsyncOperation op = null;
            try
            {
                op = SceneManager.UnloadSceneAsync(sceneName);
            }
            catch (Exception e)
            {
                Debug.LogError($"[SceneLoader] Failed to unload scene '{sceneName}': {e.Message}");
                onComplete?.Invoke(false);
                yield break;
            }

            if (op == null)
            {
                onComplete?.Invoke(false);
                yield break;
            }

            yield return op;
            Debug.Log($"[SceneLoader] Scene '{sceneName}' unloaded.");
            onComplete?.Invoke(true);
        }
    }
}
