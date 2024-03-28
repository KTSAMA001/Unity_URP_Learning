Shader "KTSAMA/URP/PBRGrass_URP_Shader"
{
    //面板属性
    Properties
    {
        [Enum(Off, 0, Front, 1, Back, 2)]
        _Cull("Cull Mode", Float) = 2.0
        _NoiseSmoothnessMin("NoiseSmoothnessMin",float)=0
        _NoiseSmoothnessMax("NoiseSmoothnessMax",float)=1
        _NoiseScale("NoiseScale",Vector)=(1,1,1,1)
        _NoiseOffset("NoiseOffset",Vector)=(0,0,0,0)
        _HeightOffset_BaseColor2("基础颜色2的高度偏移",float)=1
        //基础颜色
        [MainColor]_BaseColor("基础颜色", Color) = (1,1,1,1)
        _BaseColor2("基础颜色2", Color) = (1,1,1,1)
        //纹理贴图
        [MainTexture]_BaseMap ("主贴图", 2D) = "white" {}
        _EmissionIntensity ("自发光强度", float) = 1
        _EmissionMap ("自发光", 2D) = "black" {}
        [Toggle]_AlphaTest("AlphaTest",float)=1

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        _NormalLetp("法线向上的分布", Range(0.0, 1.0)) = 1.0
        //法线强度
        _NormalScale("法线强度", Float) = 1.0
        //法线贴图
        _NormalTex("法线贴图", 2D) = "bump" {}

        _Roughness("Roughness", Range(0.0, 1.0)) = 0.5
        [ToggleOff] _Inv_Roughness("Inv_Roughness", Float) = 0.0
        _RoughnessMap("RoughnessMap",2D) = "White" {}

        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicMap("Metallic", 2D) = "white" {}
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}


        [Header(Wind)]
        _WindAIntensity("_WindAIntensity", Float) = 1.77
        _WindAFrequency("_WindAFrequency", Float) = 4
        _WindATiling("_WindATiling", Vector) = (0.1,0.1,0)
        _WindAWrap("_WindAWrap", Vector) = (0.5,0.5,0)

        _WindBIntensity("_WindBIntensity", Float) = 0.25
        _WindBFrequency("_WindBFrequency", Float) = 7.7
        _WindBTiling("_WindBTiling", Vector) = (.37,3,0)
        _WindBWrap("_WindBWrap", Vector) = (0.5,0.5,0)


        _WindCIntensity("_WindCIntensity", Float) = 0.125
        _WindCFrequency("_WindCFrequency", Float) = 11.7
        _WindCTiling("_WindCTiling", Vector) = (0.77,3,0)
        _WindCWrap("_WindCWrap", Vector) = (0.5,0.5,0)


    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="lit"
        }
        LOD 100
        HLSLINCLUDE
        #pragma target 4.5
        #pragma prefer_hlslcc gles
        #pragma instancing_options renderinglayer


        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "GrassLitInput.hlsl"
        float3 mod3D289(float3 x) { return x - floor(x / 289.0) * 289.0; }
        float4 mod3D289(float4 x) { return x - floor(x / 289.0) * 289.0; }
        float4 permute(float4 x) { return mod3D289((x * 34.0 + 1.0) * x); }
        float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - r * 0.85373472095314; }
      float3 RotateVector(float3 v, float3 axis, float angle)
{
    float angleRad = radians(angle);
    float c = cos(angleRad);
    float s = sin(angleRad);
    float3x3 rotationMatrix = float3x3(
        c + (1 - c) * axis.x * axis.x,
        (1 - c) * axis.x * axis.y - s * axis.z,
        (1 - c) * axis.x * axis.z + s * axis.y,
        (1 - c) * axis.y * axis.x + s * axis.z,
        c + (1 - c) * axis.y * axis.y,
        (1 - c) * axis.y * axis.z - s * axis.x,
        (1 - c) * axis.z * axis.x - s * axis.y,
        (1 - c) * axis.z * axis.y + s * axis.x,
        c + (1 - c) * axis.z * axis.z
    );

    return mul(rotationMatrix, v);
}

           float3 GetPivotPos(uint instanceID)
        {
            float3 pivotPosWS = float3(_GrassInfoBuffer[instanceID].TRS[0].w, _GrassInfoBuffer[instanceID].TRS[1].w,
            _GrassInfoBuffer[instanceID].TRS[2].w);
            pivotPosWS = mul(_PivotTRS, float4(pivotPosWS, 1));
            return pivotPosWS;
        }
 
        float4 GetInstanceGrassWorldPos(float4 posOS, uint instanceID)
        {
            float3 pivotPosWS=GetPivotPos(instanceID);
            float4x4 m=mul(_PivotTRS,_GrassInfoBuffer[instanceID].TRS);
            float3 playerPosOS=mul(Inverse(m),float4(_PlayerPos,1));
            float3 pivotPosOS=mul(Inverse(m),float4(pivotPosWS,1));
            float3 upDirOS=float4(0,1,0,0);
            float3 toPosDirOS=normalize(pivotPosOS.xyz-playerPosOS);
            float3 rotateAxis=normalize(cross(upDirOS,toPosDirOS));
          
            //float3 heightFixDirOS=normalize()
            float mask=1-smoothstep(0.5,1,saturate(distance(_PlayerPos,pivotPosWS.xyz)-0.5));
                posOS.xyz=RotateVector(posOS,rotateAxis,80*mask);
            //posOS.xyz+=toPosDirWS*1*mask;
            float4 positionWS = mul(m , posOS);
            positionWS /= positionWS.w;
          
               
          
            return positionWS;
        }

        float4 GetWindGrassWorldPos(float4 posOS, float4 posWS)
        {
            float3 cameraTransformRightWS = UNITY_MATRIX_V[0].xyz;
            //UNITY_MATRIX_V[2].xyz == -1 * world space camera Forward unit vector
            float wind = 0;
            wind += (sin(_Time.y * _WindAFrequency + posWS.x * _WindATiling.x + posWS.z * _WindATiling.y) *
                _WindAWrap.x + _WindAWrap.y) * _WindAIntensity; //windA
            wind += (sin(_Time.y * _WindBFrequency + posWS.x * _WindBTiling.x + posWS.z * _WindBTiling.y) *
                _WindBWrap.x + _WindBWrap.y) * _WindBIntensity; //windB
            wind += (sin(_Time.y * _WindCFrequency + posWS.x * _WindCTiling.x + posWS.z * _WindCTiling.y) *
                _WindCWrap.x + _WindCWrap.y) * _WindCIntensity; //windC
            wind *= posOS.y; //wind only affect top region, don't affect root region
            float3 windOffset = cameraTransformRightWS * wind; //s
           posWS.xyz += windOffset;
            return posWS;
        }

        float snoise(float3 v)
        {
            const float2 C = float2(1.0 / 6.0, 1.0 / 3.0);
            float3 i = floor(v + dot(v, C.yyy));
            float3 x0 = v - i + dot(i, C.xxx);
            float3 g = step(x0.yzx, x0.xyz);
            float3 l = 1.0 - g;
            float3 i1 = min(g.xyz, l.zxy);
            float3 i2 = max(g.xyz, l.zxy);
            float3 x1 = x0 - i1 + C.xxx;
            float3 x2 = x0 - i2 + C.yyy;
            float3 x3 = x0 - 0.5;
            i = mod3D289(i);
            float4 p = permute(
           permute(permute(i.z + float4(0.0, i1.z, i2.z, 1.0)) + i.y + float4(0.0, i1.y, i2.y, 1.0)) + i.x +
            float4(0.0, i1.x, i2.x, 1.0));
            float4 j = p - 49.0 * floor(p / 49.0); // mod(p,7*7)
            float4 x_ = floor(j / 7.0);
            float4 y_ = floor(j - 7.0 * x_); // mod(j,N)
            float4 x = (x_ * 2.0 + 0.5) / 7.0 - 1.0;
            float4 y = (y_ * 2.0 + 0.5) / 7.0 - 1.0;
            float4 h = 1.0 - abs(x) - abs(y);
            float4 b0 = float4(x.xy, y.xy);
            float4 b1 = float4(x.zw, y.zw);
            float4 s0 = floor(b0) * 2.0 + 1.0;
            float4 s1 = floor(b1) * 2.0 + 1.0;
            float4 sh = -step(h, 0.0);
            float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
            float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
            float3 g0 = float3(a0.xy, h.x);
            float3 g1 = float3(a0.zw, h.y);
            float3 g2 = float3(a1.xy, h.z);
            float3 g3 = float3(a1.zw, h.w);
            float4 norm = taylorInvSqrt(float4(dot(g0, g0), dot(g1, g1), dot(g2, g2), dot(g3, g3)));
            g0 *= norm.x;
            g1 *= norm.y;
            g2 *= norm.z;
            g3 *= norm.w;
            float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
            m = m * m;
            m = m * m;
            float4 px = float4(dot(x0, g0), dot(x1, g1), dot(x2, g2), dot(x3, g3));
            return 42.0 * dot(m, px);
        }

     
     

        float GetLerpValue(float3 pivotPosWS)
        {//
            return saturate(smoothstep(_NoiseSmoothnessMin,_NoiseSmoothnessMax,snoise(_NoiseScale * mul(Inverse(_PivotTRS),pivotPosWS-mul(unity_ObjectToWorld,float4(0,0,0,1)))+_NoiseOffset)));
        }
        //         // 定义一个宏函数，接受一个参数 instanceID,修改草的高度
        //       #define KTSAMA_GRASS_HIGHT_OFFSET_LERP_VALUE(instanceID, uv) \
        //            float3 pivotPosWS = float3(_GrassInfoBuffer[instanceID].TRS[0].w, _GrassInfoBuffer[instanceID].TRS[1].w, _GrassInfoBuffer[instanceID].TRS[2].w); \
        //            pivotPosWS = mul(_PivotTRS, float4(pivotPosWS, 1)); \
        //            o.colorGradientLrapValue = saturate(snoise(_NoiseScale * pivotPosWS)); \
        //            i.positionOS.y += o.colorGradientLrapValue * 0.2f * SAMPLE_TEXTURE2D_GRAD(_MaskHeightOffsetMap,sampler_MaskHeightOffsetMap,uv,0,0).r;
        //            
        ENDHLSL
        //UniversalForward
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Products/PBR/PBR_Func.hlsl"
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ADDITIONAL_LIGHTS
            #pragma shader_feature _INV_ROUGHNESS_OFF
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            // -------------------------------------

            // 常量缓冲区的定义，GPU现在里面某一块区域，这一块区域可以非常快速的和GPU传输数据
            // 因为要占GPU显存，所以其容量不是很大。
            // CBUFFER_START = 常量缓冲区的开始，CBUFFER_END = 常量缓冲区的结束。
            // UnityPerMaterial = 每一个材质球都用这一个Cbuffer，凡是在Properties里面定义的数据(Texture除外)
            // 都需要在常量缓冲区进行声明，并且都用这一个Cbuffer，通过这些操作可以享受到SRP的合批功能
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
                float4 positionWS : TEXCOORD1;
                //世界空间法线
                float3 normalWS : TEXCOORD2;
                //世界空间切线
                float3 tangentWS : TEXCOORD3;
                //世界空间副切线
                float3 bitangentWS : TEXCOORD4;
              
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION
                 float4 screenPos:TEXCOORD5;
                 float4 shadowCoord_Screen:TEXCOORD6;
                #endif
                half colorGradientLrapValue:TEXCOORD7;
                float3 normalWS_Terrain:TEXCOORD9;
                float3 viewDirWS:TEXCOORD10;
                float3 toPivotDirWS:TEXCOORD11;
            };

            VertexOutput vert(VertexInput i, uint instanceID : SV_InstanceID)
            {
                VertexOutput o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                //输入物体空间顶点数据
                // VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
                //rotation(make grass LookAt() camera just like a billboard)
                //=========================================
                // KTSAMA_GRASS_HIGHT_OFFSET_LERP_VALUE(instanceID,i.uv)
                float3 pivotPosWS = GetPivotPos(instanceID);
                o.colorGradientLrapValue = GetLerpValue(pivotPosWS);

                i.positionOS.y  =i.positionOS.y  + (_HeightOffset_BaseColor2*i.positionOS.y)* o.colorGradientLrapValue;
                // o.positionWS = positionInputs.positionWS;
                o.positionWS = GetInstanceGrassWorldPos(i.positionOS, instanceID)/*+ float4(_OffsetPos, 0)*/;


                o.positionWS = GetWindGrassWorldPos(i.positionOS, o.positionWS);
               
                o.viewDirWS=normalize(GetWorldSpaceViewDir( o.positionWS));
                float4 ase_clipPos = TransformWorldToHClip((o.positionWS.xyz));
                  #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION
                 o.screenPos = ComputeScreenPos(ase_clipPos);
                #endif
                
               
                //获取裁切空间顶点
                o.positionCS = mul(UNITY_MATRIX_VP, o.positionWS);

                //o.colorGradient=uv_Gradient.x;
                //正常的发现转换
                float4 normalOS1 = normalize(mul(i.normalOS,Inverse( mul(_PivotTRS,_GrassInfoBuffer[instanceID].TRS))));
                //Trick,转换成默认为每个单位草的物体空间up
                float4 normalOS2 = mul(float4(0, 1, 0, 0), Inverse(mul(_PivotTRS, _GrassInfoBuffer[instanceID].TRS)));

               

                o.normalWS_Terrain=TransformObjectToWorldNormal(normalOS2);
               // float4 normalOS = lerp(normalOS1, normalOS2, _NormalLetp);
                // float4 tangent=mul(_PivotTRS,mul(_GrassInfoBuffer[instanceID].TRS,i.tangentOS) );
                VertexNormalInputs normalInputs = GetVertexNormalInputs(normalOS1.xyz, i.tangentOS);
                //获取世界空间法线
                o.normalWS = normalInputs.normalWS;

                 o.toPivotDirWS=(o.positionWS-pivotPosWS);
                // o.normalWS.xyz= GetWindGrassWorldPos(i.normalOS,  float4(o.normalWS,0));
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
            float4 frag(VertexOutput i,float face:VFACE): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                //return float4(i.normalWS*face,1);
       //return 1-min(1,distance(mul(unity_WorldToObject,_PlayerPos),mul(unity_WorldToObject,i.positionWS.xyz)));
                float4 Grasscolor = lerp(_BaseColor, _BaseColor2, i.colorGradientLrapValue);
               // return float4(GetPivotPos(i.ID),1);
             //  return i.colorGradientLrapValue;
                //return Grasscolor;
                //return float4( i.colorGradient.xyz,1);
                //return i.colorGradient.x;
                //------法线贴图转世界法线--------
                //载入法线贴图
                float4 normalTXS = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv);
                //return 

                //贴图颜色 0~1 转 -1~1并且缩放法线强度
                float3 normalTS = UnpackNormalScale(normalTXS, _NormalScale);

                //贴图法线转换为世界法线
                half3 normalWS = TransformTangentToWorld(normalTS,real3x3(i.tangentWS, i.bitangentWS, i.normalWS));
                normalWS = normalize(normalWS);
                //获取纹理 = 纹理载入（纹理变量，纹理重复，UV坐标）
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv) * Grasscolor;
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


                float3 N = normalize(i.toPivotDirWS+normalWS*face);
                
                 N = lerp(N,i.normalWS_Terrain,_NormalLetp);
               // return float4(N,1);
              //  return float4(N,1);
                //  float3 N = TransformObjectToWorldNormal(float3(0, 1, 0));
                //float3 N = mul(float3(0, 1, 0),Inverse());
                //return float4(normalWS,1);
              // float3 V = normalize(GetWorldSpaceViewDir(i.positionWS.xyz));
                 float3 V = i.viewDirWS;
                //-----------阴影数据--------------
                //当前模型接收阴影
                float4 shadow_coord_Main = TransformWorldToShadowCoord(i.positionWS.xyz);
                //放入光照数据
                Light MainlightData = GetMainLight();
                //阴影数据
                half shadow_main = 0;
                //如此使用则可以让主光源使用屏幕空间阴影
                #if _MAIN_LIGHT_SHADOWS_SCREEN
                shadow_main=SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_BaseMap, i.shadowCoord_Screen.xy);
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


                col_main.rgb = (GrassPBR_Direct_Light(albedo.rgb, MainlightData, N, V, metallic, roughness, ao) * shadow_main
                    + GrassPBR_InDirect_Light(albedo.rgb, N, V, metallic, roughness, ao));

                //GlobalIllumination()
                float shadow_add = 0;
                float distanceAttenuation_add = 0;
                #if _ADDITIONAL_LIGHTS
                int additionalLightsCount = GetAdditionalLightsCount();
                for (int lightIndex = 0; lightIndex < additionalLightsCount; ++lightIndex)
                {
                    Light additionalLight = GetAdditionalLight(lightIndex, i.positionWS.xyz, half4(1, 1, 1, 1));
                    distanceAttenuation_add += additionalLight.distanceAttenuation;
                    shadow_add = additionalLight.shadowAttenuation * additionalLight.distanceAttenuation;
                    col_add.rgb += GrassPBR_Direct_Light(albedo.rgb, additionalLight, N, V, metallic, roughness, ao) *
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

                col_final.a = albedo.a;
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
                #ifdef  _ALPHATEST_ON
                Alpha(col_final.a, _BaseColor, _Cutoff);
                #endif


                return col_final * ssao;
            }
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
            Cull [_Cull]

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
            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            struct Attributes
            {
                float4 position : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                #if defined(_ALPHATEST_ON)
        float2 uv       : TEXCOORD0;
                #endif
                float4 positionCS : SV_POSITION;
                half colorGradientLrapValue:TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings DepthOnlyVertex(Attributes input, uint instanceID : SV_InstanceID)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                #if defined(_ALPHATEST_ON)
        output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif

                float3 pivotPosWS = GetPivotPos(instanceID);
                output.colorGradientLrapValue = GetLerpValue(pivotPosWS);
   input.position.y  =input.position.y  + (_HeightOffset_BaseColor2*input.position.y)* output.colorGradientLrapValue;

                float4 positionWS = GetInstanceGrassWorldPos(input.position, instanceID);
                positionWS = GetWindGrassWorldPos(input.position, positionWS);
                output.positionCS = mul(UNITY_MATRIX_VP, positionWS);
                return output;
            }

            half DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
        Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
        LODFadeCrossFade(input.positionCS);
                #endif

                return input.positionCS.z;
            }
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
            Cull [_Cull]

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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

            #if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
            #endif

            // GLES2 has limited amount of interpolators
            #if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
            #endif

            #if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
            #endif

            #if defined(_ALPHATEST_ON) || defined(_PARALLAXMAP) || defined(_NORMALMAP) || defined(_DETAIL)
