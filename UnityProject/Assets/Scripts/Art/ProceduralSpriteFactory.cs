using UnityEngine;

namespace PiratesPlunder.Art
{
    public static class ProceduralSpriteFactory
    {
        private static Sprite boat;
        private static Sprite mine;
        private static Sprite wake;
        private static Sprite ocean;
        private static readonly Sprite[] coins = new Sprite[7];

        public static Sprite Boat => boat ??= BuildBoat();
        public static Sprite Mine => mine ??= BuildMine();
        public static Sprite Wake => wake ??= BuildWake();
        public static Sprite Ocean => ocean ??= BuildOcean();

        public static Sprite Coin(int tier)
        {
            tier = Mathf.Clamp(tier, 0, coins.Length - 1);
            return coins[tier] ??= BuildCoin(tier);
        }

        private static Sprite BuildBoat()
        {
            const int size = 128;
            var tex = Blank(size);
            Color woodDark = Hex("6b3f1c");
            Color wood = Hex("9a6231");
            Color deck = Hex("b47a42");
            Color woodLight = Hex("c58c50");
            Color ink = Hex("0a1a20");
            Color sailor = Hex("57a94a");
            Color bandana = Hex("c8322f");

            FillEllipse(tex, 64, 64, 45, 21, woodDark);
            FillEllipse(tex, 69, 64, 35, 15, deck);
            DrawLine(tex, 44, 47, 25, 20, 5, wood);
            DrawLine(tex, 44, 81, 25, 108, 5, wood);
            FillEllipse(tex, 21, 16, 5, 9, woodLight);
            FillEllipse(tex, 21, 112, 5, 9, woodLight);
            FillCircle(tex, 54, 64, 10, sailor);
            FillRect(tex, 43, 55, 8, 18, bandana);
            FillCircle(tex, 57, 60, 2, ink);
            FillCircle(tex, 57, 68, 2, ink);
            FillEllipse(tex, 34, 64, 7, 9, Hex("c9a227"));
            OutlineEllipse(tex, 64, 64, 45, 21, 3, ink);
            return Sprite(tex, 64f);
        }

        private static Sprite BuildMine()
        {
            const int size = 96;
            var tex = Blank(size);
            Color body = Hex("25292e");
            Color light = Hex("555f68");
            Color ink = Hex("0a1a20");
            Color rust = Hex("8d3a24");
            Color lamp = Hex("ffd24a");

            Vector2 c = new(48, 48);
            for (int i = 0; i < 10; i++)
            {
                float a = i * Mathf.PI * 2f / 10f;
                Vector2 p1 = c + Dir(a) * 22f;
                Vector2 p2 = c + Dir(a) * 34f;
                DrawLine(tex, Mathf.RoundToInt(p1.x), Mathf.RoundToInt(p1.y), Mathf.RoundToInt(p2.x), Mathf.RoundToInt(p2.y), 5, body);
            }
            FillCircle(tex, 48, 48, 22, body);
            FillCircle(tex, 42, 42, 10, light * 0.9f);
            DrawLine(tex, 29, 52, 67, 52, 4, rust);
            FillCircle(tex, 48, 40, 5, lamp);
            OutlineCircle(tex, 48, 48, 22, 3, ink);
            return Sprite(tex, 48f);
        }

        private static Sprite BuildCoin(int tier)
        {
            const int size = 64;
            var tex = Blank(size);
            Color[] palette =
            {
                Hex("d09a36"), Hex("d9a542"), Hex("e0ae48"), Hex("e7b84b"), Hex("efc34f"), Hex("f5cc55"), Hex("ffd65a")
            };
            Color gold = palette[tier];
            Color dark = Color.Lerp(gold, Color.black, 0.35f);
            Color bright = Color.Lerp(gold, Color.white, 0.5f);
            FillCircle(tex, 32, 32, 23, dark);
            FillCircle(tex, 32, 32, 19, gold);
            FillCircle(tex, 26, 25, 6, bright);
            OutlineCircle(tex, 32, 32, 19, 2, bright);
            DrawLine(tex, 22, 35, 42, 35, 2, dark);
            DrawLine(tex, 22, 29, 42, 29, 2, dark);
            return Sprite(tex, 32f);
        }

        private static Sprite BuildWake()
        {
            const int size = 72;
            var tex = Blank(size);
            Color foam = Hex("d9f4fb");
            DrawArc(tex, 36, 38, 26, 0.15f, 2.99f, 4, WithAlpha(foam, 0.80f));
            DrawArc(tex, 36, 46, 20, 0.25f, 2.89f, 3, WithAlpha(foam, 0.42f));
            FillCircle(tex, 49, 24, 2, WithAlpha(foam, 0.65f));
            FillCircle(tex, 56, 43, 2, WithAlpha(foam, 0.45f));
            return Sprite(tex, 36f);
        }

