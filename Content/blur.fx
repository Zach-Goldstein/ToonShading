/******************************************************************
 Shared values
 ******************************************************************/

 // For the model, similar to WebGL
float4x4 world;
float4x4 viewProj;
float4x4 worldInvTrans;
float3 eye;

// For the lighting
float3 lightPos = normalize(float3(1, 0, 0));
float4 lightColor = float4(1, 1, 1, 1); // White

// For the texture
Texture2D tex;

sampler2D texSampler = sampler_state
{
	Texture = <tex>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

float width = 1280;
float height = 720;

struct VS_Output
{
	float4 Position: POSITION0;
	float3 Normal: NORMAL0;
	float2 TexCoords: TEXCOORD0;
};

/******************************************************************
	Blur
 ******************************************************************/

float4 Pixel_Shader(VS_Output input) : COLOR0
{
	float4 s11 = tex2D(texSampler, input.TexCoords + float2(-1.0f / width, -1.0f / height));
	float4 s12 = tex2D(texSampler, input.TexCoords + float2(0, -1.0f / height));
	float4 s13 = tex2D(texSampler, input.TexCoords + float2(1.0f / width, -1.0f / height));

	float4 s21 = tex2D(texSampler, input.TexCoords + float2(-1.0f / width, 0));
	float4 s22 = tex2D(texSampler, input.TexCoords);
	float4 s23 = tex2D(texSampler, input.TexCoords + float2(-1.0f / width, 0));

	float4 s31 = tex2D(texSampler, input.TexCoords + float2(-1.0f / width, 1.0f / height));
	float4 s32 = tex2D(texSampler, input.TexCoords + float2(0, 1.0f / height));
	float4 s33 = tex2D(texSampler, input.TexCoords + float2(1.0f / width, 1.0f / height));

	float4 color = (s11 + s12 + s13 + s21 + s22 + s23 + s31 + s32 + s33) / 9;
	return color;
}

/******************************************************************
	Technique & Passes
 ******************************************************************/

// Source: MonoGame
#if OPENGL
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif


technique Blur
{
	pass Pass
	{
		PixelShader = compile PS_SHADERMODEL Pixel_Shader();
		CullMode = CCW;
	}
}
