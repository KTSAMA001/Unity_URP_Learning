Shader "KTSAMA/NPR/Toon"
{
    Properties
    {
        [Enum(Off, 0, Front, 1, Back, 2)]
        _Cull("Cull Mode", Float) = 2.0
        [Toggle]_AlphaTest("AlphaTest",float)=0
        [Toggle]_Screen_Space_HairShadow("屏幕空间头发投影(需要打开SSHSRenderPassFeature)？",float)=0
        [Toggle]_IsFace("IsFace",float)=0
        _FaceRight("_FaceRight",Vector)=(0, -1,0 ,0)
        _FaceForward("_FaceForward",Vector)=(-1, 0,0,0 )
        [Toggle]_IsHair("IsHair",float)=0
        [Toggle]_Depth_Mask_Color_Local("开启深度偏移描边（需要打开SSDepthOffsetPassFeature）？",float)=0
        [Toggle]_Inside_Edge_Albedo_Mul("内轮廓描边与基础颜色相乘？",float)=0
        [Toggle]_Inside_Edge_Screen_Aequilatus("内轮廓描边屏幕像素等宽？",float)=1
        _InsiteEdgeWidth("内轮廓描边宽度",float)=5
        _EdgeColorIntensity("内轮廓描边颜色强度",float)=2
        _DepthMaskColor1("内轮廓描边未描边区域",Color)=(0,0,0,1)
        _DepthMaskColor2("内轮廓描边描边区域",Color)=(1,1,1,1)
        [Toggle]_GetShadow("是否接受阴影？",float)=1
        [MainTexture]_BaseMap("BaseMap",2D)="white"{}
        [HDR]_EmissionColor("EmissionColor",Color)=(0,0,0,1)
        _EmissionMap("EmissionMap",2D)="black"{}
        [HideInInspector]_Metallic("_Metallic",float)=1
        [HideInInspector]_Smoothness("_Smoothness",float)=1
        [HideInInspector]_Cutoff("_Cutoff",float)=1
        [HideInInspector]_FaceShadowPosWS("_FaceShadowPosWS",Vector)=(0,0,0,0)
        _MatCapIntensity("MatCapIntensity",Range(0,1))=1
        _MatCap("MatCap",2D)="black"{}
        _M("M贴图",2D)="black"{}
        _SkinMask("皮肤遮罩",2D)="black"{}
        _RampMap_Skin("RampMap_Skin",2D)="white"{}
        _RampMap_Other("RampMap_Other",2D)="white"{}
        _FaceLightMap("FaceLightMap",2D)="white"{}
        _FaceLightSDF_Offset("FaceLightSDF_Offset",Range(-1,1))=0
        _RampColor_Skin("RampColor_Skin",Color)=(1,1,1,1)
        _RampColor_Other("RampColor_Other",Color)=(1,1,1,1)
        [MainColor]_BaseColor("Color",Color)=(1,1,1,1)
        _EnvColor_Specular("EnvColor",Color)=(1,1,1,1)
        _BumpScale("Scale", Range(-2,2)) = 1.0
        _BumpMap("Normal", 2D) ="bump"{}
        _FaceLightSDF_Add("_FaceLightSDF_Add", float) =0.1

        _HaifHightLight_Bias("HaifHightLight_Bias", float) =0
        _HaifHightLight_Power("HaifHightLight_Power", float) =5
        _HaifHightLight_Scale("HaifHightLight_Scale", float) =1
        _HairShadowDistace("HairShadowDistace", float) =0
        _DebugFloat("_DebugFloat", float) =1
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
        //        Tags
        //        {
        //            "RenderPipeline"="UniversalPipeline" 
        //            "RenderType"="Opaque" 
        //            "Queue"="Geometry" 
        //            "UniversalMaterialType"="lit"
        //        }
        LOD 100
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "LitInput.hlsl"
        #include "Assets/Products/PBR/PBR_Func.hlsl"
         //#pragma shader_feature_local_fragment _ _ISFACE_ON
        // //需要查明 为何是UnityPerMaterial而不是其他名称
        // cbuffer UnityPerMaterial
        // {
        //    
        //    
        // }
        #pragma target 4.5
        #pragma prefer_hlslcc gles
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
            Cull [_Cull]
            HLSLPROGRAM
            #pragma vertex vert
            //#pragma 
            #pragma fragment frag
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma shader_feature_local _ _ALPHATEST_ON
            #pragma shader_feature_local _ _SCREEN_SPACE_HAIRSHADOW_ON
            #pragma shader_feature_local_fragment _ _ISFACE_ON
            #pragma shader_feature_local_fragment _ _ISHAIR_ON
            #pragma shader_feature_local_fragment _ _DEPTH_MASK_COLOR_LOCAL_ON
            #pragma shader_feature_local_fragment _GETSHADOW_ON
            #pragma shader_feature_local_fragment _ _INSIDE_EDGE_ALBEDO_MUL_ON
            #pragma shader_feature_local_fragment _ _INSIDE_EDGE_SCREEN_AEQUILATUS_ON
            #pragma shader_feature _ _DEPTH_MASK_COLOR
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION


            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ADDITIONAL_LIGHTS
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            // ----
          
            TEXTURE2D(_FaceLightMap);       SAMPLER(sampler_FaceLightMap);
            TEXTURE2D(_RampMap_Skin);       SAMPLER(sampler_RampMap_Skin);
            TEXTURE2D(_RampMap_Other);      SAMPLER(sampler_RampMap_Other);
            TEXTURE2D(_SkinMask);           SAMPLER(sampler_SkinMask);
            TEXTURE2D(_MatCap);             SAMPLER(sampler_MatCap);
            TEXTURE2D(_M);                  SAMPLER(sampler_M);
            TEXTURE2D(_HairSoildColor);     SAMPLER(sampler_HairSoildColor);
            TEXTURE2D(_DepthMaskColor);     SAMPLER(sampler_DepthMaskColor);
        
   
            

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
                //世界空间法线
                float3 normalWS : TEXCOORD2;
                //世界空间切线
                float3 tangentWS : TEXCOORD3;
                //世界空间副切线
                float3 bitangentWS : TEXCOORD4;

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
                o.uv = TRANSFORM_TEX(i.uv, _BaseMap);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS);
               
                o.positionWS = positionInputs.positionWS;
                o.positionCS = positionInputs.positionCS;
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                o.normalWS = normalInputs.normalWS;
                o.bitangentWS = normalInputs.bitangentWS;
                o.tangentWS = normalInputs.tangentWS;
                o.color = i.color;
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION || _SCREEN_SPACE_HAIRSHADOW_ON||_DEPTH_MASK_COLOR
                o.screenPos=ComputeScreenPos(positionInputs.positionCS);
                o.posNDCw= positionInputs.positionNDC.w;
                #endif
                return o;
            }

            float3 GGXSpecular(float3 albedo, float shadow, Light lightData, float3 N, float3 V, float metallic,
                float roughness, float mask_skin, float mask_hait_HightLight = 1)
            {
                float3 L = normalize(lightData.direction);
                float3 F0 = lerp(0.04, albedo, metallic);
                float3 H = normalize(V + L);
                float NV = saturate(dot(N, V));
                float NL = saturate(dot(N, L));
                float D = D_DistributionGGX(N, H, roughness);
                float G = G_GeometrySmith_Direct_Light(N, V, L, roughness);
                float3 F = F_FrenelSchlick(NV, F0);
                float2 uv_rampNL = float2(0.5, NL * shadow);
                float3 kd = (1 - F)*(1-metallic) ;
                float3 rampMap_otherNL = SAMPLE_TEXTURE2D(_RampMap_Other, sampler_RampMap_Other, uv_rampNL);
                float3 rampMap_skinNL = SAMPLE_TEXTURE2D(_RampMap_Skin, sampler_RampMap_Skin, uv_rampNL);
                float3 final_other=0;
                #ifdef _ISHAIR_ON
                 float3 specular=pow(NV+_HaifHightLight_Bias,_HaifHightLight_Power)*_HaifHightLight_Scale*mask_hait_HightLight*NL*shadow;
                 specular= saturate(specular);
                 final_other = (rampMap_otherNL + specular + mask_hait_HightLight * NL * 0.5*max(0.2,shadow)) * albedo;
                // return specular;
                #else
                // float3 specular = pow(saturate(dot(H,N)),5)*1*mask_specular;
                float3 specular = (D * G * F) / (4 * max((NV * NL), 0.000001));
                 final_other = (rampMap_otherNL + specular ) * albedo;
                // return final_other;
                #endif


                


                final_other = lerp(final_other * _RampColor_Other, final_other, NL) * (1 - mask_skin);

                float3 final_skin = (rampMap_skinNL + specular) * albedo;
                final_skin = lerp(final_skin * _RampColor_Skin, final_skin, NL) * (mask_skin);
                float3 col_final = (final_other + final_skin) * lightData.color;

                //return 0;
                return col_final;
            }

            float3 GGXSpecular_Env(float3 albedo, float3 N, float3 V, float metallic, float roughness,
         float mask_hait_HightLight = 1)
            {
                float NV = saturate(dot(N, V));

                float3 F0 = lerp(0.04, albedo, metallic);
                float3 F = FresnelSchlickRoughness(NV, F0, roughness);
                float3 kd = (1 - F);
                //获取当前视角反射
                float3 reflectDirWS = reflect(-V, N);

                //数值近似
                float2 env_brdf = EnvBRDFApprox(roughness, NV);

                float mip = roughness * (1.7 - 0.7 * roughness) * UNITY_SPECCUBE_LOD_STEPS;
                //读取反射探针贴图
                // float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap, sampler_GlossyEnvironmentCubeMap,reflectDirWS, mip);
                float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS,
       mip);

                //间接光镜面反射采样的预过滤环境贴图
                //float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,_GlossyEnvironmentCubeMap_HDR);
                // float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,unity_SpecCube0_HDR);
                //float3 diffuse_col_InDirect = SampleSH(N)*albedo*kd;
                float3 diffuse_col_InDirect = SampleSH(N) * albedo * kd;

                // float3 specular_InDirect =  EnvSpecularPrefilted*(F * env_brdf.r + env_brdf.g);

                #ifdef _ISHAIR_ON
                  float3 specular_InDirect =  _EnvColor_Specular*(F * env_brdf.r + env_brdf.g)*0.2*mask_hait_HightLight;
                #else
                // float3 specular = pow(saturate(dot(H,N)),5)*1*mask_specular;
                float3 specular_InDirect = _EnvColor_Specular * (F * env_brdf.r + env_brdf.g);
                #endif

                // diffuse_col_InDirect=clamp(0,.3,pow(diffuse_col_InDirect,1));
                // specular_InDirect=clamp(0,0.3,pow(specular_InDirect,1));
                //return 0;
                return (diffuse_col_InDirect);
            }

            float4 frag(VertexOutput i, float face:VFACE): SV_Target
            {
                //return i.color.r;
                float4 normalTXS = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv);
                float4 normalPacked = normalize(float4(normalTXS.xy, 1, 0));

                //贴图颜色 0~1 转 -1~1并且缩放法线强度
                //  float3 normalTS = UnpackNormalScale(normalPacked, _BumpScale);
                float3 normalTS = 0;

                normalTS.xy = normalPacked.rg * 2.0 - 1.0;
                normalTS.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy))));

                normalTS.xy *= _BumpScale;

                float3 normalWS = normalize(
                    TransformTangentToWorld(normalTS,real3x3(i.tangentWS, i.bitangentWS, i.normalWS)));
              // return pow(saturate(dot(normalWS,TransformObjectToWorld(float3(0,1,0)))*float4(0,1,0,1)),_DebugFloat);
