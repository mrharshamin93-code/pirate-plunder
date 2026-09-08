using PiratesPlunder.Core;
using PiratesPlunder.Gameplay;
using UnityEngine;

namespace PiratesPlunder.Player
{
    [RequireComponent(typeof(Rigidbody2D))]
    public sealed class BoatController : MonoBehaviour
    {
        [SerializeField] private float pixelsPerUnit = 30f;

        private Rigidbody2D body;
        private Vector2 input;
        private float heading = -Mathf.PI / 2f;

        private void Awake()
        {
            body = GetComponent<Rigidbody2D>();
            body.gravityScale = 0f;
            body.freezeRotation = true;
        }

        public void SetMoveInput(Vector2 value) => input = Vector2.ClampMagnitude(value, 1f);

        private void FixedUpdate()
        {
            if (GameManager.Instance != null && GameManager.Instance.Phase != GamePhase.Playing) return;

            float dt = Time.fixedDeltaTime;
            Vector2 velocityPx = body.linearVelocity * pixelsPerUnit;
            float speed = velocityPx.magnitude;
            float speedFrac = Mathf.Min(1f, speed / GameRules.MaxSpeed);
            float magnitude = input.magnitude;

            if (magnitude > 0f)
            {
                float target = Mathf.Atan2(input.y, input.x);
                float diff = Mathf.DeltaAngle(heading * Mathf.Rad2Deg, target * Mathf.Rad2Deg) * Mathf.Deg2Rad;
                float rate = GameRules.TurnRate * (1f - GameRules.TurnAtSpeed * speedFrac) * dt;
                heading += Mathf.Abs(diff) <= rate ? diff : Mathf.Sign(diff) * rate;
                velocityPx += new Vector2(Mathf.Cos(heading), Mathf.Sin(heading)) * GameRules.Thrust * magnitude * dt;
            }

            Vector2 forward = new(Mathf.Cos(heading), Mathf.Sin(heading));
            float along = Vector2.Dot(velocityPx, forward);
            Vector2 sideways = velocityPx - along * forward;
            float damp = Mathf.Exp(-GameRules.Drag * dt);
            float grip = Mathf.Exp(-GameRules.LateralGrip * dt);
            velocityPx = along * damp * forward + sideways * grip;
            velocityPx = Vector2.ClampMagnitude(velocityPx, GameRules.MaxSpeed);

            body.linearVelocity = velocityPx / pixelsPerUnit;
            transform.rotation = Quaternion.Euler(0f, 0f, heading * Mathf.Rad2Deg - 90f);
        }
    }
}
