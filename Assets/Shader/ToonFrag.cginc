#ifndef TOON_FRAG_INCLUDED
#define TOON_FRAG_INCLUDED
/*
H_USE_NORMAL_MAP          // use normal map
H_USE_DETAIL_NORMAL_MAP

H_USE_DETAIL_TEXTURE

H_USE_VORONOI_TEXTURES    // use voronoi textures
H_USE_VERTEX_COLOR        // use vertex colors

H_USE_COLOR_TOON_SHADING        // round output colors
H_USE_SHADOW_TOON_SHADING // round shadows

H_USE_FRESNEL

H_USE_DAYLIGHT_GRAYSCALE  // grayscale colors based on amount of sunlight

H_USE_STANDARD            // include frag/vert functions and uniform variables

// color = albedo color
// shadow = shadow attenuation
H_COLOR_FRAG_FRONT        // divisor of rounded colors ('round(color / FRAG_FRONT)' or 'round(shadow / FRAG_FRONT)')
H_COLOR_FRAG_BACK         // amount of colors for each channel ('roundedColor / FRAG_BACK' or 'roundedShadow / FRAG_BACK')


*/

float4 hash4(float2 p) {
	return frac(sin(float4(1.0 + dot(p, float2(37.0, 17.0)),
		2.0 + dot(p, float2(11.0, 47.0)),
		3.0 + dot(p, float2(41.0, 29.0)),
		4.0 + dot(p, float2(23.0, 31.0)))) * 103.0);
}

// iq from shadertoy
float4 tex2DV(sampler2D samp, in float2 uv)
{
	float2 iuv = floor(uv);
	float2 fuv = frac(uv);

	float4 ofa = hash4(iuv + float2(0.0, 0.0));
	float4 ofb = hash4(iuv + float2(1.0, 0.0));
	float4 ofc = hash4(iuv + float2(0.0, 1.0));
	float4 ofd = hash4(iuv + float2(1.0, 1.0));

	// transform per-tile uvs
	ofa.zw = sign(ofa.zw - 0.5);
	ofb.zw = sign(ofb.zw - 0.5);
	ofc.zw = sign(ofc.zw - 0.5);
	ofd.zw = sign(ofd.zw - 0.5);

	// uv's, and derivarives (for correct mipmapping)
	float2 uva = uv * ofa.zw + ofa.xy;
	float2 uvb = uv * ofb.zw + ofb.xy;
	float2 uvc = uv * ofc.zw + ofc.xy;
	float2 uvd = uv * ofd.zw + ofd.xy;

	// fetch and blend
	float2 b = smoothstep(0.25, 0.75, fuv);

	return lerp(lerp(tex2D(samp, uva),
		tex2D(samp, uvb), b.x),
		lerp(tex2D(samp, uvc),
			tex2D(samp, uvd), b.x), b.y);
}

float4 tex2DlodV(sampler2D samp, in float2 uv)
{
	float2 iuv = floor(uv);
	float2 fuv = frac(uv);

	float4 ofa = hash4(iuv + float2(0.0, 0.0));
	float4 ofb = hash4(iuv + float2(1.0, 0.0));
	float4 ofc = hash4(iuv + float2(0.0, 1.0));
	float4 ofd = hash4(iuv + float2(1.0, 1.0));

	// transform per-tile uvs
	ofa.zw = sign(ofa.zw - 0.5);
	ofb.zw = sign(ofb.zw - 0.5);
	ofc.zw = sign(ofc.zw - 0.5);
	ofd.zw = sign(ofd.zw - 0.5);

	// uv's, and derivarives (for correct mipmapping)
	float4 uva = float4(uv * ofa.zw + ofa.xy, 0, 0);
	float4 uvb = float4(uv * ofb.zw + ofb.xy, 0, 0);
	float4 uvc = float4(uv * ofc.zw + ofc.xy, 0, 0);
	float4 uvd = float4(uv * ofd.zw + ofd.xy, 0, 0);

	// fetch and blend
	float2 b = smoothstep(0.25, 0.75, fuv);

	return lerp(lerp(tex2Dlod(samp, uva),
		tex2Dlod(samp, uvb), b.x),
		lerp(tex2Dlod(samp, uvc),
			tex2Dlod(samp, uvd), b.x), b.y);
}

