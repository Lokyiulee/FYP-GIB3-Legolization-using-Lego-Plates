Shader "Custom/LEGO_SNOT_Bump" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGPROGRAM
        #pragma surface surf Standard
        #pragma target 3.0
        
        sampler2D _MainTex;
        sampler2D _BumpMap;
        float4 _Color;
        float _Smoothness;
        
        struct Input {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 worldPos;
            float3 worldNormal;
        };
        
        void surf (Input IN, inout SurfaceOutputStandard o) {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            fixed4 col = tex * _Color;
            o.Albedo = col.rgb;
            o.Metallic = 0;
            o.Smoothness = _Smoothness;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }
        
        ENDCG
    }
}
