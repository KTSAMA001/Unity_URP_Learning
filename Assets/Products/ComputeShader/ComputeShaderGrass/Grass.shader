Shader "KTSAMA/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OffsetPos("OffsetPos",Vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_instancing //这里,第一步
            #include "UnityCG.cginc"

            struct GrassInfo
            {
                float4x4 TRS;
            };

            StructuredBuffer<GrassInfo> _GrassInfoBuffer;
            float3 _OffsetPos;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID //这里,第二步
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionWS :TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID //这里,第二步
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            v2f vert(appdata v, uint instanceID :SV_INSTANCEID)
            {
                v2f o;
                 UNITY_SETUP_INSTANCE_ID(v); //这里第三步
                UNITY_TRANSFER_INSTANCE_ID(v,o); //第三步
                //o.vertex = UnityObjectToClipPos(v.vertex+instanceID*0.01);
                //o.vertex = UnityObjectToClipPos(v.vertex);
                //从Terrian本地坐标转换到世界坐标
                // float4 positionWS = _GrassInfoBuffer[instanceID].Pos.xyzz;
                float3 cameraTransformRightWS = unity_MatrixV[0].xyz;
                //UNITY_MATRIX_V[0].xyz == world space camera Right unit vector
                float3 cameraTransformUpWS = unity_MatrixV[1].xyz;
                //UNITY_MATRIX_V[1].xyz == world space camera Up unit vector
                float3 cameraTransformForwardWS = -unity_MatrixV[2].xyz;
                //UNITY_MATRIX_V[2].xyz == -1 * world space camera Forward unit vector
                float3 posOS = v.vertex.x * cameraTransformRightWS;
                posOS += v.vertex.y * cameraTransformUpWS;
                float3 bendDir = cameraTransformForwardWS;

                bendDir.xz *= 0.5; //make grass shorter when bending, looks better
                bendDir.y = min(-0.5,bendDir.y);//prevent grass become too long if camera forward is / near parallel to ground
                 posOS = lerp(posOS.xyz + bendDir * posOS.y / -bendDir.y, posOS.xyz, 1);//don't fully bend, will produce ZFighting
               float4 positionWS =  mul(_GrassInfoBuffer[instanceID].TRS,float4(posOS,1))+float4(_OffsetPos,0);
                  // float4 positionWS = instanceID;
                 positionWS /= positionWS.w;
                o.positionWS = positionWS;
                o.vertex = mul(UNITY_MATRIX_VP, positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                 UNITY_SETUP_INSTANCE_ID(i); //最后一步
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //fixed4 col = i.positionWS.xyzz;
                // apply fog
                clip(col.a-0.5f);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}