bool in_frustum(float4 p) {
	return abs(p.x) < p.w &&
		abs(p.y) < p.w &&
		0 < p.z &&
		p.z < p.w;
}
bool in_frustumlimit(float4 p) {
	return abs(p.x) < p.w * 1.2 &&
		abs(p.y) < p.w * 1.2 &&
		0 < p.z &&
		p.z < p.w;
}

float rand31(float3 co) {
	return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
}
/*float rand(float n) {
	return frac(sin(n * 12.9898) * 43758.5453);
}
float2 rand2(float2 p) {
	float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return frac((p3.xx + p3.yz) * p3.zy);
}*/

float3 rand33(float3 p) {
	return frac(float3(
		sin(p.x * 591.32 + p.y * 154.077 + p.z * 712.223),
		cos(p.x * 391.32 + p.y * 49.077 + p.z * 401.326),
		cos(p.x * 1010.22 + p.y * 27.311 + p.z * 131.44)));
}

float3 HtoRGB(float H)
{
	half R = abs(H * 6 - 3) - 1;
	half G = 2 - abs(H * 6 - 2);
	half B = 2 - abs(H * 6 - 4);
	return saturate(half3(R, G, B));
}

half3 HSVtoRGB(half3 HSV)
{
	return saturate((HtoRGB(HSV.x) - 1) * HSV.y + 1) * HSV.z;
}
#define EPSILON  0.0001

float RGBtoHSVf(in float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);

	float H = abs(q.z + (q.w - q.y) / (6.0 * d + EPSILON));
	float S = d / (q.x + EPSILON);
	float V = q.x;
	return  H + floor(S * 9.99) + floor(V * 9.99) * 10;
}
#define GET_HUE(HSV) (frac(HSV))
#define GET_SAT(HSV) (floor(HSV) % 10 / 9)
#define GET_VAL(HSV) (floor(HSV / 10) / 9)

#define GET_HSV(HSV) float3(GET_HUE(HSV), GET_SAT(HSV), GET_VAL(HSV))

#ifdef H_USE_STANDARD
#pragma glsl // for tex2Dlod

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

struct appdata {
	float4 vertex : POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : NORMAL;
#ifdef H_USE_NORMAL_MAP
	float4 tangent : TANGENT;
#endif
#ifdef H_USE_VERTEX_COLOR
	float4 color : COLOR;
#endif
}; 

struct v2f {
	float4 pos : SV_POSITION;

#if defined(H_USE_DETAIL_TEXTURE) || defined(H_USE_DETAIL_NORMAL_MAP)
	float4 uv : TEXCOORD0;
#else
	float2 uv : TEXCOORD0;
#endif
	float3 viewDir : TEXCOORD1;

	float3 normal : NORMAL;
#ifdef H_USE_NORMAL_MAP
	half3 tangent : TEXCOORD2; // tangent.x, bitangent.x, normal.x
	half3 bitangent : TEXCOORD3; // tangent.y, bitangent.y, normal.y
	SHADOW_COORDS(4)
#else
	SHADOW_COORDS(2)
#endif

#ifdef H_USE_VERTEX_COLOR
		float4 color : COLOR;
#endif
};

//////////////////////////////////////////
// Parameters
sampler2D _MainTex;
float4 _MainTex_ST;

#ifdef H_USE_DETAIL_TEXTURE
sampler2D _DetailTex;
float4 _DetailTex_ST;

float _DetailBalance;
#endif

float4 _Color;

#ifdef H_USE_SPECULAR
float4 _SpecularColor;
#endif
float _Glossiness;

#ifdef H_USE_NORMAL_MAP
sampler2D _NormalMap;
float _Bumpiness;
// uses main texture sampler stuff
#endif

#ifdef H_USE_DETAIL_NORMAL_MAP
sampler2D _DetailNormalMap;
#ifndef H_USE_DETAIL_TEXTURE
float4 _DetailNormalMap_ST;
#endif
float _DetailBumpiness;

#endif


#ifdef H_USE_FRESNEL
float _ReflectionCoefficient;
#endif

#ifdef H_USE_DAYLIGHT_GRAYSCALE
float _Daylight;
#endif

#ifndef H_TOON_SHADING_FRAGMENTS
#define H_TOON_SHADING_FRAGMENTS 10
#endif

