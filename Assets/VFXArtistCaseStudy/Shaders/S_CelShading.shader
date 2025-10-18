Shader "S_CelShading"
{
    Properties
    {
        [HDR]_Tint               ("Tint", Color) = (1,1,1,1)
        _Ambient                 ("Ambient Add", Range(0,1)) = 0.1

        [Header(Light)]
        _LightDirection          ("Light Direction (WS)", Vector) = (0,1,0,0)
        [HDR]_LightColor         ("Light Color", Color) = (1,1,1,1)
        _LightIntensity          ("Light Intensity", Range(0,8)) = 1

        [Header(Cel)]
        _CelThreshold            ("Cel Threshold", Range(0,1)) = 0.5
        _CelFeather              ("Cel Feather", Range(0,0.5)) = 0.05

        [Header(Palette 2DArray)]
        _PaletteArray            ("Palette (Texture2D)", 2D) = "black" {}
        _Strength                ("Palette Strength", Range(0,1)) = 0.7

        [Header(Fake Shadow)]
        _ShadowDirection         ("Fake Shadow Direction (WS)", Vector) = (0,1,0,0)
        _FakeShadowStrength      ("Fake Shadow Strength", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma target 3.0
            #pragma require 2darray

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS        : SV_POSITION;
                float2 uv                : TEXCOORD0;
                float3 normalWS          : TEXCOORD1;
                float3 posWS             : TEXCOORD2;
                float4 overlayColor      : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            CBUFFER_START(HeroInstancingData)
                float4 _Tint;
                float  _Ambient;

                float  _UseLightDirection;
                float4 _LightDirection;
                float4 _LightPosition;
                float4 _LightColor;
                float  _LightIntensity;

                float  _CelThreshold;
                float  _CelFeather;

                float  _Strength;
                float4 _Tex1_TexelSize;
                float4 _ShadowDirection;
                float  _FakeShadowStrength;
            CBUFFER_END
            
            Texture2D _PaletteArray;
            SamplerState point_repeat_sampler;
        
            v2f vert(appdata v, uint id : SV_VertexID, uint instanceId : SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                float3 posOS = v.positionOS.xyz;
                float3 nrmOS = v.normalOS;

                o.overlayColor = float4(0,0,0,0);

                VertexPositionInputs pos = GetVertexPositionInputs(posOS);
                o.positionCS = pos.positionCS;
                o.posWS      = pos.positionWS;
                o.normalWS   = TransformObjectToWorldNormal(nrmOS);
                o.uv         = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 N = normalize(i.normalWS);

                float3 LdirDir  = normalize(_LightDirection.xyz);
                float NdotL     = saturate(dot(N, LdirDir));
                float shadeToon = smoothstep(_CelThreshold - _CelFeather, _CelThreshold + _CelFeather, NdotL);
                float shade     = lerp(NdotL, shadeToon, 1);
                float3 lit = _Tint.rgb * ((_LightColor.rgb * _LightIntensity) * shade + _Ambient);
                float3 palCol = _PaletteArray.Sample(point_repeat_sampler, i.uv, 0).rgb;
                float3 palChosen = palCol;
                float3 outRGB = lerp(lit, palChosen, _Strength);
                float3 Sdir = normalize(_ShadowDirection.xyz);
                float  NdotS = dot(N, Sdir);               
                float  shadowMask = saturate(-NdotS);      
                float  shadowFactor = lerp(1.0, 1.0 - _FakeShadowStrength, shadowMask);
                outRGB *= shadowFactor;

                return half4(outRGB, _Tint.a);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
