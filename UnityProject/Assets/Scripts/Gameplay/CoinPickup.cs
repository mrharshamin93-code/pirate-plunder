using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(Collider2D))]
    public sealed class CoinPickup : MonoBehaviour
    {
        [SerializeField] private int points = 10;

        private void Awake() => GetComponent<Collider2D>().isTrigger = true;

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (!other.CompareTag("Player")) return;
            GameManager.Instance?.CollectCoin(points);
            Destroy(gameObject);
        }
    }
}
