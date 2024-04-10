Shader "KTSAMA/URP/Volume"
{
    Properties
    {
        [Enum(Off, 0, Front, 1, Back, 2)]
        _Cull("Cull Mode", Float) = 1
        _ShadowMint("ShadowMint", Float) = 0.1
        _ShadowMaxt("ShadowMaxt", Float) = 1
        _ShadowK("_Shadow K", Float) = 1
        
        _SDFBorder("SDFBorder", Range(1, 100)) = 30
        [Enum(Map1,0,Map2,1,Map3,2,Map4,3,Map5,4)]_MapMode("Map Mod",int) = 0
        [Enum(R, 0, G, 1, B, 2)]
        _Channel("3D纹理通道", float) = 0
        _Ambient_Color1("环境光1",Color)=(0.5,0.5,0.5,1)
        _Ambient_Color2("环境光2",Color)=(1,1,1,1)

        _AmbientDensity("Ambient Density", Range(0, 1)) = 0
        _VolumeTex_1("3D纹理1", 3D) = "white" {}
        _VolumeTex_2("3D纹理2", 3D) = "white" {}
        _VolumeTexScale_1("3D纹理1缩放", Vector) = (1,1,1,1)
        _NoiseIntensity("3D纹理1强度", Range(0, 1)) = 1
        _MonteCarloSampleIntensity("蒙特卡洛采样噪声强度", Range(0.00, 10)) = 0.01
        _Absorption("Absorption",float)=1
        _LightEnergyIntensity("LightEnergyIntensity",float)=20
        _AmbientIntensit("_AmbientIntensit",Range(0, 1))=1
        _BackForwardLerp("BackForwardLerp",Range(0,1))=1
        _G0("_G0",Range(-1,1))=-0.1
        _G1("_G1",Range(-1,1))=0.1
    }
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #define Box_Min  float3(-0.5, -0.5, -0.5)
    #define Box_Max  float3(0.5, 0.5, 0.5)
    #define STEP_VIEW_MAX_COUNT 64
    #define STEP_LIGHT_MAX_COUNT 32

    TEXTURE3D(_VolumeTex_1);
    TEXTURE3D(_VolumeTex_2);
    SAMPLER(sampler_VolumeTex_1);
    SAMPLER(sampler_VolumeTex_2);

    cbuffer UnityPerMaterial
    {
        float _Cull;
        float _ShadowMint;
        float _ShadowMaxt;
        float _ShadowK;
        float _Absorption;
        float _MonteCarloSampleIntensity;
       
        int _MapMode;
    float _AmbientDensity;
           float _SDFBorder;
        float _Channel;
        float _BackForwardLerp;
        float _G0,_G1,_LightEnergyIntensity,_AmbientIntensit,_NoiseIntensity;
        float3 _VolumeTexScale_1;
        float4 _Ambient_Color1;
        float4 _Ambient_Color2;
    }


    //SDF形状
    float sdSphere(float3 p, float r)
    {
        return length(p) - r;
    }

    float sdTorus(float3 p, float2 t)
    {
        return length(float2(length(p.xz) - t.x, p.y)) - t.y;
    }

    float sdBox(float3 p, float3 b)
    {
        float3 d = abs(p) - b;
        return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
    }

    //SDF融合
    float opSmoothUnion(float d1, float d2, float k)
    {
        float h = max(k - abs(d1 - d2), 0.0);
        return min(d1, d2) - h * h * 0.25 / k;
    }

    float opSmoothSubtraction(float d1, float d2, float k)
    {
        return -opSmoothUnion(d1, -d2, k);

        //float h = max(k-abs(-d1-d2),0.0);
        //return max(-d1, d2) + h*h*0.25/k;
    }
 float SDF_Noise(float3 pos_cur)
    {
        float sdf = (SAMPLE_TEXTURE3D(_VolumeTex_1, sampler_VolumeTex_1, pos_cur*_VolumeTexScale_1+0.5*+_Time.y*0.1)[
            _Channel]);
        return sdf;
    }
    float map(float3 p)
    {
        float sdf = 10086.0;

        float sdf_sphere1 = sdSphere(p + float3(0, sin(_Time.y) * 0.2, 0), 0.1);
        // float3 pos_twist = p;
        // pos_twist.x += sin(pos_twist.y*50 + _Time.y)*0.1;
        float sdf_sphere2 = sdSphere(p + float3(sin(_Time.y * 2.5) * 0.4, 0, 0), 0.08);
        float sdf_torus = sdTorus(p, float2(0.2, 0.05));
        float sdf_box = sdBox(p + float3(0.35, 0, 0), float3(0.05, 0.2, 0.2));

        sdf = opSmoothUnion(sdf_torus, sdf_sphere1, 0.1);

        sdf = min(sdf, sdf_box);

        sdf = opSmoothSubtraction(sdf_sphere2, sdf, 0.05);
        // sdf = min(sdf_sphere1, sdf_sphere2);
        // sdf = min(sdf,sdf_torus);
       sdf=SAMPLE_TEXTURE3D(_VolumeTex_2,sampler_VolumeTex_2,p+0.5)+SDF_Noise(p)*0.01;
        
      
        //return sdSphere(p,0.3);
        return sdf;
    }
    // Henyey-Greenstein 相函数
    // 夹角余弦，相函数参数值
    float hg(float a, float g)
    {
        float g2 = g * g;
        return (1 - g2) / (4 * 3.1415 * pow(1 + g2 - 2 * g * (a), 1.5));
    }

    float hg2(float a)
    {
        return lerp(hg(a, _G0), hg(a, _G1), _BackForwardLerp);
    }
    float3 calcNormal(in float3 pos)
    {
        float2 e = float2(1.0, -1.0) * 0.5773;
        const float eps = 0.0005;
        return normalize(e.xyy * map(pos + e.xyy * eps) +
            e.yyx * map(pos + e.yyx * eps) +
            e.yxy * map(pos + e.yxy * eps) +
            e.xxx * map(pos + e.xxx * eps));
    }
 // http://magnuswrenninge.com/wp-content/uploads/2010/03/Wrenninge-OzTheGreatAndVolumetric.pdf
    // 模拟多次散射的效果
    float multipleOctaves(float depth, float mu)
    {
        float luminance = 0;
        int octaves = 8;
        // Attenuation
        float a = 1;
        // Contribution
        float b = 1;
        // Phase attenuation
        float c = 1;

        float phase;

        for (int i = 0; i < octaves; ++i)
        {
            phase = lerp(hg(mu, _G0 * c), hg(mu, _G1 * c), _BackForwardLerp);
            luminance += b * phase * exp(-depth * a* _Absorption);
            a *= 0.2f;
            b *= 0.5f;
            c *= 0.5f;
        }
        // return hg2(mu) * Transmittance(depth, _Absorption);
        return luminance;
    }
    float3 calcNormal2(in float3 pos)
    {
        float3 eps = float3(0.005, 0.0, 0.0);
        return normalize(float3(
            map(pos + eps.xyy).x - map(pos - eps.xyy).x,
            map(pos + eps.yxy).x - map(pos - eps.yxy).x,
            map(pos + eps.yyx).x - map(pos - eps.yyx).x));
    }

    // https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
    // Compute the near and far intersections using the slab method.
    // No intersection if tNear > tFar.
    float2 intersectAABB(float3 rayOrigin, float3 rayDir, float3 boxMin, float3 boxMax)
    {
        float3 tMin = (boxMin - rayOrigin) / rayDir;
        float3 tMax = (boxMax - rayOrigin) / rayDir;
        float3 t1 = min(tMin, tMax);
        float3 t2 = max(tMin, tMax);
        float tNear = max(max(t1.x, t1.y), t1.z);
        float tFar = min(min(t2.x, t2.y), t2.z);
        return float2(tNear, tFar);
    }

    // https://iquilezles.org/articles/rmshadows
    float calcHardShadow(float3 ro, float3 rd, float mint, float maxt)
    {
        float t = mint;
        for (int i = 0; i < 256 && t < maxt; i++)
        {
            float h = map(ro + rd * t);
            //到达物体表面=》有物体遮挡
            if (h < 0.001)
                return 0.0;
            t += h;
        }
        return 1.0;
    }

    float rand(float2 pix)
    {
        return frac(sin(pix.x * 199 + pix.y) * 1000);
    }

    float remap(float x, float low1, float high1, float low2, float high2)
    {
        return low2 + (x - low1) * (high2 - low2) / (high1 - low1);
    }

    float remap01(float x, float low1)
    {
        return (x - low1) / (1.0 - low1);
    }
    
    // https://iquilezles.org/articles/rmshadows
    float calcSoftShadow(float3 ro, float3 rd, float mint, float maxt, float k)
    {
        float res = 1.0;
        float t = mint;
        for (int i = 0; i < 256 && t < maxt; i++)
        {
            float h = map(ro + rd * t);
            if (h < 0.001)
                return 0.0;
            res = min(res, k * h / t);
            t += h;
        }
        return res;
    }
 float map_cloud2(float3 p)
    {
        float sdf = 10086.0;

        float sdf_sphere1 = sdSphere(p+float3(0,-0.06,0) ,0.17);
        float sdf_sphere2 = sdSphere(p+float3(-0.2,0,0),0.1);
        float sdf_sphere3 = sdSphere(p+float3(0.2,0,0),0.1);
      
        sdf = opSmoothUnion(sdf_sphere1,sdf_sphere2,0.1);
        sdf = opSmoothUnion(sdf,sdf_sphere3,0.1);
        
        return sdf;
    }
// 蒙特卡洛采样函数
float3 MonteCarloSample(float3 rayDirection, float randomSeed,float length)
{
    float3 randomDirection = normalize(float3(
        frac(sin(randomSeed * 43758.5453)),
        frac(cos((randomSeed + 1.0) * 43758.5453)),
        frac(sin((randomSeed + 2.0) * 43758.5453))
    ));

    // 在这里，你可以调整偏移的强度，以适应你的场景
    float offsetStrength = _MonteCarloSampleIntensity*exp(-length*3)/2;

    // 将随机方向与原始光线方向结合，引入随机偏移
    float3 offsetRayDirection = normalize(rayDirection + offsetStrength * randomDirection);

    return offsetRayDirection;
}

 void cloud(float3 pos, out float sdf, out float density)
    {
        density=0;
        sdf = SAMPLE_TEXTURE3D(_VolumeTex_2,sampler_VolumeTex_2, pos + 0.5f);

        float3 pos_torus = pos.xzy + float3(0, 0.2 + sin(_Time.y * 2) * 0.2, -0.2);

        float sdf_torus = sdTorus(pos_torus, float2(0.2, 0.08 - sin(_Time.y * 2) * 0.03));

        sdf = opSmoothUnion(sdf, sdf_torus, 0.1);

        float sdf_sphere = sdSphere(pos + float3(sin(_Time.y * 2) * 0.4, 0, 0), 0.1);

        sdf = opSmoothSubtraction(sdf_sphere, sdf, 0.1);

      
        if (sdf < 0)
        {
            // 在边缘处云密度较小
            float base = saturate(-sdf  * _SDFBorder);
            float noise = SDF_Noise(pos);
            // 在云密度上叠加噪声
            // density = saturate(remap(base, noise * _NoiseIntensity, 1, 0, 1));
            density = saturate((base - noise * _NoiseIntensity) / (1 - noise * _NoiseIntensity));
            // 另外一种叠加噪声的方式，可自行尝试
            // density = saturate(base + noise - 1.1f);
        }
        
    }
 
void clouds(float3 pos, out float sdf, out float density)
    {
        UNITY_BRANCH
        if(_MapMode == 0)
        {
             sdf = SAMPLE_TEXTURE3D(_VolumeTex_2,sampler_VolumeTex_2, pos + 0.5f);
        }
        else if(_MapMode == 1)
        {
            cloud(pos,sdf,density);
            return;
        }
        else if(_MapMode == 2)
        {
            sdf = map(pos);
        }
        else if(_MapMode == 3)
        {
            // sdf = map_cloud(pos);
            sdf = map_cloud2(pos);
            // sdf = mapHeart(pos,_Time.y);
        }
        
        // sdf = mapHeart(pos,_Time.y).x;
        
        // UNITY_BRANCH
        // if(_MapMode == 4)
        // {
        //      sdf = map_cloud2(pos);
        // }
                
        if (sdf > 0)
        {
            density = 0;
            return;
        }
        
        // 在边缘处云密度较小
        float base = saturate(-sdf* _SDFBorder);
        float noise = SDF_Noise(pos);
        // 在云密度上叠加噪声
        density = saturate(remap(base, noise * _NoiseIntensity, 1, 0, 1));
        // density = saturate((base - noise * _NoiseIntensity)/(1 - noise * _NoiseIntensity));
        // density = saturate(base +noise.r*_NoiseIntensity -1.1);
    }
float3 mod3D289(float3 x) { return x - floor(x / 289.0) * 289.0; }
float4 mod3D289(float4 x) { return x - floor(x / 289.0) * 289.0; }
float4 permute(float4 x) { return mod3D289((x * 34.0 + 1.0) * x); }
float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - r * 0.85373472095314; }
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

    float4 RayMarching(float3 rayOrigin, float3 rayDir, Light light)
    {
        float3 lightDirOS = TransformWorldToObjectDir(light.direction);
       
        float2 tNearFar_View = intersectAABB(rayOrigin, rayDir,Box_Min,Box_Max);
        float ambienLerp = 0;
        float dis_view = tNearFar_View.y - tNearFar_View.x;
        float toCamDis=0;
        float cameraNear = _ProjectionParams.y;
        dis_view = tNearFar_View.y - max(tNearFar_View.x, cameraNear);
        float3 orginPos = rayOrigin + max(tNearFar_View.x, cameraNear) * rayDir;
        float t_view = dis_view / STEP_VIEW_MAX_COUNT;
       // float t_view = 0.01;
        
       
        float3 pos_cur = orginPos;
        float result_view = 0;
        float viewDepth =  0;
        float4 final_Color = float4(0, 0, 0, 1);
        float final_resulet = 0;
        float density = 0;
        float sdf;
        float sdf2;
        float density2 = 0;
        float costheta = dot(lightDirOS,rayDir);
        float phase = hg2(costheta);
        float result_light = 0;
     
        UNITY_LOOP
        for (int i = 0; i < STEP_VIEW_MAX_COUNT; i++)
        {
           
            clouds(pos_cur,sdf,density);
        viewDepth+=max(sdf,t_view);
        toCamDis=distance(pos_cur,rayOrigin);
      
            pos_cur = orginPos + rayDir * viewDepth;
             
            result_view += density*t_view ;
            if (density > 0 && sdf<0)
            {
                float2 tNearFar_light = intersectAABB(pos_cur, lightDirOS,Box_Min,Box_Max);
                float dis_light = tNearFar_light.y;
                float3 lightSamplePos = pos_cur;
                float t_light = dis_light / STEP_LIGHT_MAX_COUNT;
               // float t_light = 0.01;
                 float lightDepth = 0;
                UNITY_LOOP
                for (int j = 0; j < STEP_LIGHT_MAX_COUNT; j++)
                {
                   clouds(lightSamplePos,sdf2,density2);
                   lightDepth += max(sdf2,t_light);
                   lightSamplePos = pos_cur + lightDirOS * lightDepth;
                   result_light += density2*t_light ;
                  
                   if (any(lightSamplePos < -0.5) || any(lightSamplePos > 0.5)) break;
                }
                float transmittance = exp(-t_view * density * _Absorption);
                //float lightEnergy = exp(-result_light * _Absorption);
                float3 lightEnergy = _LightEnergyIntensity* light.color * multipleOctaves(result_light, costheta) * PI* phase ;
                ambienLerp = (pos_cur.y + 0.5);
                float3 ambient= 20*_AmbientIntensit* light.color * lerp(_Ambient_Color1, _Ambient_Color2, ambienLerp)  * lerp(1,density,_AmbientDensity);
                float3 currentColor = ambient+ lightEnergy;
                final_Color.rgb += (1 - transmittance) * currentColor * final_Color.a ;
                final_Color.a *= transmittance;

            }

          if (any(pos_cur < -0.5) || any(pos_cur > 0.5)) break;
          
        }
     
        final_Color.a = 1 - final_Color.a;
        final_Color.rgb =  final_Color.rgb *float3(1, 1, 1)/**(1-saturate(result_light)*0.5)*/;
        //final_Color.a *= (1 - exp(-(result_view* _Absorption) ));
        // return (1-saturate(result_light)*0.5);
      
     
        //return  final_Color.a;
       // return float4(toCamDis.xxx,1);
        return float4(final_Color.rgb,final_Color.a);
        return float4(float3(1, 1, 1), 1 - exp(-(result_view) * _Absorption));
    }
    ENDHLSL
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"
        }
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest Always
            Cull [_Cull]
            HLSLPROGRAM
            #pragma vertex vert
            //#pragma 
            #pragma fragment frag
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
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
                float3 positionOS : TEXCOORD2;
 float4 screenPos:TEXCOORD5;
                #if _MAIN_LIGHT_SHADOWS_SCREEN || _SCREEN_SPACE_OCCLUSION
                
                 float4 shadowCoord_Screen:TEXCOORD6;
                #endif
            };

            VertexOutput vert(VertexInput i)
            {
                VertexOutput o;
                o.uv = i.uv;
                VertexPositionInputs position_inputs = GetVertexPositionInputs(i.positionOS);
                o.positionWS = position_inputs.positionWS;
                o.positionCS = position_inputs.positionCS;
                o.positionOS = i.positionOS;
                o.screenPos=ComputeScreenPos(position_inputs.positionCS);
                return o;
            }
 float _Seed;
            float4 frag(VertexOutput i): SV_Target
            {
              
                i.screenPos= ASE_ComputeGrabScreenPos( i.screenPos);
                i.screenPos.xy=i.screenPos.xy/i.screenPos.w;
               // return  float4(i.screenPos.xy,0,1);
             //   if(snoise(float3(i.screenPos.xy+_Time.y*_Seed*float2(0.000001,0.000001),0)*float3(200000,200000,200000)).x<=0.5)
            //   // if(snoise(float3(i.positionWS+_Time.y*float3(1,0,0))*float3(20000000,20000000,20000000)).x<=0.1)
           //     {
            //        return float4(0,0,0,0);
           //     }
                
                float3 rayOrginPosOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 rayDirOS = normalize(i.positionOS - rayOrginPosOS);
               //rayDirOS=MonteCarloSample(rayDirOS,42*rayDirOS,1);
                Light mainLight = GetMainLight();

                // return _ProjectionParams.y;
                //  return float4(RayMarching(rayOrginPosOS,rayDirOS).xyz,1);
                return RayMarching(rayOrginPosOS, rayDirOS, mainLight);
            }
            ENDHLSL
        }
    }
}