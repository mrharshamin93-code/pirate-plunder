using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(Rigidbody2D))]
    public sealed class MineController : MonoBehaviour
    {
        private Rigidbody2D body;
        private Transform target;
        private float armTimer;
        private float phase;

        public bool Armed => armTimer <= 0f;

        private void Awake()
        {
            body = GetComponent<Rigidbody2D>();
            body.gravityScale = 0f;
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
            float distance = Mathf.Max(0.01f, delta.magnitude);
            Vector2 direction = delta / distance;
            float t = Mathf.InverseLerp(GameRules.MineFarRange, GameRules.MineNearRange, distance);
            float speed = Mathf.Lerp(GameRules.MineFarSpeed, GameRules.MineNearSpeed, t);
            phase += Time.fixedDeltaTime * 2.4f;
            Vector2 tangent = new Vector2(-direction.y, direction.x);
            Vector2 weave = tangent * Mathf.Sin(phase) * speed * GameRules.MineWander;
            body.linearVelocity = direction * speed + weave;
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
