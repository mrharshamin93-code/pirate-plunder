#if UNITY_EDITOR
using PiratesPlunder.Core;
using PiratesPlunder.Gameplay;
using PiratesPlunder.Player;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace PiratesPlunder.EditorTools
{
    public static class PiratesPlunderSceneBuilder
    {
        [MenuItem("Pirate's Plunder/Build Gameplay Scene")]
        public static void Build()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var cameraGo = new GameObject("Main Camera", typeof(Camera));
            cameraGo.tag = "MainCamera";
            var cam = cameraGo.GetComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = 8f;
            cam.backgroundColor = new Color32(8, 46, 60, 255);
            cameraGo.transform.position = new Vector3(0, 0, -10);

            var manager = new GameObject("GameManager", typeof(GameManager));

            var boat = new GameObject("Boat", typeof(SpriteRenderer), typeof(Rigidbody2D), typeof(CircleCollider2D), typeof(BoatController));
            boat.tag = "Player";
            boat.transform.position = Vector3.zero;
            boat.GetComponent<CircleCollider2D>().radius = GameRules.BoatRadius / 30f;

            var canvasGo = new GameObject("HUD Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(390, 844);
            scaler.matchWidthOrHeight = 0.5f;

            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var water = new GameObject("Ocean", typeof(SpriteRenderer));
            water.transform.position = new Vector3(0, 0, 2);

            GameManager.Instance.StartGame();

            const string scenePath = "Assets/Scenes/Gameplay.unity";
            if (!AssetDatabase.IsValidFolder("Assets/Scenes")) AssetDatabase.CreateFolder("Assets", "Scenes");
            EditorSceneManager.SaveScene(scene, scenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
            Selection.activeGameObject = boat;
            Debug.Log("Pirate's Plunder gameplay scene created. Assign the existing art sprites/prefabs in the Inspector, then press Play.");
        }
    }
}
#endif
