using PiratesPlunder.Player;
using UnityEngine;
using UnityEngine.EventSystems;

namespace PiratesPlunder.Input
{
    public sealed class SemiDynamicJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        [SerializeField] private RectTransform baseRing;
        [SerializeField] private RectTransform knob;
        [SerializeField] private BoatController boat;
        [SerializeField] private float throwRadius = 40f;
        [SerializeField] private float deadZone = 7f;
        [SerializeField] private float baseShift = 72f;

        private RectTransform rect;
        private Vector2 home;
        private Vector2 origin;

        public void Configure(RectTransform ring, RectTransform thumb, BoatController controller)
        {
            baseRing = ring;
            knob = thumb;
            boat = controller;
            rect = transform as RectTransform;
            home = baseRing.anchoredPosition;
            origin = home;
        }

        private void Awake()
        {
            rect = transform as RectTransform;
            if (baseRing != null)
            {
                home = baseRing.anchoredPosition;
                origin = home;
            }
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (baseRing == null || knob == null || boat == null) return;
            Vector2 p = Local(eventData);
            Vector2 delta = p - home;
            origin = delta.magnitude <= baseShift ? p : home + delta.normalized * baseShift;
            baseRing.anchoredPosition = origin;
            knob.anchoredPosition = origin;
            Apply(p);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (boat == null) return;
            Apply(Local(eventData));
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (boat == null || baseRing == null || knob == null) return;
            boat.SetMoveInput(Vector2.zero);
            origin = home;
            baseRing.anchoredPosition = home;
            knob.anchoredPosition = home;
        }

        private Vector2 Local(PointerEventData e)
        {
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rect, e.position, e.pressEventCamera, out var p);
            return p;
        }

        private void Apply(Vector2 pointer)
        {
            Vector2 delta = pointer - origin;
            float distance = delta.magnitude;
            if (distance < deadZone)
            {
                boat.SetMoveInput(Vector2.zero);
                knob.anchoredPosition = origin + delta;
                return;
            }

            Vector2 direction = delta / distance;
            float magnitude = Mathf.Min(1f, distance / throwRadius);
            knob.anchoredPosition = origin + direction * Mathf.Min(distance, throwRadius);
            boat.SetMoveInput(direction * magnitude);
        }
    }
}
