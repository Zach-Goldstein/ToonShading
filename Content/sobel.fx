Texture2D Tex;

float3x3 sobel_x = float3x3(1, 2, 1, 0, 0, 0, -1, -2, -1);
float3x3 sobel_y = float3x3(1, 0, -1, 2, 0, -2, 1, 0, -1);

float width = 1280;
float height = 720;

struct PS_Input
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR0;
	float2 TexCoord: TEXCOORD0;
};

sampler2D TexSampler = sampler_state
{
	Texture = <Tex>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
	AddressV = Wrap;
};


float4 Pixel_Shader(PS_Input input) : COLOR0
{
	float2 UV = input.TexCoord;

	float4 s11 = tex2D(TexSampler, UV + float2(-1.0f / width, -1.0f / height));
	float4 s12 = tex2D(TexSampler, UV + float2(0, -1.0f / height));
	float4 s13 = tex2D(TexSampler, UV + float2(1.0f / width, -1.0f / height));
	
	float4 s21 = tex2D(TexSampler, UV + float2(-1.0f / width, 0));
	float4 s23 = tex2D(TexSampler, UV + float2(1.0f / width, 0));
	
	float4 s31 = tex2D(TexSampler, UV + float2(-1.0f / width, 1.0f / height));
	float4 s32 = tex2D(TexSampler, UV + float2(0, 1.0f / height));
	float4 s33 = tex2D(TexSampler, UV + float2(1.0f / width, 1.0f / height));
	
	float4 gx = (s11 + (2 * s12) + s13 - s31 - (2 * s32) - s33) / 4;
	float4 gy = (s11 + (2 * s21) + s31 - s13 - (2 * s23) - s33) / 4;

	gx[3] = 0;
	gy[3] = 0;

	float gradient = sqrt(dot(gx, gx) + dot(gy, gy));
	
	return tex2D(TexSampler, UV) * (1 - gradient);
}

// Source: MonoGame
#if OPENGL
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

technique sobel
{
	pass Pass
	{
		PixelShader = compile PS_SHADERMODEL Pixel_Shader();
	}
}