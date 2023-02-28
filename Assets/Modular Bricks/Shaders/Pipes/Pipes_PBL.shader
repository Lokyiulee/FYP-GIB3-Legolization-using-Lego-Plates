// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Modular Bricks/Pipes/PBL" {
	Properties{
		_Color("Color", Color) = (0.5019608,0.5019608,0.5019608,1)
		_MainTex("Base Color", 2D) = "white" {}
		_Metallic("Metallic", Range(0, 1)) = 0
		_Gloss("Gloss", Range(0, 1)) = 0.4700855
		_Radius("Radius", Float) = 0.025
		_Height("Height", Float) = 0.2
	}
	SubShader{
		Tags{"RenderType" = "Opaque"}
		Pass{
			Name "FORWARD"
			Tags{"LightMode" = "ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile_fog
            #pragma target 3.0
			uniform float4 _Color;
			uniform sampler2D _MainTex; 
			uniform float4 _MainTex_ST;
			uniform float _Metallic;
			uniform float _Gloss;
			half _Radius;
			half _Height;

			struct Input {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};

			struct Interpolators {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
				UNITY_FOG_COORDS(5)
			};

			Input vert(Input v) {
				return v;
			}

			Interpolators CreateInterpolator(float4 pos, float3 normal, float2 uv) {
				Input v;
				v.vertex = pos;
				v.normal = normal;
				v.texcoord0 = uv;
				Interpolators o = (Interpolators)0;
				o.uv0 = v.texcoord0;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 lightColor = _LightColor0.rgb;
				o.pos = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}

			inline float2 RotateVector(float2 v, float angle) {
				float radians = angle * 0.01745329251;
				float2 newV;
				newV.x = v.x * cos(radians) - v.y * sin(radians);
				newV.y = v.x * sin(radians) + v.y * cos(radians);
				return newV;
			}

			[maxvertexcount(24)]
			void geom(triangle Input p[3], inout TriangleStream<Interpolators> triStream)
			{
				triStream.Append(CreateInterpolator(p[0].vertex, p[0].normal, p[0].texcoord0));
				triStream.Append(CreateInterpolator(p[1].vertex, p[1].normal, p[1].texcoord0));
				triStream.Append(CreateInterpolator(p[2].vertex, p[2].normal, p[2].texcoord0));
				triStream.RestartStrip();

				// additional geometry [pipes]
				// verificam daca triunghiul tinteste in sus, produs scalar intre un vector vertical si cel rezultat din compunerea 
				// normalelor fiecarui vertex
				float3 triangleNormal = p[0].normal + p[1].normal + p[2].normal;
				//triangleNormal = normalize(triangleNormal);
				if ((triangleNormal / 3).y > 0.98)
				{
					// vectorul distanta
					float3 l1 = p[0].vertex.xyz - p[1].vertex.xyz;
					float3 l2 = p[1].vertex.xyz - p[2].vertex.xyz;
					float3 l3 = p[2].vertex.xyz - p[0].vertex.xyz;

					// laturile triunghilui sau magnitudinile vectorului de distante dintre laturi
					float m_01 = length(l1);
					float m_12 = length(l2);
					float m_20 = length(l3);

					// codul ca sa aflu mijlocul ipotenuzei
					float c = max(max(m_01, m_12), m_20);
					c -= c * 0.1;
					float3 v_max = float3(c, c, c);

					float3 coef = step(v_max, float3(m_01, m_12, m_20));
					float4 mid_ip;
					float4 new_p[3];
					new_p[0] = p[0].vertex * (coef.x + coef.z);
					new_p[1] = p[1].vertex * (coef.x + coef.y);
					new_p[2] = p[2].vertex * (coef.y + coef.z);

					// acum mid este mijlocu ipotenuzei
					mid_ip = (new_p[0] + new_p[1] + new_p[2]) / 2;
					mid_ip.w = 1;

					// aflam centru de greutate
					float4 center_of_mass = (p[0].vertex + p[1].vertex + p[2].vertex) / 3;

					// aflam vectorul diferenta dintre mijlocul ipotenuzei si centrul de greutate
					float4 d_mid = mid_ip - center_of_mass;
					d_mid = normalize(d_mid);

					// rotim vectorul pentru a afla vectorul de directie al ipotenuzei
					float4 d_mid_rot90 = float4(-d_mid.z, d_mid.y, d_mid.x, d_mid.w);
					d_mid_rot90 = normalize(d_mid_rot90);

					// punctul de start pentru semicerc relativ cu originea
					float4 circle_start = d_mid_rot90 * _Radius;

					// declaram vectorii care contin vertexurile
					float4 vertices_up[7];
					float4 vertices_down[7];
					float3 normals[7];
					float3 normal_up = float3(0, 1, 0);

					vertices_up[0] = mid_ip + float4(circle_start.x, _Height / 10, circle_start.z, 0.0f);
					vertices_down[0] = mid_ip + float4(circle_start.x, 0.0f, circle_start.z, 0.0f);
					normals[0] = float3(circle_start.x, 0.0f, circle_start.z);

					for (int i = 1; i < 7; i++)
					{
						float2 point_2d = RotateVector(float2(circle_start.x, circle_start.z), (i * 30));
						vertices_up[i] = mid_ip + float4(point_2d.x, _Height / 10, point_2d.y, 0.0f);
						vertices_down[i] = mid_ip + float4(point_2d.x, 0.0f, point_2d.y, 0.0f);
						normals[i] = float3(point_2d.x, 0.0f, point_2d.y);
						normals[i] = normalize(normals[i]);
					}

					triStream.Append(CreateInterpolator(vertices_up[0], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[6], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[1], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[5], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[2], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[4], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[3], normal_up, p[0].texcoord0));
					triStream.RestartStrip();

					// desenam baza
					for (int i = 0; i < 7; i++)
					{
						triStream.Append(CreateInterpolator(vertices_down[i], normals[i], p[0].texcoord0));
						triStream.Append(CreateInterpolator(vertices_up[i], normals[i], p[0].texcoord0));
					}
				}
			}

			float4 frag(Interpolators i) : COLOR {
				i.normalDir = normalize(i.normalDir);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 normalDirection = i.normalDir;
				float3 viewReflectDirection = reflect(-viewDirection, normalDirection);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;
				float3 halfDirection = normalize(viewDirection + lightDirection);
				////// Lighting:
				float attenuation = LIGHT_ATTENUATION(i);
				float3 attenColor = attenuation * _LightColor0.xyz;
				float Pi = 3.141592654;
				float InvPi = 0.31830988618;
				///////// Gloss:
				float gloss = _Gloss;
				float specPow = exp2(gloss * 10.0 + 1.0);
				/////// GI Data:
				UnityLight light;
				#ifdef LIGHTMAP_OFF
				light.color = lightColor;
				light.dir = lightDirection;
				light.ndotl = LambertTerm(normalDirection, light.dir);
				#else
				light.color = half3(0.f, 0.f, 0.f);
				light.ndotl = 0.0f;
				light.dir = half3(0.f, 0.f, 0.f);
				#endif
				UnityGIInput d;
				d.light = light;
				d.worldPos = i.posWorld.xyz;
				d.worldViewDir = viewDirection;
				d.atten = attenuation;
				d.boxMax[0] = unity_SpecCube0_BoxMax;
				d.boxMin[0] = unity_SpecCube0_BoxMin;
				d.probePosition[0] = unity_SpecCube0_ProbePosition;
				d.probeHDR[0] = unity_SpecCube0_HDR;
				d.boxMax[1] = unity_SpecCube1_BoxMax;
				d.boxMin[1] = unity_SpecCube1_BoxMin;
				d.probePosition[1] = unity_SpecCube1_ProbePosition;
				d.probeHDR[1] = unity_SpecCube1_HDR;
				Unity_GlossyEnvironmentData ugls_en_data;
				ugls_en_data.roughness = 1.0 - gloss;
				ugls_en_data.reflUVW = viewReflectDirection;
				UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data);
				lightDirection = gi.light.dir;
				lightColor = gi.light.color;
				////// Specular:
				float NdotL = max(0, dot(normalDirection, lightDirection));
				float LdotH = max(0.0,dot(lightDirection, halfDirection));
				float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				float3 diffuseColor = (_MainTex_var.rgb*_Color.rgb); // Need this for specular when using metallic
				float specularMonochrome;
				float3 specularColor;
				diffuseColor = DiffuseAndSpecularFromMetallic(diffuseColor, _Metallic, specularColor, specularMonochrome);
				specularMonochrome = 1 - specularMonochrome;
				float NdotV = max(0.0,dot(normalDirection, viewDirection));
				float NdotH = max(0.0,dot(normalDirection, halfDirection));
				float VdotH = max(0.0,dot(viewDirection, halfDirection));
				float visTerm = SmithBeckmannVisibilityTerm(NdotL, NdotV, 1.0 - gloss);
				float normTerm = max(0.0, NDFBlinnPhongNormalizedTerm(NdotH, RoughnessToSpecPower(1.0 - gloss)));
				float specularPBL = max(0, (NdotL*visTerm*normTerm) * (UNITY_PI / 4));
				float3 directSpecular = (floor(attenuation) * _LightColor0.xyz) * pow(max(0,dot(halfDirection,normalDirection)),specPow)*specularPBL*lightColor*FresnelTerm(specularColor, LdotH);
				half grazingTerm = saturate(gloss + specularMonochrome);
				float3 indirectSpecular = (gi.indirect.specular);
				indirectSpecular *= FresnelLerp(specularColor, grazingTerm, NdotV);
				float3 specular = (directSpecular + indirectSpecular);
				/////// Diffuse:
				NdotL = max(0.0,dot(normalDirection, lightDirection));
				half fd90 = 0.5 + 2 * LdotH * LdotH * (1 - gloss);
				float3 directDiffuse = ((1 + (fd90 - 1)*pow((1.00001 - NdotL), 5)) * (1 + (fd90 - 1)*pow((1.00001 - NdotV), 5)) * NdotL) * attenColor;
				float3 indirectDiffuse = float3(0,0,0);
				indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
				float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
				/// Final Color:
				float3 finalColor = diffuse + specular;
				fixed4 finalRGBA = fixed4(finalColor,1);
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}
		Pass{
			Name "FORWARD_DELTA"
			Tags{
			"LightMode" = "ForwardAdd"
			}
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#define UNITY_PASS_FORWARDADD
			#define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; 
			uniform float4 _MainTex_ST;
            uniform float _Metallic;
            uniform float _Gloss;
			half _Radius;
			half _Height;

			struct Input {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			struct Interpolators {
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
					UNITY_FOG_COORDS(5)
			};

			Input vert(Input v) {
				return v;
			}

			Interpolators CreateInterpolator(float4 pos, float3 normal, float2 uv) {
				Input v;
				v.vertex = pos;
				v.normal = normal;
				v.texcoord0 = uv;
				Interpolators o = (Interpolators)0;
				o.uv0 = v.texcoord0;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				float3 lightColor = _LightColor0.rgb;
				o.pos = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}

			inline float2 RotateVector(float2 v, float angle)
			{
				float radians = angle * 0.01745329251;
				float2 newV;
				newV.x = v.x * cos(radians) - v.y * sin(radians);
				newV.y = v.x * sin(radians) + v.y * cos(radians);
				return newV;
			}

			[maxvertexcount(24)]
			void geom(triangle Input p[3], inout TriangleStream<Interpolators> triStream)
			{
				triStream.Append(CreateInterpolator(p[0].vertex, p[0].normal, p[0].texcoord0));
				triStream.Append(CreateInterpolator(p[1].vertex, p[1].normal, p[1].texcoord0));
				triStream.Append(CreateInterpolator(p[2].vertex, p[2].normal, p[2].texcoord0));
				triStream.RestartStrip();

				// additional geometry [pipes]
				// verificam daca triunghiul tinteste in sus, produs scalar intre un vector vertical si cel rezultat din compunerea 
				// normalelor fiecarui vertex
				float3 triangleNormal = p[0].normal + p[1].normal + p[2].normal;
				//triangleNormal = normalize(triangleNormal);
				if ((triangleNormal / 3).y > 0.98)
				{
					// vectorul distanta
					float3 l1 = p[0].vertex.xyz - p[1].vertex.xyz;
					float3 l2 = p[1].vertex.xyz - p[2].vertex.xyz;
					float3 l3 = p[2].vertex.xyz - p[0].vertex.xyz;

					// laturile triunghilui sau magnitudinile vectorului de distante dintre laturi
					float m_01 = length(l1);
					float m_12 = length(l2);
					float m_20 = length(l3);

					// codul ca sa aflu mijlocul ipotenuzei
					float c = max(max(m_01, m_12), m_20);
					c -= c * 0.1;
					float3 v_max = float3(c, c, c);

					float3 coef = step(v_max, float3(m_01, m_12, m_20));
					float4 mid_ip;
					float4 new_p[3];
					new_p[0] = p[0].vertex * (coef.x + coef.z);
					new_p[1] = p[1].vertex * (coef.x + coef.y);
					new_p[2] = p[2].vertex * (coef.y + coef.z);

					// acum mid este mijlocu ipotenuzei
					mid_ip = (new_p[0] + new_p[1] + new_p[2]) / 2;
					mid_ip.w = 1;

					// aflam centru de greutate
					float4 center_of_mass = (p[0].vertex + p[1].vertex + p[2].vertex) / 3;

					// aflam vectorul diferenta dintre mijlocul ipotenuzei si centrul de greutate
					float4 d_mid = mid_ip - center_of_mass;
					d_mid = normalize(d_mid);

					// rotim vectorul pentru a afla vectorul de directie al ipotenuzei
					float4 d_mid_rot90 = float4(-d_mid.z, d_mid.y, d_mid.x, d_mid.w);
					d_mid_rot90 = normalize(d_mid_rot90);

					// punctul de start pentru semicerc relativ cu originea
					float4 circle_start = d_mid_rot90 * _Radius;

					// declaram vectorii care contin vertexurile
					float4 vertices_up[7];
					float4 vertices_down[7];
					float3 normals[7];
					float3 normal_up = float3(0, 1, 0);

					vertices_up[0] = mid_ip + float4(circle_start.x, _Height / 10, circle_start.z, 0.0f);
					vertices_down[0] = mid_ip + float4(circle_start.x, 0.0f, circle_start.z, 0.0f);
					normals[0] = float3(circle_start.x, 0.0f, circle_start.z);

					for (int i = 1; i < 7; i++)
					{
						float2 point_2d = RotateVector(float2(circle_start.x, circle_start.z), (i * 30));
						vertices_up[i] = mid_ip + float4(point_2d.x, _Height / 10, point_2d.y, 0.0f);
						vertices_down[i] = mid_ip + float4(point_2d.x, 0.0f, point_2d.y, 0.0f);
						normals[i] = float3(point_2d.x, 0.0f, point_2d.y);
						normals[i] = normalize(normals[i]);
					}

					triStream.Append(CreateInterpolator(vertices_up[0], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[6], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[1], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[5], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[2], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[4], normal_up, p[0].texcoord0));
					triStream.Append(CreateInterpolator(vertices_up[3], normal_up, p[0].texcoord0));
					triStream.RestartStrip();

					// desenam baza
					for (int i = 0; i < 7; i++)
					{
						triStream.Append(CreateInterpolator(vertices_down[i], normals[i], p[0].texcoord0));
						triStream.Append(CreateInterpolator(vertices_up[i], normals[i], p[0].texcoord0));
					}
				}
			}

			float4 frag(Interpolators i) : COLOR{
				i.normalDir = normalize(i.normalDir);
				float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
				float3 normalDirection = i.normalDir;
				float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
				float3 lightColor = _LightColor0.rgb;
				float3 halfDirection = normalize(viewDirection + lightDirection);
				////// Lighting:
				float attenuation = LIGHT_ATTENUATION(i);
				float3 attenColor = attenuation * _LightColor0.xyz;
				float Pi = 3.141592654;
				float InvPi = 0.31830988618;
				///////// Gloss:
				float gloss = _Gloss;
				float specPow = exp2(gloss * 10.0 + 1.0);
				////// Specular:
				float NdotL = max(0, dot(normalDirection, lightDirection));
				float LdotH = max(0.0,dot(lightDirection, halfDirection));
				float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
				float3 diffuseColor = (_MainTex_var.rgb*_Color.rgb); // Need this for specular when using metallic
				float specularMonochrome;
				float3 specularColor;
				diffuseColor = DiffuseAndSpecularFromMetallic(diffuseColor, _Metallic, specularColor, specularMonochrome);
				specularMonochrome = 1 - specularMonochrome;
				float NdotV = max(0.0,dot(normalDirection, viewDirection));
				float NdotH = max(0.0,dot(normalDirection, halfDirection));
				float VdotH = max(0.0,dot(viewDirection, halfDirection));
				float visTerm = SmithBeckmannVisibilityTerm(NdotL, NdotV, 1.0 - gloss);
				float normTerm = max(0.0, NDFBlinnPhongNormalizedTerm(NdotH, RoughnessToSpecPower(1.0 - gloss)));
				float specularPBL = max(0, (NdotL*visTerm*normTerm) * (UNITY_PI / 4));
				float3 directSpecular = attenColor * pow(max(0,dot(halfDirection,normalDirection)),specPow)*specularPBL*lightColor*FresnelTerm(specularColor, LdotH);
				float3 specular = directSpecular;
				/////// Diffuse:
				NdotL = max(0.0,dot(normalDirection, lightDirection));
				half fd90 = 0.5 + 2 * LdotH * LdotH * (1 - gloss);
				float3 directDiffuse = ((1 + (fd90 - 1)*pow((1.00001 - NdotL), 5)) * (1 + (fd90 - 1)*pow((1.00001 - NdotV), 5)) * NdotL) * attenColor;
				float3 diffuse = directDiffuse * diffuseColor;
				/// Final Color:
				float3 finalColor = diffuse + specular;
				fixed4 finalRGBA = fixed4(finalColor * 1,0);
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct Interpolators {
				V2F_SHADOW_CASTER;
			};

			struct Input {
				float4 vertex : POSITION;
				float3	normal	: NORMAL;
			};

			float _Radius;
			float _Height;
			const float degToRad = 0.01745329251;

			Input vert(Input v)
			{
				return v;
			}

			Interpolators CreateV2F(float4 vertex, float3 normal) {
				Input v;
				v.vertex = vertex;
				v.normal = normal;
				Interpolators o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
				return o;
			}

			inline float2 RotateVector(float2 v, float angle)
			{
				float radians = angle * 0.01745329251;
				float2 newV;
				newV.x = v.x * cos(radians) - v.y * sin(radians);
				newV.y = v.x * sin(radians) + v.y * cos(radians);
				return newV;
			}

			[maxvertexcount(24)]
			void geom(triangle Input p[3], inout TriangleStream<Interpolators> triStream)
			{
				// drawing the input geometry
				triStream.Append(CreateV2F(p[0].vertex, p[0].normal));
				triStream.Append(CreateV2F(p[1].vertex, p[0].normal));
				triStream.Append(CreateV2F(p[2].vertex, p[0].normal));
				triStream.RestartStrip();

				float3 triangleNormal = p[0].normal + p[1].normal + p[2].normal;
				//triangleNormal = normalize(triangleNormal);
				if ((triangleNormal / 3).y > 0.98)
				{
					// vectorul distanta
					float3 l1 = p[0].vertex.xyz - p[1].vertex.xyz;
					float3 l2 = p[1].vertex.xyz - p[2].vertex.xyz;
					float3 l3 = p[2].vertex.xyz - p[0].vertex.xyz;

					// laturile triunghilui sau magnitudinile vectorului de distante dintre laturi
					float m_01 = length(l1);
					float m_12 = length(l2);
					float m_20 = length(l3);

					// codul ca sa aflu mijlocul ipotenuzei
					float c = max(max(m_01, m_12), m_20);
					c -= c * 0.1;
					float3 v_max = float3(c, c, c);

					float3 coef = step(v_max, float3(m_01, m_12, m_20));
					float4 mid_ip;
					float4 new_p[3];
					new_p[0] = p[0].vertex * (coef.x + coef.z);
					new_p[1] = p[1].vertex * (coef.x + coef.y);
					new_p[2] = p[2].vertex * (coef.y + coef.z);

					// acum mid este mijlocu ipotenuzei
					mid_ip = (new_p[0] + new_p[1] + new_p[2]) / 2;
					mid_ip.w = 1;

					// aflam centru de greutate
					float4 center_of_mass = (p[0].vertex + p[1].vertex + p[2].vertex) / 3;

					// aflam vectorul diferenta dintre mijlocul ipotenuzei si centrul de greutate
					float4 d_mid = mid_ip - center_of_mass;
					d_mid = normalize(d_mid);

					// rotim vectorul pentru a afla vectorul de directie al ipotenuzei
					float4 d_mid_rot90 = float4(-d_mid.z, d_mid.y, d_mid.x, d_mid.w);
					d_mid_rot90 = normalize(d_mid_rot90);

					// punctul de start pentru semicerc relativ cu originea
					float4 circle_start = d_mid_rot90 * _Radius;

					// declaram vectorii care tin vertexurile
					float4 vertices_up[7];
					float4 vertices_down[7];
					float3 normals[7];
					float3 normal_up = float3(0, 1, 0);

					vertices_up[0] = mid_ip + float4(circle_start.x, _Height / 10, circle_start.z, 0.0f);
					vertices_down[0] = mid_ip + float4(circle_start.x, 0.0f, circle_start.z, 0.0f);
					normals[0] = float3(circle_start.x, 0.0f, circle_start.z);

					for (int i = 1; i < 7; i++)
					{
						float2 point_2d = RotateVector(float2(circle_start.x, circle_start.z), (i * 30));
						vertices_up[i] = mid_ip + float4(point_2d.x, _Height / 10, point_2d.y, 0.0f);
						vertices_down[i] = mid_ip + float4(point_2d.x, 0.0f, point_2d.y, 0.0f);
						normals[i] = float3(point_2d.x, 0.0f, point_2d.y);
						normals[i] = normalize(normals[i]);
					}

					triStream.Append(CreateV2F(vertices_up[0], normal_up));
					triStream.Append(CreateV2F(vertices_up[6], normal_up));
					triStream.Append(CreateV2F(vertices_up[1], normal_up));
					triStream.Append(CreateV2F(vertices_up[5], normal_up));
					triStream.Append(CreateV2F(vertices_up[2], normal_up));
					triStream.Append(CreateV2F(vertices_up[4], normal_up));
					triStream.Append(CreateV2F(vertices_up[3], normal_up));
					triStream.RestartStrip();

					// desenam baza
					for (int i = 0; i < 7; i++)
					{
						triStream.Append(CreateV2F(vertices_down[i], normals[i]));
						triStream.Append(CreateV2F(vertices_up[i], normals[i]));
					}
				}
			}

			float4 frag(Interpolators i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
