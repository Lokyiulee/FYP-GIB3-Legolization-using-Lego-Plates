Shader "Custom/SNOTShader" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
    }
    SubShader {
        Tags {"Queue"="Transparent" "RenderType"="Opaque"}
        LOD 100

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert

        sampler2D _MainTex;
        sampler2D _BumpMap;
        float4 _BumpScale;

        struct Input {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float3 worldNormal;
            float3 worldPos;
            INTERNAL_DATA
        };

        void vert(inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.worldNormal = mul (float4(v.normal, 0.0), unity_WorldToObject).xyz;
            o.worldPos = mul(unity_ObjectToWorld, v.vertex);
            o.uv_MainTex = v.texcoord;
            o.uv_BumpMap = v.texcoord.xy * 3.0;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Metallic = 0;
            o.Smoothness = 0.5;
            o.Alpha = 1;
            float3 worldNormal = normalize(IN.worldNormal);
            float3 worldPos = IN.worldPos;
            float3 offset = worldNormal * 0.5;
            worldPos += offset;
            o.Normal = normalize(mul(unity_WorldToObject, float4(worldNormal, 0.0))).xyz;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
