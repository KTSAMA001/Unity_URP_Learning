Shader "KTSAMA/NPR/UnlitShader"
{
    Properties
    {
        _BaseMap ("Example Texture", 2D) = "white" {}
        _BaseColor ("Example Colour", Color) = (0, 0.66, 0.73, 1)
        [Toggle]_Depth_Mask_Color_Local("Depth_Mask_Color_Local",float)=0
        _DepthOffset("_DepthOffset",Vector)=(300,100,0,0)
        _SDF1ScaleOffset("_SDF1ScaleOffset",Vector)=(1,1,0,0)
         _SDF1Size("_SDF1Size",Vector)=(1,1,0,0)
        _SDF2ScaleOffset("_SDF2ScaleOffset",Vector)=(1,1,0,0)
       
        _SDF2Size("_SDF2Size",Vector)=(1,1,0,0)
        _SDF3ScaleOffset("_SDF3ScaleOffset",Vector)=(1,1,0,0)
        _SDF3Size("_SDF3Size",Vector)=(1,1,0,0)
        _DepthMaskColor1("DepthOffsetColor1",Color)=(0,0,0,1)
        _DepthMaskColor2("DepthOffsetColor2",Color)=(1,1,1,1)
        _Color1("_Color1",Color)=(1,1,1,1)
        _Color2("_Color2",Color)=(1,1,1,1)
         [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
          // Editmode props
        _QueueOffset("Queue offset", Float) = 0.0
          // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
        [HideInInspector] _SampleGI("SampleGI", float) = 0.0 // needed from bakedlit
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "UniversalMaterialType" = "Unlit"
            "RenderPipeline" = "UniversalPipeline"
        }
        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]
        HLSLINCLUDE
        #include "UnLitInput.hlsl"

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
        ENDHLSL
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
 Name "Unlit"
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ _DEPTH_MASK_COLOR_LOCAL_ON
            #pragma shader_feature _ _DEPTH_MASK_COLOR
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_DepthMaskColor);
            SAMPLER(sampler_DepthMaskColor);

            //定义模型原始数据结构
            struct VertexInput
            {
                //物体空间顶点坐标
                float4 positionOS : POSITION;
                //模型UV坐标
                float2 uv : TEXCOORD0;
                //模型法线
                float4 normalOS : NORMAL;
                //物体空间切线
                float4 tangentOS : TANGENT;
                float4 color:COLOR;
            };

            //定义顶点程序片段与表i面程序片段的传递数据结构
            struct VertexOutput
            {
                //物体裁切空间坐标
                float4 positionCS : SV_POSITION;
                //UV坐标
                float2 uv : TEXCOORD0;
                //世界空间顶点
                float3 positionWS : TEXCOORD1;
                float2 uv_sdf1 : TEXCOORD2;
                float2 uv_sdf2 : TEXCOORD3;
                float2 uv_sdf3 : TEXCOORD4;

                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON ||_DEPTH_MASK_COLOR
                 float4 screenPos:TEXCOORD5;
                 float4 shadowCoord_Screen:TEXCOORD6;
                #endif
                float4 color:TEXCOORD7;
                float4 posNDCw:TEXCOORD8;
            };

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;

                //VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                //o.positionCS = positionInputs.positionCS;
                // Or this :
                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS);
                o.positionCS = positionInputs.positionCS;
                // o.uv = TRANSFORM_TEX(i.uv, _BaseMap);
               
                o.uv = i.uv*_BaseMap_ST.xy+(1-_BaseMap_ST.xy)/2+_BaseMap_ST.zw;
                o.uv_sdf1= i.uv*_SDF1ScaleOffset.xy+(1-_SDF1ScaleOffset.xy)/2+_SDF1ScaleOffset.zw;
                o.uv_sdf2= i.uv*_SDF2ScaleOffset.xy+(1-_SDF2ScaleOffset.xy)/2+_SDF2ScaleOffset.zw;
                o.uv_sdf3= i.uv*_SDF3ScaleOffset.xy+(1-_SDF3ScaleOffset.xy)/2+_SDF3ScaleOffset.zw;;
                o.color = i.color;
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON||_DEPTH_MASK_COLOR
                o.screenPos=ComputeScreenPos(positionInputs.positionCS);
                o.posNDCw= positionInputs.positionNDC.w;
                #endif
                return o;
            }

