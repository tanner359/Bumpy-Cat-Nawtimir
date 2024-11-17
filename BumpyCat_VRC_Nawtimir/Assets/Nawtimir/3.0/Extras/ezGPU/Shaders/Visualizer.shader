Shader "Quantum/GPU Particles/Visualizer"{
	Properties{
		_DataTex ("Position", 2D) = "Black" {}
		_Size ("Size", Range(0.0001, 0.01)) = 0.001
		_Color1 ("Color1", Color) = (0.0, 0.0, 1.0, 1.0)
		_Color2 ("Color2", Color) = (0.0, 1.0, 0.0, 1.0)
		_Color3 ("Color3", Color) = (1.0, 0.0, 0.0, 1.0)
		_MaxSpeed ("Max Speed", Range(0.0, 1.0)) = 0.003
		_ChangeSpeed ("Colorchange Speed", Range(0.0, 10.0)) = 1.0
		_ColorTex ("Color Texture", 2D) = "White" {}
		[HideInInspector] _DstBlend ("DstBlend", Float) = 0.0
		[HideInInspector] _ColorMode ("ColorMode", Float) = 0.0
		[HideInInspector] _WorldPos ("WorldPos", Float) = 1.0
	}
	SubShader{
		Tags { "Lightmode" = "Forwardbase" "Queue" = "Transparent+100" "RenderType" = "Transparent" }
		LOD 100

		Pass{
			Tags { "Lightmode" = "Forwardbase" "Queue" = "Transparent+100" "RenderType" = "Transparent" }
			ZWrite Off
			Cull Off
			BlendOp Add
			Blend SrcAlpha [_DstBlend]
			CGPROGRAM
			#pragma shader_feature CM_STATIC CM_PULSE CM_CHANGING CM_RAINBOW CM_DIRECTION CM_VELOCITY CM_TEXTURE
			#pragma shader_feature WORLD_POS
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom

			#include "UnityCG.cginc"

			struct appdata{
				float4 pos : POSITION;
			};

			struct v2g{
				float4 pos : POSITION;
			};

			struct g2f{
				float4 pos : SV_POSITION;
				float3 uvPos : TEXCOORD0;
				#if defined(CM_DIRECTION) || defined(CM_VELOCITY)
				float3 vel : TEXCOORD1;
				#endif
				#ifdef CM_TEXTURE
				float4 col : COLOR;
				#endif
			};

			sampler2D _DataTex;
			float4 _DataTex_TexelSize;

			#ifdef CM_TEXTURE
			sampler2D _ColorTex;
			float4 _ColorTex_TexelSize;
			#endif

			v2g vert (appdata v){
				v2g o;
				o.pos = v.pos;
				return o;
			}

			float _Size;
			float _MaxSpeed;
			float _ChangeSpeed;
			float4 _Color1;
			float4 _Color2;
			float4 _Color3;
			#define SQRT3 1.7320508075688772935274463415059

			[maxvertexcount(3)]
            void geom(triangle v2g IN[3], uint primID : SV_PrimitiveID, inout TriangleStream<g2f> tristream){
                g2f o;

				//GET NECESSARY DATA
				float2 uv = (float2((primID % _DataTex_TexelSize.z), (primID / _DataTex_TexelSize.z)))*_DataTex_TexelSize.xy;

				#ifdef WORLD_POS
				float4 c = float4(tex2Dlod(_DataTex, float4(uv.x, uv.y, 0.0, 0.0)).xyz, 1.0);
				#else
				float4 c = mul(unity_ObjectToWorld, float4(tex2Dlod(_DataTex, float4(uv.x, uv.y, 0.0, 0.0)).xyz, 1.0));
				#endif

				#ifdef CM_TEXTURE
				float4 col = tex2Dlod(_ColorTex, float4(uv.x, uv.y*2.0, 0.0, 0.0));
				#endif

				float d = distance(c.xyz, _WorldSpaceCameraPos.xyz);

				#if defined(CM_DIRECTION) || defined(CM_VELOCITY)
				float4 vel = float4(tex2Dlod(_DataTex, float4(uv.x, uv.y+0.5, 0.0, 0.0)).xyz, 1.0);
				#endif

				//FIRST VERTEX
				o.uvPos = float3(float2(-SQRT3, -1.0)*_Size*d, d);
				o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + float4(o.uvPos.xy, 0.0, 0.0));

				#if defined(CM_DIRECTION) || defined(CM_VELOCITY)
				o.vel = vel;
				#endif

				#ifdef CM_TEXTURE
				o.col = col;
				#endif

				tristream.Append(o);

				//SECOND VERTEX
				o.uvPos = float3(float2(0.0, 2.0)*_Size*d, d);
				o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + float4(o.uvPos.xy, 0.0, 0.0));

				#if defined(CM_DIRECTION) || defined(CM_VELOCITY)
				o.vel = vel;
				#endif

				#ifdef CM_TEXTURE
				o.col = col;
				#endif

				tristream.Append(o);

				//THIRD VERTEX
				o.uvPos = float3(float2(SQRT3, -1.0)*_Size*d, d);
				o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, c) + float4(o.uvPos.xy, 0.0, 0.0));

				#if defined(CM_DIRECTION) || defined(CM_VELOCITY)
				o.vel = vel;
				#endif

				#ifdef CM_TEXTURE
				o.col = col;
				#endif

				tristream.Append(o);

				//FINISH IT UP
				tristream.RestartStrip();
            }

			fixed4 frag (g2f i) : SV_Target{
				// APPLY COLOR

				#ifdef CM_STATIC
				float4 color = _Color1;
				#endif

				#ifdef CM_PULSE
				float4 color = lerp(_Color1, _Color2, sin(_Time.z*_ChangeSpeed)*0.5+0.5);
				#endif

				#ifdef CM_CHANGING
				float4 color = 1.0;
				float s = frac(_Time.x*_ChangeSpeed);
				if(s < 0.33333){
					color = lerp(_Color1, _Color2, s*3);
				}else if(s < 0.66666){
					color = lerp(_Color2, _Color3, s*3-1.0);
				}else{
					color = lerp(_Color3, _Color1, s*3-2.0);
				}
				#endif

				#ifdef CM_DIRECTION
				float4 color = 1.0;
				if(length(i.vel.rgb) < 0.00001){
					color.rgb = 0.5;
				}else{
					float3 n = normalize(abs(i.vel.xyz));
					color = n.x*_Color1 + n.y*_Color2 + n.z*_Color3;
				}
				#endif

				#ifdef CM_VELOCITY
				float4 color = 1.0;
				float s = length(i.vel.rgb)/_MaxSpeed;
				if(s < 0.5){
					color = lerp(_Color1, _Color2, s*2);
				}else{
					color = lerp(_Color2, _Color3, s*2-1.0);
				}
				#endif

				#ifdef CM_TEXTURE
				float4 color = i.col;
				#endif

				// APPLY SHAPE

				color.a *= clamp(1.0 - length(i.uvPos.xy)/_Size/i.uvPos.z, 0.0, 1.0);

				// END

				return color;
			}
			ENDCG
		}
	}
	CustomEditor "VisualizerInspector"
}
