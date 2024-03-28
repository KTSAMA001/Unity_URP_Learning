Shader "KTSAMA/RenderFeature/SSOutLine"
{
    Properties
    {
  _InsiteEdgeWidth("内轮廓描边宽度",float)=5 
        
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
float _InsiteEdgeWidth;
        ENDHLSL

        Pass
        {
            Name "SSOutLinePass"
            Tags { "LightMode" = "SSOutLine" }

            ZTest LEqual
            ZWrite On

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment frag
            float4 _EdgeColor;
            TEXTURE2D(_DepthMaskColor);     SAMPLER(sampler_DepthMaskColor);
            TEXTURE2D(_KTGrabTex);     SAMPLER(sampler_KTGrabTex);
            half4 frag(Varyings i): SV_Target
            {
            
                float4 screen_col=SAMPLE_TEXTURE2D(_KTGrabTex,sampler_KTGrabTex,i.texcoord);
                float3 final_color=1;
                float depthOffset1=1;

                float depthOffset2=0;
                float depthOffset3=0;
                float depthOffset4=0;
                float depthOffset5=0;
                float depthOffset6=0;
                float depthOffset7=0;
                float depthOffset8=0;
                float depthOffsetOrgin=0;
                float final_depthoffset_max=1;
                float final_depthoffset_min=1;
                float3 outline_col=1;
                float2 f=float2(1.0/ 1920.0,1.0/ 1080.0);

        
              
                //depthOffset  =1-SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.shadowCoord_Screen.xy*0.8+(1-0.8)/2+ _DepthOffset*float2(1.0/ 1920.0,1.0/ 1080.0)* (1 / i.posNDCw)).r;
                depthOffset1  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(1,-1)*f).r;
                depthOffset2  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(-1,1)*f).r;
                depthOffset3  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(1,1)*f).r;
                depthOffset4  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(-1,-1)*f).r;
                depthOffset5  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(1,0)*f).r;
                depthOffset6  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(-1,0)*f).r;
                depthOffset7 =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(0,1)*f).r;
                depthOffset8 =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy+ _InsiteEdgeWidth*float2(0,-1)*f).r;
                depthOffsetOrgin  =SAMPLE_TEXTURE2D(_DepthMaskColor, sampler_DepthMaskColor, i.texcoord.xy).r;
              
                final_depthoffset_max=max(depthOffset1, max(depthOffset2, max(depthOffset3,max(depthOffset4,max(depthOffset5,max(depthOffset6,max(depthOffset7,depthOffset8)))))));
                //final_depthoffset_min=min(depthOffset1, min(depthOffset2, min(depthOffset3,depthOffset4)));
                float outline=final_depthoffset_max-depthOffsetOrgin;
                //return final_depthoffset;
                outline_col=lerp(screen_col,_EdgeColor,outline);
                //这种做法就是直接把偏移的部分扣掉，实心颜色
                //final_color*=1-depthOffset1;
                //这种做法就是叠加颜色
                final_color=outline_col;
                // screen_col+=outline_col;
                // final_color=screen_col.rgb;
               // return final_depthoffset_max;d
                //return outline;
                return float4(final_color.rgb,1);
            }
            ENDHLSL

        }

     

    }
}