        private static Sprite BuildOcean()
        {
            const int size = 256;
            var tex = Blank(size);
            Color deep = Hex("082e3c");
            Color mid = Hex("125a6e");
            Color light = Hex("1f7d92");
            for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
            {
                float nx = (x - size * 0.5f) / size;
                float ny = (y - size * 0.45f) / size;
                float d = Mathf.Clamp01(Mathf.Sqrt(nx * nx + ny * ny) * 1.5f);
                Color c = Color.Lerp(light, mid, Mathf.Clamp01(d * 1.2f));
                c = Color.Lerp(c, deep, Mathf.Clamp01((d - 0.35f) * 1.4f));
                tex.SetPixel(x, y, c);
            }
            for (int i = 0; i < 22; i++)
            {
                int y = 12 + i * 11;
                DrawArc(tex, 20 + (i * 17) % 120, y, 18 + (i % 4) * 5, 0.15f, 2.99f, 2, WithAlpha(Hex("4fb6cc"), 0.26f));
            }
            tex.Apply();
            return Sprite(tex, 128f);
        }

        private static Texture2D Blank(int size)
        {
            var tex = new Texture2D(size, size, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp
            };
            var clear = new Color[size * size];
            tex.SetPixels(clear);
            tex.Apply();
            return tex;
        }

        private static Sprite Sprite(Texture2D tex, float ppu)
        {
            tex.Apply();
            return UnityEngine.Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f), ppu);
        }

        private static Vector2 Dir(float a) => new(Mathf.Cos(a), Mathf.Sin(a));
        private static Color Hex(string hex) => ColorUtility.TryParseHtmlString("#" + hex, out var c) ? c : Color.white;
        private static Color WithAlpha(Color c, float a) { c.a = a; return c; }

        private static void FillCircle(Texture2D t, int cx, int cy, int r, Color c)
        {
            int rr = r * r;
            for (int y = -r; y <= r; y++)
            for (int x = -r; x <= r; x++)
                if (x * x + y * y <= rr) Put(t, cx + x, cy + y, c);
        }

        private static void OutlineCircle(Texture2D t, int cx, int cy, int r, int w, Color c)
        {
            int outer = r * r, inner = (r - w) * (r - w);
            for (int y = -r; y <= r; y++)
            for (int x = -r; x <= r; x++)
            {
                int d = x * x + y * y;
                if (d <= outer && d >= inner) Put(t, cx + x, cy + y, c);
            }
        }

        private static void FillEllipse(Texture2D t, int cx, int cy, int rx, int ry, Color c)
        {
            for (int y = -ry; y <= ry; y++)
            for (int x = -rx; x <= rx; x++)
                if ((x * x) / (float)(rx * rx) + (y * y) / (float)(ry * ry) <= 1f) Put(t, cx + x, cy + y, c);
        }

        private static void OutlineEllipse(Texture2D t, int cx, int cy, int rx, int ry, int w, Color c)
        {
            for (int y = -ry; y <= ry; y++)
            for (int x = -rx; x <= rx; x++)
            {
                float d = (x * x) / (float)(rx * rx) + (y * y) / (float)(ry * ry);
                float di = (x * x) / (float)((rx - w) * (rx - w)) + (y * y) / (float)((ry - w) * (ry - w));
                if (d <= 1f && di >= 1f) Put(t, cx + x, cy + y, c);
            }
        }

        private static void FillRect(Texture2D t, int x, int y, int w, int h, Color c)
        {
            for (int yy = y; yy < y + h; yy++) for (int xx = x; xx < x + w; xx++) Put(t, xx, yy, c);
        }

        private static void DrawLine(Texture2D t, int x0, int y0, int x1, int y1, int w, Color c)
        {
            int steps = Mathf.Max(Mathf.Abs(x1 - x0), Mathf.Abs(y1 - y0));
            for (int i = 0; i <= steps; i++)
            {
                float q = steps == 0 ? 0f : i / (float)steps;
                int x = Mathf.RoundToInt(Mathf.Lerp(x0, x1, q));
                int y = Mathf.RoundToInt(Mathf.Lerp(y0, y1, q));
                FillCircle(t, x, y, Mathf.Max(1, w / 2), c);
            }
        }

        private static void DrawArc(Texture2D t, int cx, int cy, int r, float a0, float a1, int w, Color c)
        {
            Vector2 prev = new(cx + Mathf.Cos(a0) * r, cy + Mathf.Sin(a0) * r);
            const int steps = 48;
            for (int i = 1; i <= steps; i++)
            {
                float a = Mathf.Lerp(a0, a1, i / (float)steps);
                Vector2 next = new(cx + Mathf.Cos(a) * r, cy + Mathf.Sin(a) * r);
                DrawLine(t, Mathf.RoundToInt(prev.x), Mathf.RoundToInt(prev.y), Mathf.RoundToInt(next.x), Mathf.RoundToInt(next.y), w, c);
                prev = next;
            }
        }

        private static void Put(Texture2D t, int x, int y, Color c)
        {
            if (x < 0 || y < 0 || x >= t.width || y >= t.height) return;
            Color old = t.GetPixel(x, y);
            float a = c.a + old.a * (1f - c.a);
            if (a <= 0f) return;
            Color blended = (c * c.a + old * old.a * (1f - c.a)) / a;
            blended.a = a;
            t.SetPixel(x, y, blended);
        }
    }
}
