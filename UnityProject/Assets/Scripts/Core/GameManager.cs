using System;
using UnityEngine;

namespace PiratesPlunder.Core
{
    public enum GamePhase { Menu, Playing, GameOver }

    public sealed class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public GamePhase Phase { get; private set; } = GamePhase.Menu;
        public int Score { get; private set; }
        public int Coins { get; private set; }
        public int Mines { get; private set; }

        public event Action<int, int, int> StatsChanged;
        public event Action<GamePhase> PhaseChanged;

        private void Awake()
        {
            if (Instance != null && Instance != this) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        public void StartGame()
        {
            Score = 0;
            Coins = 0;
            Mines = 0;
            SetPhase(GamePhase.Playing);
            PublishStats();
        }

        public void CollectCoin(int points)
        {
            if (Phase != GamePhase.Playing) return;
            Score += Mathf.Max(0, points);
            Coins++;
            PublishStats();
        }

        public void RegisterMine() { Mines++; PublishStats(); }

        public void EndGame()
        {
            if (Phase != GamePhase.Playing) return;
            SetPhase(GamePhase.GameOver);
        }

        public void GoToMenu() => SetPhase(GamePhase.Menu);

        private void SetPhase(GamePhase phase)
        {
            Phase = phase;
            PhaseChanged?.Invoke(phase);
        }

        private void PublishStats() => StatsChanged?.Invoke(Score, Coins, Mines);
    }
}
