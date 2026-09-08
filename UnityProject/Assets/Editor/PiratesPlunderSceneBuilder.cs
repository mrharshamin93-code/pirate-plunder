#if UNITY_EDITOR
using PiratesPlunder.Art;
using PiratesPlunder.Core;
using PiratesPlunder.Gameplay;
using PiratesPlunder.Input;
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

            new GameObject("GameManager", typeof(GameManager), typeof(AutoStartGame));

            var water = new GameObject("Ocean", typeof(SpriteRenderer));
            var waterRenderer = water.GetComponent<SpriteRenderer>();
            waterRenderer.sprite = ProceduralSpriteFactory.Ocean;
            waterRenderer.drawMode = SpriteDrawMode.Tiled;
            waterRenderer.size = new Vector2(12f, 18f);
            waterRenderer.sortingOrder = -100;

            var boat = new GameObject("Boat", typeof(SpriteRenderer), typeof(Rigidbody2D), typeof(CircleCollider2D), typeof(BoatController));
            boat.tag = "Player";
            boat.transform.position = Vector3.zero;
            var boatRenderer = boat.GetComponent<SpriteRenderer>();
            boatRenderer.sprite = ProceduralSpriteFactory.Boat;
            boatRenderer.sortingOrder = 20;
            boat.GetComponent<CircleCollider2D>().radius = GameRules.BoatRadius / 30f;

            var spawnerGo = new GameObject("SpawnDirector", typeof(SpawnDirector));
            spawnerGo.GetComponent<SpawnDirector>().Configure(boat.transform);

            var canvasGo = new GameObject("HUD Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(390, 844);
            scaler.matchWidthOrHeight = 0.5f;

            var eventSystem = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var zone = new GameObject("Joystick Zone", typeof(RectTransform), typeof(Image), typeof(SemiDynamicJoystick));
            zone.transform.SetParent(canvasGo.transform, false);
            var zoneRect = zone.GetComponent<RectTransform>();
            zoneRect.anchorMin = new Vector2(0f, 0f);
            zoneRect.anchorMax = new Vector2(1f, 0f);
            zoneRect.pivot = new Vector2(0.5f, 0f);
            zoneRect.sizeDelta = new Vector2(0f, 158f);
            zoneRect.anchoredPosition = Vector2.zero;
            var zoneImage = zone.GetComponent<Image>();
            zoneImage.color = new Color(0f, 0f, 0f, 0.001f);

            var ring = new GameObject("Joystick Ring", typeof(RectTransform), typeof(Image));
            ring.transform.SetParent(zone.transform, false);
            var ringRect = ring.GetComponent<RectTransform>();
            ringRect.sizeDelta = new Vector2(138f, 138f);
            ringRect.anchorMin = ringRect.anchorMax = new Vector2(0.5f, 0f);
            ringRect.pivot = new Vector2(0.5f, 0.5f);
            ringRect.anchoredPosition = new Vector2(0f, 81f);
            ring.GetComponent<Image>().color = new Color(0.07f, 0.22f, 0.27f, 0.58f);

            var knob = new GameObject("Joystick Knob", typeof(RectTransform), typeof(Image));
            knob.transform.SetParent(zone.transform, false);
            var knobRect = knob.GetComponent<RectTransform>();
            knobRect.sizeDelta = new Vector2(58f, 58f);
            knobRect.anchorMin = knobRect.anchorMax = new Vector2(0.5f, 0f);
            knobRect.pivot = new Vector2(0.5f, 0.5f);
            knobRect.anchoredPosition = new Vector2(0f, 81f);
            knob.GetComponent<Image>().color = new Color(0.85f, 0.96f, 0.98f, 0.9f);

            zone.GetComponent<SemiDynamicJoystick>().Configure(ringRect, knobRect, boat.GetComponent<BoatController>());

            const string scenePath = "Assets/Scenes/Gameplay.unity";
            if (!AssetDatabase.IsValidFolder("Assets/Scenes")) AssetDatabase.CreateFolder("Assets", "Scenes");
            EditorSceneManager.SaveScene(scene, scenePath);
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
            Selection.activeGameObject = boat;
            Debug.Log("Pirate's Plunder Unity gameplay scene is ready. Press Play to test boat movement, coin spawning, mines, whirlpools and the mobile joystick.");
        }
    }
}
#endif
