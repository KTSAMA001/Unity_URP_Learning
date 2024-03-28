#ifndef KTSAMA_PBRFunc_INCLUDED
#define KTSAMA_PBRFunc_INCLUDED
//D 正态分布函数 Normal Distribution Function
float D_DistributionGGX(float3 N, float3 H, float Roughness)
{
    float a = Roughness * Roughness;
    float a2 = a * a;
    float NH = saturate(dot(N, H));
    float NH2 = NH * NH;
    float nominator = a2;
    float denominator = (NH2 * (a2 - 1.0) + 1.0);
    denominator = PI * denominator * denominator;
    //denominator =  denominator * denominator;

    return nominator / max(denominator, 0.00001); //防止分母为0
}

//G 直接光照
float GeometrySchlickGGX_D(float NV, float Roughness)
{
    float r = Roughness + 1.0;
    float k = r * r / 8;
    float nominator = NV;
    float denominator = k + (1.0 - k) * smoothstep(0.05,0.95,NV);
    return nominator / max(denominator, 0.00001); //防止分母为0
}
//G 直接光照
float Grass_GeometrySchlickGGX_D(float NV, float Roughness)
{
    float r = Roughness + 1.0;
    float k = r * r / 8;
    float nominator = NV;
    float denominator = k + (1.0 - k) * NV;
    return nominator / max(denominator, 0.00001);
    //防止分母为0
}
//G 间接光照（IBL）
float GeometrySchlickGGX_I(float NV, float Roughness)
{
    float r = Roughness;
    float k = r * r / 2;
    float nominator = NV;
    float denominator = k + (1.0 - k) * NV;
    return nominator / max(denominator, 0.00001); //防止分母为0
}

float G_GeometrySmith_Direct_Light(float3 N, float3 V, float3 L, float Roughness)
{
    float NV = saturate(dot(N, V));
    float NL = saturate(dot(N, L));

    float ggx1 = GeometrySchlickGGX_D(NV, Roughness);
    float ggx2 = GeometrySchlickGGX_D(NL, Roughness);

    return ggx1 * ggx2;
}
float G_Grass_GeometrySmith_Direct_Light(float3 N, float3 V, float3 L, float Roughness)
{
   // float NV = saturate(dot(N, V));
    float NV = saturate(dot(N, V));
    float NL = saturate(dot(N, L));

    float ggx1 = Grass_GeometrySchlickGGX_D(NV, Roughness);
    float ggx2 = GeometrySchlickGGX_D(NL, Roughness);

    return ggx1 * ggx2;
}


float G_GeometrySmith_InDirect_Light(float3 N, float3 V, float3 L, float Roughness)
{
    float NV = saturate(dot(N, V));
    float NL = saturate(dot(N, L));

    float ggx1 = GeometrySchlickGGX_I(NV, Roughness);
    float ggx2 = GeometrySchlickGGX_I(NL, Roughness);

    return ggx1 * ggx2;
}

//F
float3 F_FrenelSchlick(float NV, float3 F0)
{
    return F0 + (1 - F0) * pow(1 - NV, 5);
}
float3 F_FrenelSchlick2(float NV, float3 F0)
{
    return lerp(pow(1 - NV, 5),1,F0);
}
// float3 FresnelSchlickRoughness(float NV, float3 F0, float Roughness)
// {
//     return F0 + (max(float3(1.0 - Roughness, 1.0 - Roughness, 1.0 - Roughness), F0) - F0) * pow(1.0 - NV, 5.0);
// }

