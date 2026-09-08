using System.Collections;
using UnityEngine;

namespace PiratesPlunder.Effects
{
    public sealed class ExplosionEffect : MonoBehaviour
    {
        [SerializeField] private ParticleSystem particles;
        [SerializeField] private float life = 0.45f;

        public void Play(Vector3 position)
        {
            transform.position = position;
            gameObject.SetActive(true);
            if (particles != null)
            {
                particles.Clear(true);
                particles.Play(true);
            }
            StopAllCoroutines();
            StartCoroutine(Hide());
        }

        private IEnumerator Hide()
        {
            yield return new WaitForSeconds(life);
            gameObject.SetActive(false);
        }
    }
}
