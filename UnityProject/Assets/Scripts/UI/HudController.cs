using PiratesPlunder.Core;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

namespace PiratesPlunder.UI
{
    public sealed class HudController : MonoBehaviour
    {
        [SerializeField] private TMP_Text scoreText;
        [SerializeField] private TMP_Text coinCountText;
        [SerializeField] private TMP_Text mineCountText;
        [SerializeField] private Image coinImage;
        [SerializeField] private Sprite[] coinTierSprites;

        private void OnEnable()
        {
            if (GameManager.Instance != null) GameManager.Instance.StatsChanged += Refresh;
        }

        private void Start()
        {
            if (GameManager.Instance != null) Refresh(GameManager.Instance.Score, GameManager.Instance.Coins, GameManager.Instance.Mines);
        }

        private void OnDisable()
        {
            if (GameManager.Instance != null) GameManager.Instance.StatsChanged -= Refresh;
        }

        public void SetCoinTier(int tier)
        {
            if (coinImage == null || coinTierSprites == null || coinTierSprites.Length == 0) return;
            coinImage.sprite = coinTierSprites[Mathf.Clamp(tier, 0, coinTierSprites.Length - 1)];
        }

        private void Refresh(int score, int coins, int mines)
        {
            if (scoreText != null) scoreText.text = score.ToString("N0");
            if (coinCountText != null) coinCountText.text = coins.ToString();
            if (mineCountText != null) mineCountText.text = $"{mines}/9";
        }
    }
}
