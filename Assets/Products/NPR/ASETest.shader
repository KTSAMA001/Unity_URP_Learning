// Made with Amplify Shader Editor v1.9.1.8
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "KTSAMA/SDF_Unlit"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_DepthMaskTexScale("DepthMaskTexScale", Float) = 0.9
		_DepthOffset("_DepthOffset", Vector) = (0,0,0,0)
		_Color_DepthMask1("Color_DepthMask1", Color) = (0,0,0,1)
		_Color_DepthMask2("Color_DepthMask2", Color) = (1,1,1,1)
		_SDFColor("SDFColor", Color) = (0,0,0,0)
		_BaseColor("BaseColor", Color) = (1,1,1,0)
		_BaseMapScaleOffset("BaseMapScaleOffset", Vector) = (1,1,0,0)
		[NoScaleOffset]_BaseMap("BaseMap", 2D) = "white" {}
		_TVScale("TV Scale", Float) = 1
		_UVRotate("UVRotate", Float) = 30
		_UVScale("UVScale", Float) = 10
		_Speed("Speed", Float) = 1
		_Sdf_Box1_Size("Sdf_Box1_Size", Vector) = (0.38,0.16,0,0)
		_Sdf_sdRoundedX1_Size("Sdf_sdRoundedX1_Size", Vector) = (0.38,0.16,0,0)
		_RotateSpeedScale("RotateSpeedScale", Float) = 0.5
		_LeftEyeRotate("LeftEyeRotate", Float) = 60
		_RightEyeRotate("RightEyeRotate", Float) = -60
		_LeftEyeOffsetSize("LeftEyeOffsetSize", Vector) = (0.1,-0.05,0.06,0.015)
		_MouseOffset("MouseOffset", Vector) = (0.1,-0.05,0.06,0.015)
		_RightEyeOffsetSize("RightEyeOffsetSize", Vector) = (-0.1,-0.05,0.06,0.015)
		_Tex1Color("Tex1Color", Color) = (1,1,1,1)
		_Tex1ScaleOffset("Tex1ScaleOffset", Vector) = (1,1,0,0)
		[NoScaleOffset]_Tex1("Tex1", 2D) = "white" {}
		_Tex2Color("Tex2Color", Color) = (1,1,1,1)
		_Tex2ScaleOffset("Tex2ScaleOffset", Vector) = (1,1,0,0)
		[NoScaleOffset]_Tex2("Tex2", 2D) = "white" {}
		_MapCount("MapCount", Vector) = (0.3,0.2,0,0)
		[ASEEnd]_RandomSeed("RandomSeed", Float) = 1


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Unlit" }

		Cull Front
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
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0,0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma instancing_options renderinglayer

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        	#pragma multi_compile_fragment _ DEBUG_DISPLAY
        	#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
        	#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _BaseMap;
			sampler2D _DepthMaskColor;
			sampler2D _Tex1;
			sampler2D _Tex2;


			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			
			float4 PosCS2PosNDC23( float4 posCS )
			{
				 float4 ndc = posCS * 0.5f;
				 float4 positionNDC=0;
				positionNDC .xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
				positionNDC.zw = posCS.zw;
				return positionNDC;
			}
			
			float sdBox_Call( float2 p, float2 b )
			{
				return sdBox(p,b);
			}
			
			float sdRoundedX_Call( float2 p, float w, float r )
			{
				return sdRoundedX(p,w,r);
			}
			
			float sdArc_Call1( float2 p1, float2 p2, float r1, float r2 )
			{
				return sdArc(p1,p2,r1,r2);
			}
			
			float sdArc_Call2( float2 p1, float2 p2, float r1, float r2 )
			{
				return sdArc(p1,p2,r1,r2);
			}
			

			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord3 = screenPos;
				
				o.ase_texcoord4 = v.vertex;

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

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

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

			half4 frag ( VertexOutput IN
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
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

				float4 screenPos = IN.ase_texcoord3;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 appendResult421 = (float2(ase_grabScreenPosNorm.r , ase_grabScreenPosNorm.g));
				float2 temp_cast_0 = (0.5).xx;
				float2 break431 = ( appendResult421 - temp_cast_0 );
				float2 appendResult432 = (float2(( break431.x * ( _ScreenParams.x / _ScreenParams.y ) ) , break431.y));
				float cos435 = cos( radians( _UVRotate ) );
				float sin435 = sin( radians( _UVRotate ) );
				float2 rotator435 = mul( appendResult432 - float2( 0,0 ) , float2x2( cos435 , -sin435 , sin435 , cos435 )) + float2( 0,0 );
				float2 ScreenPos_Normalize433 = rotator435;
				float2 appendResult440 = (float2(_BaseMapScaleOffset.x , _BaseMapScaleOffset.y));
				float2 appendResult441 = (float2(_BaseMapScaleOffset.z , _BaseMapScaleOffset.w));
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float4 unityObjectToClipPos26 = TransformWorldToHClip(TransformObjectToWorld(IN.ase_texcoord4.xyz));
				float4 posCS23 = unityObjectToClipPos26;
				float4 localPosCS2PosNDC23 = PosCS2PosNDC23( posCS23 );
				float posNDCw27 = localPosCS2PosNDC23.w;
				float4 tex2DNode17 = tex2D( _DepthMaskColor, ( ( ( ase_screenPosNorm * _DepthMaskTexScale ) + ( ( 1.0 - _DepthMaskTexScale ) / 2.0 ) ) + float4( ( ( _DepthOffset / float2( 1920,1080 ) ) / posNDCw27 ), 0.0 , 0.0 ) ).xy );
				float DepthMask44 = tex2DNode17.r;
				float4 lerpResult58 = lerp( _Color_DepthMask1 , _Color_DepthMask2 , DepthMask44);
				float4 DepthMask_Color47 = lerpResult58;
				float UVScale98 = _UVScale;
				float2 temp_cast_3 = (( floor( ( ScreenPos_Normalize433 * UVScale98 ) ) / UVScale98 ).y).xx;
				float2 temp_cast_4 = (_RandomSeed).xx;
				float2 temp_output_16_0_g4 = temp_cast_4;
				float2 temp_output_19_0_g4 = ( ( ( temp_cast_3 + float2( 114,514 ) + temp_output_16_0_g4 ) * temp_output_16_0_g4 ) - temp_output_16_0_g4 );
				float2 break7_g4 = temp_output_19_0_g4;
				float lerpResult5_g4 = lerp( 0.0 , 1.0 , frac( ( sin( break7_g4.x ) * 114.0 * cos( break7_g4.y ) ) ));
				float2 break13_g4 = temp_output_19_0_g4;
				float lerpResult12_g4 = lerp( 0.0 , 1.0 , frac( ( sin( break13_g4.y ) * 514.0 * cos( break13_g4.x ) ) ));
				float2 appendResult14_g4 = (float2(lerpResult5_g4 , lerpResult12_g4));
				float2 appendResult468 = (float2((frac( appendResult14_g4 )*2.0 + -1.0).x , 0.0));
				float2 temp_output_81_0 = ( _Speed * appendResult468 );
				float2 SdfUV89 = (ScreenPos_Normalize433*UVScale98 + temp_output_81_0);
				float2 temp_output_61_0 = frac( SdfUV89 );
				float2 temp_output_78_0 = ( floor( SdfUV89 ) / UVScale98 );
				float2 temp_cast_5 = (_RandomSeed).xx;
				float2 temp_output_16_0_g3 = temp_cast_5;
				float2 temp_output_19_0_g3 = ( ( ( temp_output_78_0 + float2( 114,514 ) + temp_output_16_0_g3 ) * temp_output_16_0_g3 ) - temp_output_16_0_g3 );
				float2 break7_g3 = temp_output_19_0_g3;
				float lerpResult5_g3 = lerp( 0.0 , 1.0 , frac( ( sin( break7_g3.x ) * 114.0 * cos( break7_g3.y ) ) ));
				float2 break13_g3 = temp_output_19_0_g3;
				float lerpResult12_g3 = lerp( 0.0 , 1.0 , frac( ( sin( break13_g3.y ) * 514.0 * cos( break13_g3.x ) ) ));
				float2 appendResult14_g3 = (float2(lerpResult5_g3 , lerpResult12_g3));
				float2 temp_output_131_0 = saturate( appendResult14_g3 );
				float2 SdfUVGrid_Noise92 = temp_output_131_0;
				float2 break204 = ( temp_output_61_0 + float2( -0.5,-0.5 ) + (float2( -0.1,-0.1 ) + (SdfUVGrid_Noise92 - float2( 0,0 )) * (float2( 0.1,0.1 ) - float2( -0.1,-0.1 )) / (float2( 1,1 ) - float2( 0,0 ))) );
				float2 appendResult205 = (float2(break204.x , break204.y));
				float mulTime80 = _TimeParameters.x * (max( SdfUVGrid_Noise92 , float2( 0.1,0.1 ) )*2.0 + -1.0).x;
				float cos10 = cos( ( mulTime80 * _RotateSpeedScale ) );
				float sin10 = sin( ( mulTime80 * _RotateSpeedScale ) );
				float2 rotator10 = mul( appendResult205 - float2( 0,0 ) , float2x2( cos10 , -sin10 , sin10 , cos10 )) + float2( 0,0 );
				float2 RotateUV232 = ( float2( 0,0 ) + rotator10 );
				float2 TV_UV380 = ( ( RotateUV232 * _TVScale ) + float2( 0,0 ) );
				float4 _Vector2 = float4(0,0,0.22,0.17);
				float2 appendResult224 = (float2(_Vector2.x , _Vector2.y));
				float2 p219 = ( TV_UV380 + appendResult224 );
				float2 appendResult222 = (float2(_Vector2.z , _Vector2.w));
				float2 b219 = appendResult222;
				float localsdBox_Call219 = sdBox_Call( p219 , b219 );
				float2 appendResult195 = (float2(_Sdf_Box1_Size.z , _Sdf_Box1_Size.w));
				float2 p40 = ( TV_UV380 + appendResult195 );
				float2 appendResult194 = (float2(_Sdf_Box1_Size.x , _Sdf_Box1_Size.y));
				float2 b40 = appendResult194;
				float localsdBox_Call40 = sdBox_Call( p40 , b40 );
				float2 appendResult199 = (float2(_Sdf_sdRoundedX1_Size.z , _Sdf_sdRoundedX1_Size.w));
				float2 p182 = ( TV_UV380 + appendResult199 );
				float2 appendResult198 = (float2(_Sdf_sdRoundedX1_Size.x , _Sdf_sdRoundedX1_Size.y));
				float2 break183 = appendResult198;
				float w182 = break183.x;
				float r182 = break183.y;
				float localsdRoundedX_Call182 = sdRoundedX_Call( p182 , w182 , r182 );
				float2 appendResult244 = (float2(_LeftEyeOffsetSize.x , _LeftEyeOffsetSize.y));
				float cos255 = cos( _LeftEyeRotate );
				float sin255 = sin( _LeftEyeRotate );
				float2 rotator255 = mul( ( TV_UV380 + appendResult244 ) - float2( 0,0 ) , float2x2( cos255 , -sin255 , sin255 , cos255 )) + float2( 0,0 );
				float2 p246 = rotator255;
				float2 appendResult242 = (float2(_LeftEyeOffsetSize.z , _LeftEyeOffsetSize.w));
				float2 b246 = appendResult242;
				float localsdBox_Call246 = sdBox_Call( p246 , b246 );
				float2 appendResult264 = (float2(_RightEyeOffsetSize.x , _RightEyeOffsetSize.y));
				float cos262 = cos( _RightEyeRotate );
				float sin262 = sin( _RightEyeRotate );
				float2 rotator262 = mul( ( TV_UV380 + appendResult264 ) - float2( 0,0 ) , float2x2( cos262 , -sin262 , sin262 , cos262 )) + float2( 0,0 );
				float2 p261 = rotator262;
				float2 appendResult258 = (float2(_RightEyeOffsetSize.z , _RightEyeOffsetSize.w));
				float2 b261 = appendResult258;
				float localsdBox_Call261 = sdBox_Call( p261 , b261 );
				float4 _Vector6 = float4(0.145,-0.004,0,0);
				float2 appendResult301 = (float2(_Vector6.x , _Vector6.y));
				float2 appendResult308 = (float2(_MouseOffset.x , _MouseOffset.y));
				float cos282 = cos( 172.5 );
				float sin282 = sin( 172.5 );
				float2 rotator282 = mul( ( TV_UV380 + appendResult301 + appendResult308 ) - float2( 0,0 ) , float2x2( cos282 , -sin282 , sin282 , cos282 )) + float2( 0,0 );
				float2 p1272 = rotator282;
				float temp_output_277_0 = sin( 1.14 );
				float temp_output_278_0 = cos( 1.14 );
				float2 appendResult279 = (float2(temp_output_277_0 , temp_output_278_0));
				float2 p2272 = appendResult279;
				float r1272 = 0.04;
				float r2272 = 0.01;
				float localsdArc_Call1272 = sdArc_Call1( p1272 , p2272 , r1272 , r2272 );
				float4 _Vector7 = float4(0.08,0,0.06,0);
				float2 appendResult303 = (float2(_Vector7.x , _Vector7.y));
				float cos292 = cos( 173.0 );
				float sin292 = sin( 173.0 );
				float2 rotator292 = mul( ( TV_UV380 + appendResult303 + appendResult308 ) - float2( 0,0 ) , float2x2( cos292 , -sin292 , sin292 , cos292 )) + float2( 0,0 );
				float2 p1287 = rotator292;
				float2 appendResult288 = (float2(temp_output_277_0 , temp_output_278_0));
				float2 p2287 = appendResult288;
				float r1287 = 0.04;
				float r2287 = 0.01;
				float localsdArc_Call2287 = sdArc_Call2( p1287 , p2287 , r1287 , r2287 );
				float SDF311 = min( min( min( max( -localsdBox_Call219 , min( localsdBox_Call40 , localsdRoundedX_Call182 ) ) , localsdBox_Call246 ) , localsdBox_Call261 ) , min( localsdArc_Call1272 , localsdArc_Call2287 ) );
				float luminance317 = Luminance(float3( SdfUVGrid_Noise92 ,  0.0 ));
				float temp_output_318_0 = step( _MapCount.x , luminance317 );
				float temp_output_319_0 = ( step( SDF311 , 0.0 ) * temp_output_318_0 );
				float2 appendResult442 = (float2(_Tex1ScaleOffset.x , _Tex1ScaleOffset.y));
				float2 appendResult443 = (float2(_Tex1ScaleOffset.z , _Tex1ScaleOffset.w));
				float4 tex2DNode320 = tex2D( _Tex1, ( (RotateUV232*appendResult442 + appendResult443) - float2( -0.5,-0.5 ) ) );
				float temp_output_329_0 = step( luminance317 , _MapCount.y );
				float2 appendResult446 = (float2(_Tex2ScaleOffset.x , _Tex2ScaleOffset.y));
				float2 appendResult447 = (float2(_Tex2ScaleOffset.z , _Tex2ScaleOffset.w));
				float4 tex2DNode337 = tex2D( _Tex2, ( (RotateUV232*appendResult446 + appendResult447) - float2( -0.5,-0.5 ) ) );
				float temp_output_336_0 = ( ( 1.0 - temp_output_318_0 ) - temp_output_329_0 );
				float4 lerpResult343 = lerp( ( tex2D( _BaseMap, (ScreenPos_Normalize433*appendResult440 + appendResult441) ) * DepthMask_Color47 * _BaseColor ) , ( ( temp_output_319_0 * _SDFColor ) + ( tex2DNode320 * temp_output_329_0 * tex2DNode320.a * _Tex1Color ) + ( tex2DNode337 * temp_output_336_0 * tex2DNode337.a * _Tex2Color ) ) , saturate( max( max( temp_output_319_0 , ( temp_output_329_0 * tex2DNode320.a ) ) , ( temp_output_336_0 * tex2DNode337.a ) ) ));
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( lerpResult343 * DepthMask_Color47 ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
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

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
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

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

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

			half4 frag(VertexOutput IN  ) : SV_TARGET
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

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

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
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
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
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
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

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
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

			half4 frag(VertexOutput IN  ) : SV_TARGET
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

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "SceneSelectionPass"
            Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			int _ObjectId;
			int _PassValue;

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

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
			float4 _SelectionID;


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

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 140009


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fragment _ _WRITE_RENDERING_LAYERS
        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"

			#include "Assets/Products/NPR/SDF.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Sdf_Box1_Size;
			float4 _Tex1Color;
			float4 _Tex1ScaleOffset;
			float4 _SDFColor;
			float4 _MouseOffset;
			float4 _RightEyeOffsetSize;
			float4 _LeftEyeOffsetSize;
			float4 _Sdf_sdRoundedX1_Size;
			float4 _Tex2ScaleOffset;
			float4 _Tex2Color;
			float4 _BaseColor;
			float4 _Color_DepthMask2;
			float4 _Color_DepthMask1;
			float4 _BaseMapScaleOffset;
			float2 _DepthOffset;
			float2 _MapCount;
			float _RotateSpeedScale;
			float _TVScale;
			float _Speed;
			float _UVScale;
			float _LeftEyeRotate;
			float _RightEyeRotate;
			float _DepthMaskTexScale;
			float _RandomSeed;
			float _UVRotate;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			

			
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
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

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

			void frag( VertexOutput IN
				, out half4 outNormalWS : SV_Target0
			#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
			#endif
				 )
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( IN.clipPos );
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float3 normalWS = normalize(IN.normalWS);
					float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					float3 normalWS = IN.normalWS;
					outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}

			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19108
Node;AmplifyShaderEditor.CommentaryNode;313;-10104.18,716.8185;Inherit;False;3349.197;4025.875;SDF_小电视;16;311;305;266;294;254;192;228;231;237;238;309;310;377;378;380;379;SDF_小电视;1,0.4584905,0.7259815,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;310;-9863.195,2369.529;Inherit;False;1428.88;855.5262;Comment;16;261;259;246;241;244;240;243;264;263;262;260;258;257;256;255;242;眼;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;309;-9854.688,3297.342;Inherit;False;1495.932;1131.89;Comment;24;0;282;288;292;278;277;279;295;297;298;300;301;303;272;287;307;308;302;280;304;283;293;274;275;嘴;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;253;-4248.041,762.6292;Inherit;False;1341.436;397.6987;Sdf_Offset_Sin;7;212;215;210;209;213;214;247;Sdf_Offset_Sin;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;238;-9431.911,1915.734;Inherit;False;1010.282;394.9996;Comment;7;182;183;198;199;197;200;234;天线;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;237;-9429.486,1314.201;Inherit;False;997.3698;556.9316;Comment;6;194;195;40;236;196;193;外边框;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;231;-9423.958,911.834;Inherit;False;902.4794;327.1622;Comment;8;220;219;223;222;224;233;227;460;内部方形空洞;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;202;-3271.374,98.86919;Inherit;False;658.8367;467.7436;像素化SDF;4;71;73;74;72;像素化SDF;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;106;-7680.086,-1248.846;Inherit;False;3515.164;1471.155;SdfUV;29;128;129;175;170;125;121;124;123;60;81;64;107;62;108;101;68;89;75;98;374;376;382;433;180;375;466;467;468;469;SdfUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;102;-7679.416,-2185.313;Inherit;False;1739.038;733.8785;SdfUVGrid_Noise;11;465;92;457;131;185;184;93;90;78;77;99;SdfUVGrid_Noise;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;42;-5220.648,-2419.076;Inherit;False;2414.546;1028.229;GetDepthMask;22;453;455;59;45;58;47;48;17;44;19;39;38;36;37;18;35;34;33;31;32;29;456;GetDepthMaskColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;41;-7670.672,-2665.509;Inherit;False;1069.873;279.3557;PosNDC;5;24;26;28;27;23;PosNDC;1,1,1,1;0;0
Node;AmplifyShaderEditor.PosVertexDataNode;24;-7620.672,-2587.664;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;26;-7426.425,-2590.153;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;28;-6966.62,-2615.509;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.Vector2Node;29;-4976.888,-2065.743;Inherit;False;Property;_DepthOffset;_DepthOffset;2;0;Create;True;0;0;0;False;0;False;0,0;-1097,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.Vector2Node;32;-5033.368,-1879.984;Inherit;False;Constant;_Vector0;Vector 0;1;0;Create;True;0;0;0;False;0;False;1920,1080;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleDivideOpNode;31;-4788.487,-1975.744;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;33;-4640.135,-1883.12;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;-4666.264,-2290.051;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;18;-5004,-2369.076;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;37;-4479.063,-2158.851;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-4957.464,-2157.251;Inherit;False;Property;_DepthMaskTexScale;DepthMaskTexScale;0;0;Create;True;0;0;0;False;0;False;0.9;0.9;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;38;-4748.664,-2098.851;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;39;-4595.864,-2097.251;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;19;-4338.308,-1966.198;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;44;-3769.491,-2026.499;Inherit;False;DepthMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;17;-4175.032,-2028.106;Inherit;True;Global;_DepthMaskColor;_DepthMaskColor;1;0;Create;True;0;0;0;False;0;False;-1;None;;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;48;-3869.887,-1937.909;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;58;-3557.385,-1829.628;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;45;-3944.338,-1856.643;Inherit;False;Property;_Color_DepthMask1;Color_DepthMask1;3;0;Create;True;0;0;0;False;0;False;0,0,0,1;0.9294118,0.9333334,0.9294118,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;59;-3936.985,-1666.348;Inherit;False;Property;_Color_DepthMask2;Color_DepthMask2;4;0;Create;True;0;0;0;False;0;False;1,1,1,1;0.6603774,0.6603774,0.6603774,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RotatorNode;68;-4891.514,-1219.108;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0.5,0.5;False;2;FLOAT;0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-5807.258,-569.2691;Inherit;False;92;SdfUVGrid_Noise;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;99;-7524.569,-1731.391;Inherit;False;98;UVScale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;62;-5987.391,-779.3759;Inherit;False;Property;_SDFUV_Offset;SDFUV_Offset;10;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;-3092.858,148.8692;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;10;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FloorOpNode;73;-2935.545,188.3661;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;74;-2847.937,313.2126;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-3221.374,272.305;Inherit;False;Property;_PixcelLate;PixcelLate;11;0;Create;True;0;0;0;False;0;False;20;20;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;77;-7427.822,-2133.043;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;78;-7232.596,-2044.283;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;61;-3609.059,-579.6497;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;205;-2966.419,-517.0095;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SinOpNode;212;-3683.879,906.9279;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;215;-3850.786,916.8647;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;10,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;213;-3397.037,833.1458;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0.1,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;214;-3246.928,812.6292;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;7;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;8;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;9;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.DynamicAppendNode;194;-8854.791,1586.773;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;195;-8868.87,1680.694;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;196;-8850.552,1448.534;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;193;-9363.191,1662.133;Inherit;False;Property;_Sdf_Box1_Size;Sdf_Box1_Size;17;0;Create;True;0;0;0;False;0;False;0.38,0.16,0,0;0.25,0.2,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;200;-8953.51,1965.734;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;182;-8674.831,1972.678;Inherit;False;return sdRoundedX(p,w,r)@;1;Create;3;True;p;FLOAT2;0,0;In;;Inherit;False;True;w;FLOAT;0;In;;Inherit;False;True;r;FLOAT;0;In;;Inherit;False;sdRoundedX_Call;False;False;0;;False;3;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;40;-8688.119,1516.042;Inherit;False;return sdBox(p,b)@;1;Create;2;True;p;FLOAT2;0,0;In;;Inherit;False;True;b;FLOAT2;0,0;In;;Inherit;False;sdBox_Call;False;False;0;;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;183;-8883.267,2090.353;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMaxOpNode;228;-8114.926,1464.921;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;220;-8950.855,961.834;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;223;-9382.277,1033.116;Inherit;False;Constant;_Vector2;Vector 2;17;0;Create;True;0;0;0;False;0;False;0,0,0.22,0.17;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;222;-8983.133,1110.971;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;224;-9142.509,1032.864;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NegateNode;227;-8662.759,1096.152;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;219;-8778.52,991.6299;Inherit;False;return sdBox(p,b)@;1;Create;2;True;p;FLOAT2;0,0;In;;Inherit;False;True;b;FLOAT2;0,0;In;;Inherit;False;sdBox_Call;False;False;0;;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;197;-9406.442,2119.226;Inherit;False;Property;_Sdf_sdRoundedX1_Size;Sdf_sdRoundedX1_Size;18;0;Create;True;0;0;0;False;0;False;0.38,0.16,0,0;0.38,0.01,0,-0.1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;199;-9058.095,2201.465;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;198;-9064.428,2102.449;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMinOpNode;192;-8320.035,1514.457;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;254;-7991.859,1604.5;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;294;-7717.864,2202.421;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;266;-7689.685,1690.753;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;305;-7545.964,1790.406;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;-8625.344,3578.529;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.RotatorNode;282;-8766.116,3512.695;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CosOpNode;278;-9155.717,3614.294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;277;-9163.717,3543.895;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;279;-8936.517,3646.294;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;298;-9297.813,3441.959;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;300;-8881.995,3380.132;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;301;-9161.992,3466.004;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;274;-9268.739,3671.965;Inherit;False;Constant;_Float2;Float 2;20;0;Create;True;0;0;0;False;0;False;0.04;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;275;-9160.649,3740.122;Inherit;False;Constant;_Float3;Float 3;22;0;Create;True;0;0;0;False;0;False;0.01;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;242;-9067.091,2677.375;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;255;-8856.192,2478.688;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;257;-9040.652,2922.356;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;258;-9072.931,3071.493;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;262;-8862.033,2872.804;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;264;-9232.306,2994.188;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;240;-9007.772,2452.319;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;244;-9226.466,2600.07;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;246;-8654.414,2567.869;Inherit;False;return sdBox(p,b)@;1;Create;2;True;p;FLOAT2;0,0;In;;Inherit;False;True;b;FLOAT2;0,0;In;;Inherit;False;sdBox_Call;False;False;0;;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;272;-8630.059,3666.589;Inherit;False;return sdArc(p1,p2,r1,r2)@;1;Create;4;True;p1;FLOAT2;0,0;In;;Inherit;False;True;p2;FLOAT2;0,0;In;;Inherit;False;True;r1;FLOAT;0;In;;Inherit;False;True;r2;FLOAT;0;In;;Inherit;False;sdArc_Call1;False;False;0;;False;4;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;308;-9558.195,3746.563;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;261;-8601.92,2916.153;Inherit;False;return sdBox(p,b)@;1;Create;2;True;p;FLOAT2;0,0;In;;Inherit;False;True;b;FLOAT2;0,0;In;;Inherit;False;sdBox_Call;False;False;0;;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;311;-7385.048,1862.06;Inherit;False;SDF;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;307;-9804.687,3702.013;Inherit;False;Property;_MouseOffset;MouseOffset;23;0;Create;True;0;0;0;False;0;False;0.1,-0.05,0.06,0.015;-0.11,0.04,0.06,0.015;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;302;-9589.93,3410.165;Inherit;False;Constant;_Vector6;Vector 6;18;0;Create;True;0;0;0;False;0;False;0.145,-0.004,0,0;0.145,-0.004,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;280;-9424.068,3588.222;Inherit;False;Constant;_Float4;Float 4;24;0;Create;True;0;0;0;False;0;False;1.14;1.14;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;283;-8971.467,3539.802;Inherit;False;Constant;_Float5;Float 5;26;0;Create;True;0;0;0;False;0;False;172.5;172.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;293;-8874.299,4011.689;Inherit;False;Constant;_Float9;Float 9;27;0;Create;True;0;0;0;False;0;False;173;173;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;303;-9253.033,4027.968;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;304;-9753.208,4013.15;Inherit;False;Constant;_Vector7;Vector 7;19;0;Create;True;0;0;0;False;0;False;0.08,0,0.06,0;0.08,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;295;-9740.817,3920.068;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;297;-9053.38,3931.595;Inherit;False;3;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;288;-8741.826,4131.087;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;287;-8553.001,4080.913;Inherit;False;return sdArc(p1,p2,r1,r2)@;1;Create;4;True;p1;FLOAT2;0,0;In;;Inherit;False;True;p2;FLOAT2;0,0;In;;Inherit;False;True;r1;FLOAT;0;In;;Inherit;False;True;r2;FLOAT;0;In;;Inherit;False;sdArc_Call2;False;False;0;;False;4;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;292;-8704.923,3936.93;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;263;-9034.034,2988.004;Inherit;False;Property;_RightEyeRotate;RightEyeRotate;21;0;Create;True;0;0;0;False;0;False;-60;-60.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-9031.394,2597.887;Inherit;False;Property;_LeftEyeRotate;LeftEyeRotate;20;0;Create;True;0;0;0;False;0;False;60;60.37;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;241;-9466.234,2599.521;Inherit;False;Property;_LeftEyeOffsetSize;LeftEyeOffsetSize;22;0;Create;True;0;0;0;False;0;False;0.1,-0.05,0.06,0.015;0.12,-0.05,0.06,0.01;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;260;-9472.075,2993.638;Inherit;False;Property;_RightEyeOffsetSize;RightEyeOffsetSize;24;0;Create;True;0;0;0;False;0;False;-0.1,-0.05,0.06,0.015;-0.11,-0.05,0.06,0.01;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;319;-3293.527,1718.854;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;312;-3875.726,1644.125;Inherit;False;311;SDF;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;16;-3620.8,1634.723;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;335;-3515.66,1890.036;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;327;-2732.304,1859.114;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;345;-2547.341,2350.656;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;346;-2881.563,2015.343;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;324;-3147.157,2309.843;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;348;-3226.565,2455.159;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;340;-3038.015,2596.503;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;349;-3060.165,2739.078;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;347;-2682.043,2207.297;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;350;-2182.529,2197.575;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;351;-2385.973,2386.337;Inherit;False;47;DepthMask_Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;342;-3339.411,1533.234;Inherit;False;Property;_SDFColor;SDFColor;5;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.07298841,0.4253479,0.4479999,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StepOpNode;329;-3751.998,2024.103;Inherit;True;2;0;FLOAT;0.3;False;1;FLOAT;0.22;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;353;-2480.097,-370.5836;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;318;-3727.927,1760.453;Inherit;True;2;0;FLOAT;0.33;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;316;-4271.924,1781.254;Inherit;True;92;SdfUVGrid_Noise;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LuminanceNode;317;-4031.127,1785.254;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;369;-4055.428,2079.707;Inherit;False;Property;_MapCount;MapCount;31;0;Create;True;0;0;0;False;0;False;0.3,0.2;0.56,0.4;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ColorNode;371;-3494.349,2471.66;Inherit;False;Property;_Tex1Color;Tex1Color;25;0;Create;True;0;0;0;False;0;False;1,1,1,1;0.9215687,0.9294118,0.9176471,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;181;-2906.056,-348.2555;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;216;-3175.622,-276.495;Inherit;False;Property;_RotateSpeedScale;RotateSpeedScale;19;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;80;-3204.453,-353.993;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;358;-2730.497,-264.1837;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.8;False;4;FLOAT;1.8;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;377;-9965.406,900.9712;Inherit;False;Property;_TVScale;TV Scale;9;0;Create;True;0;0;0;False;0;False;1;0.96;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;379;-9000.355,852.2798;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;243;-9423.59,2514.146;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;233;-9339.632,947.7422;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;234;-9270.563,1967.311;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;259;-9426.229,2900.264;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-5826.175,-1180.11;Inherit;False;Property;_UVScale;UVScale;13;0;Create;True;0;0;0;False;0;False;10;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;98;-5498.878,-1198.046;Inherit;False;UVScale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;373;-3523.324,-331.6838;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;381;-3688.281,-278.153;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0.1,0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;95;-3937.136,-320.6183;Inherit;True;92;SdfUVGrid_Noise;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;370;-3406.348,2722.06;Inherit;False;Property;_Tex2Color;Tex2Color;28;0;Create;True;0;0;0;False;0;False;1,1,1,1;0.4449096,0.4479999,0.4449096,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GrabScreenPosition;383;-9318.472,-1278.143;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenParams;384;-9425.734,-1037.569;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;429;-9106.827,-1047.251;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;426;-8787.308,-1264.271;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;421;-9037.979,-1304.471;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;431;-8625.2,-1175.282;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;430;-8439.786,-1276.611;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;382;-7837.074,-1399.076;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;432;-8274.386,-1228.842;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RadiansOpNode;437;-8418.226,-814.9371;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;427;-8867.228,-988.5919;Inherit;False;Constant;_Float1;Float 1;31;0;Create;True;0;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RotatorNode;435;-8130.834,-958.34;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;30;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;436;-8556.086,-881.1169;Inherit;False;Property;_UVRotate;UVRotate;12;0;Create;True;0;0;0;False;0;False;30;10.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;320;-3723.098,2309.02;Inherit;True;Property;_Tex1;Tex1;27;0;Create;True;0;0;0;False;1;NoScaleOffset;False;-1;None;5bed2a284c8ee4b4e98cfc8d7876ada3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;337;-3716.808,2611.973;Inherit;True;Property;_Tex2;Tex2;30;0;Create;True;0;0;0;False;1;NoScaleOffset;False;-1;None;b8a3a20a3e472754786d93a19395aac0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;445;-4188.585,2393.558;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;325;-3926.795,2386.071;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;-0.5,-0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-6825.601,-2579.365;Inherit;False;posNDCw;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CameraDepthFade;453;-4791.947,-1615.712;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;23;-7179.781,-2582.51;Inherit;False; float4 ndc = posCS * 0.5f@$ float4 positionNDC=0@$positionNDC .xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w@$positionNDC.zw = posCS.zw@$return positionNDC@;4;Create;1;True;posCS;FLOAT4;0,0,0,0;In;;Inherit;False;PosCS2PosNDC;True;False;0;;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;34;-5143.427,-1757.673;Inherit;False;27;posNDCw;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;456;-4839.413,-1722.738;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;455;-5089.127,-1624.898;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;127;-7931.054,-913.9257;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RelayNode;170;-5937.095,-441.9648;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;60;-4880.314,-944.1452;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;1;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;336;-3336.548,1926.145;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;341;-2985.702,1713.866;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;-1959.14,2197.71;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;KTSAMA/SDF_Unlit;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;1;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;False;0;True;_1;0.9;True;_Float0;True;1;LightMode=UniversalForwardOnly;False;False;2;Include;;False;;Native;False;0;0;;Include;;True;5d014482aca08f1488321dcffc6b87ca;Custom;False;0;0;;;0;0;Standard;23;Surface;0;638468081894040522;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;True;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.LerpOp;343;-2355.324,2115.639;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;50;-2877.287,1192.457;Inherit;True;Property;_BaseMap;BaseMap;8;0;Create;True;0;0;0;False;1;NoScaleOffset;False;-1;None;cfbb2354dffda1a45b199fdc91b36e9f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;438;-3103.04,1211.794;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;434;-3375.256,1193.703;Inherit;False;433;ScreenPos_Normalize;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;440;-3341.968,1287.498;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;439;-3674.202,1269.537;Inherit;False;Property;_BaseMapScaleOffset;BaseMapScaleOffset;7;0;Create;True;0;0;0;False;0;False;1,1,0,0;0.8,0.8,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;441;-3335.2,1383.009;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;352;-2807.358,1516.277;Inherit;False;Property;_BaseColor;BaseColor;6;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.3509427,0.3509427,0.3509427,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;51;-2809.833,1408.233;Inherit;False;47;DepthMask_Color;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;55;-2492.779,1337.661;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;339;-3881.799,2637.329;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;-0.5,-0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;449;-4109.596,2643.596;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;1,0;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;338;-4383.373,2629.341;Inherit;False;232;RotateUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;446;-4343.742,2736.361;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;447;-4345.559,2845.162;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;47;-3192.627,-1820.709;Inherit;False;DepthMask_Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;459;-2055.33,2375.558;Inherit;False;232;RotateUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;236;-9153.048,1415.07;Inherit;False;380;TV_UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;380;-9643.463,885.9282;Inherit;False;TV_UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;460;-8876.253,980.8137;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;378;-10054.67,787.5281;Inherit;False;232;RotateUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;366;-2190.752,-535.1168;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;247;-3106.604,859.327;Inherit;False;Sdf_Offset_Sin;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;232;-1987.271,-479.0436;Inherit;False;RotateUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;323;-4534.014,2311.5;Inherit;False;232;RotateUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;442;-4578.804,2406.854;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;443;-4569.439,2512.656;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;444;-4812.73,2393.978;Inherit;False;Property;_Tex1ScaleOffset;Tex1ScaleOffset;26;0;Create;True;0;0;0;False;0;False;1,1,0,0;0.528,1.1,0,0.05;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;448;-4764.413,2688.788;Inherit;False;Property;_Tex2ScaleOffset;Tex2ScaleOffset;29;0;Create;True;0;0;0;False;0;False;1,1,0,0;1.2,1.2,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;89;-4474.557,-933.3475;Inherit;True;SdfUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RotatorNode;10;-2743.115,-454.6185;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;130;-3947.839,-452.9393;Inherit;False;89;SdfUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;65;-3416.299,-582.9836;Inherit;True;3;3;0;FLOAT2;0,0;False;1;FLOAT2;-0.5,-0.5;False;2;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TFHCRemapNode;367;-3541.34,-788.3322;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;-0.1,-0.1;False;4;FLOAT2;0.1,0.1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LuminanceNode;356;-3034.871,-165.1094;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;204;-3214.354,-564.162;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;463;-3706.039,-104.5373;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RelayNode;464;-3524.146,35.22226;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;462;-3529.284,-195.9977;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;355;-3923.425,-86.84531;Inherit;True;92;SdfUVGrid_Noise;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;184;-6389.914,-2147.104;Inherit;False;Property;_NoiseMin;NoiseMin;15;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;185;-6397.913,-2027.103;Inherit;False;Property;_NoiseMax;NoiseMax;16;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;465;-6879.214,-1908.052;Inherit;False;KTRandom2;-1;;3;1aed3f816d8cfc245aeaff2d1795e34f;0;2;6;FLOAT2;0,0;False;16;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;93;-6888.493,-2137.328;Inherit;True;SdfUV_Grid;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;131;-6685.151,-1897.125;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;457;-6473.279,-1731.166;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;92;-6313.902,-1913.545;Inherit;True;SdfUVGrid_Noise;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;458;-2512.042,-545.631;Inherit;False;247;Sdf_Offset_Sin;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;210;-4004.201,857.3278;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;209;-4198.041,928.4478;Inherit;False;93;SdfUV_Grid;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;90;-7631.502,-2132.868;Inherit;True;89;SdfUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;374;-5614.356,-504.7286;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;467;-5335.307,-546.0167;Inherit;True;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;468;-5085.706,-574.817;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;64;-5461.422,-870.3737;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-5273.186,-842.5874;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;469;-5429.858,-740.2144;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1080;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;466;-5001.982,-748.4908;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;-5653.042,-930.1718;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;108;-5825.583,-852.6091;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;180;-5775.144,-740.8317;Inherit;False;Property;_Speed;Speed;14;0;Create;True;0;0;0;False;0;False;1;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;121;-7563.883,-768.5844;Inherit;False;98;UVScale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;433;-7634.706,-1182.738;Inherit;False;ScreenPos_Normalize;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FractNode;175;-6135.766,-449.3486;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;375;-6384.762,-466.012;Inherit;True;KTRandom2;-1;;4;1aed3f816d8cfc245aeaff2d1795e34f;0;2;6;FLOAT2;0,0;False;16;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RelayNode;128;-6610.213,-762.6295;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;376;-6788.896,-474.891;Inherit;False;Property;_RandomSeed;RandomSeed;32;0;Create;True;0;0;0;False;0;False;1;212.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;129;-6777.109,-797.3079;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleDivideOpNode;125;-6986.37,-803.4974;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FloorOpNode;124;-7141.009,-809.0008;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;123;-7362.114,-837.4921;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
WireConnection;26;0;24;0
WireConnection;28;0;23;0
WireConnection;31;0;29;0
WireConnection;31;1;32;0
WireConnection;33;0;31;0
WireConnection;33;1;34;0
WireConnection;35;0;18;0
WireConnection;35;1;36;0
WireConnection;37;0;35;0
WireConnection;37;1;39;0
WireConnection;38;0;36;0
WireConnection;39;0;38;0
WireConnection;19;0;37;0
WireConnection;19;1;33;0
WireConnection;44;0;17;1
WireConnection;17;1;19;0
WireConnection;48;0;17;1
WireConnection;58;0;45;0
WireConnection;58;1;59;0
WireConnection;58;2;44;0
WireConnection;71;0;61;0
WireConnection;71;1;72;0
WireConnection;73;0;71;0
WireConnection;74;0;73;0
WireConnection;74;1;72;0
WireConnection;77;0;90;0
WireConnection;78;0;77;0
WireConnection;78;1;99;0
WireConnection;61;0;130;0
WireConnection;205;0;204;0
WireConnection;205;1;204;1
WireConnection;212;0;215;0
WireConnection;215;0;209;0
WireConnection;213;0;212;0
WireConnection;214;0;213;0
WireConnection;214;1;213;0
WireConnection;194;0;193;1
WireConnection;194;1;193;2
WireConnection;195;0;193;3
WireConnection;195;1;193;4
WireConnection;196;0;236;0
WireConnection;196;1;195;0
WireConnection;200;0;234;0
WireConnection;200;1;199;0
WireConnection;182;0;200;0
WireConnection;182;1;183;0
WireConnection;182;2;183;1
WireConnection;40;0;196;0
WireConnection;40;1;194;0
WireConnection;183;0;198;0
WireConnection;228;0;227;0
WireConnection;228;1;192;0
WireConnection;220;0;233;0
WireConnection;220;1;224;0
WireConnection;222;0;223;3
WireConnection;222;1;223;4
WireConnection;224;0;223;1
WireConnection;224;1;223;2
WireConnection;227;0;219;0
WireConnection;219;0;220;0
WireConnection;219;1;222;0
WireConnection;199;0;197;3
WireConnection;199;1;197;4
WireConnection;198;0;197;1
WireConnection;198;1;197;2
WireConnection;192;0;40;0
WireConnection;192;1;182;0
WireConnection;254;0;228;0
WireConnection;254;1;246;0
WireConnection;294;0;272;0
WireConnection;294;1;287;0
WireConnection;266;0;254;0
WireConnection;266;1;261;0
WireConnection;305;0;266;0
WireConnection;305;1;294;0
WireConnection;282;0;300;0
WireConnection;282;2;283;0
WireConnection;278;0;280;0
WireConnection;277;0;280;0
WireConnection;279;0;277;0
WireConnection;279;1;278;0
WireConnection;300;0;298;0
WireConnection;300;1;301;0
WireConnection;300;2;308;0
WireConnection;301;0;302;1
WireConnection;301;1;302;2
WireConnection;242;0;241;3
WireConnection;242;1;241;4
WireConnection;255;0;240;0
WireConnection;255;2;256;0
WireConnection;257;0;259;0
WireConnection;257;1;264;0
WireConnection;258;0;260;3
WireConnection;258;1;260;4
WireConnection;262;0;257;0
WireConnection;262;2;263;0
WireConnection;264;0;260;1
WireConnection;264;1;260;2
WireConnection;240;0;243;0
WireConnection;240;1;244;0
WireConnection;244;0;241;1
WireConnection;244;1;241;2
WireConnection;246;0;255;0
WireConnection;246;1;242;0
WireConnection;272;0;282;0
WireConnection;272;1;279;0
WireConnection;272;2;274;0
WireConnection;272;3;275;0
WireConnection;308;0;307;1
WireConnection;308;1;307;2
WireConnection;261;0;262;0
WireConnection;261;1;258;0
WireConnection;311;0;305;0
WireConnection;303;0;304;1
WireConnection;303;1;304;2
WireConnection;297;0;295;0
WireConnection;297;1;303;0
WireConnection;297;2;308;0
WireConnection;288;0;277;0
WireConnection;288;1;278;0
WireConnection;287;0;292;0
WireConnection;287;1;288;0
WireConnection;287;2;274;0
WireConnection;287;3;275;0
WireConnection;292;0;297;0
WireConnection;292;2;293;0
WireConnection;319;0;16;0
WireConnection;319;1;318;0
WireConnection;16;0;312;0
WireConnection;335;1;318;0
WireConnection;327;0;341;0
WireConnection;327;1;324;0
WireConnection;327;2;340;0
WireConnection;345;0;347;0
WireConnection;346;0;319;0
WireConnection;346;1;348;0
WireConnection;324;0;320;0
WireConnection;324;1;329;0
WireConnection;324;2;320;4
WireConnection;324;3;371;0
WireConnection;348;0;329;0
WireConnection;348;1;320;4
WireConnection;340;0;337;0
WireConnection;340;1;336;0
WireConnection;340;2;337;4
WireConnection;340;3;370;0
WireConnection;349;0;336;0
WireConnection;349;1;337;4
WireConnection;347;0;346;0
WireConnection;347;1;349;0
WireConnection;350;0;343;0
WireConnection;350;1;351;0
WireConnection;329;0;317;0
WireConnection;329;1;369;2
WireConnection;353;0;10;0
WireConnection;353;1;358;0
WireConnection;318;0;369;1
WireConnection;318;1;317;0
WireConnection;317;0;316;0
WireConnection;181;0;80;0
WireConnection;181;1;216;0
WireConnection;80;0;373;0
WireConnection;358;0;356;0
WireConnection;379;0;378;0
WireConnection;379;1;377;0
WireConnection;98;0;75;0
WireConnection;373;0;381;0
WireConnection;381;0;95;0
WireConnection;429;0;384;1
WireConnection;429;1;384;2
WireConnection;426;0;421;0
WireConnection;426;1;427;0
WireConnection;421;0;383;1
WireConnection;421;1;383;2
WireConnection;431;0;426;0
WireConnection;430;0;431;0
WireConnection;430;1;429;0
WireConnection;432;0;430;0
WireConnection;432;1;431;1
WireConnection;437;0;436;0
WireConnection;435;0;432;0
WireConnection;435;2;437;0
WireConnection;320;1;325;0
WireConnection;337;1;339;0
WireConnection;445;0;323;0
WireConnection;445;1;442;0
WireConnection;445;2;443;0
WireConnection;325;0;445;0
WireConnection;27;0;28;3
WireConnection;453;2;455;0
WireConnection;23;0;26;0
WireConnection;456;0;455;0
WireConnection;170;0;175;0
WireConnection;60;0;433;0
WireConnection;60;1;98;0
WireConnection;60;2;81;0
WireConnection;336;0;335;0
WireConnection;336;1;329;0
WireConnection;341;0;319;0
WireConnection;341;1;342;0
WireConnection;1;2;350;0
WireConnection;343;0;55;0
WireConnection;343;1;327;0
WireConnection;343;2;345;0
WireConnection;50;1;438;0
WireConnection;438;0;434;0
WireConnection;438;1;440;0
WireConnection;438;2;441;0
WireConnection;440;0;439;1
WireConnection;440;1;439;2
WireConnection;441;0;439;3
WireConnection;441;1;439;4
WireConnection;55;0;50;0
WireConnection;55;1;51;0
WireConnection;55;2;352;0
WireConnection;339;0;449;0
WireConnection;449;0;338;0
WireConnection;449;1;446;0
WireConnection;449;2;447;0
WireConnection;446;0;448;1
WireConnection;446;1;448;2
WireConnection;447;0;448;3
WireConnection;447;1;448;4
WireConnection;47;0;58;0
WireConnection;380;0;460;0
WireConnection;460;0;379;0
WireConnection;366;1;10;0
WireConnection;247;0;214;0
WireConnection;232;0;366;0
WireConnection;442;0;444;1
WireConnection;442;1;444;2
WireConnection;443;0;444;3
WireConnection;443;1;444;4
WireConnection;89;0;60;0
WireConnection;10;0;205;0
WireConnection;10;2;181;0
WireConnection;65;0;61;0
WireConnection;65;2;367;0
WireConnection;367;0;355;0
WireConnection;356;0;355;0
WireConnection;204;0;65;0
WireConnection;463;0;355;0
WireConnection;464;0;463;1
WireConnection;462;0;463;0
WireConnection;465;6;78;0
WireConnection;465;16;376;0
WireConnection;93;0;78;0
WireConnection;131;0;465;0
WireConnection;457;0;131;0
WireConnection;92;0;131;0
WireConnection;210;0;209;0
WireConnection;374;0;170;0
WireConnection;467;0;374;0
WireConnection;468;0;467;0
WireConnection;64;0;108;0
WireConnection;81;0;180;0
WireConnection;81;1;468;0
WireConnection;469;0;180;0
WireConnection;466;0;81;0
WireConnection;107;0;108;0
WireConnection;433;0;435;0
WireConnection;175;0;375;0
WireConnection;375;6;128;0
WireConnection;375;16;376;0
WireConnection;128;0;129;1
WireConnection;129;0;125;0
WireConnection;125;0;124;0
WireConnection;125;1;121;0
WireConnection;124;0;123;0
WireConnection;123;0;433;0
WireConnection;123;1;121;0
ASEEND*/
//CHKSM=3CADDAE78A6725F70F04AA0D00FD980960941EEA