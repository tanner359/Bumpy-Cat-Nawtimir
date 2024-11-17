// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Quantum/GPU Particles/ResetShape" {
	Properties {
		_Scale ("Scale", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Position ("Position", Vector) = (0.0, 0.0, 0.0, 0.0)
		_DataTex ("Data", 2D) = "Black" {}
	}
	SubShader {
		Tags { "Lightmode" = "Forwardbase"}
		LOD 100

		Pass {
			Tags { "Lightmode" = "Forwardbase"}
			Cull Off
			CGPROGRAM
			#pragma shader_feature PREGEN_SHAPE
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D_float _DataTex;
			uniform float4 _DataTex_TexelSize;

			v2f vert (appdata v) {
				v2f o;
				if(distance(mul(unity_ObjectToWorld,v.vertex).xyz, _WorldSpaceCameraPos) < 0.001){
					o.vertex = float4((v.uv.x-0.5)*(_ScreenParams.y/_ScreenParams.x)*2.0, (v.uv.y-0.5)*-2.0, 0.5, 1.0);
				}else{
					o.vertex = 0.0;
				}
				o.uv = v.uv;
				return o;
			}

			float4 _Scale;
			float4 _Position;

			float4 frag (v2f i) : SV_Target {
				#ifdef PREGEN_SHAPE
				if(i.uv.y < 0.5){
					return mul(unity_ObjectToWorld, float4((tex2D(_DataTex, i.uv).xyz) * _Scale.xyz * _Scale.w + _Position, 1.0));
				}else{
					return float4((tex2D(_DataTex, i.uv).xyz) * _Scale.xyz * _Scale.w, 1.0);
				}
				#else
				if(i.uv.y < 0.5){
					return mul(unity_ObjectToWorld, float4((frac(sin(float3(dot(i.uv,float2(512.4, 956.3)), dot(i.uv,float2(628.4, 139.7)), dot(i.uv,float2(927.4, 651.5))))*43758.5453) - 0.5) * _Scale.xyz * _Scale.w + _Position, 1.0));
				}else{
					return float4(0.0, 0.0, 0.0, 1.0);
				}
				#endif
			}
			ENDCG
		}
	}
	CustomEditor "ResetInspector"
}
