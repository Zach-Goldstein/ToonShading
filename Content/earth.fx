/******************************************************************
 Shared values
 ******************************************************************/

matrix worldMatrix;
matrix viewMatrix;
matrix projectionMatrix;
Texture2D shaderTexture;

float4 diffuseColor = float4(1, 1, 1, 1);
float4 specularColor = float4(1, 1, 0.8, 1);
float3 lightDirection = float3(-0.5, 1, 0);

Texture2D texSurface;

sampler2D texSurfSampler = sampler_state
{
	Texture = <texSurface>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

Texture2D texBump;

sampler2D texBumpSampler = sampler_state
{
	Texture = <texBump>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

Texture2D texLights;

sampler2D texLightsSampler = sampler_state
{
	Texture = <texLights>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

Texture2D texClouds;

sampler2D texCloudsSampler = sampler_state
{
	Texture = <texClouds>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

Texture2D texOcean;

sampler2D texOceanSampler = sampler_state
{
	Texture = <texOcean>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Clamp;
	AddressV = Clamp;
};

/******************************************************************
 Shaders
 ******************************************************************/

struct VS_Input
{
	float4 Position : POSITION;
	float2 TexCoord : TEXCOORD0;
	float3 Normal : NORMAL;
	float3 Binormal : BINORMAL;
	float3 Tangent : TANGENT;
};

struct VS_Output
{
	float4 Position : SV_POSITION;
	float2 TexCoord : TEXCOORD0;
	float3 Normal : NORMAL;
	float3 Binormal : BINORMAL;
	float3 Tangent : TANGENT;
};

VS_Output Vertex_Shader(VS_Input input)
{
	VS_Output output;

	input.Position.w = 1.0f;
	output.Position = mul(input.Position, worldMatrix);
	output.Position = mul(output.Position, viewMatrix);
	output.Position = mul(output.Position, projectionMatrix);

	output.TexCoord = input.TexCoord;

	// Transform normal and others
	output.Normal = normalize(mul(input.Normal, (float3x3)worldMatrix));
	output.Binormal = normalize(mul(input.Binormal, (float3x3)worldMatrix));
	output.Tangent = normalize(mul(input.Tangent, (float3x3)worldMatrix));

	return output;
}

float4 Pixel_Shader(VS_Output input) : COLOR0
{
	float3 lightDir = normalize(-1.0f * lightDirection);
	float4 textureColor = tex2D(texSurfSampler, input.TexCoord);
	float3 bump = (float3) tex2D(texBumpSampler, input.TexCoord) - float3(0.5f, 0.5f, 0.5f);
	float4 lights = tex2D(texLightsSampler, input.TexCoord);

	// Calculate the diffuse impact of the bump map
	float3 bumpNormal = input.Normal + bump[0] * input.Tangent + bump[1] * input.Binormal;
	bumpNormal = normalize(bumpNormal);
	float diffuseIntensityBump = max(dot(lightDir, bumpNormal), 0) * 0.95f + 0.05f;

	// Calculate the specular impact of the bump map
	float3 bumpSpec = normalize(2 * dot(lightDir, bumpNormal) * bumpNormal - lightDir);
	float3 toCamera = (normalize(float3(1, 0, 0)));
	float angle = dot(bumpSpec, toCamera);

	float4 specular = saturate(specularColor * max(pow(angle, 200), 0) * diffuseIntensityBump);

	float4 color = saturate(textureColor * diffuseIntensityBump + specular * tex2D(texOceanSampler, input.TexCoord)[0]);

	if (length((float3) color) < 0.2)
		color += lights * (1 - length((float3) color) * 5);

	// Clouds
	float4 clouds = tex2D(texCloudsSampler, input.TexCoord);
	float4 diffuseIntensityAlpha = float4(1.0f, 1.0f, 1.0f, 1.0f) * max(dot(lightDir, input.Normal), 0) * 0.9f + 0.1f;
	
	color = diffuseIntensityAlpha * clouds.x + (1 -  clouds.x) * color;

	// Atmosphere
	float scatteringIntensity = pow(saturate((1.0f - dot(input.Normal, toCamera)) * 1.8f), 3) * saturate((dot(lightDir, input.Normal) + 1.0f) / 2.0f);
	// (1.0f - dot(input.Normal, toCamera))   // saturate((dot(lightDir, input.Normal) + 1.0f) / 2.0f)
	float4 scatteringColor = float4(0.2f, 0.8f, 1.0f, 1);

	scatteringIntensity = scatteringIntensity / 2.0f;
	color = scatteringColor * scatteringIntensity + (1 - scatteringIntensity) * color;
	color[3] = 1;

	return color;
}

/******************************************************************
 Compiler Settings and Passes
 ******************************************************************/

// Source: MonoGame
#if OPENGL
#define VS_SHADERMODEL vs_4_0
#define PS_SHADERMODEL ps_4_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif


technique Earth_Shader
{
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL Vertex_Shader();
		PixelShader = compile PS_SHADERMODEL Pixel_Shader();
		CullMode = CCW;
	}
}