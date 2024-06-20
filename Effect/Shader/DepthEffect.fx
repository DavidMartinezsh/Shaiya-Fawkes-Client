//--------------------------------------------------------------//
// Pass 0
//--------------------------------------------------------------//
float4x4 matViewProjection;
////////////////////////////////////////////////////////////////////
static const int MAX_MATRICES = 52;
float4x3 mWorldMatrixArray[MAX_MATRICES] : WORLDMATRIXARRAY;
////////////////////////////////////////////////////////////////////
float g_far = 790.0f;
float g_near = 1.0f;
float g_fBlurDist = 0.002f;

float3 f3FogColor = float3(1.0f, 1.0f, 1.0f);
//
float4 fDiffuseAlpha = 1.0f;
//

bool bAlphaAble = false;
///////////////////////////////////////////////////////////////////
float     g_fViewportWidth;
float     g_fViewportHeight;


const float2 samples[12] = {
   -0.326212, -0.405805,
   -0.840144, -0.073580,
   -0.695914,  0.457137,
   -0.203345,  0.620716,
    0.962340, -0.194983,
    0.473434, -0.480026,
    0.519456,  0.767022,
    0.185461, -0.893124,
    0.507431,  0.064425,
    0.896420,  0.412458,
   -0.321940, -0.932615,
   -0.791559, -0.597705,
};

///////////////////////////////////////////////////////////////////
texture BaseTex;
sampler Texture0 = sampler_state
{
	Texture = (BaseTex);
	MAGFILTER = LINEAR;
	MINFILTER = LINEAR;
	MIPFILTER = LINEAR;
	
};

texture DepthTex;
sampler Texture1 = sampler_state
{

	Texture = (DepthTex);
	MAGFILTER = LINEAR;
	MINFILTER = LINEAR;
	MIPFILTER = LINEAR;
};

///////////////////////////////////////////////////////////////////
struct VS_INPUT 
{
   float4 Position : POSITION0;
   float3 Normal : NORMAL0;
   float2 Tex0 : TEXCOORD0;
};

struct VS_INPUT_EFFECT
{
   float4 Position : POSITION0;
   float4 Color : Color0;
   float2 Tex0 : TEXCOORD0; 
};

struct VS_INPUT_2
{
   float4 Position : POSITION0;
   float3 Normal : NORMAL0;
   float4 Color : COLOR0;
   float2 Tex0 : TEXCOORD0;
};

struct VS_INPUT_3
{
   float4 Position : POSITION0;
   float4 BlendWeights : BLENDWEIGHT;
   float4 BlendIndices : BLENDINDICES;
   float3 Normal : NORMAL;
   float2 Tex0   : TEXCOORD0;
};

struct VS_OUTPUT 
{
   float4 Position : POSITION0;
   float2 Tex0 : TEXCOORD0;
   float Depth : TEXCOORD1;
   
};

struct VS_OUTPUT_2
{
	float4 Position : POSITION0;
	float2 Tex0 : TEXCOORD0;
	float Depth : TEXCOORD1;
};

struct VS_OUTPUT_3
{
   float4 Position : POSITION0;
   float2 Tex0 : TEXCOORD0;
};

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

float ComputeDepthBlur (float depth)
{
   float f;
   f = (depth - g_near)/g_far;
   f = clamp (f, 0, 1);
   return f;
}

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

VS_OUTPUT Pass_0_vs_main( VS_INPUT Input )
{
   VS_OUTPUT Output= (VS_OUTPUT)0;

   float4 Pos = mul( Input.Position, matViewProjection );

   Output.Position = Pos;
   Output.Tex0 = Input.Tex0;
   Output.Depth = Pos.z;
   
   return( Output );
}

VS_OUTPUT Pass_0_Effect_vs_main( VS_INPUT_EFFECT Input )
{
   VS_OUTPUT Output= (VS_OUTPUT)0;

   float4 Pos = mul( Input.Position, matViewProjection );

   Output.Position = Pos;
   Output.Depth = Pos.z;
   
   return( Output );
}

VS_OUTPUT Pass_0_RHW_vs_main( VS_INPUT_EFFECT Input )
{
   VS_OUTPUT Output = (VS_OUTPUT)0;

   Output.Position = Input.Position;
   Output.Tex0 = Input.Tex0;
   Output.Depth = Output.Position.z;
   
   return( Output );
}

