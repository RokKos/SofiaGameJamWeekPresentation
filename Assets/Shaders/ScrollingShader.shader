Shader "ShaderBonanza/ScrollingShader"
{
    Properties
    {
        _MainTex ("Ripple Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}
        [HDR]_RippleColor("Ripple Color", Color) = (0.3, 0.1, 0.6, 1.0)
        _RippleSpeed ("Ripple Speed", Float) = 3.0
        _Distortion ("Distortion", Range(0.0, 1.0)) = 0.5
        _VoronoiSpeed ("VoronoiSpeed", Float) = 3.0
        _VoronoiCellDensity ("Voronoi Cell Density", Float) = 3.0
        _VoronoiOffset ("Voronoi Offset", Float) = 3.0
        _DisolveCoef("Disolve Coef", Range(0.0, 1.0)) = 0.5
        _DisolvePower("Disolve Power", Float) = 3.0
        //_VertexDisplacement("Vertex Displacement", Float) = 3.0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
        LOD 100
        Cull off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "VoronoiHelper.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float _RippleSpeed;
            float _Distortion;
            float _VoronoiSpeed;
            float _VoronoiCellDensity;
            float _VoronoiOffset;
            float _DisolveCoef;
            float _DisolvePower;
            //float _VertexDisplacement;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float voronoiUV = o.uv + float2(0, _Time.y) * _VoronoiSpeed;
                float voronoiNoise = VoronoiNoise(voronoiUV, _VoronoiOffset, _VoronoiCellDensity);
                
                o.uv += float2(0, _Time.y) * _RippleSpeed;
                o.uv = lerp(o.uv, o.uv + float2(voronoiNoise, voronoiNoise), _Distortion); 

                // Vertex distortion
                //fixed4 alpha = tex2Dlod(_MainTex, float4(o.uv, 0.0, 0.0));
                //voronoiNoise = VoronoiNoise(o.uv, _VoronoiOffset, _VoronoiCellDensity);
                //float disolve = lerp(alpha.r, voronoiNoise, _DisolveCoef);
                //disolve = pow(disolve, _DisolvePower);

                //fixed4 mask = tex2Dlod(_MaskTex, float4(o.uv, 0.0, 0.0));
                //o.vertex += float4(v.normal * disolve * mask.r, 0.0) * _VertexDisplacement;    

                return o;
            }

            float4 _RippleColor;

            fixed4 frag (v2f i) : SV_Target
            {
                //return float4(i.uv, 0.0, 1.0);
                fixed4 alpha = tex2D(_MainTex, i.uv);
                //return alpha;
                float voronoiNoise = VoronoiNoise(i.uv, _VoronoiOffset, _VoronoiCellDensity);
                float disolve = lerp(alpha.r, voronoiNoise, _DisolveCoef);
                disolve = pow(disolve, _DisolvePower);


                
                fixed4 mask = tex2D(_MaskTex, i.uv);
                //return mask;
                fixed4 color = _RippleColor;
                color.a = disolve * mask.r;

                return color * i.color;
            }
            ENDCG
        }
    }
}

