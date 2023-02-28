// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Modular Bricks/Pipes/VertexLit Cull"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Radius("Radius", Float) = 0.5
		_Height("Height", Float) = 0.5
		_DrawRadius("DrawRadius", Float) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Geometry" "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			LOD 200
			ZWrite On

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex VS_Main
			#pragma fragment FS_Main
			#pragma geometry GS_Main
			#include "UnityCG.cginc" // for UnityObjectToWorldNormal
			#include "UnityLightingCommon.cginc" // for _LightColor0


			// compile shader into multiple variants, with and without shadows
			// (we don't care about any lightmaps yet, so skip these variants)
			#pragma multi_compile_fwdbase
			// shadow helper functions and macros
			#include "AutoLight.cginc"

			// **************************************************************
			// Data structures												*
			// **************************************************************

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal   : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct GS_INPUT
			{
				float4	pos		: POSITION;
				float3	normal	: NORMAL;
				float2  tex0	: TEXCOORD0;
			};

			struct FS_INPUT
			{
				float4	pos		: SV_POSITION;
				fixed3 diff : COLOR0; // diffuse lighting color 
				fixed3 ambient : COLOR1;
				SHADOW_COORDS(1) // put shadows data into TEXCOORD1
				//float3	normal	: NORMAL;
				float2  tex0	: TEXCOORD0;
			};


			// **************************************************************
			// Vars															*
			// **************************************************************

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Radius;
			float _Height;
			float _DrawRadius = 1;
			const float degToRad = 0.01745329251;

			// **************************************************************
			// Shader Programs												*
			// **************************************************************

			// Vertex Shader ------------------------------------------------
			GS_INPUT VS_Main(appdata v)
			{
				GS_INPUT o;
				o.pos = v.vertex;
				o.normal = v.normal;
				o.tex0 = v.uv;
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

			// Geometry Shader -----------------------------------------------------
			[maxvertexcount(24)]
			void GS_Main(triangle GS_INPUT p[3], inout TriangleStream<FS_INPUT> triStream)
			{
				FS_INPUT pIn;

				half3 worldNormal;
				half nl;

				pIn.pos = UnityObjectToClipPos(p[0].pos);
				worldNormal = UnityObjectToWorldNormal(p[0].normal);
				nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				pIn.diff = nl * _LightColor0;
				pIn.ambient = ShadeSH9(half4(worldNormal, 1));
				pIn.tex0 = p[0].tex0;
				TRANSFER_SHADOW(pIn);
				triStream.Append(pIn);

				pIn.pos = UnityObjectToClipPos(p[1].pos);
				worldNormal = UnityObjectToWorldNormal(p[1].normal);
				nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				pIn.diff = nl * _LightColor0;
				pIn.ambient = ShadeSH9(half4(worldNormal, 1));
				pIn.tex0 = p[1].tex0;
				TRANSFER_SHADOW(pIn);
				triStream.Append(pIn);

				pIn.pos = UnityObjectToClipPos(p[2].pos);
				worldNormal = UnityObjectToWorldNormal(p[2].normal);
				nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				pIn.diff = nl * _LightColor0;
				pIn.ambient = ShadeSH9(half4(worldNormal, 1));
				pIn.tex0 = p[2].tex0;
				TRANSFER_SHADOW(pIn);
				triStream.Append(pIn);

				triStream.RestartStrip();

				// verificam daca triunghiul tinteste in sus, produs scalar intre un vector vertical si cel rezultat din compunerea 
				// normalelor fiecarui vertex
				float3 triangleNormal = p[0].normal + p[1].normal + p[2].normal;
				//triangleNormal = normalize(triangleNormal);
				if ((triangleNormal / 3).y > 0.98)
				{
					// vectorul distanta
					float3 l1 = p[0].pos.xyz - p[1].pos.xyz;
					float3 l2 = p[1].pos.xyz - p[2].pos.xyz;
					float3 l3 = p[2].pos.xyz - p[0].pos.xyz;

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
					new_p[0] = p[0].pos * (coef.x + coef.z);
					new_p[1] = p[1].pos * (coef.x + coef.y);
					new_p[2] = p[2].pos * (coef.y + coef.z);

					// acum mid este mijlocu ipotenuzei
					mid_ip = (new_p[0] + new_p[1] + new_p[2]) / 2;
					mid_ip.w = 1;
					
					
					float4 mid_ip_world;
					half3 worldNormal_ip;
					mid_ip_world = mul(unity_ObjectToWorld, mid_ip);
					
					float3 difference;
					difference =_WorldSpaceCameraPos - float3(mid_ip_world.x, mid_ip_world.y, mid_ip_world.z);
					difference = abs(difference);
					float magnitude;
					magnitude = length(difference);

					if (magnitude < _DrawRadius) {



						// aflam centru de greutate
						float4 center_of_mass = (p[0].pos + p[1].pos + p[2].pos) / 3;

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

						FS_INPUT pIn;

						half3 worldNormal;
						half nl;

						// desenam cilindrul de sus
						pIn.pos = UnityObjectToClipPos(vertices_up[0]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[6]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[1]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[5]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[2]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[4]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						pIn.pos = UnityObjectToClipPos(vertices_up[3]);
						worldNormal = UnityObjectToWorldNormal(normal_up);
						nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
						pIn.diff = nl * _LightColor0;
						pIn.ambient = ShadeSH9(half4(worldNormal, 1));
						pIn.tex0 = p[0].tex0;
						TRANSFER_SHADOW(pIn);
						//TRANSFER_VERTEX_TO_FRAGMENT(pIn);
						triStream.Append(pIn);

						triStream.RestartStrip();



						// desenam baza

						for (int i = 0; i < 7; i++)
						{
							pIn.pos = UnityObjectToClipPos(vertices_down[i]);
							worldNormal = UnityObjectToWorldNormal(normals[i]);
							nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
							pIn.diff = nl * _LightColor0;
							pIn.ambient = ShadeSH9(half4(worldNormal, 1));
							pIn.tex0 = p[0].tex0;
							TRANSFER_SHADOW(pIn);
							triStream.Append(pIn);

							pIn.pos = UnityObjectToClipPos(vertices_up[i]);
							worldNormal = UnityObjectToWorldNormal(normals[i]);
							nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
							pIn.diff = nl * _LightColor0;
							pIn.ambient = ShadeSH9(half4(worldNormal, 1));
							pIn.tex0 = p[0].tex0;
							TRANSFER_SHADOW(pIn);
							triStream.Append(pIn);
						}
					}
				}
			}



			// Fragment Shader -----------------------------------------------
			fixed4 FS_Main(FS_INPUT input) : COLOR
			{
				fixed4 col = tex2D(_MainTex, input.tex0);;
				// compute shadow attenuation (1.0 = fully lit, 0.0 = fully shadowed)
				fixed shadow = SHADOW_ATTENUATION(input);
				// darken light's illumination with shadow, keep ambient intact
				fixed3 lighting = input.diff * shadow + input.ambient;
				col.rgb *= lighting;
				return col;
				//return float4(1.0, 0.0, 0.0, 1.0);
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

			struct v2f {
				V2F_SHADOW_CASTER;
			};

			struct VertexToGeom {
				float4 vertex : POSITION;
				float3	normal	: NORMAL;
			};

			float _Radius;
			float _Height;
			float _DrawRadius = 1;
			const float degToRad = 0.01745329251;

			VertexToGeom vert(appdata_base v)
			{
				VertexToGeom o;
				//TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.vertex = v.vertex;
				o.normal = v.normal;
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
			void geom(triangle VertexToGeom p[3], inout TriangleStream<v2f> triStream)
			{
				// drawing the input geometry
				v2f pIn;
				VertexToGeom v;

				v.vertex = p[0].vertex;
				v.normal = p[0].normal;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn);
				triStream.Append(pIn);

				v.vertex = p[1].vertex;
				v.normal = p[1].normal;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn);
				triStream.Append(pIn);

				v.vertex = p[2].vertex;
				v.normal = p[2].normal;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn);
				triStream.Append(pIn);

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
					
					float4 mid_ip_world;
					half3 worldNormal_ip;
					mid_ip_world = mul(unity_ObjectToWorld, mid_ip);

					float3 difference;
					difference = float3(mid_ip_world.x, mid_ip_world.y, mid_ip_world.z) - _WorldSpaceCameraPos;
					float magnitude;
					magnitude = length(difference);

					if (magnitude < _DrawRadius) {

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

						v2f pIn;
						VertexToGeom v;

						// desenam cilindrul de sus
						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[0]);
						v.vertex = vertices_up[0];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[6]);
						v.vertex = vertices_up[6];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[1]);
						v.vertex = vertices_up[1];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[5]);
						v.vertex = vertices_up[5];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[2]);
						v.vertex = vertices_up[2];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[4]);
						v.vertex = vertices_up[4];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						//pIn.pos = mul(UNITY_MATRIX_MVP, vertices_up[3]);
						v.vertex = vertices_up[3];
						v.normal = normal_up;
						TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
							triStream.Append(pIn);

						triStream.RestartStrip();

						// desenam baza

						for (int i = 0; i < 7; i++)
						{
							v.vertex = vertices_down[i];
							v.normal = normals[i];
							TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
								triStream.Append(pIn);

							v.vertex = vertices_up[i];
							v.normal = normals[i];
							TRANSFER_SHADOW_CASTER_NORMALOFFSET(pIn)
								triStream.Append(pIn);
						}
					}
				}
			}

			float4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}


	}
}