float4 Pass_0_ps_main(float4 Position : POSITION0,
					float2 Tex0 : TEXCOORD0,
					float Depth : TEXCOORD1) : COLOR
{
	float4 Color = tex2D(Texture0, Tex0);
   float4 Out;
   Out = ComputeDepthBlur(Depth).xxxx;
   Out.w = Color.a;
   return Out;
}

float4 Pass_0_Object_ps_main(float4 Position : POSITION0,
					float2 Tex0 : TEXCOORD0,
					float Depth : TEXCOORD1) : COLOR
{
   float4 Out;
   Out = ComputeDepthBlur(Depth).xxxx;
   Out.w = 1.0f;
   
   return Out;
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

VS_OUTPUT_2 Pass_1_vs_main( VS_INPUT Input )
{
   VS_OUTPUT_2 Output;

   float4 Pos = mul( Input.Position, matViewProjection );

   Output.Position = Pos;
   Output.Tex0 = Input.Tex0;
   Output.Depth = Pos.z;
   
   return( Output );
}

float4 Pass_1_ps_main(float4 Position : POSITION0,
			   float2 Tex0 : TEXCOORD0,
               float Depth : TEXCOORD1) : COLOR
{
   float4 Color = tex2D(Texture0, Tex0);
   float4 Out = ComputeDepthBlur(Depth).xxxx;
   
   Color.r = Out.r;
   Color.g = Out.g;
   Color.b = Out.b;
   
   return Color;
}

/////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////


VS_OUTPUT_3 Pass_2_vs_main( float4 Position : POSITION0,
							float2 Tex0 : TEXCOORD0 )
{
   VS_OUTPUT_3 Output;

   float2 halfPixelSize = 1.0 / float2( g_fViewportWidth, g_fViewportHeight );
   
   // Clean up inaccuracies
   Position.xy = sign(Position.xy);
   Output.Position = float4(Position.xy, 0, 1);
   
   // offset to properly align pixels with texels   
   Output.Position.xy += float2(-1, 1) * halfPixelSize;
   Output.Position.z = 1.0f;
   
   Output.Tex0 = 0.5 * Position.xy + 0.5;
   Output.Tex0.y = 1.0 - Output.Tex0.y;
   
   return( Output );
}

float4 Pass_2_ps_main(float4 Position : POSITION0,
						float2 Tex0 : TEXCOORD0) : COLOR
{
	float4 Blur = tex2D(Texture0, Tex0);
	float4 Original = Blur;
	float4 Depth = tex2D(Texture1, Tex0);
	float4 Result = float4(1.0f,1.0f,1.0f,1.0f);

	for(int i = 0 ; i < 12 ; i++)
	{
		Blur += tex2D(Texture0, Tex0 + g_fBlurDist * samples[i]);
	}
	Blur = Blur/13;
	
	Result.rgb = ((1.0f - Depth) * Original) + (Depth * Blur);

	return Result;
}

//////////////////////////////////////////////////////////////////

VS_OUTPUT_2 Pass_3_vs_main( VS_INPUT_2 Input )
{
   VS_OUTPUT_2 Output;

   float4 Pos = mul( Input.Position, matViewProjection );

   Output.Position = Pos;
   Output.Tex0 = Input.Tex0;
   Output.Depth = Pos.z;
   
   return( Output );
}

//////////////////////////////////////////////////////////////////
float4 Pass_3_ps_main(float4 Position : POSITION0,
						float2 Tex0 : TEXCOORD0) : COLOR
{
	float4 Color = tex2D(Texture0, Tex0);
	return Color;
}

///////////////////////////////////////////////////////////////////

VS_OUTPUT Pass_4_vs_main(VS_INPUT_3 Input)
{
   VS_OUTPUT Output = (VS_OUTPUT)0;
   
   float3 Pos = 0.0f;
   float  LastWeight = 0.0f;
   
   //int4 IndexVector = D3DCOLORtoUBYTE4(Input.BlendIndices);
   
   float BlendWeightArray[4] = (float[4])Input.BlendWeights;
   int IndexArray[4]         = (int[4])Input.BlendIndices;
   
   
   for(int iBone = 0 ; iBone < 3 ; iBone++)
   {
      LastWeight = LastWeight + BlendWeightArray[iBone];
      Pos += mul(Input.Position, mWorldMatrixArray[IndexArray[iBone]]) * BlendWeightArray[iBone];
   }
   LastWeight = 1.0f - LastWeight;
   Pos += mul(Input.Position, mWorldMatrixArray[IndexArray[3]]) * LastWeight ;
   

   Output.Position = mul(float4(Pos.xyz,1.0f), matViewProjection );
   Output.Tex0 = Input.Tex0;
   Output.Depth = Output.Position.z;

   //Output.Position = mul( Input.Position, matViewProjection );
   
   return( Output );

}

float4 Pass_4_ps_main(VS_OUTPUT_2 output) : COLOR
{
	float4 Color = tex2D(Texture0, output.Tex0);

	return float4(0.0f, 0.0f, 0.0f, Color.a);
}
///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////
float4 Pass_5_ps_main(float4 Position : POSITION0,
						float2 Tex0 : TEXCOORD0) : COLOR
{
	float4 Color = float4(1.0f,1.0f,1.0f,1.0f);
	
	float Value = clamp(Tex0.y/1.0f, 0.0f, 1.0f);
	
	Color.rgb = float3(Value, Value,Value);
	
	return Color;
}


//////////////////////////////////////////////////////////////////////
float4 Pass_6_ps_main(float4 Position : POSITION0,
						float2 Tex0 : TEXCOORD0) : COLOR
{
	float4 Orign = tex2D(Texture0, Tex0);
	float4 Depth = tex2D(Texture1, Tex0);
	float4 Background = float4(1.0f,1.0f,1.0f,1.0f);
 
	Background.rgb = ((1.0f - Depth) * Orign) + (Depth * f3FogColor);

	return Background;
}

//--------------------------------------------------------------//
// Technique Section for Default_DirectX_Effect
//--------------------------------------------------------------//

technique DepthShader
{
	// 지형 처리
   pass Pass_0
   {
		CULLMODE = CCW;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
	    
	    
	    ALPHABLENDENABLE = TRUE;
	    ALPHATESTENABLE = TRUE;
	    
	    
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		ZWRITEENABLE = TRUE;
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		
		//AlphaOp[0] = SelectArg1;
		//AlphaArg1[0] = Texture;
		//
	  
      VertexShader = compile vs_2_0 Pass_0_vs_main();
      PixelShader = compile ps_2_0 Pass_0_ps_main();
   }
   
   // 일반 Mesh 처리(트리)
   pass Pass_1
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = TRUE;
	    ALPHATESTENABLE = TRUE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		
		ZWRITEENABLE = TRUE;
		AlphaOp[0] = Modulate;
		AlphaArg1[0] = Texture;
		AlphaArg2[0] = Diffuse;
		//
		
      VertexShader = compile vs_1_1 Pass_1_vs_main();
      PixelShader = compile ps_2_0 Pass_1_ps_main();
   }
   
   // 블루 효과 처리 
   pass Pass_2
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = TRUE;
	    ALPHATESTENABLE = TRUE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		
		ZWRITEENABLE = TRUE;
		AlphaOp[0] = Modulate;
		AlphaArg1[0] = Texture;
		AlphaArg2[0] = Diffuse;
		//
	  
	  
		VertexShader = compile vs_1_1 Pass_2_vs_main();
      PixelShader = compile ps_2_0 Pass_2_ps_main();
   }
   
   // 애니 Mesh 처리
   pass Pass_3
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = TRUE;
	    ALPHATESTENABLE = TRUE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		ZWRITEENABLE = TRUE;
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		
		ZWRITEENABLE = TRUE;
		AlphaOp[0] = Modulate;
		AlphaArg1[0] = Texture;
		AlphaArg2[0] = Diffuse;
		
	VertexShader = compile vs_1_1 Pass_3_vs_main();
	PixelShader = compile ps_2_0 Pass_1_ps_main();
   }
   
   //Skin Mesh 처리
   pass Pass_4
   {
   		CULLMODE = CCW;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = FALSE;
	    ALPHATESTENABLE = FALSE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		ZWRITEENABLE = TRUE;
		ZENABLE = TRUE;
		
				
		//
		ColorOp[0] = MODULATE;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		//
   
	VertexShader = compile vs_1_1 Pass_4_vs_main();
	PixelShader = compile ps_2_0 Pass_0_ps_main();
   }
   
   //Effect Mesh 처리
   pass Pass_5
   {
		CULLMODE = NONE;
		
		AMBIENT = 0xFFFFFFFF;
		ALPHABLENDENABLE = FALSE;
		ALPHATESTENABLE = FALSE;
		LIGHTING = FALSE;
		
		VertexShader = compile vs_1_1 Pass_0_Effect_vs_main();
		PixelShader = compile ps_2_0 Pass_0_ps_main();
   }
   
	// 텍스트 관련 처리 ( 2D 렌더)
   pass Pass_6
   {
	ZENABLE = TRUE;
	ZWRITEENABLE = TRUE;
	//ZFUNC = LESSEQUAL;
	
	CULLMODE = NONE;
	LIGHTING = FALSE;
	
	ALPHABLENDENABLE = FALSE;
	ALPHATESTENABLE = TRUE;
	SRCBLEND = SRCALPHA;
	DESTBLEND = INVSRCALPHA;
	
	AMBIENT = 0xFFFFFFFF;
	DITHERENABLE = FALSE;
	
	ColorOp[0] = Modulate;
	ColorArg1[0] = Texture;
	ColorArg2[0] = Diffuse;
	
	VertexShader = compile vs_1_1 Pass_0_RHW_vs_main();
	PixelShader = compile ps_2_0 Pass_4_ps_main();
   }
   
   // 텍스트 관련 처리 ( 던전 툴팁 렌더)
   pass Pass_7
   {
	CULLMODE = CCW;
	LIGHTING = FALSE;
	ZWRITEENABLE = FALSE;
	ZENABLE = FALSE;
	ALPHABLENDENABLE = TRUE;
	ALPHATESTENABLE = FALSE;
	AMBIENT = 0xFFFFFFFF;
	DITHERENABLE = FALSE;

	SRCBLEND = SRCALPHA;
	DESTBLEND = INVSRCALPHA;
	
	ColorOp[0] = Modulate;
	ColorArg1[0] = Texture;
	ColorArg2[0] = Current;
	
	AlphaOp[0] = Modulate;
	AlphaArg1[0] = Diffuse;
	AlphaArg2[0] = Texture;
	

	VertexShader = compile vs_1_1 Pass_0_RHW_vs_main();
	PixelShader = compile ps_2_0 Pass_4_ps_main();
   }
   // 스카이 박스 대용
   pass Pass_8
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = FALSE;
	    ALPHATESTENABLE = FALSE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		ZWRITEENABLE = TRUE;
		ZENABLE = TRUE;
	
		VertexShader = compile vs_1_1 Pass_2_vs_main();
		PixelShader = compile ps_2_0 Pass_5_ps_main();
	
   }
   
   // 포그 효과 처리 // 마지막 출력
   pass Pass_9
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = TRUE;
	    ALPHATESTENABLE = TRUE;
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		CULLMODE = NONE;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = Current;
		
		ZWRITEENABLE = TRUE;
		AlphaOp[0] = Modulate;
		AlphaArg1[0] = Texture;
		AlphaArg2[0] = Diffuse;
		//
	  
	  
		VertexShader = compile vs_1_1 Pass_2_vs_main();
      PixelShader = compile ps_2_0 Pass_6_ps_main();
   }
   
   // 일반 Mesh 처리(트리 이외 오브젝트)
   pass Pass_10
   {
		CULLMODE = NONE;
		DITHERENABLE = FALSE;
		FOGENABLE = FALSE;
		
	    ALPHABLENDENABLE = FALSE;
	    ALPHATESTENABLE = FALSE;
	    
	    AMBIENT = 0xFFFFFFFF;
	    DIFFUSEMATERIALSOURCE = COLOR1;
	  
		SRCBLEND = SRCALPHA;
		DESTBLEND = INVSRCALPHA;
		LIGHTING = TRUE;
		
		DITHERENABLE = FALSE;
		RANGEFOGENABLE = FALSE;
		
		ZWRITEENABLE = TRUE;
		ZENABLE = TRUE;
		
		//
		ColorOp[0] = Disable;
		//ColorArg1[0] = Texture;
		//ColorArg2[0] = Current;
		
		AlphaOp[0] = Disable;
		
		texture[0] = NULL;
		//
	  
      VertexShader = compile vs_2_0 Pass_0_vs_main();
      PixelShader = compile ps_2_0 Pass_0_Object_ps_main();
   }
}
