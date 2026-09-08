using UnityEngine;

namespace PiratesPlunder.Core
{
    public sealed class AutoStartGame : MonoBehaviour
    {
        private void Start()
        {
            GameManager.Instance?.StartGame();
        }
    }
}
