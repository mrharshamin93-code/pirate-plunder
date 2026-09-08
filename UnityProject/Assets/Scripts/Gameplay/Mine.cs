using PiratesPlunder.Core;
using UnityEngine;

namespace PiratesPlunder.Gameplay
{
    [RequireComponent(typeof(Collider2D))]
    public sealed class Mine : MonoBehaviour
    {
        private void OnCollisionEnter2D(Collision2D collision)
        {
            if (!collision.collider.CompareTag("Player")) return;
            GameManager.Instance?.EndGame();
        }

        private void OnTriggerEnter2D(Collider2D other)
        {
            if (!other.CompareTag("Player")) return;
            GameManager.Instance?.EndGame();
        }
    }
}
