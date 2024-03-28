// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "TNshaders/GeometryShaderPractise"
{
    Properties
    {
      
       _MainTex("MainTex",2D)= "white" {}
       _Offset("Offset",Vector) =(0,0,0,0)
       _Offset_Block("Offset_Block",float) =1
       _Scale("Scale",Vector) =(1,1,1,1)
       _Speed("Speed",float)=1
       _BlockLayer1_U("BlockLayer1_U",float)=1
       _BlockLayer1_V("BlockLayer1_V",float)=1
        
       _BlockLayer2_U("BlockLayer2_U",float)=1
       _BlockLayer2_V("BlockLayer2_V",float)=1
       _BlockLayer1_Indensity("BlockLayer1_Indensity",float)=1
       _BlockLayer2_Indensity("BlockLayer2_Indensity",float)=1
       _RGBSplit_Indensity("RGBSplit_Indensity",float)=1
       _RGB_Switch("RGB_Switch",int)=1
       _Alpha("Alpha",Range(0,1))=1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
        //输出三角形的pass
            NAME "TRIANGLE PASS"
            
            ZWrite Off
            ZTest Always
            CGPROGRAM
            #pragma vertex vert
            //几何着色器声明
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
            float4 _TriangleColor;
            float3 _Offset,_Scale;
            float _Alpha,_Speed,_Offset_Block,_BlockLayer1_U,_BlockLayer1_V,_BlockLayer2_U,_BlockLayer2_V,_BlockLayer1_Indensity,_BlockLayer2_Indensity,_RGBSplit_Indensity;
	        uniform sampler2D _MainTex;
		    uniform float4 _MainTex_ST;
            int _RGB_Switch;
            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            //几何着色器需要传递的数据
            struct v2g 
            {
                float4 pos : POSITION;
                float2 uvG : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };
            //再从几何着色器变化过的数据传到片元着色器的结构      所以可以不用v2f 不过一个名字 想怎么取随便 自己别忘了就行
            struct g2f
            {
                float2 uv : TEXCOORD0;
                float4 posf : SV_POSITION;
            };

        //取代原本v2f 将顶点结构传入到结合着色器需要的结构中
            v2g  vert (a2v v)
            {
                v2g o = (v2g)0;
                o.pos =v.vertex;
                o.normal = v.normal;
                o.uvG = v.texcoord;
                
                return o;
            }

	//几何着色器 是在顶点着色器和片元着色器之间 vs 的输出作为gs的输入      vs 顶点着色器  gs 几何着色器
            //最大调用顶点数，三角形因为是三个顶点，因此最小输入3个顶点进入
			[maxvertexcount(3)]
			//输入 point line triangle lineadj triangleadj----输出: PointStream只显示点，LineStream只显示线，TriangleStream三角形
			void geom (triangle v2g input[3], inout TriangleStream<g2f> g)
			{
                g2f o = (g2f)0;
                float3 camPos_OS=mul(unity_WorldToObject,_WorldSpaceCameraPos);
                //3个顶点 就要计算三次。 如果输入的是一个顶点 就计算一次  不用循环写三次也是可以的
                for (int i = 0; i<3; i++)
                {
                   o.posf = float4(input[i].pos.xyz*_Scale+_Offset,input[i].pos.w);
                   o.posf.z= - 1;
                    //o.posf = float4((_WorldSpaceCameraPos.xy+i)/5,_WorldSpaceCameraPos.z+_ProjectionParams.y/10,1);
                    o.uv = -input[i].uvG;
                     
                    o.posf = mul(UNITY_MATRIX_P, o.posf);
                    g.Append(o);
                }
          
             
            }
inline float randomNoise(float2 seed)
{
    return frac(sin(dot(seed * floor(_Time.y * _Speed), float2(17.13, 3.71))) * 43758.5453123);
}

inline float randomNoise(float seed)
{
    return randomNoise(float2(seed, 1.0));
}
     float3 HSVToRGB( float3 c )
		{
			float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


            half4 frag (g2f i) : SV_Target
            {
               // return _ProjectionParams.y;
                //return mul(unity_WorldToObject,_WorldSpaceCameraPos).xyzz;
               float2 blockLayer1 = floor(i.uv * float2(_BlockLayer1_U, _BlockLayer1_V));
               float2 blockLayer2 = floor(i.uv * float2(_BlockLayer2_U, _BlockLayer2_V));

               float lineNoise1 = pow(randomNoise(blockLayer1), _BlockLayer1_Indensity);
               float lineNoise2 = pow(randomNoise(blockLayer2), _BlockLayer2_Indensity);
               float RGBSplitNoise = pow(randomNoise(5.1379), 7.1) * _RGBSplit_Indensity;
               float lineNoise = lineNoise1 * lineNoise2 * _Offset_Block  - RGBSplitNoise;

                half ColorR = tex2D(_MainTex,  i.uv + float2(lineNoise*.1  * randomNoise(1.0), 0.0)).r;
                half ColorG = tex2D(_MainTex,  i.uv + float2(lineNoise*.1  * randomNoise(15.0), 0.0)).g;
                half ColorB = tex2D(_MainTex, i.uv - float2(lineNoise *.1* randomNoise(3.0), 0.0)).b;
                half ColorA = tex2D(_MainTex, i.uv - float2(lineNoise *.1* randomNoise(5.0), 0.0)).a;
                
                float4 final_col=float4(ColorR,ColorG,ColorB,ColorA);
                final_col.rgb*=lerp(1,HSVToRGB(float3(i.uv.x/5+_Time.y/5,0.8,1))*1.5,_RGB_Switch);
                float a=final_col.a*_Alpha-0.1;
                a=saturate(a);
                //return float4(RGBToHSV(float3(sin(_Time.y*2),sin(_Time.y/2),1)),1);
              // return lineNoise;
                return float4(final_col.rgb,a);
            }
            ENDCG
        }
      }
}

