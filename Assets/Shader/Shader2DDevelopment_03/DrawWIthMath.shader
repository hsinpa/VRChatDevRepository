Shader "Hsinpa/DrawWIthMath"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ThickNess ("Line Thickness", Range(0.000001, 0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _ThickNess;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed circle(float2 center, float radius, float softness, float2 uv)
            {
                fixed d = distance(center, uv);
                return 1 - smoothstep(
                    radius - softness, radius + softness, d
                );
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = (i.uv * 2) - 1;

                fixed circle1 = circle(float2(0.5, 0.5), 0.2, 0.005, uv);
                fixed circle2 = circle(float2(0.35, 0.35), 0.1, 0.005, uv);

                fixed c = circle1 - circle2;

                return fixed4(c, c, c, 1);
            }
            ENDCG
        }
    }
}
