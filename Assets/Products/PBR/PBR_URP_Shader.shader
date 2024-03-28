Shader "KTSAMA/URP/PBR_URP_Shader"
{
    //面板属性
    Properties
    {
        [Enum(Off, 0, Front, 1, Back, 2)]
        _Cull("Cull Mode", Float) = 2.0
        //基础颜色
        [MainColor]_Color("基础颜色", Color) = (1,1,1,1)
        //纹理贴图
        [MainTexture]_MainTex ("主贴图", 2D) = "white" {}
        _EmissionIntensity ("自发光强度", float) = 1
        _EmissionMap ("自发光", 2D) = "black" {}

        

        //法线贴图
        _NormalTex("法线贴图", 2D) = "bump" {}
        //法线强度
        _NormalScale("法线强度", Float) = 1.0
        _Roughness("Roughness", Range(0.0, 1.0)) = 0.5
        [ToggleOff] _Inv_Roughness("Inv_Roughness", Float) = 0.0
        _RoughnessMap("RoughnessMap",2D) = "White" {}

        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicMap("Metallic", 2D) = "white" {}
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

    }
    SubShader
    {
          Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }
        LOD 100
        HLSLINCLUDE
        #pragma target 4.5
        #pragma prefer_hlslcc gles
        #pragma multi_compile_instancing
        #pragma instancing_options renderinglayer
        float _Cull;
        ENDHLSL
        Pass
        {
            Cull [_Cull]
               Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex vert
            //#pragma 
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "PBR_Func.hlsl"
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ADDITIONAL_LIGHTS
            #pragma shader_feature _INV_ROUGHNESS_OFF
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
            // 常量缓冲区的定义，GPU现在里面某一块区域，这一块区域可以非常快速的和GPU传输数据
            // 因为要占GPU显存，所以其容量不是很大。
            // CBUFFER_START = 常量缓冲区的开始，CBUFFER_END = 常量缓冲区的结束。
            // UnityPerMaterial = 每一个材质球都用这一个Cbuffer，凡是在Properties里面定义的数据(Texture除外)
            // 都需要在常量缓冲区进行声明，并且都用这一个Cbuffer，通过这些操作可以享受到SRP的合批功能
            CBUFFER_START(UnityPerMaterial)
                //变量引入开始
                //获取属性面板颜色
                float4 _Color;
                float _NormalScale;
                float _Roughness;
                float _Metallic;
                float _OcclusionStrength;
                float _Inv_Roughness;
                float _EmissionIntensity;
            CBUFFER_END //变量引入结束
            //获取面板纹理
            TEXTURE2D(_MainTex);
            TEXTURE2D(_MetallicMap);
            TEXTURE2D(_RoughnessMap);
            TEXTURE2D(_OcclusionMap);
            TEXTURE2D(_EmissionMap);
            //获取贴图的偏移与重复
            SAMPLER(sampler_MainTex);
            SAMPLER(sampler_MetallicMap);
            SAMPLER(sampler_RoughnessMap);
            SAMPLER(sampler_OcclusionMap);
            SAMPLER(sampler_EmissionMap);
            //获取面板纹理
            TEXTURE2D(_NormalTex);
            //获取贴图的偏移与重复
            SAMPLER(sampler_NormalTex);

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
                UNITY_VERTEX_INPUT_INSTANCE_ID
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
                //世界空间法线
                float3 normalWS : TEXCOORD2;
                //世界空间切线
                float3 tangentWS : TEXCOORD3;
                //世界空间副切线
                float3 bitangentWS : TEXCOORD4;
                float4 screenPos:TEXCOORD5;
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION
                 float4 shadowCoord_Screen:TEXCOORD10;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert(VertexInput i, uint instanceID : SV_InstanceID)
            {
                VertexOutput o ;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                //输入物体空间顶点数据
                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
                //获取裁切空间顶点
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                float4 ase_clipPos = TransformObjectToHClip((i.positionOS).xyz);
                o.screenPos = ComputeScreenPos(ase_clipPos);
                //输入物体空间法线数据
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                //获取世界空间法线
                o.normalWS = normalInputs.normalWS;
                //获取世界空间顶点
                o.tangentWS = normalInputs.tangentWS;
                //获取世界空间顶点
                o.bitangentWS = normalInputs.bitangentWS;
                //传递法线变量
                o.uv = i.uv;

                //输出数据
                return o;
            }


            //表面程序片段
            float4 frag(VertexOutput i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                //------法线贴图转世界法线--------
                //载入法线贴图
                float4 normalTXS = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);

                //贴图颜色 0~1 转 -1~1并且缩放法线强度
                float3 normalTS = UnpackNormalScale(normalTXS, _NormalScale);

                //贴图法线转换为世界法线
                half3 normalWS = TransformTangentToWorld(normalTS,real3x3(i.tangentWS, i.bitangentWS, i.normalWS));
                normalWS = normalize(normalWS);
                //获取纹理 = 纹理载入（纹理变量，纹理重复，UV坐标）
                float4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                //albedo=pow(albedo,2.2);
                float metallic = SAMPLE_TEXTURE2D(_MetallicMap, sampler_MetallicMap, i.uv).r;
                float ao = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, i.uv).r;
                float3 emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, i.uv).rgb * _EmissionIntensity;

                float ssao = 1;
                ao = lerp(1.0, ao, _OcclusionStrength);

                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION
                 i.shadowCoord_Screen=ASE_ComputeGrabScreenPos(i.screenPos);
                
                i.shadowCoord_Screen=i.shadowCoord_Screen/i.shadowCoord_Screen.w;
                #endif

                #if  _SCREEN_SPACE_OCCLUSION


                 //ssao= SampleAmbientOcclusion( i.shadowCoord_Screen.xy);
                ssao= GetScreenSpaceAmbientOcclusion( i.shadowCoord_Screen.xy).directAmbientOcclusion;
                #endif


                metallic *= _Metallic;
                float roughness = 0.5;
                #if defined(_INV_ROUGHNESS_OFF)
                 roughness= 1 -SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.uv).r;
                #else
                roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.uv).r;
                #endif

                roughness = lerp(0, _Roughness, roughness);


                float3 N = normalWS;
                float3 V = normalize(GetWorldSpaceViewDir(i.positionWS));
                //-----------阴影数据--------------
                //当前模型接收阴影
                float4 shadow_coord_Main = TransformWorldToShadowCoord(i.positionWS);
                //放入光照数据
                Light MainlightData = GetMainLight();
                //阴影数据
                half shadow_main = 0;
                //如此使用则可以让主光源使用屏幕空间阴影
                #if _MAIN_LIGHT_SHADOWS_SCREEN
                shadow_main=SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_MainTex, i.shadowCoord_Screen.xy);
                #else
                //测试发现下面两种获取主光源阴影的结果没什么区别，
                //唯一的区别就是定义使用MainlightData.shadowAttenuation的时候必须使用下面的方式获取主光源：
                //Light MainlightData = GetMainLight(shadow_coord_Main);
                //shadow_main= MainlightData.shadowAttenuation;
                //而 MainLightRealtimeShadow(shadow_coord_Main)的方式并不需要，更加方便。
                shadow_main = MainLightRealtimeShadow(shadow_coord_Main);
                shadow_main = saturate(shadow_main);
                #endif

                //光照渐变
                //diffuse_main=GetNL(normalWS, MainlightData)*shadow_main;
                float4 col_main = 0;
                col_main.a = 1;
                float4 col_add = 0;
                col_add.a = 1;


                col_main.rgb = (PBR_Direct_Light(albedo.rgb, MainlightData, N, V, metallic, roughness, ao) * shadow_main
                    + PBR_InDirect_Light(albedo.rgb * _Color.rgb, N, V, metallic, roughness, ao));

                //GlobalIllumination()
                float shadow_add = 0;
                float distanceAttenuation_add = 0;
                #if _ADDITIONAL_LIGHTS
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int lightIndex = 0; lightIndex < additionalLightsCount; ++lightIndex)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS, half4(1, 1, 1, 1));
                    distanceAttenuation_add += additionalLight.distanceAttenuation;
                    shadow_add = additionalLight.shadowAttenuation * additionalLight.distanceAttenuation;
                    col_add.rgb += PBR_Direct_Light(albedo.rgb, additionalLight, N, V, metallic, roughness, ao) *
                        shadow_add;

                    //*additionalLight.shadowAttenuation*shadow_add;

                    // return additionalLight.direction.xyzz;
                    //col_add.rgb=saturate(shadow_add)*distanceAttenuation_add;
                }


                #endif
                //float diffuse_final=diffuse_add+diffuse_main;


                float4 col_final = 0;

                //col_final.rgb =  (col_add+col_main)+ _GlossyEnvironmentColor.rgb;
                col_final.rgb = (col_add.rgb + col_main.rgb) + emission;


                //光照着色
                //col_final.rgb *= _Color.rgb;

                //透明度混合
                //col_final.a += albedo.a;

                //clip(col_final.a - 0.5);
                //输出颜色

                //return   shadow_main;
                //return   SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_MainTex, i.shadowCoord_Screen.xy);
                //col_final=pow(col_final,1/2.2);
                //return ACESToneMapping(col_final);
                //return float4(i.shadowCoord_Screen.xy,0,1);
                return col_final * ssao;
            }
            ENDHLSL
        }
  Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite[_ZWrite]
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 4.5

            // Deferred Rendering Path does not support the OpenGL-based graphics API:
            // Desktop OpenGL, OpenGL ES 3.0, WebGL 2.0.
            #pragma exclude_renderers gles3 glcore

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitGBufferPassVertex
            #pragma fragment LitGBufferPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED

            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitGBufferPass.hlsl"
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
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Universal Pipeline keywords
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
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
            #pragma fragment UniversalFragmentMetaLit

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SPECGLOSSMAP
            #pragma shader_feature EDITOR_VISUALIZATION

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "Universal2D"
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // -------------------------------------
            // Render State Commands
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }
       
    }

    FallBack "KTSAMA/ErrorShader"

}