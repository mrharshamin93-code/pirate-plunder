using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    public sealed class Whirlpool : MonoBehaviour
    {
        [SerializeField] private float visualRadius = 1.25f;
        [SerializeField] private float pullRadius = 3.75f;
        [SerializeField] private float outerPull = 1.5f;
        [SerializeField] private float innerPull = 10f;
        [SerializeField] private float swirlStrength = 4.5f;

        private void FixedUpdate()
        {
            var hits = Physics2D.OverlapCircleAll(transform.position, pullRadius);
            foreach (var hit in hits)
            {
                if (!hit.CompareTag("Player")) continue;
                var body = hit.attachedRigidbody;
                if (body == null) continue;

                Vector2 offset = (Vector2)transform.position - body.position;
                float distance = Mathf.Max(0.05f, offset.magnitude);
                float normalized = Mathf.Clamp01(1f - distance / pullRadius);
                float strength = Mathf.Lerp(outerPull, innerPull, normalized * normalized);
                Vector2 inward = offset / distance;
                Vector2 tangent = new Vector2(-inward.y, inward.x);
                body.AddForce((inward * strength + tangent * swirlStrength * normalized) * body.mass, ForceMode2D.Force);
            }
        }

        private void OnDrawGizmosSelected()
        {
            Gizmos.DrawWireSphere(transform.position, visualRadius);
            Gizmos.DrawWireSphere(transform.position, pullRadius);
        }
    }
}
