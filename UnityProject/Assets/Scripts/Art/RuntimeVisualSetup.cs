using PiratesPlunder.Gameplay;
using UnityEngine;

namespace PiratesPlunder.Art
{
    public sealed class RuntimeVisualSetup : MonoBehaviour
    {
        [SerializeField] private SpriteRenderer boatRenderer;
        [SerializeField] private SpriteRenderer oceanRenderer;
        [SerializeField] private SpriteRenderer whirlpoolRenderer;

        private void Awake()
        {
            if (boatRenderer != null)
            {
                boatRenderer.sprite = ProceduralSpriteFactory.Boat;
                boatRenderer.sortingOrder = 20;
            }

            if (oceanRenderer != null)
            {
                oceanRenderer.sprite = ProceduralSpriteFactory.Ocean;
                oceanRenderer.drawMode = SpriteDrawMode.Tiled;
                oceanRenderer.size = new Vector2(12f, 18f);
                oceanRenderer.sortingOrder = -100;
            }

            if (whirlpoolRenderer != null)
            {
                var shader = Shader.Find("PiratesPlunder/Whirlpool");
                if (shader != null) whirlpoolRenderer.material = new Material(shader);
                whirlpoolRenderer.sortingOrder = 5;
            }
        }

        public static void ApplyCoin(SpriteRenderer renderer, int tier)
        {
            if (renderer == null) return;
            renderer.sprite = ProceduralSpriteFactory.Coin(tier);
            renderer.sortingOrder = 10;
        }

        public static void ApplyMine(SpriteRenderer renderer)
        {
            if (renderer == null) return;
            renderer.sprite = ProceduralSpriteFactory.Mine;
            renderer.sortingOrder = 12;
        }

        public static void ApplyWake(SpriteRenderer renderer)
        {
            if (renderer == null) return;
            renderer.sprite = ProceduralSpriteFactory.Wake;
            renderer.sortingOrder = 4;
        }
    }
}
