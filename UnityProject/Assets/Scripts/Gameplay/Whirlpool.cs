using PiratesPlunder.Art;
using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(SpriteRenderer))]
    public sealed class Whirlpool : MonoBehaviour
    {
        private const float PixelsPerUnit = 30f;
        private float life;
        private SpriteRenderer renderer2D;

        private void Awake()
        {
            life = GameRules.WhirlpoolLife;
            renderer2D = GetComponent<SpriteRenderer>();
            var shader = Shader.Find("PiratesPlunder/Whirlpool");
            if (shader != null) renderer2D.material = new Material(shader);
            renderer2D.sprite = ProceduralSpriteFactory.Coin(0);
            renderer2D.color = Color.white;
            renderer2D.sortingOrder = 5;
            transform.localScale = Vector3.one * 2.65f;
        }

        private void Update()
        {
            life -= Time.deltaTime;
            float fade = Mathf.Clamp01(Mathf.Min(life / 0.5f, (GameRules.WhirlpoolLife - life) / 0.35f));
            if (renderer2D != null)
            {
                var c = renderer2D.color;
                c.a = fade;
                renderer2D.color = c;
            }
            if (life <= 0f) Destroy(gameObject);
        }

        private void FixedUpdate()
        {
            float pullRadius = GameRules.WhirlpoolRange / PixelsPerUnit;
            float coreRadius = GameRules.WhirlpoolCore / PixelsPerUnit;
            var hits = Physics2D.OverlapCircleAll(transform.position, pullRadius);

            foreach (var hit in hits)
            {
                var body = hit.attachedRigidbody;
                if (body == null) continue;

                Vector2 offset = (Vector2)transform.position - body.position;
                float distance = Mathf.Max(0.01f, offset.magnitude);
                float distancePx = distance * PixelsPerUnit;
                Vector2 inward = offset / distance;
                Vector2 tangent = new(-inward.y, inward.x);
                float normalized = Mathf.Clamp01(1f - distancePx / GameRules.WhirlpoolRange);
                float pullPx = GameRules.WhirlpoolPull * normalized;

                if (hit.CompareTag("Player"))
                {
                    if (distance <= coreRadius)
                    {
                        GameManager.Instance?.EndGame();
                        continue;
                    }
                    body.AddForce((inward + tangent * 0.45f) * (pullPx / PixelsPerUnit) * body.mass, ForceMode2D.Force);
                    continue;
                }

                var mine = hit.GetComponent<MineController>();
                if (mine != null)
                {
                    if (distance <= coreRadius)
                    {
                        mine.Explode();
                        continue;
                    }
                    body.AddForce((inward + tangent * 0.45f) * (pullPx * GameRules.WhirlpoolMinePull / PixelsPerUnit) * body.mass, ForceMode2D.Force);
                }
            }
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.DrawWireSphere(transform.position, GameRules.WhirlpoolCore / PixelsPerUnit);
            Gizmos.DrawWireSphere(transform.position, GameRules.WhirlpoolRange / PixelsPerUnit);
        }
    }
}
