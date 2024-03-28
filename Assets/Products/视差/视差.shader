// Made with Amplify Shader Editor v1.9.1.8
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "视差"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_Front1("Front1", 2D) = "white" {}
		_Size("Size", Range( 0 , 10)) = 1
		_DepthMain("DepthMain", Float) = 0
		_SO_M("SO_M", Vector) = (1,1,0,0)
		_M("M", 2D) = "white" {}
		_BackFlashHadrness("Back Flash Hadrness", Float) = 0.17
		_BackFlashwidth("Back Flash width", Float) = 0.21
		_SO_B("SO_B", Vector) = (1,1,0,0)
		_DepthBack("DepthBack", Float) = 0
		_PikaPikaMap(" PikaPika Map", 2D) = "white" {}
		_B("B", 2D) = "white" {}
		_CardBack("Card Back", 2D) = "white" {}
		_FlowMap_ST("_FlowMap_ST", Vector) = (0,0,0,0)
		_NoiseMap_ST("_NoiseMap_ST", Vector) = (0,0,0,0)
		_FlowMap("FlowMap", 2D) = "white" {}
		[HideInInspector]_NormalMap("NormalMap", 2D) = "bump" {}
		_B2("B2", 2D) = "black" {}
		_SO_B2("SO_B2", Vector) = (0,0,0,0)
		[Toggle]_CardBackPikaPika("Card Back PikaPika?", Float) = 1
		[Toggle]_FPikaPika("F PikaPika?", Float) = 1
		[Toggle]_Back_AddtionMask("Back_AddtionMask?", Float) = 0
		[Toggle]_F_AddtionMask("F_AddtionMask?", Float) = 1
		_MaskPos("MaskPos", Vector) = (0,0,0,0)
		_BaseDir("BaseDir", Vector) = (0,0,0,0)
		[ToggleUI]_F_Flow("F_Flow?", Float) = 0
		[ASEEnd]_F_FlowMap("F_FlowMap", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Lit" }

		Cull Off
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _LIGHT_LAYERS
			#pragma multi_compile_fragment _ _LIGHT_COOKIES
			#pragma multi_compile _ _FORWARD_PLUS

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
					float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _CardBack;
			sampler2D _NormalMap;
			sampler2D _PikaPikaMap;
			sampler2D _Front1;
			sampler2D _F_FlowMap;
			sampler2D _M;
			sampler2D _B2;
			sampler2D _FlowMap;
			sampler2D _B;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float4 KT_Flow213( float2 uv, float _Size, sampler2D _FlowMap, sampler2D _NoiseMap, float2 _FlowStrength, float _FlowSpeed )
			{
				float2 uv_NoiseMap = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
				float2 temp_output_4_0_g3 = (( uv_NoiseMap / _Size )).xy;
				float2 uv_FlowMap =uv * _FlowMap_ST.xy + _FlowMap_ST.zw;
				float4 tex2DNode2 = tex2D( _FlowMap, uv_FlowMap );
				float2 temp_output_17_0_g3 = _FlowStrength;
				float mulTime22_g3 = _Time.y * _FlowSpeed;
				float temp_output_27_0_g3 = frac( mulTime22_g3 );
				float2 temp_output_11_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * temp_output_27_0_g3 ) );
				float2 temp_output_12_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * frac( ( mulTime22_g3 + 0.5 ) ) ) );
				float4 lerpResult9_g3 = lerp( tex2D( _NoiseMap, temp_output_11_0_g3 ) , tex2D( _NoiseMap, temp_output_12_0_g3 ) , ( abs( ( temp_output_27_0_g3 - 0.5 ) ) / 0.5 ));
				float4 break10 = lerpResult9_g3;
				return break10;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord8.xy = v.texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif

				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						, bool ase_vface : SV_IsFrontFace ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_CardBack = IN.ase_texcoord8.xy * _CardBack_ST.xy + _CardBack_ST.zw;
				float4 tex2DNode64 = tex2D( _CardBack, uv_CardBack );
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 ase_tanViewDir =  tanToWorld0 * WorldViewDirection.x + tanToWorld1 * WorldViewDirection.y  + tanToWorld2 * WorldViewDirection.z;
				ase_tanViewDir = SafeNormalize( ase_tanViewDir );
				float4 appendResult287 = (float4(ase_tanViewDir.y , ase_tanViewDir.x , 0.0 , 0.0));
				float2 uv_NormalMap = IN.ase_texcoord8.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float switchResult12 = (((ase_vface>0)?(1.0):(0.0)));
				float Face13 = switchResult12;
				float3 lerpResult183 = lerp( -UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , Face13);
				float3 Normal222 = lerpResult183;
				float4 temp_output_284_0 = reflect( -appendResult287 , float4( Normal222 , 0.0 ) );
				float luminance138 = Luminance(temp_output_284_0.xyz);
				float mulTime119 = _TimeParameters.x * -0.02;
				float3 hsvTorgb85 = HSVToRGB( float3(( ( luminance138 * 3.0 * ase_tanViewDir.z ) + mulTime119 ),1.0,3.0) );
				float3 PikaPika_Color251 = hsvTorgb85;
				float luminance299 = Luminance(tex2DNode64.rgb);
				float smoothstepResult300 = smoothstep( 0.13 , 1.39 , luminance299);
				float CardBackMask301 = smoothstepResult300;
				float2 uv_PikaPikaMap = IN.ase_texcoord8.xy * _PikaPikaMap_ST.xy + _PikaPikaMap_ST.zw;
				float luminance137 = Luminance(tex2D( _PikaPikaMap, uv_PikaPikaMap ).rgb);
				float smoothstepResult136 = smoothstep( _BackFlashHadrness , ( _BackFlashHadrness + _BackFlashwidth ) , luminance137);
				float FB_PikaPika_AddtionMask258 = smoothstepResult136;
				float3 Back_PikaPika_Addtion_Color309 = ( PikaPika_Color251 * (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 )) );
				float2 uv_Front1 = IN.ase_texcoord8.xy * _Front1_ST.xy + _Front1_ST.zw;
				float4 temp_output_77_0 = ( tex2D( _Front1, uv_Front1 ) + float4( 0,0,0,0 ) );
				float4 FMapColor234 = ( temp_output_77_0 * temp_output_77_0.a );
				float2 texCoord16 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 UV57 = texCoord16;
				float2 temp_output_4_0_g4 = (( UV57 / _Size )).xy;
				float2 temp_output_17_0_g4 = float2( 0.2,0.2 );
				float mulTime22_g4 = _TimeParameters.x * 0.5;
				float temp_output_27_0_g4 = frac( mulTime22_g4 );
				float2 temp_output_11_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * temp_output_27_0_g4 ) );
				float2 temp_output_12_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * frac( ( mulTime22_g4 + 0.5 ) ) ) );
				float4 lerpResult9_g4 = lerp( tex2D( _F_FlowMap, temp_output_11_0_g4 ) , tex2D( _F_FlowMap, temp_output_12_0_g4 ) , ( abs( ( temp_output_27_0_g4 - 0.5 ) ) / 0.5 ));
				float luminance350 = Luminance(lerpResult9_g4.rgb);
				float luminance347 = Luminance(FMapColor234.rgb);
				float smoothstepResult345 = smoothstep( 0.03 , 1.67 , luminance347);
				float4 lerpResult353 = lerp( FMapColor234 , ( luminance350 * FMapColor234 * 3.0 * float4( PikaPika_Color251 , 0.0 ) ) , (( _F_Flow )?( smoothstepResult345 ):( 0.0 )));
				float FrontMap_Mask226 = ( 1.0 - temp_output_77_0.a );
				float2 appendResult70 = (float2(_SO_M.x , _SO_M.y));
				float2 appendResult71 = (float2(_SO_M.z , _SO_M.w));
				float3 UV_M58 = ( float3( (UV57*appendResult70 + appendResult71) ,  0.0 ) + ( ( _DepthMain / ase_tanViewDir.z ) * ase_tanViewDir ) );
				float4 tex2DNode24 = tex2D( _M, (UV_M58*1.0 + float3( ( sin( _TimeParameters.x ) * float2( 0,0.02 ) ) ,  0.0 )).xy );
				float4 MMapColor237 = ( tex2DNode24 * tex2DNode24.a );
				float MMap_Mask230 = ( 1.0 - tex2DNode24.a );
				float2 appendResult74 = (float2(_SO_B.x , _SO_B.y));
				float2 appendResult75 = (float2(_SO_B.z , _SO_B.w));
				float3 UV_B60 = ( ( ( _DepthBack / ase_tanViewDir.z ) * ase_tanViewDir ) + float3( (UV57*appendResult74 + appendResult75) ,  0.0 ) );
				float2 appendResult295 = (float2(_SO_B2.x , _SO_B2.y));
				float2 appendResult296 = (float2(_SO_B2.z , _SO_B2.w));
				float2 CenteredUV15_g3 = ( UV_B60.xy - float2( 0.5,0.5 ) );
				float2 break17_g3 = CenteredUV15_g3;
				float2 appendResult23_g3 = (float2(( length( CenteredUV15_g3 ) * 0.2 * 2.0 ) , ( atan2( break17_g3.x , break17_g3.y ) * ( 1.0 / TWO_PI ) * 3.0 )));
				float2 panner220 = ( 1.0 * _Time.y * float2( -0.1,0 ) + appendResult23_g3);
				float2 uv213 = panner220;
				float _Size213 = 1.0;
				sampler2D _FlowMap213 = _FlowMap;
				sampler2D _NoiseMap213 = _B;
				float2 _FlowStrength213 = float2( 0.1,0.1 );
				float _FlowSpeed213 = -0.5;
				float4 localKT_Flow213 = KT_Flow213( uv213 , _Size213 , _FlowMap213 , _NoiseMap213 , _FlowStrength213 , _FlowSpeed213 );
				float4 BMapColor245 = localKT_Flow213;
				float B_Map_Mask247 = localKT_Flow213.x;
				float temp_output_121_0 = saturate( (distance( UV_B60 , float3( 0.5,0.5,0 ) )*0.43 + 0.42) );
				float smoothstepResult122 = smoothstep( 0.0 , 0.1 , ( 1.0 - temp_output_121_0 ));
				float smoothstepResult123 = smoothstep( 0.71 , 0.78 , temp_output_121_0);
				float B_PikaPika_Mask240 = ( smoothstepResult122 * smoothstepResult123 );
				float4 lerpResult289 = lerp( tex2D( _B2, (UV_B60*float3( appendResult295 ,  0.0 ) + float3( appendResult296 ,  0.0 )).xy ) , ( BMapColor245 * B_Map_Mask247 * B_PikaPika_Mask240 ) , ( B_Map_Mask247 * B_PikaPika_Mask240 ));
				float4 F_Final_Diffuse_Color263 = ( lerpResult353 + ( FrontMap_Mask226 * ( MMapColor237 + ( MMap_Mask230 * lerpResult289 ) ) ) );
				float B_PikaPIka_Final_Mask268 = ( B_Map_Mask247 * B_PikaPika_Mask240 );
				float luminance311 = Luminance(FMapColor234.rgb);
				float smoothstepResult312 = smoothstep( 0.15 , 1.49 , luminance311);
				float F_Map_Mask313 = smoothstepResult312;
				float3 F_PikaPika_Addtion_Color274 = ( PikaPika_Color251 * (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 )) );
				float3 F_PakaPika_Final_Color273 = ( ( PikaPika_Color251 * FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) + F_PikaPika_Addtion_Color274 );
				float4 lerpResult48 = lerp( ( tex2DNode64 + float4( (( _CardBackPikaPika )?( Back_PikaPika_Addtion_Color309 ):( float3( 0,0,0 ) )) , 0.0 ) ) , ( F_Final_Diffuse_Color263 + float4( (( _FPikaPika )?( F_PakaPika_Final_Color273 ):( float3( 0,0,0 ) )) , 0.0 ) ) , Face13);
				
				float Back_PikaPika_AddtionMask323 = (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 ));
				float F_PikaPika_AddtionMask322 = (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 ));
				float lerpResult180 = lerp( Back_PikaPika_AddtionMask323 , ( F_PikaPika_AddtionMask322 + ( FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) ) , Face13);
				
				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float3 BaseColor = lerpResult48.rgb;
				float3 Normal = Normal222;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = saturate( ( 0.8 * lerpResult180 ) );
				float Occlusion = 1;
				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _CLEARCOAT
					float CoatMask = 0;
					float CoatSmoothness = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							inputData.normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent, WorldBiTangent, WorldNormal));
						#elif _NORMAL_DROPOFF_OS
							inputData.normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							inputData.normalWS = Normal;
						#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = ShadowCoords;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif
					inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
				#else
					inputData.bakedGI = SAMPLE_GI(IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS);
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
					#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				SurfaceData surfaceData;
				surfaceData.albedo              = BaseColor;
				surfaceData.metallic            = saturate(Metallic);
				surfaceData.specular            = Specular;
				surfaceData.smoothness          = saturate(Smoothness),
				surfaceData.occlusion           = Occlusion,
				surfaceData.emission            = Emission,
				surfaceData.alpha               = saturate(Alpha);
				surfaceData.normalTS            = Normal;
				surfaceData.clearCoatMask       = 0;
				surfaceData.clearCoatSmoothness = 1;

				#ifdef _CLEARCOAT
					surfaceData.clearCoatMask       = saturate(CoatMask);
					surfaceData.clearCoatSmoothness = saturate(CoatSmoothness);
				#endif

				#ifdef _DBUFFER
					ApplyDecalToSurfaceData(IN.clipPos, surfaceData, inputData);
				#endif

				half4 color = UniversalFragmentPBR( inputData, surfaceData);

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;

					#define SUM_LIGHT_TRANSMISSION(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 transmission = max( 0, -dot( inputData.normalWS, Light.direction ) ) * atten * Transmission;\
						color.rgb += BaseColor * transmission;

					SUM_LIGHT_TRANSMISSION( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSMISSION( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSMISSION( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#define SUM_LIGHT_TRANSLUCENCY(Light)\
						float3 atten = Light.color * Light.distanceAttenuation;\
						atten = lerp( atten, atten * Light.shadowAttenuation, shadow );\
						half3 lightDir = Light.direction + inputData.normalWS * normal;\
						half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );\
						half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;\
						color.rgb += BaseColor * translucency * strength;

					SUM_LIGHT_TRANSLUCENCY( GetMainLight( inputData.shadowCoord ) );

					#if defined(_ADDITIONAL_LIGHTS)
						uint meshRenderingLayers = GetMeshRenderingLayer();
						uint pixelLightCount = GetAdditionalLightsCount();
						#if USE_FORWARD_PLUS
							for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
							{
								FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

								Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
								#ifdef _LIGHT_LAYERS
								if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
								#endif
								{
									SUM_LIGHT_TRANSLUCENCY( light );
								}
							}
						#endif
						LIGHT_LOOP_BEGIN( pixelLightCount )
							Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
							#ifdef _LIGHT_LAYERS
							if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
							#endif
							{
								SUM_LIGHT_TRANSLUCENCY( light );
							}
						LIGHT_LOOP_END
					#endif
				}
				#endif

				#ifdef ASE_REFRACTION
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, float4( WorldNormal,0 ) ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos.xy ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD2;
				#endif				
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;
				o.clipPosV = clipPos;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask R
			AlphaToMask Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			
			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD2;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(	VertexOutput IN
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature EDITOR_VISUALIZATION

			#define SHADERPASS SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float4 VizUV : TEXCOORD2;
					float4 LightCoord : TEXCOORD3;
				#endif
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _CardBack;
			sampler2D _NormalMap;
			sampler2D _PikaPikaMap;
			sampler2D _Front1;
			sampler2D _F_FlowMap;
			sampler2D _M;
			sampler2D _B2;
			sampler2D _FlowMap;
			sampler2D _B;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float4 KT_Flow213( float2 uv, float _Size, sampler2D _FlowMap, sampler2D _NoiseMap, float2 _FlowStrength, float _FlowSpeed )
			{
				float2 uv_NoiseMap = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
				float2 temp_output_4_0_g3 = (( uv_NoiseMap / _Size )).xy;
				float2 uv_FlowMap =uv * _FlowMap_ST.xy + _FlowMap_ST.zw;
				float4 tex2DNode2 = tex2D( _FlowMap, uv_FlowMap );
				float2 temp_output_17_0_g3 = _FlowStrength;
				float mulTime22_g3 = _Time.y * _FlowSpeed;
				float temp_output_27_0_g3 = frac( mulTime22_g3 );
				float2 temp_output_11_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * temp_output_27_0_g3 ) );
				float2 temp_output_12_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * frac( ( mulTime22_g3 + 0.5 ) ) ) );
				float4 lerpResult9_g3 = lerp( tex2D( _NoiseMap, temp_output_11_0_g3 ) , tex2D( _NoiseMap, temp_output_12_0_g3 ) , ( abs( ( temp_output_27_0_g3 - 0.5 ) ) / 0.5 ));
				float4 break10 = lerpResult9_g3;
				return break10;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord5.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord6.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord7.xyz = ase_worldBitangent;
				
				o.ase_texcoord4.xy = v.texcoord0.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.zw = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );

				#ifdef EDITOR_VISUALIZATION
					float2 VizUV = 0;
					float4 LightCoord = 0;
					UnityEditorVizData(v.vertex.xyz, v.texcoord0.xy, v.texcoord1.xy, v.texcoord2.xy, VizUV, LightCoord);
					o.VizUV = float4(VizUV, 0, 0);
					o.LightCoord = LightCoord;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord0 = v.texcoord0;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord0 = patch[0].texcoord0 * bary.x + patch[1].texcoord0 * bary.y + patch[2].texcoord0 * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN , bool ase_vface : SV_IsFrontFace ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_CardBack = IN.ase_texcoord4.xy * _CardBack_ST.xy + _CardBack_ST.zw;
				float4 tex2DNode64 = tex2D( _CardBack, uv_CardBack );
				float3 ase_worldTangent = IN.ase_texcoord5.xyz;
				float3 ase_worldNormal = IN.ase_texcoord6.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_tanViewDir =  tanToWorld0 * ase_worldViewDir.x + tanToWorld1 * ase_worldViewDir.y  + tanToWorld2 * ase_worldViewDir.z;
				ase_tanViewDir = SafeNormalize( ase_tanViewDir );
				float4 appendResult287 = (float4(ase_tanViewDir.y , ase_tanViewDir.x , 0.0 , 0.0));
				float2 uv_NormalMap = IN.ase_texcoord4.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float switchResult12 = (((ase_vface>0)?(1.0):(0.0)));
				float Face13 = switchResult12;
				float3 lerpResult183 = lerp( -UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , Face13);
				float3 Normal222 = lerpResult183;
				float4 temp_output_284_0 = reflect( -appendResult287 , float4( Normal222 , 0.0 ) );
				float luminance138 = Luminance(temp_output_284_0.xyz);
				float mulTime119 = _TimeParameters.x * -0.02;
				float3 hsvTorgb85 = HSVToRGB( float3(( ( luminance138 * 3.0 * ase_tanViewDir.z ) + mulTime119 ),1.0,3.0) );
				float3 PikaPika_Color251 = hsvTorgb85;
				float luminance299 = Luminance(tex2DNode64.rgb);
				float smoothstepResult300 = smoothstep( 0.13 , 1.39 , luminance299);
				float CardBackMask301 = smoothstepResult300;
				float2 uv_PikaPikaMap = IN.ase_texcoord4.xy * _PikaPikaMap_ST.xy + _PikaPikaMap_ST.zw;
				float luminance137 = Luminance(tex2D( _PikaPikaMap, uv_PikaPikaMap ).rgb);
				float smoothstepResult136 = smoothstep( _BackFlashHadrness , ( _BackFlashHadrness + _BackFlashwidth ) , luminance137);
				float FB_PikaPika_AddtionMask258 = smoothstepResult136;
				float3 Back_PikaPika_Addtion_Color309 = ( PikaPika_Color251 * (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 )) );
				float2 uv_Front1 = IN.ase_texcoord4.xy * _Front1_ST.xy + _Front1_ST.zw;
				float4 temp_output_77_0 = ( tex2D( _Front1, uv_Front1 ) + float4( 0,0,0,0 ) );
				float4 FMapColor234 = ( temp_output_77_0 * temp_output_77_0.a );
				float2 texCoord16 = IN.ase_texcoord4.xy * float2( 1,1 ) + float2( 0,0 );
				float2 UV57 = texCoord16;
				float2 temp_output_4_0_g4 = (( UV57 / _Size )).xy;
				float2 temp_output_17_0_g4 = float2( 0.2,0.2 );
				float mulTime22_g4 = _TimeParameters.x * 0.5;
				float temp_output_27_0_g4 = frac( mulTime22_g4 );
				float2 temp_output_11_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * temp_output_27_0_g4 ) );
				float2 temp_output_12_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * frac( ( mulTime22_g4 + 0.5 ) ) ) );
				float4 lerpResult9_g4 = lerp( tex2D( _F_FlowMap, temp_output_11_0_g4 ) , tex2D( _F_FlowMap, temp_output_12_0_g4 ) , ( abs( ( temp_output_27_0_g4 - 0.5 ) ) / 0.5 ));
				float luminance350 = Luminance(lerpResult9_g4.rgb);
				float luminance347 = Luminance(FMapColor234.rgb);
				float smoothstepResult345 = smoothstep( 0.03 , 1.67 , luminance347);
				float4 lerpResult353 = lerp( FMapColor234 , ( luminance350 * FMapColor234 * 3.0 * float4( PikaPika_Color251 , 0.0 ) ) , (( _F_Flow )?( smoothstepResult345 ):( 0.0 )));
				float FrontMap_Mask226 = ( 1.0 - temp_output_77_0.a );
				float2 appendResult70 = (float2(_SO_M.x , _SO_M.y));
				float2 appendResult71 = (float2(_SO_M.z , _SO_M.w));
				float3 UV_M58 = ( float3( (UV57*appendResult70 + appendResult71) ,  0.0 ) + ( ( _DepthMain / ase_tanViewDir.z ) * ase_tanViewDir ) );
				float4 tex2DNode24 = tex2D( _M, (UV_M58*1.0 + float3( ( sin( _TimeParameters.x ) * float2( 0,0.02 ) ) ,  0.0 )).xy );
				float4 MMapColor237 = ( tex2DNode24 * tex2DNode24.a );
				float MMap_Mask230 = ( 1.0 - tex2DNode24.a );
				float2 appendResult74 = (float2(_SO_B.x , _SO_B.y));
				float2 appendResult75 = (float2(_SO_B.z , _SO_B.w));
				float3 UV_B60 = ( ( ( _DepthBack / ase_tanViewDir.z ) * ase_tanViewDir ) + float3( (UV57*appendResult74 + appendResult75) ,  0.0 ) );
				float2 appendResult295 = (float2(_SO_B2.x , _SO_B2.y));
				float2 appendResult296 = (float2(_SO_B2.z , _SO_B2.w));
				float2 CenteredUV15_g3 = ( UV_B60.xy - float2( 0.5,0.5 ) );
				float2 break17_g3 = CenteredUV15_g3;
				float2 appendResult23_g3 = (float2(( length( CenteredUV15_g3 ) * 0.2 * 2.0 ) , ( atan2( break17_g3.x , break17_g3.y ) * ( 1.0 / TWO_PI ) * 3.0 )));
				float2 panner220 = ( 1.0 * _Time.y * float2( -0.1,0 ) + appendResult23_g3);
				float2 uv213 = panner220;
				float _Size213 = 1.0;
				sampler2D _FlowMap213 = _FlowMap;
				sampler2D _NoiseMap213 = _B;
				float2 _FlowStrength213 = float2( 0.1,0.1 );
				float _FlowSpeed213 = -0.5;
				float4 localKT_Flow213 = KT_Flow213( uv213 , _Size213 , _FlowMap213 , _NoiseMap213 , _FlowStrength213 , _FlowSpeed213 );
				float4 BMapColor245 = localKT_Flow213;
				float B_Map_Mask247 = localKT_Flow213.x;
				float temp_output_121_0 = saturate( (distance( UV_B60 , float3( 0.5,0.5,0 ) )*0.43 + 0.42) );
				float smoothstepResult122 = smoothstep( 0.0 , 0.1 , ( 1.0 - temp_output_121_0 ));
				float smoothstepResult123 = smoothstep( 0.71 , 0.78 , temp_output_121_0);
				float B_PikaPika_Mask240 = ( smoothstepResult122 * smoothstepResult123 );
				float4 lerpResult289 = lerp( tex2D( _B2, (UV_B60*float3( appendResult295 ,  0.0 ) + float3( appendResult296 ,  0.0 )).xy ) , ( BMapColor245 * B_Map_Mask247 * B_PikaPika_Mask240 ) , ( B_Map_Mask247 * B_PikaPika_Mask240 ));
				float4 F_Final_Diffuse_Color263 = ( lerpResult353 + ( FrontMap_Mask226 * ( MMapColor237 + ( MMap_Mask230 * lerpResult289 ) ) ) );
				float B_PikaPIka_Final_Mask268 = ( B_Map_Mask247 * B_PikaPika_Mask240 );
				float luminance311 = Luminance(FMapColor234.rgb);
				float smoothstepResult312 = smoothstep( 0.15 , 1.49 , luminance311);
				float F_Map_Mask313 = smoothstepResult312;
				float3 F_PikaPika_Addtion_Color274 = ( PikaPika_Color251 * (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 )) );
				float3 F_PakaPika_Final_Color273 = ( ( PikaPika_Color251 * FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) + F_PikaPika_Addtion_Color274 );
				float4 lerpResult48 = lerp( ( tex2DNode64 + float4( (( _CardBackPikaPika )?( Back_PikaPika_Addtion_Color309 ):( float3( 0,0,0 ) )) , 0.0 ) ) , ( F_Final_Diffuse_Color263 + float4( (( _FPikaPika )?( F_PakaPika_Final_Color273 ):( float3( 0,0,0 ) )) , 0.0 ) ) , Face13);
				
				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float3 BaseColor = lerpResult48.rgb;
				float3 Emission = 0;
				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = BaseColor;
				metaInput.Emission = Emission;
				#ifdef EDITOR_VISUALIZATION
					metaInput.VizUV = IN.VizUV.xy;
					metaInput.LightCoord = IN.LightCoord;
				#endif

				return UnityMetaFragment(metaInput);
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _CardBack;
			sampler2D _NormalMap;
			sampler2D _PikaPikaMap;
			sampler2D _Front1;
			sampler2D _F_FlowMap;
			sampler2D _M;
			sampler2D _B2;
			sampler2D _FlowMap;
			sampler2D _B;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float4 KT_Flow213( float2 uv, float _Size, sampler2D _FlowMap, sampler2D _NoiseMap, float2 _FlowStrength, float _FlowSpeed )
			{
				float2 uv_NoiseMap = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
				float2 temp_output_4_0_g3 = (( uv_NoiseMap / _Size )).xy;
				float2 uv_FlowMap =uv * _FlowMap_ST.xy + _FlowMap_ST.zw;
				float4 tex2DNode2 = tex2D( _FlowMap, uv_FlowMap );
				float2 temp_output_17_0_g3 = _FlowStrength;
				float mulTime22_g3 = _Time.y * _FlowSpeed;
				float temp_output_27_0_g3 = frac( mulTime22_g3 );
				float2 temp_output_11_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * temp_output_27_0_g3 ) );
				float2 temp_output_12_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * frac( ( mulTime22_g3 + 0.5 ) ) ) );
				float4 lerpResult9_g3 = lerp( tex2D( _NoiseMap, temp_output_11_0_g3 ) , tex2D( _NoiseMap, temp_output_12_0_g3 ) , ( abs( ( temp_output_27_0_g3 - 0.5 ) ) / 0.5 ));
				float4 break10 = lerpResult9_g3;
				return break10;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN , bool ase_vface : SV_IsFrontFace ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_CardBack = IN.ase_texcoord2.xy * _CardBack_ST.xy + _CardBack_ST.zw;
				float4 tex2DNode64 = tex2D( _CardBack, uv_CardBack );
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_tanViewDir =  tanToWorld0 * ase_worldViewDir.x + tanToWorld1 * ase_worldViewDir.y  + tanToWorld2 * ase_worldViewDir.z;
				ase_tanViewDir = SafeNormalize( ase_tanViewDir );
				float4 appendResult287 = (float4(ase_tanViewDir.y , ase_tanViewDir.x , 0.0 , 0.0));
				float2 uv_NormalMap = IN.ase_texcoord2.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float switchResult12 = (((ase_vface>0)?(1.0):(0.0)));
				float Face13 = switchResult12;
				float3 lerpResult183 = lerp( -UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , Face13);
				float3 Normal222 = lerpResult183;
				float4 temp_output_284_0 = reflect( -appendResult287 , float4( Normal222 , 0.0 ) );
				float luminance138 = Luminance(temp_output_284_0.xyz);
				float mulTime119 = _TimeParameters.x * -0.02;
				float3 hsvTorgb85 = HSVToRGB( float3(( ( luminance138 * 3.0 * ase_tanViewDir.z ) + mulTime119 ),1.0,3.0) );
				float3 PikaPika_Color251 = hsvTorgb85;
				float luminance299 = Luminance(tex2DNode64.rgb);
				float smoothstepResult300 = smoothstep( 0.13 , 1.39 , luminance299);
				float CardBackMask301 = smoothstepResult300;
				float2 uv_PikaPikaMap = IN.ase_texcoord2.xy * _PikaPikaMap_ST.xy + _PikaPikaMap_ST.zw;
				float luminance137 = Luminance(tex2D( _PikaPikaMap, uv_PikaPikaMap ).rgb);
				float smoothstepResult136 = smoothstep( _BackFlashHadrness , ( _BackFlashHadrness + _BackFlashwidth ) , luminance137);
				float FB_PikaPika_AddtionMask258 = smoothstepResult136;
				float3 Back_PikaPika_Addtion_Color309 = ( PikaPika_Color251 * (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 )) );
				float2 uv_Front1 = IN.ase_texcoord2.xy * _Front1_ST.xy + _Front1_ST.zw;
				float4 temp_output_77_0 = ( tex2D( _Front1, uv_Front1 ) + float4( 0,0,0,0 ) );
				float4 FMapColor234 = ( temp_output_77_0 * temp_output_77_0.a );
				float2 texCoord16 = IN.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 UV57 = texCoord16;
				float2 temp_output_4_0_g4 = (( UV57 / _Size )).xy;
				float2 temp_output_17_0_g4 = float2( 0.2,0.2 );
				float mulTime22_g4 = _TimeParameters.x * 0.5;
				float temp_output_27_0_g4 = frac( mulTime22_g4 );
				float2 temp_output_11_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * temp_output_27_0_g4 ) );
				float2 temp_output_12_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * frac( ( mulTime22_g4 + 0.5 ) ) ) );
				float4 lerpResult9_g4 = lerp( tex2D( _F_FlowMap, temp_output_11_0_g4 ) , tex2D( _F_FlowMap, temp_output_12_0_g4 ) , ( abs( ( temp_output_27_0_g4 - 0.5 ) ) / 0.5 ));
				float luminance350 = Luminance(lerpResult9_g4.rgb);
				float luminance347 = Luminance(FMapColor234.rgb);
				float smoothstepResult345 = smoothstep( 0.03 , 1.67 , luminance347);
				float4 lerpResult353 = lerp( FMapColor234 , ( luminance350 * FMapColor234 * 3.0 * float4( PikaPika_Color251 , 0.0 ) ) , (( _F_Flow )?( smoothstepResult345 ):( 0.0 )));
				float FrontMap_Mask226 = ( 1.0 - temp_output_77_0.a );
				float2 appendResult70 = (float2(_SO_M.x , _SO_M.y));
				float2 appendResult71 = (float2(_SO_M.z , _SO_M.w));
				float3 UV_M58 = ( float3( (UV57*appendResult70 + appendResult71) ,  0.0 ) + ( ( _DepthMain / ase_tanViewDir.z ) * ase_tanViewDir ) );
				float4 tex2DNode24 = tex2D( _M, (UV_M58*1.0 + float3( ( sin( _TimeParameters.x ) * float2( 0,0.02 ) ) ,  0.0 )).xy );
				float4 MMapColor237 = ( tex2DNode24 * tex2DNode24.a );
				float MMap_Mask230 = ( 1.0 - tex2DNode24.a );
				float2 appendResult74 = (float2(_SO_B.x , _SO_B.y));
				float2 appendResult75 = (float2(_SO_B.z , _SO_B.w));
				float3 UV_B60 = ( ( ( _DepthBack / ase_tanViewDir.z ) * ase_tanViewDir ) + float3( (UV57*appendResult74 + appendResult75) ,  0.0 ) );
				float2 appendResult295 = (float2(_SO_B2.x , _SO_B2.y));
				float2 appendResult296 = (float2(_SO_B2.z , _SO_B2.w));
				float2 CenteredUV15_g3 = ( UV_B60.xy - float2( 0.5,0.5 ) );
				float2 break17_g3 = CenteredUV15_g3;
				float2 appendResult23_g3 = (float2(( length( CenteredUV15_g3 ) * 0.2 * 2.0 ) , ( atan2( break17_g3.x , break17_g3.y ) * ( 1.0 / TWO_PI ) * 3.0 )));
				float2 panner220 = ( 1.0 * _Time.y * float2( -0.1,0 ) + appendResult23_g3);
				float2 uv213 = panner220;
				float _Size213 = 1.0;
				sampler2D _FlowMap213 = _FlowMap;
				sampler2D _NoiseMap213 = _B;
				float2 _FlowStrength213 = float2( 0.1,0.1 );
				float _FlowSpeed213 = -0.5;
				float4 localKT_Flow213 = KT_Flow213( uv213 , _Size213 , _FlowMap213 , _NoiseMap213 , _FlowStrength213 , _FlowSpeed213 );
				float4 BMapColor245 = localKT_Flow213;
				float B_Map_Mask247 = localKT_Flow213.x;
				float temp_output_121_0 = saturate( (distance( UV_B60 , float3( 0.5,0.5,0 ) )*0.43 + 0.42) );
				float smoothstepResult122 = smoothstep( 0.0 , 0.1 , ( 1.0 - temp_output_121_0 ));
				float smoothstepResult123 = smoothstep( 0.71 , 0.78 , temp_output_121_0);
				float B_PikaPika_Mask240 = ( smoothstepResult122 * smoothstepResult123 );
				float4 lerpResult289 = lerp( tex2D( _B2, (UV_B60*float3( appendResult295 ,  0.0 ) + float3( appendResult296 ,  0.0 )).xy ) , ( BMapColor245 * B_Map_Mask247 * B_PikaPika_Mask240 ) , ( B_Map_Mask247 * B_PikaPika_Mask240 ));
				float4 F_Final_Diffuse_Color263 = ( lerpResult353 + ( FrontMap_Mask226 * ( MMapColor237 + ( MMap_Mask230 * lerpResult289 ) ) ) );
				float B_PikaPIka_Final_Mask268 = ( B_Map_Mask247 * B_PikaPika_Mask240 );
				float luminance311 = Luminance(FMapColor234.rgb);
				float smoothstepResult312 = smoothstep( 0.15 , 1.49 , luminance311);
				float F_Map_Mask313 = smoothstepResult312;
				float3 F_PikaPika_Addtion_Color274 = ( PikaPika_Color251 * (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 )) );
				float3 F_PakaPika_Final_Color273 = ( ( PikaPika_Color251 * FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) + F_PikaPika_Addtion_Color274 );
				float4 lerpResult48 = lerp( ( tex2DNode64 + float4( (( _CardBackPikaPika )?( Back_PikaPika_Addtion_Color309 ):( float3( 0,0,0 ) )) , 0.0 ) ) , ( F_Final_Diffuse_Color263 + float4( (( _FPikaPika )?( F_PakaPika_Final_Color273 ):( float3( 0,0,0 ) )) , 0.0 ) ) , Face13);
				
				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float3 BaseColor = lerpResult48.rgb;
				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;

				half4 color = half4(BaseColor, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			Blend One Zero
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float4 worldTangent : TEXCOORD2;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD3;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD4;
				#endif
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _NormalMap;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord5.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal( v.ase_normal );
				float4 tangentWS = float4(TransformObjectToWorldDir( v.ase_tangent.xyz), v.ase_tangent.w);
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.worldNormal = normalWS;
				o.worldTangent = tangentWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag(	VertexOutput IN
						, out half4 outNormalWS : SV_Target0
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						, bool ase_vface : SV_IsFrontFace )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				float3 WorldNormal = IN.worldNormal;
				float4 WorldTangent = IN.worldTangent;

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_NormalMap = IN.ase_texcoord5.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float switchResult12 = (((ase_vface>0)?(1.0):(0.0)));
				float Face13 = switchResult12;
				float3 lerpResult183 = lerp( -UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , Face13);
				float3 Normal222 = lerpResult183;
				
				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float3 Normal = Normal222;
				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;
				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(WorldNormal);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					#if defined(_NORMALMAP)
						#if _NORMAL_DROPOFF_TS
							float crossSign = (WorldTangent.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
							float3 bitangent = crossSign * cross(WorldNormal.xyz, WorldTangent.xyz);
							float3 normalWS = TransformTangentToWorld(Normal, half3x3(WorldTangent.xyz, bitangent, WorldNormal.xyz));
						#elif _NORMAL_DROPOFF_OS
							float3 normalWS = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							float3 normalWS = Normal;
						#endif
					#else
						float3 normalWS = WorldNormal;
					#endif
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "GBuffer"
			Tags { "LightMode"="UniversalGBuffer" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma instancing_options renderinglayer
			#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_GBUFFER

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif
			
			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
				#define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_FRAG_WORLD_POSITION


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				ASE_SV_POSITION_QUALIFIERS float4 clipPos : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				float4 lightmapUVOrVertexSH : TEXCOORD1;
				half4 fogFactorAndVertexLight : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD6;
				#endif
				#if defined(DYNAMICLIGHTMAP_ON)
				float2 dynamicLightmapUV : TEXCOORD7;
				#endif
				float4 ase_texcoord8 : TEXCOORD8;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			sampler2D _CardBack;
			sampler2D _NormalMap;
			sampler2D _PikaPikaMap;
			sampler2D _Front1;
			sampler2D _F_FlowMap;
			sampler2D _M;
			sampler2D _B2;
			sampler2D _FlowMap;
			sampler2D _B;


			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float4 KT_Flow213( float2 uv, float _Size, sampler2D _FlowMap, sampler2D _NoiseMap, float2 _FlowStrength, float _FlowSpeed )
			{
				float2 uv_NoiseMap = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
				float2 temp_output_4_0_g3 = (( uv_NoiseMap / _Size )).xy;
				float2 uv_FlowMap =uv * _FlowMap_ST.xy + _FlowMap_ST.zw;
				float4 tex2DNode2 = tex2D( _FlowMap, uv_FlowMap );
				float2 temp_output_17_0_g3 = _FlowStrength;
				float mulTime22_g3 = _Time.y * _FlowSpeed;
				float temp_output_27_0_g3 = frac( mulTime22_g3 );
				float2 temp_output_11_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * temp_output_27_0_g3 ) );
				float2 temp_output_12_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * frac( ( mulTime22_g3 + 0.5 ) ) ) );
				float4 lerpResult9_g3 = lerp( tex2D( _NoiseMap, temp_output_11_0_g3 ) , tex2D( _NoiseMap, temp_output_12_0_g3 ) , ( abs( ( temp_output_27_0_g3 - 0.5 ) ) / 0.5 ));
				float4 break10 = lerpResult9_g3;
				return break10;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.ase_texcoord8.xy = v.texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				#if defined(LIGHTMAP_ON)
					OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
				#endif

				#if defined(DYNAMICLIGHTMAP_ON)
					o.dynamicLightmapUV.xy = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif

				#if !defined(LIGHTMAP_ON)
					OUTPUT_SH(normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz);
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord.xy;
					o.lightmapUVOrVertexSH.xy = v.texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );

				o.fogFactorAndVertexLight = half4(0, vertexLight);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				o.clipPosV = positionCS;
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			FragmentOutput frag ( VertexOutput IN
								#ifdef ASE_DEPTH_WRITE_ON
								,out float outputDepth : ASE_SV_DEPTH
								#endif
								, bool ase_vface : SV_IsFrontFace )
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = IN.clipPosV;
				float4 ScreenPos = ComputeScreenPos( IN.clipPosV );

				float2 NormalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#else
					ShadowCoords = float4(0, 0, 0, 0);
				#endif

				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_CardBack = IN.ase_texcoord8.xy * _CardBack_ST.xy + _CardBack_ST.zw;
				float4 tex2DNode64 = tex2D( _CardBack, uv_CardBack );
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 ase_tanViewDir =  tanToWorld0 * WorldViewDirection.x + tanToWorld1 * WorldViewDirection.y  + tanToWorld2 * WorldViewDirection.z;
				ase_tanViewDir = SafeNormalize( ase_tanViewDir );
				float4 appendResult287 = (float4(ase_tanViewDir.y , ase_tanViewDir.x , 0.0 , 0.0));
				float2 uv_NormalMap = IN.ase_texcoord8.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float switchResult12 = (((ase_vface>0)?(1.0):(0.0)));
				float Face13 = switchResult12;
				float3 lerpResult183 = lerp( -UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0 ) , Face13);
				float3 Normal222 = lerpResult183;
				float4 temp_output_284_0 = reflect( -appendResult287 , float4( Normal222 , 0.0 ) );
				float luminance138 = Luminance(temp_output_284_0.xyz);
				float mulTime119 = _TimeParameters.x * -0.02;
				float3 hsvTorgb85 = HSVToRGB( float3(( ( luminance138 * 3.0 * ase_tanViewDir.z ) + mulTime119 ),1.0,3.0) );
				float3 PikaPika_Color251 = hsvTorgb85;
				float luminance299 = Luminance(tex2DNode64.rgb);
				float smoothstepResult300 = smoothstep( 0.13 , 1.39 , luminance299);
				float CardBackMask301 = smoothstepResult300;
				float2 uv_PikaPikaMap = IN.ase_texcoord8.xy * _PikaPikaMap_ST.xy + _PikaPikaMap_ST.zw;
				float luminance137 = Luminance(tex2D( _PikaPikaMap, uv_PikaPikaMap ).rgb);
				float smoothstepResult136 = smoothstep( _BackFlashHadrness , ( _BackFlashHadrness + _BackFlashwidth ) , luminance137);
				float FB_PikaPika_AddtionMask258 = smoothstepResult136;
				float3 Back_PikaPika_Addtion_Color309 = ( PikaPika_Color251 * (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 )) );
				float2 uv_Front1 = IN.ase_texcoord8.xy * _Front1_ST.xy + _Front1_ST.zw;
				float4 temp_output_77_0 = ( tex2D( _Front1, uv_Front1 ) + float4( 0,0,0,0 ) );
				float4 FMapColor234 = ( temp_output_77_0 * temp_output_77_0.a );
				float2 texCoord16 = IN.ase_texcoord8.xy * float2( 1,1 ) + float2( 0,0 );
				float2 UV57 = texCoord16;
				float2 temp_output_4_0_g4 = (( UV57 / _Size )).xy;
				float2 temp_output_17_0_g4 = float2( 0.2,0.2 );
				float mulTime22_g4 = _TimeParameters.x * 0.5;
				float temp_output_27_0_g4 = frac( mulTime22_g4 );
				float2 temp_output_11_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * temp_output_27_0_g4 ) );
				float2 temp_output_12_0_g4 = ( temp_output_4_0_g4 + ( -(-(IN.ase_color).rg*2.0 + -1.0) * temp_output_17_0_g4 * frac( ( mulTime22_g4 + 0.5 ) ) ) );
				float4 lerpResult9_g4 = lerp( tex2D( _F_FlowMap, temp_output_11_0_g4 ) , tex2D( _F_FlowMap, temp_output_12_0_g4 ) , ( abs( ( temp_output_27_0_g4 - 0.5 ) ) / 0.5 ));
				float luminance350 = Luminance(lerpResult9_g4.rgb);
				float luminance347 = Luminance(FMapColor234.rgb);
				float smoothstepResult345 = smoothstep( 0.03 , 1.67 , luminance347);
				float4 lerpResult353 = lerp( FMapColor234 , ( luminance350 * FMapColor234 * 3.0 * float4( PikaPika_Color251 , 0.0 ) ) , (( _F_Flow )?( smoothstepResult345 ):( 0.0 )));
				float FrontMap_Mask226 = ( 1.0 - temp_output_77_0.a );
				float2 appendResult70 = (float2(_SO_M.x , _SO_M.y));
				float2 appendResult71 = (float2(_SO_M.z , _SO_M.w));
				float3 UV_M58 = ( float3( (UV57*appendResult70 + appendResult71) ,  0.0 ) + ( ( _DepthMain / ase_tanViewDir.z ) * ase_tanViewDir ) );
				float4 tex2DNode24 = tex2D( _M, (UV_M58*1.0 + float3( ( sin( _TimeParameters.x ) * float2( 0,0.02 ) ) ,  0.0 )).xy );
				float4 MMapColor237 = ( tex2DNode24 * tex2DNode24.a );
				float MMap_Mask230 = ( 1.0 - tex2DNode24.a );
				float2 appendResult74 = (float2(_SO_B.x , _SO_B.y));
				float2 appendResult75 = (float2(_SO_B.z , _SO_B.w));
				float3 UV_B60 = ( ( ( _DepthBack / ase_tanViewDir.z ) * ase_tanViewDir ) + float3( (UV57*appendResult74 + appendResult75) ,  0.0 ) );
				float2 appendResult295 = (float2(_SO_B2.x , _SO_B2.y));
				float2 appendResult296 = (float2(_SO_B2.z , _SO_B2.w));
				float2 CenteredUV15_g3 = ( UV_B60.xy - float2( 0.5,0.5 ) );
				float2 break17_g3 = CenteredUV15_g3;
				float2 appendResult23_g3 = (float2(( length( CenteredUV15_g3 ) * 0.2 * 2.0 ) , ( atan2( break17_g3.x , break17_g3.y ) * ( 1.0 / TWO_PI ) * 3.0 )));
				float2 panner220 = ( 1.0 * _Time.y * float2( -0.1,0 ) + appendResult23_g3);
				float2 uv213 = panner220;
				float _Size213 = 1.0;
				sampler2D _FlowMap213 = _FlowMap;
				sampler2D _NoiseMap213 = _B;
				float2 _FlowStrength213 = float2( 0.1,0.1 );
				float _FlowSpeed213 = -0.5;
				float4 localKT_Flow213 = KT_Flow213( uv213 , _Size213 , _FlowMap213 , _NoiseMap213 , _FlowStrength213 , _FlowSpeed213 );
				float4 BMapColor245 = localKT_Flow213;
				float B_Map_Mask247 = localKT_Flow213.x;
				float temp_output_121_0 = saturate( (distance( UV_B60 , float3( 0.5,0.5,0 ) )*0.43 + 0.42) );
				float smoothstepResult122 = smoothstep( 0.0 , 0.1 , ( 1.0 - temp_output_121_0 ));
				float smoothstepResult123 = smoothstep( 0.71 , 0.78 , temp_output_121_0);
				float B_PikaPika_Mask240 = ( smoothstepResult122 * smoothstepResult123 );
				float4 lerpResult289 = lerp( tex2D( _B2, (UV_B60*float3( appendResult295 ,  0.0 ) + float3( appendResult296 ,  0.0 )).xy ) , ( BMapColor245 * B_Map_Mask247 * B_PikaPika_Mask240 ) , ( B_Map_Mask247 * B_PikaPika_Mask240 ));
				float4 F_Final_Diffuse_Color263 = ( lerpResult353 + ( FrontMap_Mask226 * ( MMapColor237 + ( MMap_Mask230 * lerpResult289 ) ) ) );
				float B_PikaPIka_Final_Mask268 = ( B_Map_Mask247 * B_PikaPika_Mask240 );
				float luminance311 = Luminance(FMapColor234.rgb);
				float smoothstepResult312 = smoothstep( 0.15 , 1.49 , luminance311);
				float F_Map_Mask313 = smoothstepResult312;
				float3 F_PikaPika_Addtion_Color274 = ( PikaPika_Color251 * (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 )) );
				float3 F_PakaPika_Final_Color273 = ( ( PikaPika_Color251 * FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) + F_PikaPika_Addtion_Color274 );
				float4 lerpResult48 = lerp( ( tex2DNode64 + float4( (( _CardBackPikaPika )?( Back_PikaPika_Addtion_Color309 ):( float3( 0,0,0 ) )) , 0.0 ) ) , ( F_Final_Diffuse_Color263 + float4( (( _FPikaPika )?( F_PakaPika_Final_Color273 ):( float3( 0,0,0 ) )) , 0.0 ) ) , Face13);
				
				float Back_PikaPika_AddtionMask323 = (( _Back_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( CardBackMask301 ));
				float F_PikaPika_AddtionMask322 = (( _F_AddtionMask )?( FB_PikaPika_AddtionMask258 ):( F_Map_Mask313 ));
				float lerpResult180 = lerp( Back_PikaPika_AddtionMask323 , ( F_PikaPika_AddtionMask322 + ( FrontMap_Mask226 * MMap_Mask230 * B_PikaPIka_Final_Mask268 ) ) , Face13);
				
				float3 normalizeResult335 = normalize( ( WorldPosition - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				float3 BaseColor = lerpResult48.rgb;
				float3 Normal = Normal222;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = 0;
				float Smoothness = saturate( ( 0.8 * lerpResult180 ) );
				float Occlusion = 1;
				float Alpha = dotResult337;
				float AlphaClipThreshold = 0.0;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef ASE_DEPTH_WRITE_ON
					float DepthValue = IN.clipPos.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = WorldPosition;
				inputData.positionCS = IN.clipPos;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
						inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
						inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
						inputData.normalWS = Normal;
					#endif
				#else
					inputData.normalWS = WorldNormal;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				inputData.viewDirectionWS = SafeNormalize( WorldViewDirection );

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				#ifdef ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#else
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, IN.dynamicLightmapUV.xy, SH, inputData.normalWS);
					#else
						inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
					#endif
				#endif

				inputData.normalizedScreenSpaceUV = NormalizedScreenSpaceUV;
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				#if defined(DEBUG_DISPLAY)
					#if defined(DYNAMICLIGHTMAP_ON)
						inputData.dynamicLightmapUV = IN.dynamicLightmapUV.xy;
						#endif
					#if defined(LIGHTMAP_ON)
						inputData.staticLightmapUV = IN.lightmapUVOrVertexSH.xy;
					#else
						inputData.vertexSH = SH;
					#endif
				#endif

				#ifdef _DBUFFER
					ApplyDecal(IN.clipPos,
						BaseColor,
						Specular,
						inputData.normalWS,
						Metallic,
						Occlusion,
						Smoothness);
				#endif

				BRDFData brdfData;
				InitializeBRDFData
				(BaseColor, Metallic, Specular, Smoothness, Alpha, brdfData);

				Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, inputData.shadowMask);
				half4 color;
				MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, inputData.shadowMask);
				color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, Occlusion, inputData.positionWS, inputData.normalWS, inputData.viewDirectionWS);
				color.a = Alpha;

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return BRDFDataToGbuffer(brdfData, inputData, Smoothness, Emission + color.rgb, Occlusion);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define SCENESELECTIONPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				o.ase_texcoord.xyz = ase_worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 ase_worldPos = IN.ase_texcoord.xyz;
				float3 normalizeResult335 = normalize( ( ase_worldPos - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				surfaceDescription.Alpha = dotResult337;
				surfaceDescription.AlphaClipThreshold = 0.0;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#define _NORMAL_DROPOFF_TS 1
			#define ASE_FOG 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

		    #define SCENEPICKINGPASS 1

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NoiseMap_ST;
			float4 _FlowMap_ST;
			float4 _CardBack_ST;
			float4 _SO_B2;
			float4 _NormalMap_ST;
			float4 _SO_B;
			float4 _SO_M;
			float4 _PikaPikaMap_ST;
			float4 _Front1_ST;
			float3 _MaskPos;
			float3 _BaseDir;
			float _F_Flow;
			float _BackFlashHadrness;
			float _DepthMain;
			float _DepthBack;
			float _Back_AddtionMask;
			float _CardBackPikaPika;
			float _FPikaPika;
			float _F_AddtionMask;
			float _BackFlashwidth;
			float _Size;
			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			// Property used by ScenePickingPass
			#ifdef SCENEPICKINGPASS
				float4 _SelectionID;
			#endif

			// Properties used by SceneSelectionPass
			#ifdef SCENESELECTIONPASS
				int _ObjectId;
				int _PassValue;
			#endif

			

			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
			//#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/SelectionPickingPass.hlsl"

			//#ifdef HAVE_VFX_MODIFICATION
			//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
			//#endif

			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = TransformObjectToWorld( (v.vertex).xyz );
				o.ase_texcoord.xyz = ase_worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float3 ase_worldPos = IN.ase_texcoord.xyz;
				float3 normalizeResult335 = normalize( ( ase_worldPos - _MaskPos ) );
				float dotResult337 = dot( normalizeResult335 , _BaseDir );
				

				surfaceDescription.Alpha = dotResult337;
				surfaceDescription.AlphaClipThreshold = 0.0;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
						clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;

				#ifdef SCENESELECTIONPASS
					outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				#elif defined(SCENEPICKINGPASS)
					outColor = _SelectionID;
				#endif

				return outColor;
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphLitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19108
Node;AmplifyShaderEditor.CommentaryNode;288;1014.434,-1136.591;Inherit;False;2776.514;1472.937;Final;37;301;300;299;275;64;297;270;179;229;233;261;260;32;200;189;180;192;191;282;264;257;255;48;225;164;223;165;173;172;171;170;169;168;167;166;325;338;Final;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;277;647.562,-3978.824;Inherit;False;1001.702;366.8376;F_PikaPika_Addtion_Color;7;274;174;259;253;314;315;322;F_PikaPika_Addtion_Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;271;-2222.3,-590.1948;Inherit;False;894.9699;497.3458;B_PikaPIka_Final_Mask;4;241;106;249;268;B_PikaPIka_Final_Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;267;-447.1302,-528.3069;Inherit;False;1253.018;607.5868;Comment;8;273;281;276;269;228;252;232;176;F_PakaPika_Final_Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;265;-456.0316,-1137.615;Inherit;False;1285.927;532.748;FB_PikaPika_AddtionMask;7;193;137;195;197;196;136;258;FB_PikaPika_AddtionMask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;262;173.7929,-2363.87;Inherit;False;3748.225;1194.762;F_Final_Diffuse_Color;31;353;54;345;355;350;354;339;341;347;263;343;235;227;292;294;291;295;296;293;231;289;290;246;53;238;109;242;248;42;44;356;F_Final_Diffuse_Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;254;987.4337,-3181.751;Inherit;False;1802.657;638.8389;PikaPika_Color;16;87;138;284;286;285;283;118;111;85;115;251;119;104;113;112;287;PikaPika_Color;0.9336329,0,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;250;-2224.626,-1467.776;Inherit;False;1566.995;689.7039;Comment;9;219;213;218;220;117;101;245;217;247;BMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;244;-2270.619,-2326.581;Inherit;False;2117.901;670.356;B_PikaPika_Mask;9;127;126;123;122;121;120;131;243;240;B_PikaPika_Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;239;-2309.842,-2946.443;Inherit;False;1900.311;500.6093;MMap;11;59;203;207;205;209;24;208;237;46;43;230;MMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;236;-2265.324,-3621.764;Inherit;False;2192.019;688.3339;FMap;10;313;312;311;234;226;52;78;34;77;51;FMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;224;-3653.605,-980.3143;Inherit;False;1218.801;501.4;Normal;6;222;183;221;182;188;187;Normal;0.5,0.5,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;66;-3664.426,-2152.666;Inherit;False;1326.526;982.6851;UV;23;75;74;72;62;73;71;70;69;68;29;18;14;67;16;57;58;23;60;41;40;15;38;39;UV;1,1,0,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;56;-3295.701,-2417.571;Inherit;False;500.0526;184.0395;Face;2;12;13;Face;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;237;-634.3323,-2889.151;Inherit;False;MMapColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;230;-654.592,-2669.262;Inherit;False;MMap_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;-1323.383,-3543.163;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;-1770.273,-3562.195;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;34;-2215.323,-3571.765;Inherit;True;Property;_Front1;Front1;0;0;Create;True;0;0;0;False;0;False;-1;None;41c612133128815448803b0c643f4c88;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;78;-1537.103,-3419.636;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.OneMinusNode;52;-1378.81,-3284.431;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;226;-1086.905,-3212.165;Inherit;False;FrontMap_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;59;-1983.08,-2896.443;Inherit;False;58;UV_M;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;203;-1789.371,-2846.916;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SinOpNode;207;-2091.771,-2832.516;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;205;-1951.772,-2761.316;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0.01,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;209;-2143.77,-2738.116;Inherit;False;Constant;_Vector0;Vector 0;15;0;Create;True;0;0;0;False;0;False;0,0.02;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;24;-1511.524,-2862.277;Inherit;True;Property;_M;M;6;0;Create;True;0;0;0;False;0;False;-1;None;57817e50e3ef7ba418e81ff947f9702d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;208;-2259.843,-2850.479;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-993.3086,-2830.808;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;43;-1021.044,-2699.234;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;127;-1865.926,-2260.539;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0.5,0.5,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-701.1967,-2127.927;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;123;-1243.015,-1909.626;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.71;False;2;FLOAT;0.78;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;122;-1041.17,-2220.268;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;121;-1425.724,-2261.864;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;120;-1255.589,-2276.581;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;131;-1620.063,-2268.213;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.43;False;2;FLOAT;0.42;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;243;-2220.619,-2215.026;Inherit;False;60;UV_B;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;219;-1853.379,-1222.925;Inherit;True;Property;_FlowMap;FlowMap;17;0;Create;True;0;0;0;False;0;False;None;bd252a0df24f94c41b4bfbfaa9c36284;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.CustomExpressionNode;213;-1521.616,-1381.176;Inherit;False;float2 uv_NoiseMap = uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw@$float2 temp_output_4_0_g3 = (( uv_NoiseMap / _Size )).xy@$float2 uv_FlowMap =uv * _FlowMap_ST.xy + _FlowMap_ST.zw@$float4 tex2DNode2 = tex2D( _FlowMap, uv_FlowMap )@$float2 temp_output_17_0_g3 = _FlowStrength@$float mulTime22_g3 = _Time.y * _FlowSpeed@$float temp_output_27_0_g3 = frac( mulTime22_g3 )@$float2 temp_output_11_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * temp_output_27_0_g3 ) )@$float2 temp_output_12_0_g3 = ( temp_output_4_0_g3 + ( -(tex2DNode2.rg*2.0 + -1.0) * temp_output_17_0_g3 * frac( ( mulTime22_g3 + 0.5 ) ) ) )@$float4 lerpResult9_g3 = lerp( tex2D( _NoiseMap, temp_output_11_0_g3 ) , tex2D( _NoiseMap, temp_output_12_0_g3 ) , ( abs( ( temp_output_27_0_g3 - 0.5 ) ) / 0.5 ))@$float4 break10 = lerpResult9_g3@$return break10@;4;Create;6;True;uv;FLOAT2;0,0;In;;Inherit;False;True;_Size;FLOAT;1;In;;Inherit;False;True;_FlowMap;SAMPLER2D;;In;;Inherit;False;True;_NoiseMap;SAMPLER2D;;In;;Inherit;False;True;_FlowStrength;FLOAT2;0.1,0.1;In;;Inherit;False;True;_FlowSpeed;FLOAT;-0.5;In;;Inherit;False;KT_Flow;True;False;0;;False;6;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;SAMPLER2D;;False;3;SAMPLER2D;;False;4;FLOAT2;0.1,0.1;False;5;FLOAT;-0.5;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexturePropertyNode;218;-1888.791,-1008.073;Inherit;True;Property;_B;B;13;0;Create;True;0;0;0;False;0;False;None;0de92893c6d716c418c33e20955bb0d7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.PannerNode;220;-1737.821,-1384.979;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;-0.1,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;117;-1984.492,-1382.691;Inherit;False;Polar Coordinates;-1;;3;7dab8e02884cf104ebefaa2e788e4162;0;4;1;FLOAT2;0,0;False;2;FLOAT2;0.5,0.5;False;3;FLOAT;0.2;False;4;FLOAT;3;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-2174.626,-1388.319;Inherit;False;60;UV_B;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;217;-1133.226,-1256.165;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;112;1225.667,-2758.074;Inherit;False;Constant;_Float4;Float 4;11;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;113;1398.429,-2725.412;Inherit;False;FLOAT4;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DistanceOpNode;104;1577.617,-2853.121;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,-0.6,1,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;119;1824.186,-2858.774;Inherit;False;1;0;FLOAT;-0.02;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;1544.593,-1913.87;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;1336.593,-1865.87;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;248;840.5929,-1577.87;Inherit;False;247;B_Map_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;242;824.5929,-1497.87;Inherit;False;240;B_PikaPika_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;109;1160.593,-1641.87;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;1224.593,-2137.869;Inherit;True;237;MMapColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;1768.593,-1945.87;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;193;-406.0316,-1087.615;Inherit;True;Property;_PikaPikaMap; PikaPika Map;12;0;Create;True;0;0;0;False;0;False;-1;2c77856d9a860174ca7dc15b87e3bc98;30945aadf8e80bb439d488eff7243c67;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LuminanceNode;137;-60.5955,-1071.372;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;195;-371.7737,-845.4107;Inherit;False;Property;_BackFlashHadrness;Back Flash Hadrness;7;0;Create;True;0;0;0;False;0;False;0.17;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;197;-356.116,-726.7177;Inherit;False;Property;_BackFlashwidth;Back Flash width;8;0;Create;True;0;0;0;False;0;False;0.21;0.79;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;-15.84576,-738.6673;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;136;246.4545,-957.1585;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;176;93.9963,-418.9476;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;232;-395.0013,-209.3918;Inherit;True;230;MMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;252;-397.13,-478.3069;Inherit;False;251;PikaPika_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;228;-395.3909,-404.9781;Inherit;True;226;FrontMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;269;-146.4133,-109.7407;Inherit;False;268;B_PikaPIka_Final_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;241;-2171.509,-322.8491;Inherit;True;240;B_PikaPika_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-1853.719,-372.19;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;249;-2172.3,-540.1948;Inherit;True;247;B_Map_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;268;-1596.13,-370.0456;Inherit;False;B_PikaPIka_Final_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;281;378.7572,-377.6584;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;273;541.4969,-369.2259;Inherit;False;F_PakaPika_Final_Color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;276;111.0456,-246.1766;Inherit;False;274;F_PikaPika_Addtion_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;1821.878,-3020.589;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;3;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;85;2283.776,-3042.508;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;3;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector2Node;111;1162.086,-2717.113;Inherit;False;Property;_View_Color_Offset;View_Color_Offset;9;0;Create;True;0;0;0;False;0;False;0,0;-0.08,-0.11;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;118;2102.404,-3017.485;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;283;1174.993,-3116.969;Inherit;False;60;UV_B;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;286;1205.312,-2905.315;Inherit;False;222;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ReflectOpNode;284;1392.512,-2970.914;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LuminanceNode;138;1652.372,-3034.316;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;87;1021.433,-2977.666;Inherit;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;287;1192.512,-3068.515;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.NegateNode;285;1306.912,-3016.514;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SwitchByFaceNode;12;-3245.701,-2367.331;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;13;-3020.448,-2367.571;Inherit;False;Face;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-3455.441,-1561.657;Inherit;False;Property;_DepthBack;DepthBack;11;0;Create;True;0;0;0;False;0;False;0;-0.97;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;38;-3189.208,-1520.041;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;-3469.927,-1968.42;Inherit;False;Property;_DepthMain;DepthMain;4;0;Create;True;0;0;0;False;0;False;0;-0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;-3030.512,-1653.418;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;41;-2770.847,-1638.237;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;60;-2577.845,-1628.895;Inherit;False;UV_B;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;23;-2768.653,-1896.157;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;-2562.698,-1863.027;Inherit;False;UV_M;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;57;-3082.581,-2101.967;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;16;-3474.732,-2110.013;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;67;-3277.818,-2127.95;Inherit;False;57;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;14;-3537.841,-1829.434;Inherit;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;18;-3220.889,-1817.234;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-3018.768,-1761.086;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;68;-2929.02,-2039.149;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;69;-3319.501,-2041.805;Inherit;False;Property;_SO_M;SO_M;5;0;Create;True;0;0;0;False;0;False;1,1,0,0;0.8,1.16,0.12,-0.08;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;70;-3111.501,-1993.805;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;71;-3104.751,-1902.5;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;73;-3443.775,-1446.031;Inherit;False;Property;_SO_B;SO_B;10;0;Create;True;0;0;0;False;0;False;1,1,0,0;0.81,1.81,-0.02,-0.52;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;62;-3036.095,-1534.741;Inherit;False;57;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;72;-2821.94,-1464.518;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;74;-3112.581,-1430.169;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;75;-3104.76,-1339.936;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;222;-2659.605,-642.3143;Inherit;False;Normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;183;-2851.605,-674.3143;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;221;-3059.605,-594.3145;Inherit;False;13;Face;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;182;-2995.605,-802.3142;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;188;-3235.605,-770.3142;Inherit;False;Tangent;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;187;-3603.605,-930.3143;Inherit;True;Property;_NormalMap;NormalMap;18;1;[HideInInspector];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;215;-3638.002,-2631.735;Inherit;False;Property;_NoiseMap_ST;_NoiseMap_ST;16;0;Create;True;0;0;0;True;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;216;-3625.386,-2434.332;Inherit;False;Property;_FlowMap_ST;_FlowMap_ST;15;0;Create;True;0;0;0;True;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;166;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;167;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;True;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;168;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;169;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;170;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthNormals;0;6;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormals;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;171;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;GBuffer;0;7;GBuffer;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalGBuffer;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;172;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;SceneSelectionPass;0;8;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;173;2652.988,-232.039;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ScenePickingPass;0;9;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;223;2545.156,-338.957;Inherit;False;222;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;164;2229.127,-469.9629;Float;False;False;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.GetLocalVarNode;225;2018.07,-335.2956;Inherit;False;13;Face;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;48;2491.642,-512.9416;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;255;2135.332,-899.0685;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;257;2243.667,-517.55;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;264;1922.075,-731.8489;Inherit;False;263;F_Final_Diffuse_Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;2395.955,-96.83807;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;192;2587.85,-73.64204;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;180;2176.303,-24.28499;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;189;2167.588,-116.9527;Inherit;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;0;False;0;False;0.8;0.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;200;1831.794,-91.73064;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;32;1822.805,94.38403;Inherit;False;13;Face;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;233;1064.434,-180.394;Inherit;True;230;MMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;229;1068.93,-395.7042;Inherit;True;226;FrontMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;1456.144,-48.61208;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;270;1091.308,63.19918;Inherit;False;268;B_PikaPIka_Final_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;247;-882.4312,-1225.377;Inherit;False;B_Map_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;245;-1156.992,-1417.776;Inherit;False;BMapColor;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;246;840.5929,-1657.87;Inherit;False;245;BMapColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;290;1145.563,-1443.764;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;289;1453.788,-1641.142;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;825.3928,-2139.47;Inherit;True;230;MMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;293;717.5628,-1844.564;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;1,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;296;578.3629,-1578.964;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;295;543.9628,-1765.364;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;291;939.1631,-1865.364;Inherit;True;Property;_B2;B2;19;0;Create;True;0;0;0;False;0;False;-1;None;81facf35a6ffe254ea2be630879de0d4;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;294;312.7628,-1697.364;Inherit;False;Property;_SO_B2;SO_B2;20;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.61,0.29,0.26,0.39;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;292;511.1628,-1880.565;Inherit;False;60;UV_B;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;64;1172.569,-1108.99;Inherit;True;Property;_CardBack;Card Back;14;0;Create;True;0;0;0;False;0;False;-1;2c77856d9a860174ca7dc15b87e3bc98;81da8bfd035b3424ab342fa7726d40b8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;306;1796.124,-3885.611;Inherit;False;1023.302;556.4374;B_PikaPika_Addtion_Color;7;302;298;308;307;310;309;323;B_PikaPika_Addtion_Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;274;1350.864,-3914.926;Inherit;False;F_PikaPika_Addtion_Color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;174;1126.956,-3916.586;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;307;1839.104,-3845.366;Inherit;False;251;PikaPika_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;302;1835.398,-3738.072;Inherit;False;301;CardBackMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;310;2280.959,-3827.53;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;275;1210.792,-648.8258;Inherit;False;309;Back_PikaPika_Addtion_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LuminanceNode;299;1807.959,-1092.028;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;301;2413.688,-1051.137;Inherit;False;CardBackMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;234;-1080.089,-3538.686;Inherit;True;FMapColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LuminanceNode;311;-818.0581,-3426.89;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;308;1813.965,-3583.677;Inherit;False;258;FB_PikaPika_AddtionMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;313;-326.8579,-3272.49;Inherit;True;F_Map_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;312;-609.2581,-3331.689;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.15;False;2;FLOAT;1.49;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;260;1567.319,-284.9301;Inherit;False;323;Back_PikaPika_AddtionMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;253;718.701,-3939.225;Inherit;False;251;PikaPika_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;314;683.0892,-3851.831;Inherit;False;313;F_Map_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;315;923.0894,-3847.831;Inherit;False;Property;_F_AddtionMask;F_AddtionMask?;24;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;259;653.5619,-3743.133;Inherit;False;258;FB_PikaPika_AddtionMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;240;-390.3187,-2075.265;Inherit;False;B_PikaPika_Mask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;298;2055.303,-3737.087;Inherit;False;Property;_Back_AddtionMask;Back_AddtionMask?;23;0;Create;True;0;0;0;False;0;False;0;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;309;2532.867,-3813.069;Inherit;False;Back_PikaPika_Addtion_Color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;258;543.3565,-912.7554;Inherit;False;FB_PikaPika_AddtionMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;323;2359.017,-3522.763;Inherit;False;Back_PikaPika_AddtionMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;261;1463.621,-152.7749;Inherit;False;322;F_PikaPika_AddtionMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;165;3140.198,-379.4516;Float;False;True;-1;2;UnityEditor.ShaderGraphLitGUI;0;12;视差;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;20;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Lit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;;0;0;Standard;41;Workflow;1;638438352686692409;Surface;0;0;  Refraction Model;0;0;  Blend;0;0;Two Sided;0;638437864506495097;Fragment Normal Space,InvertActionOnDeselection;0;0;Forward Only;0;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;_FinalColorxAlpha;0;0;Meta Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;DOTS Instancing;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position,InvertActionOnDeselection;1;0;Debug Display;0;0;Clear Coat;0;0;0;10;False;True;True;True;True;True;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.RangedFloatNode;325;3004.427,62.00103;Inherit;False;Constant;_Float1;Float 1;22;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;319;1370.425,518.251;Inherit;False;Property;_Dissolve_Amount;Dissolve_Amount;25;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;334;1599.232,660.9874;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;335;1811.392,662.0275;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;336;1264.352,1002.108;Inherit;False;Property;_BaseDir;BaseDir;27;0;Create;True;0;0;0;False;0;False;0,0,0;0,1,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;316;2069.13,1277.098;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RelayNode;317;2384.968,1367.566;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;330;2078.672,1100.907;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RelayNode;331;2413.553,1115.467;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;337;2041.231,780.5872;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;329;2244.342,903.0837;Inherit;False;3;0;FLOAT;-1.1;False;1;FLOAT;1.1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;318;2670.968,689.7633;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;333;1280.032,648.9873;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;332;1282.033,799.3071;Inherit;False;Property;_MaskPos;MaskPos;26;0;Create;True;0;0;0;False;0;False;0,0,0;0,-1,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;282;1609.574,-550.44;Inherit;False;273;F_PakaPika_Final_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;297;1864.551,-861.5677;Inherit;False;Property;_CardBackPikaPika;Card Back PikaPika?;21;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;338;1908.816,-509.5237;Inherit;False;Property;_FPikaPika;F PikaPika?;22;0;Create;True;0;0;0;False;0;False;1;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;300;2105.559,-1104.029;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.13;False;2;FLOAT;1.39;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;227;1530.993,-2127.469;Inherit;True;226;FrontMap_Mask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;235;1534.193,-2318.67;Inherit;True;234;FMapColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LuminanceNode;342;584.1547,-2801.019;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;343;1032.955,-2313.02;Inherit;False;57;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;341;1192.002,-2319.743;Inherit;True;Property;_F_FlowMap;F_FlowMap;29;0;Create;True;0;0;0;False;0;False;None;bd252a0df24f94c41b4bfbfaa9c36284;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;355;2020.729,-1965.685;Inherit;False;Constant;_Float5;Float 5;27;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;263;3228.115,-1879.62;Inherit;False;F_Final_Diffuse_Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;3047.49,-1930.664;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LuminanceNode;347;1825.794,-2263.419;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;356;2704.867,-2071.706;Inherit;False;Property;_F_Flow;F_Flow?;28;0;Create;True;0;0;0;False;0;False;0;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;353;2914.988,-2223.234;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;354;2153.999,-2036.291;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LuminanceNode;350;2009.822,-2137.984;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;357;2060.067,-1781.306;Inherit;False;251;PikaPika_Color;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;322;1131.017,-3692.364;Inherit;False;F_PikaPika_AddtionMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;2564.49,-3132.551;Inherit;False;PikaPika_Color;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;339;1698.6,-2156.095;Inherit;False;Flow;1;;4;acad10cc8145e1f4eb8042bebe2d9a42;2,50,0,51,0;6;5;SAMPLER2D;;False;2;FLOAT2;0,0;False;55;FLOAT;1;False;18;FLOAT2;0,0;False;17;FLOAT2;0.2,0.2;False;24;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;345;2300.235,-2174.848;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0.03;False;2;FLOAT;1.67;False;1;FLOAT;0
WireConnection;237;0;46;0
WireConnection;230;0;43;0
WireConnection;51;0;77;0
WireConnection;51;1;78;3
WireConnection;77;0;34;0
WireConnection;78;0;77;0
WireConnection;52;0;78;3
WireConnection;226;0;52;0
WireConnection;203;0;59;0
WireConnection;203;2;205;0
WireConnection;207;0;208;0
WireConnection;205;0;207;0
WireConnection;205;1;209;0
WireConnection;24;1;203;0
WireConnection;46;0;24;0
WireConnection;46;1;24;4
WireConnection;43;0;24;4
WireConnection;127;0;243;0
WireConnection;126;0;122;0
WireConnection;126;1;123;0
WireConnection;123;0;121;0
WireConnection;122;0;120;0
WireConnection;121;0;131;0
WireConnection;120;0;121;0
WireConnection;131;0;127;0
WireConnection;213;0;220;0
WireConnection;213;2;219;0
WireConnection;213;3;218;0
WireConnection;220;0;117;0
WireConnection;117;1;101;0
WireConnection;217;0;213;0
WireConnection;113;0;111;0
WireConnection;113;2;112;0
WireConnection;104;0;284;0
WireConnection;104;1;113;0
WireConnection;44;0;238;0
WireConnection;44;1;42;0
WireConnection;42;0;231;0
WireConnection;42;1;289;0
WireConnection;109;0;246;0
WireConnection;109;1;248;0
WireConnection;109;2;242;0
WireConnection;53;0;227;0
WireConnection;53;1;44;0
WireConnection;137;0;193;0
WireConnection;196;0;195;0
WireConnection;196;1;197;0
WireConnection;136;0;137;0
WireConnection;136;1;195;0
WireConnection;136;2;196;0
WireConnection;176;0;252;0
WireConnection;176;1;228;0
WireConnection;176;2;232;0
WireConnection;176;3;269;0
WireConnection;106;0;249;0
WireConnection;106;1;241;0
WireConnection;268;0;106;0
WireConnection;281;0;176;0
WireConnection;281;1;276;0
WireConnection;273;0;281;0
WireConnection;115;0;138;0
WireConnection;115;2;87;3
WireConnection;85;0;118;0
WireConnection;118;0;115;0
WireConnection;118;1;119;0
WireConnection;284;0;285;0
WireConnection;284;1;286;0
WireConnection;138;0;284;0
WireConnection;287;0;87;2
WireConnection;287;1;87;1
WireConnection;285;0;287;0
WireConnection;13;0;12;0
WireConnection;38;0;39;0
WireConnection;38;1;14;3
WireConnection;40;0;38;0
WireConnection;40;1;14;0
WireConnection;41;0;40;0
WireConnection;41;1;72;0
WireConnection;60;0;41;0
WireConnection;23;0;68;0
WireConnection;23;1;29;0
WireConnection;58;0;23;0
WireConnection;57;0;16;0
WireConnection;18;0;15;0
WireConnection;18;1;14;3
WireConnection;29;0;18;0
WireConnection;29;1;14;0
WireConnection;68;0;67;0
WireConnection;68;1;70;0
WireConnection;68;2;71;0
WireConnection;70;0;69;1
WireConnection;70;1;69;2
WireConnection;71;0;69;3
WireConnection;71;1;69;4
WireConnection;72;0;62;0
WireConnection;72;1;74;0
WireConnection;72;2;75;0
WireConnection;74;0;73;1
WireConnection;74;1;73;2
WireConnection;75;0;73;3
WireConnection;75;1;73;4
WireConnection;222;0;183;0
WireConnection;183;0;182;0
WireConnection;183;1;188;0
WireConnection;183;2;221;0
WireConnection;182;0;188;0
WireConnection;188;0;187;0
WireConnection;48;0;255;0
WireConnection;48;1;257;0
WireConnection;48;2;225;0
WireConnection;255;0;64;0
WireConnection;255;1;297;0
WireConnection;257;0;264;0
WireConnection;257;1;338;0
WireConnection;191;0;189;0
WireConnection;191;1;180;0
WireConnection;192;0;191;0
WireConnection;180;0;260;0
WireConnection;180;1;200;0
WireConnection;180;2;32;0
WireConnection;200;0;261;0
WireConnection;200;1;179;0
WireConnection;179;0;229;0
WireConnection;179;1;233;0
WireConnection;179;2;270;0
WireConnection;247;0;217;0
WireConnection;245;0;213;0
WireConnection;290;0;248;0
WireConnection;290;1;242;0
WireConnection;289;0;291;0
WireConnection;289;1;109;0
WireConnection;289;2;290;0
WireConnection;293;0;292;0
WireConnection;293;1;295;0
WireConnection;293;2;296;0
WireConnection;296;0;294;3
WireConnection;296;1;294;4
WireConnection;295;0;294;1
WireConnection;295;1;294;2
WireConnection;291;1;293;0
WireConnection;274;0;174;0
WireConnection;174;0;253;0
WireConnection;174;1;315;0
WireConnection;310;0;307;0
WireConnection;310;1;298;0
WireConnection;299;0;64;0
WireConnection;301;0;300;0
WireConnection;234;0;51;0
WireConnection;311;0;234;0
WireConnection;313;0;312;0
WireConnection;312;0;311;0
WireConnection;315;0;314;0
WireConnection;315;1;259;0
WireConnection;240;0;126;0
WireConnection;298;0;302;0
WireConnection;298;1;308;0
WireConnection;309;0;310;0
WireConnection;258;0;136;0
WireConnection;323;0;298;0
WireConnection;165;0;48;0
WireConnection;165;1;223;0
WireConnection;165;4;192;0
WireConnection;165;6;337;0
WireConnection;165;7;325;0
WireConnection;334;0;333;0
WireConnection;334;1;332;0
WireConnection;335;0;334;0
WireConnection;317;0;316;2
WireConnection;331;0;330;2
WireConnection;337;0;335;0
WireConnection;337;1;336;0
WireConnection;318;0;329;0
WireConnection;318;1;331;0
WireConnection;297;1;275;0
WireConnection;338;1;282;0
WireConnection;300;0;299;0
WireConnection;263;0;54;0
WireConnection;54;0;353;0
WireConnection;54;1;53;0
WireConnection;347;0;235;0
WireConnection;356;1;345;0
WireConnection;353;0;235;0
WireConnection;353;1;354;0
WireConnection;353;2;356;0
WireConnection;354;0;350;0
WireConnection;354;1;235;0
WireConnection;354;2;355;0
WireConnection;354;3;357;0
WireConnection;350;0;339;0
WireConnection;322;0;315;0
WireConnection;251;0;85;0
WireConnection;339;5;341;0
WireConnection;339;2;343;0
WireConnection;345;0;347;0
ASEEND*/
//CHKSM=E1529FC8A792FC848FA7EBCF9F462A01897C64EE