using System.Collections.Generic;
using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    public sealed class SpawnDirector : MonoBehaviour
    {
        [SerializeField] private Transform boat;
        [SerializeField] private CoinPickup coinPrefab;
        [SerializeField] private MineController minePrefab;
        [SerializeField] private Whirlpool whirlpoolPrefab;
        [SerializeField] private Vector2 minBounds = new(-4.6f, -6.5f);
        [SerializeField] private Vector2 maxBounds = new(4.6f, 6.5f);
        [SerializeField] private float pixelsPerUnit = 30f;

        private readonly List<MineController> mines = new();
        private CoinPickup activeCoin;
        private Whirlpool activeWhirlpool;

        private void Start() => SpawnCoin();

        public void CoinCollected()
        {
            SpawnMine();
            if (Random.value < GameRules.WhirlpoolChance) SpawnWhirlpool();
            SpawnCoin();
        }

        public void SpawnCoin()
        {
            if (activeCoin != null) Destroy(activeCoin.gameObject);
            Vector2 position = RandomPoint(GameRules.CoinMinDistance / pixelsPerUnit);
            activeCoin = Instantiate(coinPrefab, position, Quaternion.identity);
            activeCoin.SetTier(GameRules.PickCoinTier(), this);
        }

        private void SpawnMine()
        {
            MineController mine = mines.Find(m => !m.gameObject.activeSelf);
            if (mine == null)
            {
                if (mines.Count >= GameRules.MaxMines) return;
                mine = Instantiate(minePrefab);
                mines.Add(mine);
            }
            mine.transform.position = RandomPoint(46f / pixelsPerUnit);
            mine.Launch(boat);
            GameManager.Instance?.RegisterMine();
        }

        private void SpawnWhirlpool()
        {
            if (activeWhirlpool != null) Destroy(activeWhirlpool.gameObject);
            activeWhirlpool = Instantiate(whirlpoolPrefab, RandomPoint(GameRules.WhirlpoolMinDistance / pixelsPerUnit), Quaternion.identity);
        }

        private Vector2 RandomPoint(float minimumBoatDistance)
        {
            Vector2 p = minBounds;
            for (int i = 0; i < 24; i++)
            {
                p = new Vector2(Random.Range(minBounds.x, maxBounds.x), Random.Range(minBounds.y, maxBounds.y));
                if (boat == null || Vector2.Distance(p, boat.position) >= minimumBoatDistance) break;
            }
            return p;
        }
    }
}
