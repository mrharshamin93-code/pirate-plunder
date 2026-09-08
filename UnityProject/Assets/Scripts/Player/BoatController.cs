using UnityEngine;

namespace PiratesPlunder.Player
{
    [RequireComponent(typeof(Rigidbody2D))]
    public sealed class BoatController : MonoBehaviour
    {
        [SerializeField] private float speed = 5.2f;
        [SerializeField] private float acceleration = 14f;
        [SerializeField] private float turnSpeed = 12f;

        private Rigidbody2D body;
        private Vector2 input;

        private void Awake()
        {
            body = GetComponent<Rigidbody2D>();
            body.gravityScale = 0f;
            body.freezeRotation = true;
        }

        public void SetMoveInput(Vector2 value) => input = Vector2.ClampMagnitude(value, 1f);

        private void FixedUpdate()
        {
            Vector2 targetVelocity = input * speed;
            body.linearVelocity = Vector2.MoveTowards(body.linearVelocity, targetVelocity, acceleration * Time.fixedDeltaTime);

            if (input.sqrMagnitude > 0.01f)
            {
                float targetAngle = Mathf.Atan2(input.y, input.x) * Mathf.Rad2Deg - 90f;
                float angle = Mathf.LerpAngle(transform.eulerAngles.z, targetAngle, turnSpeed * Time.fixedDeltaTime);
                transform.rotation = Quaternion.Euler(0f, 0f, angle);
            }
        }
    }
}
