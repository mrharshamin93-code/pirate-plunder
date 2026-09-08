using PiratesPlunder.Art;
using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(Rigidbody2D))]
    [RequireComponent(typeof(SpriteRenderer))]
    [RequireComponent(typeof(CircleCollider2D))]
    public sealed class MineController : MonoBehaviour
    {
        private const float PixelsPerUnit = 30f;
        private Rigidbody2D body;
        private Transform target;
        private float armTimer;
        private float phase;

        public bool Armed => armTimer <= 0f;

        private void Awake()
        {
            body = GetComponent<Rigidbody2D>();
            body.gravityScale = 0f;
            GetComponent<CircleCollider2D>().isTrigger = true;
            GetComponent<CircleCollider2D>().radius = GameRules.MineSpikeRadius / PixelsPerUnit;
            RuntimeVisualSetup.ApplyMine(GetComponent<SpriteRenderer>());
            phase = Random.value * Mathf.PI * 2f;
        }

        public void Launch(Transform boat)
        {
            target = boat;
            armTimer = GameRules.MineArmTime;
            phase = Random.value * Mathf.PI * 2f;
            gameObject.SetActive(true);
        }

        private void FixedUpdate()
        {
            if (target == null || GameManager.Instance == null || GameManager.Instance.Phase != GamePhase.Playing) return;
            armTimer -= Time.fixedDeltaTime;

            Vector2 delta = (Vector2)target.position - body.position;
            float distancePx = Mathf.Max(0.01f, delta.magnitude * PixelsPerUnit);
            Vector2 direction = delta.normalized;
            float t = Mathf.InverseLerp(GameRules.MineFarRange, GameRules.MineNearRange, distancePx);
            float speedPx = Mathf.Lerp(GameRules.MineFarSpeed, GameRules.MineNearSpeed, t);
            phase += Time.fixedDeltaTime * 2.4f;
            Vector2 tangent = new Vector2(-direction.y, direction.x);
            Vector2 weavePx = tangent * Mathf.Sin(phase) * speedPx * GameRules.MineWander;
            body.linearVelocity = (direction * speedPx + weavePx) / PixelsPerUnit;
        }

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (other.CompareTag("Player") && Armed)
            {
                GameManager.Instance?.EndGame();
                return;
            }

            var otherMine = other.GetComponent<MineController>();
            if (otherMine != null && otherMine != this && Armed && otherMine.Armed)
            {
                otherMine.Explode();
                Explode();
            }
        }

        public void Explode()
        {
            body.linearVelocity = Vector2.zero;
            gameObject.SetActive(false);
        }
    }
}