#define REQUIRES_UV_INTERPOLATOR
            #endif

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 tangentOS : TANGENT;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                #if defined(REQUIRES_UV_INTERPOLATOR)
    float2 uv          : TEXCOORD1;
                #endif
                half3 normalWS : TEXCOORD2;

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    half4 tangentWS    : TEXCOORD4;    // xyz: tangent, w: sign
                #endif

                half3 viewDirWS : TEXCOORD5;

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS    : TEXCOORD8;
                #endif
                half colorGradientLrapValue:TEXCOORD7;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            Varyings DepthNormalsVertex(Attributes input, uint instanceID : SV_InstanceID)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                #if defined(REQUIRES_UV_INTERPOLATOR)
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                #endif
                float3 pivotPosWS = GetPivotPos(instanceID);
                output.colorGradientLrapValue = GetLerpValue(pivotPosWS);
                input.positionOS.y  =input.positionOS.y  + (_HeightOffset_BaseColor2*input.positionOS.y)* output.colorGradientLrapValue;



                float4 positionWS = GetInstanceGrassWorldPos(input.positionOS, instanceID);
                positionWS = GetWindGrassWorldPos(input.positionOS, positionWS);
                output.positionCS = mul(UNITY_MATRIX_VP, positionWS);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

                output.normalWS = half3(normalInput.normalWS);
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        float sign = input.tangentOS.w * float(GetOddNegativeScale());
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #endif

                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
        output.tangentWS = tangentWS;
                #endif

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
        half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
        output.viewDirTS = viewDirTS;
                #endif

                return output;
            }

            void DepthNormalsFragment(
                Varyings input
                , out half4 outNormalWS : SV_Target0
                #ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
                #endif
            )
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if defined(_ALPHATEST_ON)
        Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                #endif

                #if defined(LOD_FADE_CROSSFADE)
        LODFadeCrossFade(input.positionCS);
                #endif

                #if defined(_GBUFFER_NORMALS_OCT)
        float3 normalWS = normalize(input.normalWS);
        float2 octNormalWS = PackNormalOctQuadEncode(normalWS);           // values between [-1, +1], must use fp32 on some platforms
        float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);   // values between [ 0,  1]
        half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);      // values between [ 0,  1]
        outNormalWS = half4(packedNormalWS, 0.0);
                #else
                #if defined(_PARALLAXMAP)
                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS = input.viewDirTS;
                #else
                half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, input.viewDirWS);
                #endif
            ApplyPerPixelDisplacement(viewDirTS, input.uv);
                #endif

                #if defined(_NORMALMAP) || defined(_DETAIL)
            float sgn = input.tangentWS.w;      // should be either +1 or -1
            float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
            float3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

                #if defined(_DETAIL)
                half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, input.uv).a;
                float2 detailUv = input.uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
                normalTS = ApplyDetailNormal(detailUv, normalTS, detailMask);
                #endif

            float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                #else
                float3 normalWS = input.normalWS;
                #endif

                outNormalWS = half4(NormalizeNormalPerPixel(normalWS), 0.0);
                #endif

                #ifdef _WRITE_RENDERING_LAYERS
        uint renderingLayers = GetMeshRenderingLayer();
        outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                #endif
            }
            ENDHLSL
        }
        //当前模型创建阴影计算
/*

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
           Cull [_Cull]

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
 half colorGradientLrapValue:TEXCOORD7;
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

Varyings ShadowPassVertex(Attributes input, uint instanceID : SV_InstanceID)
{
   Varyings output;
   UNITY_SETUP_INSTANCE_ID(input);
   UNITY_TRANSFER_INSTANCE_ID(input, output);

   #if defined(_ALPHATEST_ON)
       output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
   #endif
 float3 pivotPosWS = GetPivotPos(instanceID);
                output.colorGradientLrapValue = GetLerpValue(pivotPosWS);
               
                   input.positionOS.y  =input.positionOS.y  + (_HeightOffset_BaseColor2*input.positionOS.y)* output.colorGradientLrapValue;



float4 positionWS = GetInstanceGrassWorldPos(input.positionOS,instanceID);
   positionWS=GetWindGrassWorldPos(input.positionOS,positionWS);
               output.positionCS = mul(UNITY_MATRIX_VP, positionWS);
 
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
       }*/
        // UsePass "Universal Render Pipeline/Lit/Universal2D"
    }
    FallBack "KTSAMA/Grass"
}