// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Modular Bricks/Pipes/Diffuse Color" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_Radius("Radius", Float) = 0.1
		_Height("Height", Float) = 0.4
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
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile_fog
			#pragma target 3.0
			uniform float4 _LightColor0;
			uniform float4 _Color;
			half _Radius;
			half _Height;

			struct Input {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct Interpolators {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				LIGHTING_COORDS(2,3)
					UNITY_FOG_COORDS(4)
			};

			Input vert(Input v) {
				return v;
			}

			Interpolators CreateInterpolator(float4 pos, float3 normal) {
				Input v;
				v.vertex = pos;
				v.normal = normal;
				Interpolators o = (Interpolators)0;
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
				triStream.Append(CreateInterpolator(p[0].vertex, p[0].normal));
				triStream.Append(CreateInterpolator(p[1].vertex, p[0].normal));
				triStream.Append(CreateInterpolator(p[2].vertex, p[0].normal));
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

					triStream.Append(CreateInterpolator(vertices_up[0], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[6], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[1], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[5], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[2], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[4], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[3], normal_up));
					triStream.RestartStrip();

					// desenam baza
					for (int i = 0; i < 7; i++)
					{
						triStream.Append(CreateInterpolator(vertices_down[i], normals[i]));
						triStream.Append(CreateInterpolator(vertices_up[i], normals[i]));
					}
				}
			}

			float4 frag(Interpolators i) : COLOR{
				i.normalDir = normalize(i.normalDir);
				float3 normalDirection = i.normalDir;
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightColor = _LightColor0.rgb;
				////// Lighting:
				float attenuation = LIGHT_ATTENUATION(i);
				float3 attenColor = attenuation * _LightColor0.xyz;
				/////// Diffuse:
				float NdotL = max(0.0,dot(normalDirection, lightDirection));
				float3 directDiffuse = max(0.0, NdotL) * attenColor;
				float3 indirectDiffuse = float3(0,0,0);
				indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
				float3 diffuseColor = _Color.rgb;
				float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
				/// Final Color:
				float3 finalColor = diffuse;
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
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#pragma target 3.0
			uniform float4 _LightColor0;
			uniform float4 _Color;
			half _Radius;
			half _Height;

			struct Input {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct Interpolators {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				LIGHTING_COORDS(2,3)
					UNITY_FOG_COORDS(4)
			};

			Input vert(Input v) {
				return v;
			}

			Interpolators CreateInterpolator(float4 pos, float3 normal) {
				Input v;
				v.vertex = pos;
				v.normal = normal;
				Interpolators o = (Interpolators)0;
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
				triStream.Append(CreateInterpolator(p[0].vertex, p[0].normal));
				triStream.Append(CreateInterpolator(p[1].vertex, p[0].normal));
				triStream.Append(CreateInterpolator(p[2].vertex, p[0].normal));
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

					triStream.Append(CreateInterpolator(vertices_up[0], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[6], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[1], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[5], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[2], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[4], normal_up));
					triStream.Append(CreateInterpolator(vertices_up[3], normal_up));
					triStream.RestartStrip();

					// desenam baza
					for (int i = 0; i < 7; i++)
					{
						triStream.Append(CreateInterpolator(vertices_down[i], normals[i]));
						triStream.Append(CreateInterpolator(vertices_up[i], normals[i]));
					}
				}
			}

			float4 frag(Interpolators i) : COLOR{
				i.normalDir = normalize(i.normalDir);
				float3 normalDirection = i.normalDir;
				float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
				float3 lightColor = _LightColor0.rgb;
				////// Lighting:
				float attenuation = LIGHT_ATTENUATION(i);
				float3 attenColor = attenuation * _LightColor0.xyz;
				/////// Diffuse:
				float NdotL = max(0.0,dot(normalDirection, lightDirection));
				float3 directDiffuse = max(0.0, NdotL) * attenColor;
				float3 diffuseColor = _Color.rgb;
				float3 diffuse = directDiffuse * diffuseColor;
				/// Final Color:
				float3 finalColor = diffuse;
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
