Shader "Hsinpa/DisplayShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PaintTex ("Texture", 2D) = "white" {}
        [MaterialToggle] _OverrideColor ("Override Color", Float) = 0
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

            sampler2D _PaintTex;
            float4 _PaintTex_ST;

            float _OverrideColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 paintTex = tex2D(_PaintTex, i.uv);

                if ((length(paintTex.rgb) * _OverrideColor) > 0) {
                    return paintTex;
                }

                col = col + paintTex;
                

                return col;
            }
            ENDCG
        }
    }
}
