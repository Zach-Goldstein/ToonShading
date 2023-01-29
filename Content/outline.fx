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

float width = 800;
float height = 480;

/******************************************************************
	Outline
 ******************************************************************/

struct VS_Input
{
	float4 Position: POSITION0;
	float3 Normal: NORMAL0;
};

struct VS_Output
{
	float4 Position: POSITION0;
	float3 Normal: NORMAL0;
	float2 Edge: TEXCOORD1;
	float Diffuse: TEXCOORD2;
};

VS_Output Vertex_Shader(VS_Input input)
{
	VS_Output output;

	output.Position = mul(input.Position, mul(world, viewProj));
	output.Normal = mul(input.Normal, worldInvTrans);

	float3 N = normalize(input.Normal);
	output.Diffuse = max(dot(normalize(lightPos - output.Position), N), 0);

	float3 eyeDir = normalize(eye - output.Position.xyz);

	output.Edge = float2(max(dot(N, eyeDir), dot(N, eyeDir) * -1), 0);

	return output;
}

float4 Pixel_Shader(VS_Output input) : COLOR0
{
	float4 texColor = float4(1, 1, 1, 1);

	float diffuseIntensity = 0;

	if (input.Diffuse > 0.9)
		diffuseIntensity = 1.0f;
	else if (input.Diffuse > 0.5)
		diffuseIntensity = .7f;
	else if (input.Diffuse > 0.05)
		diffuseIntensity = .3f;
	else
		diffuseIntensity = .1f;

	float edgeIntensity = 1;
	if (input.Edge[0] < 0.1f)
		edgeIntensity = 0;

	float4 color = texColor * 1 * diffuseIntensity;
	color[3] = 1.0f;

	return color;
}

// Source: MonoGame
#if OPENGL
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif


technique Toon_Shader
{
	pass Pass
	{
		VertexShader = compile VS_SHADERMODEL Vertex_Shader();
		PixelShader = compile PS_SHADERMODEL Pixel_Shader();
		CullMode = CCW;
	}
}