Shader "Unlit/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AmbientLight("AmbientLight", Color) = (1,1,1,1)

        _RimLightColor("RimLightColor", Color) = (1,1,1,1)
        _RimLightPower("RimLightPower", Range(0, 5)) = 1
        _RimLightStrength("RimLightStrength", Range(0, 1)) = 0.5

        _ToonShaderThreshold("ToonShaderThreshold", Range(0, 2)) = 1
        _ToonShaderStrength("ToonShaderStrength", Range(0, 1)) = 0.5

        _SpecularColor("SpecularColor", Color) = (1,1,1,1)
        _SpecularPower("SpecularPower", Range(0, 32)) = 1
        _SpecularStrength("SpecularStrength", Range(0, 1)) = 0.5
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

            sampler2D _MainTex;
            float4 _MainTex_ST;


            //Light Related properties
            float4 _AmbientLight;

            float4 _RimLightColor;
            float _RimLightPower;
            float _RimLightStrength;

            float _ToonShaderThreshold;
            float _ToonShaderStrength;

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

            fixed4 CalDiffuse(fixed4 mainTex, fixed4 lightColor, fixed lightStr) {
                fixed4 diffuseCol = smoothstep(0.05, _ToonShaderThreshold, lightStr);
                return mainTex * lightColor * clamp(diffuseCol, 1 - _ToonShaderStrength, 1);
            }

            fixed4 CalSpecular() {
            
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                
                fixed4 rimLight = CalRimLight(i.normal, i.cameraDirection, _RimLightColor);

                //PhongBling, ToonShading, Decide shadow side
                fixed normalLightDot = dot(i.normal, normalize(_WorldSpaceLightPos0));
                fixed4 diffuseCol = CalDiffuse(mainTex, _LightColor0, normalLightDot);

                fixed3 V = normalize(i.vertexWorldPos - _WorldSpaceCameraPos);
                fixed specularStr = dot( reflect(normalize(_WorldSpaceLightPos0), i.normal), V);
                      specularStr = pow(max(0, specularStr), _SpecularPower) * _SpecularStrength;
                fixed4 specularCol = specularStr * _SpecularColor;


                fixed4 finalColor = diffuseCol + _AmbientLight + rimLight + specularCol;

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
