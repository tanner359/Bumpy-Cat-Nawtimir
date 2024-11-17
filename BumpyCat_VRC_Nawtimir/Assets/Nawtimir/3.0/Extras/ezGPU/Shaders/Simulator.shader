Shader "Quantum/GPU Particles/Simulator" {
	Properties {
		_DataTex ("Data", 2D) = "white" {}
		_Attraction ("Attraction", Range(-10.0, 10.0)) = 0.01
		_Falloff ("Falloff", Range(-10.0, 10.0)) = -2.0
		_DistOff ("Distance Offset", Range(0.0, 1.0)) = 0.0
		_MaxAttraction ("Max Attraction", Range(0.0, 100.0)) = 1.0
		_MaxSpeed ("Max Speed", Range(0.0, 10.0)) = 0.01
		_SpeedLoss ("Speed Loss", Range(0.0, 1.0)) = 0.01
		_NoisePos ("Positional Noise", Range(0.000001, 0.001)) = 0.0
		_AttractorTex ("Attractor Data", 2D) = "Black" {}
		[HideInInspector] _ShapedAttract ("DstBlend", Float) = 0.0
	}
	SubShader {
		Tags { "Lightmode" = "Forwardbase"}
		LOD 100

		Pass {
			Tags { "Lightmode" = "Forwardbase"}
			Cull Off
			CGPROGRAM
			#pragma shader_feature NOISY_POS
			#pragma shader_feature SHAPED_ATTRACT
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

			float _Attraction;
			float _SpeedLoss;
			float _MaxSpeed;
			float _MaxAttraction;
			float _Falloff;
			float _DistOff;
			#ifdef NOISY_POS
			float _NoisePos;
			#endif
			#ifdef SHAPED_ATTRACT
			sampler2D_float _AttractorTex;
			#endif

			float4 frag (v2f i) : SV_Target {
				float4 oldPos = tex2Dlod(_DataTex, float4(i.uv.x, i.uv.y%0.5, 0.0, 0.0));
				float4 oldDir = tex2Dlod(_DataTex, float4(i.uv.x, i.uv.y%0.5+0.5, 0.0, 0.0));
				if(i.uv.y < 0.5){
					// CALC POSITION
					#ifdef NOISY_POS
					return oldPos + oldDir + float4(frac(sin(float3(dot(i.uv,float2(512.4, 956.3)), dot(i.uv,float2(628.4, 139.7)), dot(i.uv,float2(927.4, 651.5))))*43758.5453) - 0.5, 0.0)*_NoisePos;
					#else
					return oldPos + oldDir;
					#endif
				}else{
					// CALC VELOCITY

					#ifdef SHAPED_ATTRACT
					float3 attractor = mul(unity_ObjectToWorld, float4((tex2D(_AttractorTex, float2(i.uv.x, i.uv.y%0.5)).xyz), 1.0)).xyz;
					float dist = length(attractor - oldPos.xyz);
					float3 dir = normalize(attractor - oldPos.xyz);
					#else
					float dist = length(_WorldSpaceCameraPos - oldPos.xyz);
					float3 dir = normalize(_WorldSpaceCameraPos - oldPos.xyz);
					#endif

					float f = 0.01*pow(dist + _DistOff, _Falloff);
					if(f > _MaxAttraction) f = _MaxAttraction;
					oldDir.xyz = oldDir.xyz*(1.0-_SpeedLoss*unity_DeltaTime.z*100.) + dir * f * _Attraction * unity_DeltaTime.z;
					if(length(oldDir.xyz) > _MaxSpeed) oldDir.xyz = normalize(oldDir.xyz)*_MaxSpeed;
					return float4(oldDir.xyz, 1.0);
				}
			}
			ENDCG
		}
	}
	CustomEditor "SimulatorInspector"
}