#define ROUND_COLOR(COLOR) round(COLOR * H_TOON_SHADING_FRAGMENTS)
#define ROUND_STEP(COLOR) (ROUND_COLOR(COLOR) / H_TOON_SHADING_FRAGMENTS)

#ifdef H_USE_VORONOI_TEXTURES
#define SAMPLE_TEX(sampler,uv) tex2DV(sampler, uv)
#else
#define SAMPLE_TEX(sampler,uv) tex2D(sampler, uv)
#endif

v2f vertMAIN(in appdata v) {
	v2f o;
	// apply linear shadow bias and translate to clip pos
	o.pos = UnityObjectToClipPos(v.vertex);
	o.normal = UnityObjectToWorldNormal(v.normal);
	o.viewDir = WorldSpaceViewDir(v.vertex);
	#if !defined(H_USE_DETAIL_TEXTURE) && !defined(H_USE_DETAIL_NORMAL_MAP)
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	#elif defined(H_USE_DETAIL_TEXTURE)
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	#else // if H_USE_DETAIL_NORMAL_MAP
		o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
		o.uv.zw = TRANSFORM_TEX(v.uv, _DetailNormalMap);
	#endif

	#ifdef H_USE_NORMAL_MAP
		o.tangent = UnityObjectToWorldNormal(v.tangent.xyz);
		o.bitangent = UnityObjectToWorldNormal(cross(o.normal, o.tangent));
	#endif

	TRANSFER_SHADOW(o);

	#ifdef H_USE_VERTEX_COLOR
		o.color = v.color;
	#endif
	return o;
}

