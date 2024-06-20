//--------------------------------------------------------------------------------------
// File: SimpleSample.fx
//
// The effect file for the SimpleSample sample.  
// 
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------
// Global variables
//--------------------------------------------------------------------------------------
float4 g_MaterialAmbientColor;      // Material's ambient color
float4 g_MaterialDiffuseColor;      // Material's diffuse color
float3 g_LightDir;                  // Light's direction in world space
float4 g_LightDiffuse;              // Light's diffuse color
texture g_MeshTexture;              // Color texture for mesh

float    g_fTime;                   // App's time in seconds
float4x4 g_mWorld : WORLD;                  // World matrix for object
float4x4 g_mView : VIEW;                  // World matrix for object
float4x4 g_mProj : PROJECTION;                  // World matrix for object

float4x4 g_mWorldViewProjection;    // World * View * Projection matrix
float4x4 g_mViewProjection;			// View * Projection matrix
float g_ShadowBright = 0.5;


//--------------------------------------------------------------------------------------
// Texture samplers
//--------------------------------------------------------------------------------------
sampler MeshTextureSampler = 
sampler_state
{
    Texture = <g_MeshTexture>;
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};


//--------------------------------------------------------------------------------------
// Vertex shader output structure
//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Position   : POSITION;   // vertex position 
    float4 Diffuse    : COLOR0;     // vertex diffuse color (note that COLOR0 is clamped from 0..1)
    float2 TextureUV  : TEXCOORD0;  // vertex texture coords 
};


//--------------------------------------------------------------------------------------
// This shader computes standard transform and lighting
//--------------------------------------------------------------------------------------
VS_OUTPUT RenderSceneVS( float4 vPos : POSITION, 
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD0 )
{
    VS_OUTPUT Output;
    float3 vNormalWorldSpace;
    
    // Transform the position from object space to homogeneous projection space
    //Output.Position = mul(vPos, g_mWorldViewProjection);
    
    float4 vVertexPos = vPos;
    vVertexPos.y = max( 0, vPos.y );    
       
    float4x4 vp = mul(g_mView, g_mProj);
    float4x4 wvp = mul(g_mWorld, vp);
    
    Output.Position = mul(vVertexPos, wvp);
    
       
        
    Output.Diffuse.rgba = (float4)1;
    
      
    
    // Just copy the texture coordinate through
    Output.TextureUV = vTexCoord0; 
    //Output.TextureUV.x = vPos.y;
    
    
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
PS_OUTPUT RenderScenePS( VS_OUTPUT In ) 
{ 
    PS_OUTPUT Output;

    // Lookup mesh texture and modulate it with diffuse
    //Output.RGBColor = tex2D(MeshTextureSampler, In.TextureUV) * In.Diffuse;
    Output.RGBColor = In.Diffuse * g_ShadowBright;
    
    
    return Output;
}


//--------------------------------------------------------------------------------------
// Renders scene 
//--------------------------------------------------------------------------------------
technique RenderScene
{
    pass P0
    {          
        VertexShader = compile vs_1_1 RenderSceneVS();
        PixelShader  = NULL;
    }
}
