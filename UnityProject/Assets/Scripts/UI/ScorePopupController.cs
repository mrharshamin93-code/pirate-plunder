using System.Collections;
using TMPro;
using UnityEngine;

namespace PiratesPlunder.UI
{
    public sealed class ScorePopupController : MonoBehaviour
    {
        [SerializeField] private TMP_Text label;
        [SerializeField] private float rise = 0.75f;
        [SerializeField] private float duration = 0.55f;

        public void Show(int points, Vector3 worldPosition)
        {
            StopAllCoroutines();
            transform.position = worldPosition;
            if (label != null) label.text = $"+{points:N0}";
            gameObject.SetActive(true);
            StartCoroutine(Animate());
        }

        private IEnumerator Animate()
        {
            Vector3 start = transform.position;
            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = Mathf.Clamp01(elapsed / duration);
                transform.position = start + Vector3.up * rise * t;
                if (label != null)
                {
                    var c = label.color;
                    c.a = 1f - t;
                    label.color = c;
                }
                yield return null;
            }
            gameObject.SetActive(false);
        }
    }
}
