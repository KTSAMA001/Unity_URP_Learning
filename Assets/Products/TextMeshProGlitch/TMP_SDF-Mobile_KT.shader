// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Simplified SDF shader:
// - No Shading Option (bevel / bump / env map)
// - No Glow Option
// - Softness is applied on both side of the outline

Shader "KTSAMA/TMP/Mobile/Distance Field" {

Properties {
	  _DebugFloat("_DbugFloat", Range(0,1)) = 0
	  _Offset_Block("Offset_Block",float) =1
      _Speed("Speed",float)=1
       _BlockLayer1_U("BlockLayer1_U",float)=1
       _BlockLayer1_V("BlockLayer1_V",float)=1
        
       _BlockLayer2_U("BlockLayer2_U",float)=1
       _BlockLayer2_V("BlockLayer2_V",float)=1
       _BlockLayer1_Indensity("BlockLayer1_Indensity",float)=1
       _BlockLayer2_Indensity("BlockLayer2_Indensity",float)=1
       _RGBSplit_Indensity("RGBSplit_Indensity",float)=1
       _Alpha("Alpha",Range(0,1))=1
	
	 [Toggle]_Depth_Mask_Color_Local("Depth_Mask_Color_Local",float)=0
     _DepthOffset("_DepthOffset",Vector)=(300,100,0,0)
	_DepthMaskColor1("_DepthMaskColor1",Color)=(1,1,1,1)
	_DepthMaskColor2("_DepthMaskColor2",Color)=(0,0,0,1)
	
	
	
	
	
	
	
	
	
	
	
	
	
	[HDR]_FaceColor     ("Face Color", Color) = (1,1,1,1)
	_FaceDilate			("Face Dilate", Range(-1,1)) = 0

	[HDR]_OutlineColor	("Outline Color", Color) = (0,0,0,1)
	_OutlineWidth		("Outline Thickness", Range(0,1)) = 0
	_OutlineSoftness	("Outline Softness", Range(0,1)) = 0

	[HDR]_UnderlayColor	("Border Color", Color) = (0,0,0,.5)
	_UnderlayOffsetX 	("Border OffsetX", Range(-1,1)) = 0
	_UnderlayOffsetY 	("Border OffsetY", Range(-1,1)) = 0
	_UnderlayDilate		("Border Dilate", Range(-1,1)) = 0
	_UnderlaySoftness 	("Border Softness", Range(0,1)) = 0

	_WeightNormal		("Weight Normal", float) = 0
	_WeightBold			("Weight Bold", float) = .5

	_ShaderFlags		("Flags", float) = 0
	_ScaleRatioA		("Scale RatioA", float) = 1
	_ScaleRatioB		("Scale RatioB", float) = 1
	_ScaleRatioC		("Scale RatioC", float) = 1

	_MainTex			("Font Atlas", 2D) = "white" {}
	_TextureWidth		("Texture Width", float) = 512
	_TextureHeight		("Texture Height", float) = 512
	_GradientScale		("Gradient Scale", float) = 5
	_ScaleX				("Scale X", float) = 1
	_ScaleY				("Scale Y", float) = 1
	_PerspectiveFilter	("Perspective Correction", Range(0, 1)) = 0.875
	_Sharpness			("Sharpness", Range(-1,1)) = 0

	_VertexOffsetX		("Vertex OffsetX", float) = 0
	_VertexOffsetY		("Vertex OffsetY", float) = 0

	_ClipRect			("Clip Rect", vector) = (-32767, -32767, 32767, 32767)
	_MaskSoftnessX		("Mask SoftnessX", float) = 0
	_MaskSoftnessY		("Mask SoftnessY", float) = 0

	_StencilComp		("Stencil Comparison", Float) = 8
	_Stencil			("Stencil ID", Float) = 0
	_StencilOp			("Stencil Operation", Float) = 0
	_StencilWriteMask	("Stencil Write Mask", Float) = 255
	_StencilReadMask	("Stencil Read Mask", Float) = 255

	_CullMode			("Cull Mode", Float) = 0
	_ColorMask			("Color Mask", Float) = 15
	
}

SubShader {
	Tags
	{
		"Queue"="Transparent"
		"IgnoreProjector"="True"
		"RenderType"="Transparent"
	}


	Stencil
	{
		Ref [_Stencil]
		Comp [_StencilComp]
		Pass [_StencilOp]
		ReadMask [_StencilReadMask]
		WriteMask [_StencilWriteMask]
	}

	Cull [_CullMode]
	ZWrite Off
	Lighting Off
	Fog { Mode Off }
	ZTest [unity_GUIZTestMode]
	//Blend One OneMinusSrcAlpha
	Blend SrcAlpha OneMinusSrcAlpha
	ColorMask [_ColorMask]
	Pass {
		CGPROGRAM
		#pragma vertex VertShader
		#pragma fragment PixShader
		#pragma shader_feature __ OUTLINE_ON
		#pragma shader_feature __ UNDERLAY_ON UNDERLAY_INNER

		#pragma multi_compile __ UNITY_UI_CLIP_RECT
		#pragma multi_compile __ UNITY_UI_ALPHACLIP
		 #pragma shader_feature_local_fragment _ _DEPTH_MASK_COLOR_LOCAL_ON
            #pragma shader_feature _ _DEPTH_MASK_COLOR
        float _DebugFloat;
		float _Offset_Block,_Alpha,_Speed,_BlockLayer1_U,_BlockLayer1_V,_BlockLayer2_U,_BlockLayer2_V,_BlockLayer1_Indensity,_BlockLayer2_Indensity,_RGBSplit_Indensity;
		#include "UnityCG.cginc"
		#include "UnityUI.cginc"
		#include "TMPro_Properties.cginc"
        sampler2D _DepthMaskColor;
		float4 _DepthMaskColor1,_DepthMaskColor2;
		float2 _DepthOffset;
		inline float4 ASE_ComputeGrabScreenPos(float4 pos)
        {
            #if UNITY_UV_STARTS_AT_TOP
            float scale = -1.0;
            #else
				float scale = 1.0;
            #endif
            float4 o = pos;
            o.y = pos.w * 0.5f;
            o.y = (pos.y - o.y) * _ProjectionParams.x * scale + o.y;
            return o;
        }
		struct vertex_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			float4	vertex			: POSITION;
			float3	normal			: NORMAL;
			fixed4	color			: COLOR;
			float2	texcoord0		: TEXCOORD0;
			float2	texcoord1		: TEXCOORD1;
		};

		struct pixel_t {
			UNITY_VERTEX_INPUT_INSTANCE_ID
			UNITY_VERTEX_OUTPUT_STEREO
			float4	vertex			: SV_POSITION;
			fixed4	faceColor		: COLOR;
			fixed4	outlineColor	: COLOR1;
			float4	texcoord0		: TEXCOORD0;			// Texture UV, Mask UV
			half4	param			: TEXCOORD1;			// Scale(x), BiasIn(y), BiasOut(z), Bias(w)
			half4	mask			: TEXCOORD2;			// Position in clip space(xy), Softness(zw)
			#if (UNDERLAY_ON | UNDERLAY_INNER)
			float4	texcoord1		: TEXCOORD3;			// Texture UV, alpha, reserved
			half2	underlayParam	: TEXCOORD4;			// Scale(x), Bias(y)
			#endif
			float4 posOS:TEXCOORD6;
			float4 screenPos:TEXCOORD7;
			  float4 posNDCw:TEXCOORD8;
		};

float4 GetPosNDC(float4 posCS)
{
	
 float4 ndc = posCS * 0.5f;
 float4 positionNDC=0;
positionNDC .xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
positionNDC.zw = posCS.zw;
	return positionNDC;
}
		pixel_t VertShader(vertex_t input)
		{
			pixel_t output;

			UNITY_INITIALIZE_OUTPUT(pixel_t, output);
			UNITY_SETUP_INSTANCE_ID(input);
			UNITY_TRANSFER_INSTANCE_ID(input, output);
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

			float bold = step(input.texcoord1.y, 0);

			float4 vert = input.vertex;
			output.posOS=vert;
			vert.x += _VertexOffsetX;
			vert.y += _VertexOffsetY;
			float4 vPosition = UnityObjectToClipPos(vert);

			float2 pixelSize = vPosition.w;
			pixelSize /= float2(_ScaleX, _ScaleY) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

			float scale = rsqrt(dot(pixelSize, pixelSize));
			scale *= abs(input.texcoord1.y) * _GradientScale * (_Sharpness + 1);
			if(UNITY_MATRIX_P[3][3] == 0) scale = lerp(abs(scale) * (1 - _PerspectiveFilter), scale, abs(dot(UnityObjectToWorldNormal(input.normal.xyz), normalize(WorldSpaceViewDir(vert)))));

			float weight = lerp(_WeightNormal, _WeightBold, bold) / 4.0;
			weight = (weight + _FaceDilate) * _ScaleRatioA * 0.5;

			float layerScale = scale;

			scale /= 1 + (_OutlineSoftness * _ScaleRatioA * scale);
			float bias = (0.5 - weight) * scale - 0.5;
			float outline = _OutlineWidth * _ScaleRatioA * 0.5 * scale;

			float opacity = input.color.a;
			#if (UNDERLAY_ON | UNDERLAY_INNER)
			opacity = 1.0;
			#endif

			fixed4 faceColor = fixed4(input.color.rgb, opacity) * _FaceColor;
			faceColor.rgb *= faceColor.a;

			fixed4 outlineColor = _OutlineColor;
			outlineColor.a *= opacity;
			outlineColor.rgb *= outlineColor.a;
			outlineColor = lerp(faceColor, outlineColor, sqrt(min(1.0, (outline * 2))));

			#if (UNDERLAY_ON | UNDERLAY_INNER)
			layerScale /= 1 + ((_UnderlaySoftness * _ScaleRatioC) * layerScale);
			float layerBias = (.5 - weight) * layerScale - .5 - ((_UnderlayDilate * _ScaleRatioC) * .5 * layerScale);

			float x = -(_UnderlayOffsetX * _ScaleRatioC) * _GradientScale / _TextureWidth;
			float y = -(_UnderlayOffsetY * _ScaleRatioC) * _GradientScale / _TextureHeight;
			float2 layerOffset = float2(x, y);
			#endif

			// Generate UV for the Masking Texture
			float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
			float2 maskUV = (vert.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);

			// Populate structure for pixel shader
			output.vertex = vPosition;
			output.faceColor = faceColor;
			output.outlineColor = outlineColor;
			output.texcoord0 = float4(input.texcoord0.x, input.texcoord0.y, maskUV.x, maskUV.y);
			output.param = half4(scale, bias - outline, bias + outline, bias);
			output.mask = half4(vert.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy));
			#if (UNDERLAY_ON || UNDERLAY_INNER)
			output.texcoord1 = float4(input.texcoord0 + layerOffset, input.color.a, 0);
			output.underlayParam = half2(layerScale, layerBias);
			#endif
            output.screenPos=ComputeScreenPos(output.vertex);

			
			output.posNDCw= GetPosNDC(output.vertex).w;
			return output;
		}
//取材毛星云的故障艺术后处理知乎文章：
//https://zhuanlan.zhihu.com/p/148256756#:~:text=2.3%20%E8%BF%9B%E9%98%B6%E7%89%88%E7%9A%84%E9%94%99%E4%BD%8D%E5%9B%BE%E5%9D%97%E6%95%85%E9%9A%9C%EF%BC%88Image%20Block%20Glitch%EF%BC%89
inline float randomNoise(float2 seed)
{
    return frac(sin(dot(seed * floor(_Time.y * _Speed), float2(17.13, 3.71))) * 43758.5453123);
}

inline float randomNoise(float seed)
{
    return randomNoise(float2(seed, 1.0));
}

		// PIXEL SHADER
		fixed4 PixShader(pixel_t input) : SV_Target
		{
			UNITY_SETUP_INSTANCE_ID(input);
float4 screenPos=ASE_ComputeGrabScreenPos(input.screenPos);
			screenPos.xy=screenPos.xy/screenPos.w;
			half d = tex2D(_MainTex, input.texcoord0.xy).a * input.param.x;
		

	        float3 PosOS_Normalize=input.posOS.xyz/float3(72,20,1);
            float2 blockLayer1 = floor(PosOS_Normalize.xy * float2(_BlockLayer1_U, _BlockLayer1_V));
               float2 blockLayer2 = floor(PosOS_Normalize.xy * float2(_BlockLayer2_U, _BlockLayer2_V));

               float lineNoise1 = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity);
               float lineNoise2 = pow(randomNoise(blockLayer2), _BlockLayer2_Indensity);
               float RGBSplitNoise = pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
               float lineNoise = lineNoise1 *lineNoise2 * _Offset_Block  - RGBSplitNoise;

                half ColorR1 = lineNoise*.1*   randomNoise(1.0);
                half ColorR2 = lineNoise*.1*   randomNoise(8.0);
                // half ColorG = tex2D(_MainTex, input.texcoord0.xy + float2(lineNoise*.001  * randomNoise(15.0), 0.0)).a;
                half ColorG1 =lineNoise*.1*  randomNoise(20.0);
                half ColorG2 =lineNoise*.1*  randomNoise(10.0);
                half ColorB1 = lineNoise*.1*   randomNoise(3.0);
                half ColorB2 = lineNoise*.1*   randomNoise(15.0);
                half ColorA1 = tex2D(_MainTex, input.texcoord0.xy - float2(lineNoise *.01* randomNoise(5.0), 0.0)).a;
                half ColorA2 = tex2D(_MainTex, input.texcoord0.xy - float2(lineNoise *.01* randomNoise(40.0), 0.0)).a;
half ColorR=max(ColorR1,ColorR2);
half ColorG=max(ColorG1,ColorG2);
half ColorB=max(ColorB1,ColorB2);
			
                float3 offsetRGB=float3(saturate(ColorR),saturate(ColorG),saturate(ColorB))*max(max(input.faceColor.r,input.faceColor.g),input.faceColor.b);
                d=max(ColorA1,ColorA2)* input.param.x;

half4 c = input.faceColor * saturate(d - input.param.w);
//half4 c = saturate(d - input.param.w);
	
//
//
//return float4(offsetRGB,1);
// return float4(ColorA.xxx,1);
// return float4(input.texcoord0.xy,0,1);
			float depthOffset = 1;
            float3 depthColor = 1;
  #ifdef _DEPTH_MASK_COLOR
                #ifdef _DEPTH_MASK_COLOR_LOCAL_ON


			
			depthOffset  =1-tex2D(_DepthMaskColor,screenPos.xy*0.9+(1-0.9)/2+ _DepthOffset*float2(1.0/ 1920.0,1.0/ 1080.0)* (1 / input.posNDCw)).r;
			depthOffset=max(0,depthOffset);
            depthColor=lerp(_DepthMaskColor1,_DepthMaskColor2,depthOffset);
			
#endif
			#endif
			



			



			
			#ifdef OUTLINE_ON
			c = lerp(input.outlineColor, input.faceColor, saturate(d - input.param.z));
			c *= saturate(d - input.param.y);
			#endif

			#if UNDERLAY_ON
			d = tex2D(_MainTex, input.texcoord1.xy).a * input.underlayParam.x;
			c += float4(_UnderlayColor.rgb * _UnderlayColor.a, _UnderlayColor.a) * saturate(d - input.underlayParam.y) * (1 - c.a);
			#endif

			#if UNDERLAY_INNER
			half sd = saturate(d - input.param.z);
			d = tex2D(_MainTex, input.texcoord1.xy).a * input.underlayParam.x;
			c += float4(_UnderlayColor.rgb * _UnderlayColor.a, _UnderlayColor.a) * (1 - saturate(d - input.underlayParam.y)) * sd * (1 - c.a);
			#endif

			// Alternative implementation to UnityGet2DClipping with support for softness.
			#if UNITY_UI_CLIP_RECT
			half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(input.mask.xy)) * input.mask.zw);
			c *= m.x * m.y;
			#endif

			#if (UNDERLAY_ON | UNDERLAY_INNER)
			c *= input.texcoord1.z;
			#endif

			#if UNITY_UI_ALPHACLIP
			clip(c.a - 0.001);
			#endif
		
			//return +1,0);
			// 	c.rgb-=	offsetRGB;
			// 	c.rgb =	max(offsetRGB*1,c.rgb);
			// c.rgb=max(0,c.rgb);
			// c.rgb=min(c.rgb,1.2);
		//	return float4(1,0,0,PosOS_Normalize.x>_DbugFloat);
			//return lerp(float4(0,1,0,1),float4(1,0,0,1),PosOS_Normalize.x>_DbugFloat);
			c.rgb=abs(c.rgb-offsetRGB);
			c.rgb*=depthColor;


			c.a*=_Alpha;
			return c;
		}
		ENDCG
	}
}

CustomEditor "TMPro.EditorUtilities.TMP_SDFShaderGUI"
}
