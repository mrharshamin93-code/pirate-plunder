using System.Collections.Generic;
using UnityEngine;

namespace PiratesPlunder.Effects
{
    public sealed class BoatWake : MonoBehaviour
    {
        [SerializeField] private Rigidbody2D boatBody;
        [SerializeField] private SpriteRenderer wakePrefab;
        [SerializeField] private int poolSize = 24;
        [SerializeField] private float minimumSpeed = 0.73f;
        [SerializeField] private float interval = 0.055f;
        [SerializeField] private float lifetime = 0.72f;
        [SerializeField] private float sternOffset = 0.38f;

        private readonly List<WakeItem> pool = new();
        private float timer;
        private int cursor;

        private sealed class WakeItem
        {
            public SpriteRenderer Renderer;
            public float Life;
        }

        private void Start()
        {
            for (int i = 0; i < poolSize; i++)
            {
                var r = Instantiate(wakePrefab, transform.parent);
                r.gameObject.SetActive(false);
                pool.Add(new WakeItem { Renderer = r });
            }
        }

        private void Update()
        {
            float dt = Time.deltaTime;
            foreach (var item in pool)
            {
                if (!item.Renderer.gameObject.activeSelf) continue;
                item.Life -= dt;
                float t = Mathf.Clamp01(item.Life / lifetime);
                var c = item.Renderer.color;
                c.a = t * 0.72f;
                item.Renderer.color = c;
                item.Renderer.transform.localScale = Vector3.one * Mathf.Lerp(1.35f, 0.75f, t);
                if (item.Life <= 0f) item.Renderer.gameObject.SetActive(false);
            }

            if (boatBody == null || boatBody.linearVelocity.magnitude < minimumSpeed) return;
            timer -= dt;
            if (timer > 0f) return;
            timer = interval;
            Emit();
        }

        private void Emit()
        {
            var item = pool[cursor];
            cursor = (cursor + 1) % pool.Count;
            Vector3 stern = transform.position - transform.up * sternOffset;
            item.Renderer.transform.SetPositionAndRotation(stern, transform.rotation);
            item.Renderer.transform.localScale = Vector3.one * 0.75f;
            var c = item.Renderer.color;
            c.a = 0.72f;
            item.Renderer.color = c;
            item.Life = lifetime;
            item.Renderer.gameObject.SetActive(true);
        }
    }
}
