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

        public void Configure(Transform boatTransform) => boat = boatTransform;

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
            activeCoin = coinPrefab != null ? Instantiate(coinPrefab, position, Quaternion.identity) : CreateCoin(position);
            activeCoin.SetTier(GameRules.PickCoinTier(), this);
        }

        private void SpawnMine()
        {
            MineController mine = mines.Find(m => !m.gameObject.activeSelf);
            if (mine == null)
            {
                if (mines.Count >= GameRules.MaxMines) return;
                mine = minePrefab != null ? Instantiate(minePrefab) : CreateMine();
                mines.Add(mine);
            }
            mine.transform.position = RandomPoint(46f / pixelsPerUnit);
            mine.Launch(boat);
            GameManager.Instance?.RegisterMine();
        }

        private void SpawnWhirlpool()
        {
            if (activeWhirlpool != null) Destroy(activeWhirlpool.gameObject);
            Vector2 position = RandomPoint(GameRules.WhirlpoolMinDistance / pixelsPerUnit);
            activeWhirlpool = whirlpoolPrefab != null ? Instantiate(whirlpoolPrefab, position, Quaternion.identity) : CreateWhirlpool(position);
        }

        private CoinPickup CreateCoin(Vector2 position)
        {
            var go = new GameObject("Coin", typeof(SpriteRenderer), typeof(CircleCollider2D), typeof(CoinPickup));
            go.transform.position = position;
            go.GetComponent<CircleCollider2D>().radius = GameRules.CoinRadius / pixelsPerUnit;
            go.GetComponent<CircleCollider2D>().isTrigger = true;
            return go.GetComponent<CoinPickup>();
        }

        private MineController CreateMine()
        {
            var go = new GameObject("Mine", typeof(SpriteRenderer), typeof(Rigidbody2D), typeof(CircleCollider2D), typeof(MineController));
            go.SetActive(false);
            return go.GetComponent<MineController>();
        }

        private Whirlpool CreateWhirlpool(Vector2 position)
        {
            var go = new GameObject("Whirlpool", typeof(SpriteRenderer), typeof(Whirlpool));
            go.transform.position = position;
            return go.GetComponent<Whirlpool>();
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
