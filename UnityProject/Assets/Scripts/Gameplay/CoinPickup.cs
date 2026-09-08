using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(Collider2D))]
    public sealed class CoinPickup : MonoBehaviour
    {
        public int Tier { get; private set; }
        public int Points { get; private set; } = 10;
        private SpawnDirector director;

        private void Awake() => GetComponent<Collider2D>().isTrigger = true;

        public void SetTier(int tier, SpawnDirector owner)
        {
            Tier = Mathf.Clamp(tier, 0, GameRules.CoinPoints.Length - 1);
            Points = GameRules.CoinPoints[Tier];
            director = owner;
        }

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (!other.CompareTag("Player")) return;
            GameManager.Instance?.CollectCoin(Points);
            director?.CoinCollected();
            Destroy(gameObject);
        }
    }
}