//return float4(normalWS,1);
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv)*_BaseColor;
                //m.r是金属度
                //m.b目前定为用作MatCap的mask
                //m.g暂定为光滑度
                float4 m = SAMPLE_TEXTURE2D(_M, sampler_M, i.uv);
                float mask_skin = SAMPLE_TEXTURE2D(_SkinMask, sampler_SkinMask, i.uv).r;
               #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION|| _SCREEN_SPACE_HAIRSHADOW_ON||_DEPTH_MASK_COLOR
                i.shadowCoord_Screen=ASE_ComputeGrabScreenPos(i.screenPos);
                
                i.shadowCoord_Screen=i.shadowCoord_Screen/i.shadowCoord_Screen.w;
                #endif

       
                //放入光照数据
                Light light_main = GetMainLight();
                #ifdef _ISFACE_ON
                float4 shadow_coord_Main = TransformWorldToShadowCoord(_FaceShadowPosWS);
                #else
                   //当前模型接收阴影
                float4 shadow_coord_Main = TransformWorldToShadowCoord(i.positionWS);
                #endif
                
             
                //阴影数据
                half shadow_main = 1;
                #ifdef _GETSHADOW_ON
                  //如此使用则可以让主光源使用屏幕空间阴影
                #if _MAIN_LIGHT_SHADOWS_SCREEN
                shadow_main=SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, i.shadowCoord_Screen.xy);
                #else
                //测试发现下面两种获取主光源阴影的结果没什么区别，
                //唯一的区别就是定义使用MainlightData.shadowAttenuation的时候必须使用下面的方式获取主光源：
                //Light MainlightData = GetMainLight(shadow_coord_Main);
                //shadow_main= MainlightData.shadowAttenuation;
                //而 MainLightRealtimeShadow(shadow_coord_Main)的方式并不需要，更加方便。
                shadow_main = MainLightRealtimeShadow(shadow_coord_Main);
                shadow_main = saturate(shadow_main);
                #endif
                #endif
                
              


             //   float3 rightDirWS = TransformObjectToWorldDir(float3(0, -1,0 ));
             //   float3 lightDirWS = light_main.direction;
             //   float3 forwardDirWS = TransformObjectToWorldDir(float3(-1, 0,0 ));

                
                float3 rightDirWS =_FaceRight;
                float3 lightDirWS = light_main.direction;
                float3 forwardDirWS = _FaceForward;
            //    return float4(_FaceForward.xyz,1);
                //--控制面捕SDF跟随主光源方向进行变化
                //float FL_step = step(0, dot(lightDirWS, forwardDirWS));
                float FL_step = smoothstep(0,0.2,max(0, dot(lightDirWS, forwardDirWS)));
               // return FL_step;
                // FL_step=1;
                float faceNL = dot(lightDirWS, rightDirWS) ;
                //-----------
               // return faceNL;
                //return normalTXS.a;
                //faceLightmap.b高光mask通道
                float4 faceLightmap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap,
                float2(step(faceNL,0.0)*i.uv.x+step(0.0,faceNL)*(1-i.uv.x),i.uv.y));

                //NL=floor(NL*4)/4;
                float3 viewDirWS = normalize(GetWorldSpaceViewDir(i.positionWS));
                float3 final_color = 0;
                //Env
                float3 env_col = 0;
                float3 specular = 0;

                //MatCap
                float3 normalVS = TransformWorldToViewNormal(normalWS);
                float2 uv_matCap = normalVS + 0.5;
                float3 matCap = 0;
                //菲涅尔边缘光在这里效果不佳，考虑是否移除
                float frenal=0;
                // return specular;
                //return float4(normalWS,1);
                #ifdef  _ISFACE_ON
               //float l=saturate((faceLightmap.r+faceLightmap.g+faceLightmap.b*0.1)*0.5-_FaceLightSDF_Offset);
                normalTXS.a=0;
                normalTXS.b=0.5;
                m.r=192.0/255;
                m.b=25.0/255;
                float abs_value=abs(faceNL);
                abs_value=abs_value*abs_value;
                //return abs_value;
                float l=smoothstep(abs_value,abs_value+0.2,(faceLightmap.r+faceLightmap.g)*0.5)*FL_step;
                //return l;
                //float l2=smoothstep(_FaceLightSDF_Offset,_FaceLightSDF_Offset,faceLightmap.g);
                //return l;
                float2 uv_ramp=float2(0.5,l);
                float4 rampMap_skin=SAMPLE_TEXTURE2D(_RampMap_Skin,sampler_RampMap_Skin,uv_ramp);
                //return rampMap_skin*col;
                float3 final=rampMap_skin*albedo*light_main.color;
                float4 ssHairShadowMap=1;
                float ssHairShadow=1;
                //参考文章：https://zhuanlan.zhihu.com/p/232450616
                #ifdef _SCREEN_SPACE_HAIRSHADOW_ON
                
                float4 scaledScreenParams = GetScaledScreenParams();
                //使用i.posNDCw的目的是防止因为距离造成的离得越远头发投影越大的问题
                float3 viewLightDir = normalize(TransformWorldToViewDir(light_main.direction)) * (1 / i.posNDCw) ;
                //此处固定为1920*1080的屏幕为标准来偏移屏幕空间的头发投影，如果使用屏幕实际分辨率的话，因为移动的是实际的像素数量，所以会导致不同分辨率下结果不同（偏移距离不同的问题）
                //float2 samplingPoint = i.shadowCoord_Screen.xy + _HairShadowDistace * viewLightDir.xy * float2(1 / scaledScreenParams.x, 1 / scaledScreenParams.y);
                float2 samplingPoint = i.shadowCoord_Screen.xy + _HairShadowDistace * viewLightDir.xy * float2(1.0/ 1920.0,1.0/ 1080.0);
                //在Light Dir的基础上乘以NDC.w的倒数以修正摄像机距离所带来的变化
            
                ssHairShadowMap=SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint);
                ssHairShadow=1-ssHairShadowMap.r;
                  float depth=(i.positionCS.z / i.positionCS.w) * 0.5 + 0.5;
                float hairDepth=ssHairShadowMap.g;
                ssHairShadow=lerp(1,ssHairShadow,step(depth,hairDepth+0.02))*(1-smoothstep(0.6,0.8,(i.uv.y)));
                #endif
                final_color= lerp(final*_RampColor_Skin,final,l*ssHairShadow*shadow_main);
                
                #else
  
                matCap =max(shadow_main,0.5)* SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, uv_matCap)*_MatCapIntensity*dot(normalWS,light_main.direction)*light_main.color;

                
                //PBR GGX高光
                #ifdef  _ISHAIR_ON
                env_col = GGXSpecular_Env(albedo,normalWS,viewDirWS,m.r,saturate(1-m.g),m.b)*(1-mask_skin);
                final_color=GGXSpecular(albedo,shadow_main,light_main,normalWS,viewDirWS,m.r,saturate(1-m.g),mask_skin,m.b);
                matCap=0;
               
                // return 0.5;
                // return float4(final_color,1);
                #else
                frenal=(1-saturate(pow(dot(viewDirWS,normalWS),6)*70))*light_main.color*lerp(0.3,0.1,shadow_main); 
                // return frenal;
                env_col = GGXSpecular_Env(albedo, normalWS, viewDirWS, m.r, saturate(1 - m.g), 1) * (1 - mask_skin);
                final_color = GGXSpecular(albedo, shadow_main, light_main, normalWS, viewDirWS, m.r, saturate(1 - m.g),  mask_skin, 0);

                //让金属部分更多的只被MatCap影响 
                final_color*=(1-m.b);
                matCap *= saturate(m.b);
                #endif
