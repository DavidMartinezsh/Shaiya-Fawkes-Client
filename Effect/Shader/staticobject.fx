
//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------

float4 g_LightDiffuse;
float4 g_MaterialAmbientColor;      // Material's ambient color
float4 g_MaterialDiffuseColor;      // Material's diffuse color
float4 g_LightDir;                  // Light's direction in world space

texture g_MeshTexture;              // Color texture for mesh
texture g_LightmapTexture;          //던전용 라이트맵



float4 g_UnderwaterColor;
float4 g_UnderwaterAmbientColor;
float  g_UnderwaterIntensity;
float  g_UnderwaterViewDist;
float  g_UnderwaterRefractionSpeedU;
float  g_UnderwaterRefractionSpeedV;


float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld;                  // World matrix for object
float4x4 g_mWorldViewProjection;    // World * View * Projection matrix

float4   g_FogDist;		//start, end,  empty, empty
float4   g_FogColor;




//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------



sampler2D MeshTextureSampler = 
sampler_state
{
	Texture	  = (g_MeshTexture);
    MIPFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
};


sampler2D LightmapTextureSampler = 
sampler_state
{
	Texture	  = (g_LightmapTexture);
    MIPFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
};




struct VS_OUTPUT
{
    float4 Position   : POSITION;   // vertex position 
    float4 Diffuse    : COLOR0;     // vertex diffuse color (note that COLOR0 is clamped from 0..1)
    float4 Fog		  : COLOR1;
    float2 TextureUV  : TEXCOORD0;  // vertex texture coords 
    float2 TextureUV2  : TEXCOORD1;  // vertex texture coords 
 
    float4 PSPos : TEXCOORD7;
};
//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVS( float4 vPos : POSITION, 
						 float4 vColor : COLOR0,
						 float4 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD0,
                         float2 vTexCoord1 : TEXCOORD1 )
{
    VS_OUTPUT Output;
    float3 vNormalWorldSpace;
    
   
    // Transform the position from object space to homogeneous projection space
    Output.Position = mul(vPos, g_mWorldViewProjection);
    
    // Transform the normal from object space to world space    
    vNormalWorldSpace = normalize(mul(vNormal, (float3x3)g_mWorld)); // normal (world space)

    // Calc diffuse color    
    //Output.Diffuse.rgb = g_MaterialDiffuseColor * g_LightDiffuse * max(0,dot(vNormalWorldSpace, -g_LightDir.xyz)) + g_MaterialAmbientColor;
    Output.Diffuse.rgb = vColor * g_LightDiffuse * max(0,dot(vNormalWorldSpace, -g_LightDir.xyz)) + g_MaterialAmbientColor;
    Output.Diffuse.a = vColor.a;
    
    // Just copy the texture coordinate through
    Output.TextureUV = vTexCoord0;
    Output.TextureUV2 = vTexCoord1; 
    
    Output.PSPos = mul( vPos, g_mWorld );
    
	
	Output.Fog = g_FogDist.x + Output.Position.w * g_FogDist.y;
	Output.Fog.yzw = 1;
	
    
    return Output;    
}



//--------------------------------------------------------------------------------------
// Pixel shader output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 RGBColor : COLOR0;  // Pixel color    
};


//--------------------------------------------------------------------------------------
// This shader outputs the pixel's color by modulating the texture's
// color with diffuse material color
//--------------------------------------------------------------------------------------
PS_OUTPUT RenderScenePSWithUnderwater( float2 vTexCoord0 : TEXCOORD0,
										float4 Diffuse	  : COLOR0,
										 float4 Fog		  : COLOR1, 
										 float4 PSPos : TEXCOORD7) 
{ 
    PS_OUTPUT Output;
    float2 BaseUV = vTexCoord0;
    
    
   
	float UnderwaterHeight = 0;
		
	
	//수면아래 지형의 uv 흔들어주기
    if( PSPos.y < 0 )
    {
		UnderwaterHeight = clamp( 0, 1, (-PSPos.y/g_UnderwaterViewDist)+g_UnderwaterIntensity );
		BaseUV.x += sin(g_fTime*g_UnderwaterRefractionSpeedU + BaseUV.x*40)*(0.03*UnderwaterHeight+0.001);
		BaseUV.y += sin(g_fTime*g_UnderwaterRefractionSpeedV + BaseUV.y*40)*(0.03*UnderwaterHeight+0.001);
		
    }
    
    
    
    float4 BaseTexColor = tex2D(MeshTextureSampler, BaseUV)*Diffuse;    
    float4 UnderwaterColor = (g_UnderwaterColor * g_UnderwaterAmbientColor);
        
    // Lookup mesh texture and modulate it with diffuseS    
    float4 Color = lerp( g_FogColor, BaseTexColor, Fog.x );
    
    
    
    Output.RGBColor.rgb = lerp( Color, UnderwaterColor, UnderwaterHeight ).rgb;
    Output.RGBColor.a = BaseTexColor.a;
    
    
    return Output;
}

PS_OUTPUT RenderScenePSDungeon( float2 vTexCoord0 : TEXCOORD0,
								float2 vTexCoord1 : TEXCOORD1,
								float4 Diffuse	  : COLOR0,
								 float4 Fog		  : COLOR1 ) 
{ 
    PS_OUTPUT Output;
    float4 BaseTexColor = tex2D(MeshTextureSampler, vTexCoord0);
    float4 LightmapTexColor = tex2D( LightmapTextureSampler, vTexCoord1 );
    

    
    float4 TexColor = BaseTexColor * LightmapTexColor * Diffuse;
        
    // Lookup mesh texture and modulate it with diffuse
    float4 Color = lerp( g_FogColor, TexColor, Fog.x );
    
    
    Output.RGBColor = Color;
    Output.RGBColor.a = BaseTexColor.a; 
    
    
    
    return Output;
}

PS_OUTPUT RenderScenePSBasic( float2 vTexCoord0 : TEXCOORD0,
								float4 Diffuse	  : COLOR0,
								 float4 Fog		  : COLOR1, 
								 float4 PSPos : TEXCOORD7) 
{ 
    PS_OUTPUT Output;
    float4 BaseTexColor = tex2D(MeshTextureSampler, vTexCoord0)*Diffuse;
        
    // Lookup mesh texture and modulate it with diffuse
    float4 Color = lerp( g_FogColor, BaseTexColor, Fog.x );
    
    
    Output.RGBColor.rgb = Color.rgb;
    Output.RGBColor.a = BaseTexColor.a;    
    
    return Output;
}


//--------------------------------------------------------------------------------------
// Renders scene 
//--------------------------------------------------------------------------------------
technique RenderSceneWithUnderwater
{
    pass P0
    {   
		FogEnable = false;
        VertexShader = compile vs_1_1 RenderSceneVS();
        PixelShader  = compile ps_2_0 RenderScenePSWithUnderwater(); 
    }
}


technique RenderSceneDungeon
{
    pass P0
    {   
		FogEnable = false;
        VertexShader = compile vs_1_1 RenderSceneVS();
        PixelShader  = compile ps_2_0 RenderScenePSDungeon(); 
    }
}

technique RenderSceneBasic
{
    pass P0
    {   
		FogEnable = false;
        VertexShader = compile vs_1_1 RenderSceneVS();
        PixelShader  = compile ps_2_0 RenderScenePSBasic(); 
    }
}