float sdBox( in float2 p, in float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
            float sdHexagram( in float2 p, in float r )
{
    const float4 k = float4(-0.5,0.8660254038,0.5773502692,1.7320508076);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= 2.0*min(dot(k.yx,p),0.0)*k.yx;
    p -= float2(clamp(p.x,r*k.z,r*k.w),r);
    return length(p)*sign(p.y);
}
            half4 frag(VertexOutput i) : SV_Target
            {
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION|| _SCREEN_SPACE_HAIRSHADOW_ON||_DEPTH_MASK_COLOR
                i.shadowCoord_Screen=ASE_ComputeGrabScreenPos(i.screenPos);
                
                i.shadowCoord_Screen=i.shadowCoord_Screen/i.shadowCoord_Screen.w;
                #endif
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float depthOffset = 1;
                float3 depthColor = 1;
                //屏幕空间的指定物体画纯色（SSDepthOffsetPassFeature配合使用），偏移后当作背景阴影使用
                #ifdef _DEPTH_MASK_COLOR
                #ifdef _DEPTH_MASK_COLOR_LOCAL_ON
                //使用i.posNDCw的目的是防止因为距离造成的离得越远头发投影越大的问题
                depthOffset  =1-SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy*0.9+(1-0.9)/2+ _DepthOffset*float2(1.0/ 1920.0,1.0/ 1080.0)* (1 / i.posNDCw)).r;
                depthOffset=max(0,depthOffset);
                depthColor=lerp(_DepthMaskColor1,_DepthMaskColor2,depthOffset);
                //这种做法就是直接把偏移的部分扣掉，实心颜色
                //final_color*=depthOffset;
                //final_color+=depthColor;
                //这种做法就是叠加颜色
                baseMap.rgb*=depthColor;
                #endif
                #endif
                //return float4(i.uv,0,1);
                float cos10 = cos( 1.0 * _Time.y );
				float sin10 = sin( 1.0 * _Time.y );
                float2 sdf1_pos=frac(i.uv_sdf1-_Time.x)-0.5;
                float2 sdf2_pos=frac(i.uv_sdf2-_Time.x)-0.5;
                float2 sdf3_pos=frac(i.uv_sdf2-_Time.x)-0.5;
                sdf1_pos= mul( sdf1_pos - float2( 0,0 ) , float2x2( cos10 , -sin10 , sin10 , cos10 )) + float2( 0,0 );
                sdf2_pos= mul( sdf2_pos - float2( 0,0 ) , float2x2( cos10 , -sin10 , sin10 , cos10 )) + float2( 0,0 );
                sdf3_pos= mul( sdf3_pos - float2( 0,0 ) , float2x2( cos10 , -sin10 , sin10 , cos10 )) + float2( 0,0 );
                //float sdf1=sdBox(sdf_pos,_SDBoxBox);
                //float sdf1=length(frac(sdf1_pos.x-_Time.x)*_SDF1Size.x)/(_SDF1Size.y)-_SDF1Size.z;
                float sdf1=sdHexagram(sdf1_pos,_SDF1Size.x);
                float sdf2=length(sdf2_pos.x-_Time.x*_SDF2Size.x)/(_SDF2Size.y)-_SDF2Size.z;
                float sdf3=length(sdf3_pos.x-_Time.x*_SDF3Size.x)/(_SDF3Size.y)-_SDF3Size.z;
                float sdf=sdf1;
             
                float sdfShape=step(0,sdf);
                float4 col_sdf=lerp(_Color1,_Color2,sdfShape);
                return col_sdf;
                //return float4(depthColor,1);
                return baseMap * _BaseColor * i.color*col_sdf*(i.uv.y);
            }
            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAMODULATE_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitGBufferPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormalsOnly"
            Tags
            {
                "LightMode" = "DepthNormalsOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT // forward-only variant
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // -------------------------------------
            // Render State Commands
            Cull Off

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            // -------------------------------------
            // Unity defined keywords
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitMetaPass.hlsl"
            ENDHLSL
        }
    }
}