//return float4(final_color,1);
              // return (1-m.b);
                #endif

                
             
                final_color += matCap;
                final_color += specular + env_col;
                final_color *= light_main.color;
                //屏幕空间的指定物体画纯色（SSDepthOffsetPassFeature配合使用），偏移后当作背景阴影使用
              
                #ifdef _DEPTH_MASK_COLOR
                #ifdef _DEPTH_MASK_COLOR_LOCAL_ON
                float depthOffset1=1;
                float depthOffset2=1;
                float depthOffset3=1;
                float depthOffset4=1;
                float final_depthoffset=1;
                float3 depthColor=1;
                //使用i.posNDCw的目的是防止因为距离造成的离得越远头发投影越大的问题
                #ifdef _INSIDE_EDGE_SCREEN_AEQUILATUS_ON
                float2 f=float2(1.0/ 1920.0,1.0/ 1080.0);
                #else
                float2 f=float2(1.0/ 1920.0,1.0/ 1080.0)* (1 / i.posNDCw);
                #endif
              
               // depthOffset  =1-SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy*0.8+(1-0.8)/2+ _DepthOffset*float2(1.0/ 1920.0,1.0/ 1080.0)* (1 / i.posNDCw)).r;
                depthOffset1  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy+ _InsiteEdgeWidth*float2(1,-1)*f).r;
                depthOffset2  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy+ _InsiteEdgeWidth*float2(-1,1)*f).r;
                depthOffset3  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy+ _InsiteEdgeWidth*float2(1,1)*f).r;
                depthOffset4  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy+ _InsiteEdgeWidth*float2(-1,-1)*f).r;
              
                final_depthoffset=1-min(depthOffset1, min(depthOffset2, min(depthOffset3,depthOffset4)));
                 //return final_depthoffset;
                depthColor=lerp(_DepthMaskColor1,_DepthMaskColor2,final_depthoffset);
                //这种做法就是直接把偏移的部分扣掉，实心颜色
                //final_color*=1-depthOffset1;
                 final_color*=1-final_depthoffset;
               
                #ifdef _INSIDE_EDGE_ALBEDO_MUL_ON
               
                final_color+=depthColor*albedo*_EdgeColorIntensity;
                #else
                 final_color+=depthColor*_EdgeColorIntensity;
                #endif
                //这种做法就是叠加颜色
                //final_color*=depthColor;
               
                #endif
                #endif
              
                //return m.r;
                //normalTXS.a暂定为类似高光的通道
                //normalTXS.b暂定为类似AO的通道
                normalTXS.b += 0.5;
                //return float4(i.tangentWS,1);
           
float3 emission=SAMPLE_TEXTURE2D(_EmissionMap,sampler_EmissionMap,i.uv)*_EmissionColor*light_main.color;
                return float4((final_color+(frenal*albedo)) * normalTXS.b+emission, 1);

                //return float4(matCap,1)*normalTXS.a;
                //return normalTXS.b;
                return float4(normalWS, 1);
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
           
            
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

// Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
// For Directional lights, _LightDirection is used when applying shadow Normal Bias.
// For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
float3 _LightDirection;
float3 _LightPosition;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    #if defined(_ALPHATEST_ON)
        float2 uv       : TEXCOORD0;
    #endif
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 GetShadowPositionHClip(Attributes input)
{
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    #if defined(_ALPHATEST_ON)
        output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    #endif




      output.positionCS = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);

    #if defined(_ALPHATEST_ON)
        Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    #endif

    #if defined(LOD_FADE_CROSSFADE)
        LODFadeCrossFade(input.positionCS);
    #endif

    return 0;
}

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
}