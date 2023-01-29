float4x4 WorldMatrix;
float4x4 ViewMatrix;
float4x4 ProjectionMatrix;

float3 EyePosition;

float4 AmbienceColor = float4(0.2f, 0.2f, 0.2f, 1.0f);

float4x4 WorldInverseTransposeMatrix;
float3 DiffuseLightDirection = normalize(float3(3, 0, 0));
float4 DiffuseColor = float4(1, 1, 1, 1);

struct VS_Input
{
	float4 Position : POSITION0;
	float3 NormalVector : NORMAL0;
};

struct VS_Output
{
	float4 Position : POSITION0;
	float4 VertexColor : COLOR0;
	float2 DiffuseEdge: TEXCOORD0;
};

VS_Output Vertex_Shader(VS_Input input)
{
	VS_Output output;

	float4x4 modelViewProjMatrix = mul(mul(WorldMatrix, ViewMatrix), ProjectionMatrix);

	output.Position = mul(input.Position, modelViewProjMatrix);
	float3 worldPosition = mul(input.Position, WorldMatrix);

	float3 eyePosition = mul(EyePosition, modelViewProjMatrix);

	// For Diffuse Lightning
	// float3 normal = normalize(mul(input.NormalVector, WorldInverseTransposeMatrix));
	float3 normal = normalize(input.NormalVector);
	float lightIntensity = max(dot(normal, DiffuseLightDirection), 0);
	output.DiffuseEdge.x = DiffuseColor * lightIntensity;
	float3 eyeDirection = normalize(eyePosition - output.Position);

	output.DiffuseEdge.y = max(dot(normal, eyeDirection), -1 * dot(normal, eyeDirection));

	return output;
}

float4 Pixel_Shader(VS_Output input) : COLOR0
{

	float diffuseIntensity = 0;

	if (input.DiffuseEdge[0] > 0.9)
		diffuseIntensity = 1.0f;
	else if (input.DiffuseEdge[0] > 0.5)
		diffuseIntensity = .7f;
	else if (input.DiffuseEdge[0] > 0.05)
		diffuseIntensity = .3f;
	else
		diffuseIntensity = .1f;

	float outlineIntensity = 1;
	//if (input.DiffuseEdge[1] < 0.2)
	//	outlineIntensity = 0;

	float4 color = float4(1, 1, 1, 1) * diffuseIntensity * outlineIntensity;
	color[3] = 1;

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


technique Toon_Shader_V2
{
	pass Pass
	{
		VertexShader = compile VS_SHADERMODEL Vertex_Shader();
		PixelShader = compile PS_SHADERMODEL Pixel_Shader();
		CullMode = CCW;
	}
}