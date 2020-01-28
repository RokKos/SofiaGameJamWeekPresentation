Shader "ShaderBonanza/WaterfallShader"
{
    Properties
    {
        [HDR]_WaterColor("Water Color", Color) = (0.3, 0.1, 0.6, 1.0)
        _WaterSpeed("Water Speed", Float) = 5.0
        _RippleIntensity("Ripple Intensity", Float) = 5.0
        _VoronoiSpeed("Voronoi Speed", Float) = 5.0
        _CellDensity("Cell Density", Float) = 5.0
        _MinRippleValue("Min Ripple Value", Range(0.0, 1.0)) = 0.3
        _FoamScale("Foam Scale", Float) = 0.5
        _FoamHeight("Foam Height", Float) = 0.5
        _FoamMaxValue("Foam MaxValue", Float) = 5.0
        _VertexOffsetCoef("Vertex Offset Coef", Float) = 5.0
        _Errorsion("Errorsion", Range(-1.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        LOD 100

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
                float2 movedUv : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            ////////////////
            // Putting everything together -> Main effect
            ////////////////
            float _WaterSpeed;
            float _RippleIntensity;
            float _CellDensity;
            float _VoronoiSpeed;
            float _MinRippleValue;
            float _FoamHeight;
            float _FoamScale;
            float _FoamMaxValue;
            float _VertexOffsetCoef;

            float WaterFallEffect(float2 UV, float2 movedUV) {
                // Ripple effect
                float ripple = Unity_Voronoi_float(movedUV, _Time.z * _VoronoiSpeed, _CellDensity);
                ripple = pow(ripple, _RippleIntensity);
                ripple = Remap(ripple, float2(0.0, 1.0), float2(_MinRippleValue, 1.0));
                //return ripple;

                // Foam effect
                float invertedUVy = 1 - UV.y;
                invertedUVy = pow(invertedUVy, _FoamHeight);
                float foam = SimpleNoise(movedUV, _FoamScale) * invertedUVy;
                foam = Remap(foam, float2(0.0, 1.0), float2(0.0, _FoamMaxValue));
                //return foam;

                return ripple + foam;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.color = v.color;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.movedUv = v.uv + float2(0.0, _Time.x * _WaterSpeed);

                // vertex displacement
                o.vertex.rgb += WaterFallEffect(o.uv, o.movedUv) * v.normal * _VertexOffsetCoef;

                return o;
            }

            float4 _WaterColor;
            float _Errorsion;

            fixed4 frag (v2f i) : SV_Target
            {   
                float noise = WaterFallEffect(i.uv, i.movedUv);
                
                float invertedNoise = 1.0 - noise;
                clip(_Errorsion - invertedNoise);

                return  noise * _WaterColor * i.color;
            }
            ENDCG
        }
    }
}
