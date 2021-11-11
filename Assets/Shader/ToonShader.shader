Shader "Hsinpa/ToonShader"
{
    Properties
    {
        [Header(Basic)]
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _AmbientLight("AmbientLight", Color) = (1,1,1,1)

        [Header(Rim Light)]
        _RimLightColor("RimLightColor", Color) = (1,1,1,1)
        _RimLightPower("RimLightPower", Range(0, 5)) = 1
        _RimLightStrength("RimLightStrength", Range(0, 1)) = 0.5

        [Header(Bling Phong)]
        _ToonShaderStyleTex("ToonShaderStyleTex",  2D) = "white" {}
        _ToonShaderNoiseTex("ToonShaderNoiseTex",  2D) = "white" {}
        _ToonShaderNoiseDisort("ToonShaderNoiseDisort", Range(0, 1)) = 0
        _ToonShaderThreshold("ToonShaderThreshold", Range(0.05, 1)) = 0.1
        _ToonShaderStrength("ToonShaderStrength", Range(0, 1)) = 0.5
        _ToonShaderGradientColor("ToonShaderGradientColor", Color) = (1,1,1,1)

        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _SpecularPower("SpecularPower", Range(0, 32)) = 1
        _SpecularStrength("SpecularStrength", Range(0, 3)) = 1
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
            #include "UnityLightingCommon.cginc" // for _LightColor0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal   : NORMAL;    // The vertex normal in model space.
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 cameraDirection : TEXCOORD2;
                float3 vertexWorldPos : TEXCOORD3;
            };

            struct SpecularLightStruct {
                float4 lightColor;
                float lightStrength;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //Light Related properties
            float4 _AmbientLight;

            float4 _RimLightColor;
            float _RimLightPower;
            float _RimLightStrength;

            float _ToonShaderThreshold;
            float _ToonShaderStrength;
            float4 _ToonShaderGradientColor;
            sampler2D _ToonShaderStyleTex;
            float4 _ToonShaderStyleTex_ST;
            sampler2D _ToonShaderNoiseTex;
            float4 _ToonShaderNoiseTex_ST;
            float _ToonShaderNoiseDisort;

            float4 _SpecularColor;
            float _SpecularPower;
            float _SpecularStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertexWorldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //float3 forward = normalize( mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)) * -1);

                float3 forward = normalize(_WorldSpaceCameraPos - o.vertexWorldPos);

                o.cameraDirection = forward;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 CalRimLight(fixed3 normal, fixed3 cameraDirection, float4 rimColor) {
                float cameraNormalDot = dot(normal, cameraDirection);

                float4 rimLight = 1.0 - saturate(cameraNormalDot);
                rimLight = pow(rimLight, _RimLightPower);
                rimLight = smoothstep(_RimLightStrength - 0.01, _RimLightStrength + 0.01, rimLight);

                return rimLight * rimColor;
            }

            fixed4 CalDiffuse(fixed4 mainTex, fixed3 normal, fixed4 lightColor, fixed4 styleColor) {
                float smoothStepMin = 0.01;
                fixed lightStr = dot(normal, normalize(_WorldSpaceLightPos0));
                fixed smoothLightStr = smoothstep(smoothStepMin, _ToonShaderThreshold, lightStr);

                fixed4 diffuseCol = mainTex * lightColor;
                fixed shadowHardness = clamp(smoothLightStr, 1 - _ToonShaderStrength, 1);

                if (lightStr >= smoothStepMin && lightStr < _ToonShaderThreshold) {
                    diffuseCol *= _ToonShaderGradientColor;
                }

                if ( lightStr < _ToonShaderThreshold) {
                    diffuseCol *= lerp(styleColor, fixed4(1, 1, 1, 1), shadowHardness) ;
                }

                return diffuseCol * shadowHardness;
            }

            SpecularLightStruct CalSpecularLight(fixed3 vertexWorldPos, fixed3 normal) {
                fixed3 V = normalize(vertexWorldPos - _WorldSpaceCameraPos);
                fixed specularStr = dot(reflect(normalize(_WorldSpaceLightPos0), normal), V);
                specularStr = pow(max(0, specularStr), _SpecularPower) * _SpecularStrength;
                
                SpecularLightStruct slStruct;
                slStruct.lightColor = specularStr * _SpecularColor;
                slStruct.lightStrength = saturate(specularStr);

                return slStruct;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainTex = tex2D(_MainTex, i.uv);

                fixed4 shadowNoiseTex = tex2D(_ToonShaderNoiseTex, fixed2(i.uv.x * _ToonShaderNoiseDisort, i.uv.y * _ToonShaderNoiseDisort));
                fixed4 shadowStyleTex = tex2D(_ToonShaderStyleTex, fixed2(i.uv.x * 10 * shadowNoiseTex.x, i.uv.y * 10 * shadowNoiseTex.y));

                fixed4 rimLight = CalRimLight(i.normal, i.cameraDirection, _RimLightColor);

                //PhongBling, ToonShading, Decide shadow side
                SpecularLightStruct specularStruct = CalSpecularLight(i.vertexWorldPos, i.normal);
                fixed4 specularCol = specularStruct.lightColor;
               
                fixed4 diffuseCol = CalDiffuse(mainTex, i.normal, _LightColor0, shadowStyleTex);

                fixed4 finalColor = diffuseCol + rimLight + specularCol + _AmbientLight;

                return finalColor;
            }
            ENDCG
        }

        Pass
        {
            Tags{ "LightMode" = "ShadowCaster" }
            CGPROGRAM
            #pragma vertex VSMain
            #pragma fragment PSMain

            float4 VSMain(float4 vertex:POSITION) : SV_POSITION
            {
                return UnityObjectToClipPos(vertex);
            }

            float4 PSMain(float4 vertex:SV_POSITION) : SV_TARGET
            {
                return 0;
            }

            ENDCG
        }

    }
}
