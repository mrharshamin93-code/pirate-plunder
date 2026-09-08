using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    public static class GameRules
    {
        public const float BoatRadius = 8f;
        public const float TurnRate = 9f;
        public const float TurnAtSpeed = 0.28f;
        public const float Thrust = 620f;
        public const float Drag = 3.6f;
        public const float LateralGrip = 11f;
        public const float MaxSpeed = 190f;
        public const float CoinRadius = 13f;
        public const float CoinMinDistance = 90f;
        public const float MineRadius = 8f;
        public const float MineSpikeRadius = 11f;
        public const int MaxMines = 9;
        public const float MineFarSpeed = 22f;
        public const float MineNearSpeed = 100f;
        public const float MineFarRange = 400f;
        public const float MineNearRange = 40f;
        public const float MineWander = 0.42f;
        public const float MineArmTime = 0.55f;
        public const float WhirlpoolChance = 0.13f;
        public const float WhirlpoolRange = 140f;
        public const float WhirlpoolCore = 12f;
        public const float WhirlpoolPull = 260f;
        public const float WhirlpoolMinePull = 2.6f;
        public const float WhirlpoolLife = 6.5f;
        public const float WhirlpoolMinDistance = 110f;
        public const float ExplosionLife = 0.45f;

        public static readonly int[] CoinPoints = { 10, 25, 50, 100, 250, 500, 1000 };
        public static readonly int[] CoinWeights = { 38, 26, 17, 10, 5, 3, 1 };

        public static int PickCoinTier()
        {
            int total = 0;
            foreach (int weight in CoinWeights) total += weight;
            int roll = Random.Range(0, total);
            int cumulative = 0;
            for (int i = 0; i < CoinWeights.Length; i++)
            {
                cumulative += CoinWeights[i];
                if (roll < cumulative) return i;
            }
            return 0;
        }
    }
}
