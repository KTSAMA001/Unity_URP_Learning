using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class ComputeBuferTest : MonoBehaviour
{
    // struct Properties
    // {
    //     Vector3 vertices;
    //     Vector3 normals;
    //     Vector4 tangent;
    // };
    // Properties[] _meshProp;
    // ComputeBuffer _meshBuffer;


    public ComputeShader _cs;
    [Range(0.0f, 0.5f)] public float m_radius = 0.5f;
    [Range(0.0f, 1.0f)] public float m_center = 0.5f;
    [Range(0.0f, 0.5f)] public float m_smooth = 0.01f;
    public Color m_maincolor = new Color();
    private RenderTexture m_mainTex;
    private int m_texsize = 128;
    private Renderer m_rend;

    struct Circle
    { 
        public float radius;
        public float center;
        public float smooth;
    }

    private Circle[] m_circle;

    private ComputeBuffer m_buffer;
    // Start is called before the first frame update
    void Start()
    {
        CreateShaderTex();
    }
    private void CreateShaderTex( )
    {
        m_mainTex = new RenderTexture(m_texsize, m_texsize, 0, RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();

        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;
    }

    void SetShaderTex()
    {
        uint threadGrupSizeX;
        _cs.GetKernelThreadGroupSizes(0,out threadGrupSizeX,out _,out _);
        int size = (int)threadGrupSizeX;
       
        m_circle = new Circle[size];
        for (int i = 0; i < size; i++)
        {
            //错误示范
            // Circle circle = m_circle[i];
            // circle.radius = m_radius;
            // circle.center = m_center;
            // circle.smooth = m_smooth;
            
            //正确用法一
            // Circle circle = new Circle();
            // circle.radius = m_radius;
            // circle.center = m_center;
            // circle.smooth = m_smooth;
            // m_circle[i] = circle;
            
            //正确用法二
            m_circle[i] = new Circle
            {
                radius = m_radius,
                center = m_center,
                smooth = m_smooth
            };
        }

        int stride = 12;
        Debug.Log(m_circle.Length);
        m_buffer = new ComputeBuffer(size, stride, ComputeBufferType.Default);
        m_buffer.SetData(m_circle);
        _cs.SetBuffer(0,"CircleBuffer",m_buffer);
        
        _cs.SetTexture(0,"Result",m_mainTex);
        _cs.SetVector("MainColor",m_maincolor);
        m_rend.material.SetTexture("_BaseMap",m_mainTex);
        _cs.Dispatch(0,m_texsize/128,m_texsize/1,1);
        m_buffer.Release();

    }
    // Update is called once per frame
    void Update()
    {
        SetShaderTex();
    }
}