float4 fragMAIN(in v2f i) : SV_Target{ 
	/////////////////////////////////////////////////
	// Calculate material colors
	/////////////////////////////////////////////////
		float3 sample =
		#ifndef H_USE_DETAIL_TEXTURE
			SAMPLE_TEX(_MainTex, i.uv.xy).rgb
		#else
			lerp(
			SAMPLE_TEX(_MainTex, i.uv.zw).rgb,
			SAMPLE_TEX(_DetailTex, i.uv.zw).rgb,
			_DetailBalance)
		#endif
		;

		float3 albedoColor = _Color * sample
		#ifdef H_USE_VERTEX_COLOR
			* i.color
		#endif
		;
		
		#ifdef H_USE_SPECULAR
			float3 specularColor = _SpecularColor;
		#endif
		fixed3 lightColor = _LightColor0.rgb;

	/////////////////////////////////////////////////
	// Calculate misc. vectors
	/////////////////////////////////////////////////
		half3 worldNormal;
		#ifdef H_USE_NORMAL_MAP
			half3 texNormal = UnpackScaleNormal(SAMPLE_TEX(_NormalMap, i.uv.xy), _Bumpiness)
			#ifdef H_USE_DETAIL_NORMAL_MAP
				+ UnpackScaleNormal(SAMPLE_TEX(_DetailNormalMap, i.uv.zw), _DetailBumpiness)
			#endif
			;

			worldNormal = mul(
				float3x3(
					float3(i.tangent.x, i.bitangent.x, i.normal.x),
					float3(i.tangent.y, i.bitangent.y, i.normal.y),
					float3(i.tangent.z, i.bitangent.z, i.normal.z))
				, texNormal);
			//normal = i.normal;
			//i.normal = i.normal.xzy;
		#else
			worldNormal = i.normal;
		#endif
		worldNormal = normalize(worldNormal);
		//float3 normal = i.normal;
		float3 viewDir = normalize(i.viewDir);

		#ifdef H_TEST_NORMAL
				return float4( worldNormal, 1);
		#endif
	/////////////////////////////////////////////////
	// Calculate illumination and shadow
	/////////////////////////////////////////////////
		float3 lightDir;
		UNITY_LIGHT_ATTENUATION(attenuation, i, 0);

		#ifdef H_USE_SHADOW_TOON_SHADING 
			//attenuation = ROUND_STEP(attenuation);
		#endif

		//float3 reflectionDir = reflect(-viewDir, i.normal);
		//half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
		//// decode cubemap data into actual color
		//half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);

		lightColor *= attenuation; 

		// directional light direction is constant and normalized so just copy it
		lightDir = _WorldSpaceLightPos0.xyz; 
				
	/////////////////////////////////////////////////
	// Calculate diffuse using the Lambertian model 'NdotL * albedo * light'
	// translated and adjusted to:	( NdotL * albedoColor * lightColor * lightAttenuation) )
	/////////////////////////////////////////////////
		fixed NdotL = dot(lightDir, worldNormal);

		#ifdef H_USE_SHADOW_TOON_SHADING 
			//NdotL = ROUND_STEP(NdotL);
		#endif

		float3 diffuse = NdotL * albedoColor * saturate(lightColor);

	/////////////////////////////////////////////////
	// Calculate specular reflection using the Blinn-Phong model 'pow(NdotH,glossiness) * specular * light' 
	// translated and adjusted to: ( pow(NdotH, glossiness) *lightColor * lightAttenuation) )
	/////////////////////////////////////////////////
	#ifdef H_USE_SPECULAR
		#define EIGHT_PI 25.1327412287
			float3 Hv = normalize(lightDir + viewDir);
			float NdotH = dot(worldNormal, Hv);
			float specularBrightness = pow(saturate(NdotH), _Glossiness);

		#ifdef H_USE_SHADOW_TOON_SHADING 
			//NdotH = ROUND_STEP(NdotH*20)/20;
		#endif

	/////////////////////////////////////////////////
	// Calculate fresnel using the Schlick Approximation 'R0 + (1 - R0)(1 - cos(theta))'
	//	translated and adjusted to: ( n + (1-n)(1-NdotV) )
	/////////////////////////////////////////////////
		#ifdef H_USE_FRESNEL
			float NdotV = dot(worldNormal, viewDir);

			float coefficient = _ReflectionCoefficient;

			float fresnel = 
				coefficient + (1 - coefficient) * pow(1 - NdotV,5)
				* (1 / (coefficient + (1 - coefficient) / 6)); // conservation of energy factor (reciprocal of 'n + (1-n)/6')

			#ifdef H_USE_SHADOW_TOON_SHADING 
				//fresnelAttenuation = ROUND_STEP(fresnelAttenuation);
			#endif

			// specular weighted 0.8, fresnel weighted 0.2
			// spherical integral of specular is (g + 8) / 8pi where g is glossiness

			specularBrightness *= 0.8;
			specularBrightness += saturate(fresnel) * 0.2;
		#endif

		float3 specular = specularBrightness * lightColor * specularColor
			* ((_Glossiness + 8) / EIGHT_PI);
	#endif
		
	/////////////////////////////////////////////////
	// Calculate overall color (specular + diffuse + ambient)
	/////////////////////////////////////////////////
		float3 color = saturate(diffuse) + UNITY_LIGHTMODEL_AMBIENT.rgb * albedoColor
			#ifdef H_USE_SPECULAR
				+ saturate(specular)
			#endif
			;

	#ifdef H_USE_COLOR_TOON_SHADING 
		color = ROUND_STEP(color);
		//attenuation = ROUND_STEP(attenuation);d
	#endif

	#ifdef H_USE_DAYLIGHT_GRAYSCALE
		float gray = (color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722);
		float3 grayscale = gray.xxx;

		color = lerp(grayscale, color, _Daylight);
	#endif
	return float4(color, 1);
}
#endif

#ifdef H_USE_META 
#include "UnityStandardMeta.cginc"

float4 _EmissionColor;

#ifdef H_USE_EMISSION_MAP
sampler2D _EmissionMap;
float4 _EmissionMap_ST;
#endif

#ifdef H_USE_VORONOI_TEXTURES
#define SAMPLE_TEX(sampler,uv) tex2DV(sampler, uv)
#else
#define SAMPLE_TEX(sampler,uv) tex2D(sampler, uv)
#endif

struct appdata {
	float4 pos : POSITION;
	float4 uv : TEXCOORD0;
};
struct v2f {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

v2f vertMETA(in appdata v) {
	v2f o;
	// apply linear shadow bias and translate to clip pos
	o.pos = UnityObjectToClipPos(v.vertex);

	#ifdef H_USE_EMISSION_MAP
		o.uv.xy = TRANSFORM_TEX(v.uv, _EmissionMap);
	#endif

	return o;
}

fixed4 fragMETA(v2f i) : SV_Target{
	return float4(2,2,2,2);
	return float4(
		_EmissionColor.rgb
		#ifdef H_USE_EMISSION_MAP
		* SAMPLE_TEX(_EmissionMap_ST, i.uv)
		#endif
	, 1);
}

#endif
#endif