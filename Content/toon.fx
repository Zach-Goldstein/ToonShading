/******************************************************************
 Shared values
 ******************************************************************/

// For the model, similar to WebGL
float4x4 world;
float4x4 view;
float4x4 projection;

float4x4 worldInv;

// For the lighting
float3 lightDir = normalize(float3(1, 1, 1));
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

/******************************************************************
	Cell Shading
 ******************************************************************/

struct VS_Input_Cell
{
    float4 Position: POSITION0;
    float2 TexCoord: TEXCOORD0;
    float3 Normal: NORMAL0;
};

struct VS_Output_Cell
{
    float4 Position: POSITION0;
    float2 TexCoord: TEXCOORD0;
    float3 Normal: NORMAL0;
};

VS_Output_Cell Vertex_Shader_Cell(VS_Input_Cell input)
{
    VS_Output_Cell output;
    
    // Transform position
    float4 worldPos = mul(input.Position, world);
    float4 worldviewPos = mul(worldPos, view);
    output.Position = mul(worldviewPos, projection);

    // Transform normal
    output.Normal = mul(input.Normal, worldInv);

    // Keep the original texcoord, just like in WebGL
    output.TexCoord = input.TexCoord;

    return output;
}

float4 Pixel_Shader_Cell(VS_Output_Cell input) : COLOR0
{
    float intensity = dot(normalize(lightDir), input.Normal);

    if (intensity < 0)
        intensity = 0;

    float4 texColor = tex2D(texSampler, input.TexCoord) * lightColor;
	if (intensity > 0.9)
		texColor = float4(1, 1, 1, 1.0) * texColor;
	else if (intensity > 0.5)
		texColor = float4(0.7, 0.7, 0.7, 1.0) * texColor;
	else if (intensity > 0.05)
		texColor = float4(0.3, 0.3, 0.3, 1.0) * texColor;
	else
		texColor = float4(0.1, 0.1, 0.1, 1.0) * texColor;

    return texColor;
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
	pass Pass1
	{
		VertexShader = compile VS_SHADERMODEL Vertex_Shader_Cell();
		PixelShader = compile PS_SHADERMODEL Pixel_Shader_Cell();
		CullMode = CCW;
	}
}