float3 ACESToneMapping(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

float4 ACESToneMapping(float4 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}
// //UE4 Black Ops II modify version
// float2 EnvBRDFApprox(float Roughness, float NV )
// {
//     // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
//     // Adaptation to fit our G term.
//     const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
//     const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
//     float4 r = Roughness * c0 + c1;
//     float a004 = min( r.x * r.x, exp2( -9.28 * NV ) ) * r.x + r.y;
//     float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
//     return AB;
// }
float GGX_DistanceFade(float3 N,float3 V,float3 L,float Roughness,float DistanceFade)
{
    float3 H = normalize(L+V);
    float D = D_DistributionGGX(N,H,Roughness);
    float F = F_FrenelSchlick(saturate( dot(N,V)),0.04);
   // float G = G_GeometrySmith(N,V,L,Roughness);

    return D*F*DistanceFade;//Kill G for more natural looking
}
float3 PBR_Direct_Light(float3 albedo, Light lightData, float3 N, float3 V, float metallic, float roughness,float ao)
{
    float3 L=normalize(lightData.direction);
    float3 F0 = lerp(0.04, albedo, metallic);
    float3 H = normalize(V + L);
    float NV = saturate(dot(N, V));
    float NH = saturate(dot(N, H));
   // float NL = smoothstep(0.3,0.5,saturate(dot(N, L)));
    float NL = saturate(dot(N, L));
    float D = D_DistributionGGX(N, H, roughness);
    float G = G_GeometrySmith_Direct_Light(N,V, L,roughness);
    float3 F = F_FrenelSchlick(NV, F0);
    float3 kd = (1 - F)*(1-metallic) ;
   
    float3 diffuse_col = ((kd * albedo) / PI);
    float3 specular = (D * G * F) / (4 * max((NV * NL), 0.000001));
    float3 col_final = (diffuse_col + specular) * NL * lightData.color;
    float3 debug = (diffuse_col ) * NL * lightData.color;
    //return 0;
    return col_final*ao;
}
float3 GrassPBR_Direct_Light(float3 albedo, Light lightData, float3 N, float3 V, float metallic, float roughness,float ao)
{
    float3 L=normalize(lightData.direction);
    float3 F0 = lerp(0.04, albedo, metallic);
    float3 H = normalize(V + L);
    float3 H_NV = normalize(V + N);
    float NV = saturate(dot(N, V));
    float NH = saturate(dot(N, H));
    float NH_NV = saturate(dot(N, H_NV));
    // float NL = smoothstep(0.3,0.5,saturate(dot(N, L)));
    float NL = saturate(dot(N, L));
    float D = D_DistributionGGX(N, H, roughness);
    float G = G_Grass_GeometrySmith_Direct_Light(N,V, L,roughness);
    float3 F = F_FrenelSchlick(NH, F0);
    float3 kd = (1 - F)*(1-metallic) ;
   
    float3 diffuse_col = ((kd * albedo) / PI);
  //  float3 specular = (D * G * F) / (4 * max((NV * NL), 0.0001));
    float3 specular = (D  * G* F) / (4 * max((NV * NL), 0.0001));
    float3 col_final = (diffuse_col + specular)  * lightData.color;
    float3 debug = (diffuse_col ) * NL * lightData.color;
  //return 0;
    return col_final*ao;
}

float3 PBR_InDirect_Light(float3 albedo,float3 N, float3 V, float metallic, float roughness,float ao)
{
    float NV = saturate(dot(N, V));
    float3 F0 = lerp(0.04, albedo, metallic);
    float3 F = FresnelSchlickRoughness(NV, F0, roughness);
    float3 kd = (1 - F) ;
    //获取当前视角反射
    float3 reflectDirWS = reflect(-V, N);
 
    //数值近似
    float2 env_brdf = EnvBRDFApprox(roughness,NV);

    float mip = roughness*(1.7 - 0.7*roughness) * UNITY_SPECCUBE_LOD_STEPS ;
    //读取反射探针贴图
    // float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap, sampler_GlossyEnvironmentCubeMap,reflectDirWS, mip);
    float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0,reflectDirWS, mip);
    
    //间接光镜面反射采样的预过滤环境贴图
    //float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,_GlossyEnvironmentCubeMap_HDR);
    float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,unity_SpecCube0_HDR);
    float3 diffuse_col_InDirect = SampleSH(N)*albedo*kd;

    float3 specular_InDirect =  EnvSpecularPrefilted*(F * env_brdf.r + env_brdf.g);
   //return 0;
    return (diffuse_col_InDirect + specular_InDirect)*ao;
}
float3 GrassPBR_InDirect_Light(float3 albedo,float3 N, float3 V, float metallic, float roughness,float ao)
{
    float NV = saturate(dot(N, V));
    float3 F0 = lerp(0.04, albedo, metallic);
    float3 F = FresnelSchlickRoughness(NV, F0, roughness);
    float3 kd = (1 - F) ;
    //获取当前视角反射
    float3 reflectDirWS = reflect(-V, N);
 
    //数值近似
    float2 env_brdf = EnvBRDFApprox(roughness,NV);

    float mip = roughness*(1.7 - 0.7*roughness) * UNITY_SPECCUBE_LOD_STEPS ;
    //读取反射探针贴图
    // float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap, sampler_GlossyEnvironmentCubeMap,reflectDirWS, mip);
    float4 _CubeMapColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0,reflectDirWS, mip);
    
    //间接光镜面反射采样的预过滤环境贴图
    //float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,_GlossyEnvironmentCubeMap_HDR);
    float3 EnvSpecularPrefilted=DecodeHDREnvironment(_CubeMapColor,unity_SpecCube0_HDR);
    float3 diffuse_col_InDirect = SampleSH(N)*albedo*kd;

    float3 specular_InDirect =  EnvSpecularPrefilted*(F * env_brdf.r + env_brdf.g);
    //return specular_InDirect;
    //trik 防止环境过暗的时候暗部纯黑
    float powDiffuse=lerp(0.8,1,saturate(Luminance(specular_InDirect)*25));
    return (pow(diffuse_col_InDirect,powDiffuse) + specular_InDirect)*ao;
}
#endif
