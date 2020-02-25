Shader "Hyperion/Standard/PBRShader"
{
	Properties
	{
		[Header(Standard)]
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}

		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		_Glossiness("Glossiness", Range(0.1, 32)) = 1

		_DetailTex("Detail Texture", 2D) = "white" {}
		_DetailBalance("Detail Balance", Float) = 0.5

		[NoScaleOffset] _NormalMap("Normal Texture", 2D) = "bump" {}
		_Bumpiness("Bumpiness", Float) = 1.0

		_DetailNormalMap("Detail Normal Texture", 2D) = "bump" {}
		_DetailBumpiness("Detail Bumpiness", Float) = 1.0

		_ReflectionCoefficient("Reflection Coefficient", Range(0,0.99)) = 1.0

		[Header(Emission)]
		_EmissionColor("Emission Color", Color) =  (1,1,1,1)
	}
	SubShader {
		Tags { "RenderType" = "Opaque" }
		Pass {
			Name "Standard"
			LOD 50
			Cull Back
			ZTest Less

			Tags {
				"LightMode" = "ForwardBase"
				//"PassFlags" = "OnlyDirectional"
			}

			CGPROGRAM
			#pragma vertex vertMAIN
			#pragma fragment fragMAIN

			// Compile multiple versions of this shader depending on lighting settings.
			#pragma multi_compile_fwdbase
			//#pragma multi_compile DIRECTIONAL POINT

			#define H_USE_STANDARD

			///////////
			// Color processing options
			#pragma shader_feature_local H_USE_DETAIL_TEXTURE
			#pragma shader_feature_local H_USE_VORONOI_TEXTURES

			#pragma shader_feature_local H_USE_VERTEX_COLOR

			#pragma shader_feature_local H_USE_FRESNEL
			#pragma shader_feature_local H_USE_SPECULAR

			//////////
			// Normal mapping
			#pragma shader_feature_local H_USE_NORMAL_MAP
			#pragma shader_feature_local H_USE_DETAIL_NORMAL_MAP


			///////////
			// Stylistic options
			#pragma shader_feature_local H_USE_DAYLIGHT_GRAYSCALE

			#pragma shader_feature_local H_USE_COLOR_TOON_SHADING
			#pragma shader_feature_local H_USE_SHADOW_TOON_SHADING

			#pragma shader_feature_local H_USE_CUTOUT

			#include "ToonFrag.cginc"
			ENDCG
		}

		// Shadow casting support.
		Pass{
			Name "Shadow"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}
			LOD 250
			ZWrite On
			ZTest Less
			Cull Off

			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_shadowcaster

			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				//float4 pos : SV_POSITION;d
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata v) {
				v2f o;
				o.pos = UnityClipSpaceShadowCasterPos(v.vertex.xyz, v.normal);
				o.pos = UnityApplyLinearShadowBias(o.pos);
				//TRANSFER_SHADOW_CASTER(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}
	CustomEditor "PBRGUIScript"
}