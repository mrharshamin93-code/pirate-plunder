Shader "PiratesPlunder/Whirlpool"
{
    Properties
    {
        _DeepColor ("Deep", Color) = (0.01,0.05,0.07,1)
        _MidColor ("Mid", Color) = (0.02,0.22,0.28,1)
        _FoamColor ("Foam", Color) = (0.75,0.95,1,1)
        _Spin ("Spin", Float) = 2.2
        _Strength ("Strength", Float) = 5.0
        _Core ("Core", Range(0.01,0.3)) = 0.07
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; };
            struct v2f { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; };

            fixed4 _DeepColor, _MidColor, _FoamColor;
            float _Spin, _Strength, _Core;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 p = i.uv - 0.5;
                float r = length(p) * 2.0;
                if (r > 1.0) discard;

                float a = atan2(p.y, p.x);
                float spin = a + _Time.y * _Spin + (1.0 - r) * _Strength;
                float rings = sin(spin * 4.0 + r * 34.0) * 0.5 + 0.5;
                float bands = smoothstep(0.62, 0.95, rings) * smoothstep(1.0, 0.18, r);
                float foam = bands * smoothstep(_Core + 0.04, 0.95, r);

                float core = 1.0 - smoothstep(_Core, _Core + 0.08, r);
                fixed3 water = lerp(_MidColor.rgb, _DeepColor.rgb, pow(1.0 - r, 1.7));
                water = lerp(water, _FoamColor.rgb, foam * 0.85);
                water = lerp(water, fixed3(0,0,0), core * 0.92);

                float edge = smoothstep(1.0, 0.82, r);
                float alpha = edge * (0.78 + foam * 0.22);
                return fixed4(water, alpha);
            }
            ENDCG
        }
    }
}
