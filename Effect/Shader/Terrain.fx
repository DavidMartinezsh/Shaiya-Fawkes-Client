
//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------

float4 g_MtrlColor;					//light * MaterialDiffuse * Materialambient
texture g_AlphaTexture; 
texture g_MeshTexture;              // Color texture for mesh
texture g_LightMapTexture;


float4 g_UnderwaterColor;
float4 g_UnderwaterAmbientColor;
float  g_UnderwaterIntensity;
float  g_UnderwaterViewDist;
float  g_UnderwaterRefractionSpeedU;
float  g_UnderwaterRefractionSpeedV;
float  g_UnderwaterRefractionWeight;


float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld;                  // World matrix for object
float4x4 g_mWorldViewProjection;    // World * View * Projection matrix

float4   g_FogDist;		//start, end,  empty, empty
float4   g_FogColor;




//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------
sampler AlphaTextureSampler = 
sampler_state
{
    Texture = <g_AlphaTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};


sampler2D MeshTextureSampler = 
sampler_state
{
	Texture	  = (g_MeshTexture);
    MIPFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MINFILTER = LINEAR;
};



sampler LightMapTextureSampler = 
sampler_state
{
    Texture = <g_LightMapTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};


struct VS_OUTPUT
{
    float4 Position   : POSITION;   // vertex position 
    float4 Fog		  : COLOR1;
    float2 TextureUV  : TEXCOORD0;  // vertex texture coords 
    float2 TextureUV2  : TEXCOORD1;  // vertex texture coords 
    float2 TextureUV3  : TEXCOORD2;  // vertex texture coords
    
    float4 PSPos : TEXCOORD7;
};
//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVS( float4 vPos : POSITION, 
                         float2 vTexCoord0 : TEXCOORD0,
                         float2 vTexCoord1 : TEXCOORD1,
                         float2 vTexCoord2 : TEXCOORD2 )
{
    VS_OUTPUT Output;
    float3 vNormalWorldSpace;
    
    // Transform the position from object space to homogeneous projection space
    Output.Position = mul(vPos, g_mWorldViewProjection);
  
   
    
    // Just copy the texture coordinate through
    Output.TextureUV = vTexCoord0; 
    Output.TextureUV2 = vTexCoord1; 
    Output.TextureUV3 = vTexCoord2; 
    
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
                         float2 vTexCoord1 : TEXCOORD1,
                         float2 vTexCoord2 : TEXCOORD2,
                         float4 Fog		  : COLOR1, 
                         float4 PSPos : TEXCOORD7) 
{ 
    PS_OUTPUT Output;
    float2 BaseUV = vTexCoord1;
    
    
   
	float UnderwaterHeight = 0;
		
	
	//수면아래 지형의 uv 흔들어주기
    if( PSPos.y < 0 )
    {
		UnderwaterHeight = clamp( 0, 1, (-PSPos.y/g_UnderwaterViewDist)+g_UnderwaterIntensity );
		BaseUV.x += sin(g_fTime*g_UnderwaterRefractionSpeedU + BaseUV.x*40)*(0.01*UnderwaterHeight*g_UnderwaterRefractionWeight+(0.001*g_UnderwaterRefractionWeight));
		BaseUV.y += sin(g_fTime*g_UnderwaterRefractionSpeedV + BaseUV.y*40)*(0.01*UnderwaterHeight*g_UnderwaterRefractionWeight+(0.001*g_UnderwaterRefractionWeight));
		
    }
    
    
    float4 AlphaTexColor = tex2D(AlphaTextureSampler, vTexCoord0);
    float4 BaseTexColor = tex2D(MeshTextureSampler, BaseUV);
    float4 LightMapTexColor = tex2D(LightMapTextureSampler, vTexCoord2);
    
    //LightMapTexColor = LightMapTexColor*3 - 0.5;
    

	//BaseTexColor = (AlphaTexColor+BaseTexColor)-0.5;
             
    
    float4 UnderwaterColor = (g_UnderwaterColor * g_UnderwaterAmbientColor);
        
    // Lookup mesh texture and modulate it with diffuseS    
    float4 Color = lerp( g_FogColor, (AlphaTexColor * (BaseTexColor*1.2f) * LightMapTexColor * g_MtrlColor ), Fog.x );
    
    
    
    Output.RGBColor.rgb = lerp( Color, UnderwaterColor, UnderwaterHeight ).rgb;
    Output.RGBColor.a = AlphaTexColor.a;
    
    
    return Output;
}

PS_OUTPUT RenderScenePSBasic( float2 vTexCoord0 : TEXCOORD0,
                         float2 vTexCoord1 : TEXCOORD1,
                         float2 vTexCoord2 : TEXCOORD2,
                         float4 Fog		  : COLOR1, 
                         float4 PSPos : TEXCOORD7) 
{ 
    PS_OUTPUT Output;
       
    float4 AlphaTexColor = tex2D(AlphaTextureSampler, vTexCoord0);
    float4 BaseTexColor = tex2D(MeshTextureSampler, vTexCoord1);
    float4 LightMapTexColor = tex2D(LightMapTextureSampler, vTexCoord2);
    
   
	//BaseTexColor = (AlphaTexColor+BaseTexColor)-0.5;
        
    // Lookup mesh texture and modulate it with diffuseS    
    float4 Color = lerp( g_FogColor, (AlphaTexColor * (BaseTexColor*1.2f) * LightMapTexColor * g_MtrlColor ), Fog.x );
    
    
    Output.RGBColor.rgb = Color.rgb;
    Output.RGBColor.a = AlphaTexColor.a;
    
    
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


technique RenderSceneBasic
{
    pass P0
    {   
		FogEnable = false;
        VertexShader = compile vs_1_1 RenderSceneVS();
        PixelShader  = compile ps_2_0 RenderScenePSBasic(); 
    }
}