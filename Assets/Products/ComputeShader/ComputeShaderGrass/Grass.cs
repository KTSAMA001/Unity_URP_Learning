using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class Grass : MonoBehaviour
{
    public int grassCountPerFace = 10;
    [Range(0,1)]public float debugFloat=0;
    public Mesh terrianMesh;
    public Mesh _grassMesh;
    public ComputeShader _cs;
    private RenderTexture m_mainTex;
    private int m_texsize = 128;
    private Renderer m_rend;
    [FormerlySerializedAs("m_material")] public Material m_grassMaterial;
    private List<Vector3> _meshVertexPos = new List<Vector3>();
    struct GrassInfo
    {
        public Vector3 Pos;
        public Matrix4x4 TRS;
        public int id;
    }
  
    private GrassInfo[] m_grassInfos;
/// <summary>
/// 草数据的Buffer
/// </summary>
    private ComputeBuffer m_grassInfo_buffer;
    // 获取每个核心的线程组大小
    uint threadGroupSizeX, threadGroupSizeY, threadGroupSizeZ;
    // Start is called before the first frame update
    void Start()
    {
        terrianMesh = GetComponent<MeshFilter>().mesh;
        foreach (var v in terrianMesh.vertices)
        {
            var vertexPosition = v;
            _meshVertexPos.Add(vertexPosition);
            
        }
        _cs.GetKernelThreadGroupSizes(0, out threadGroupSizeX, out threadGroupSizeY, out threadGroupSizeZ);

       Debug.Log($"terrianMesh的顶点数{_meshVertexPos.Count}");
    }

    private void SetShaderTex()
    {
        uint threadGrupSizeX;
        _cs.GetKernelThreadGroupSizes(0,out threadGrupSizeX,out _,out _);
        int size = (int)threadGrupSizeX;
        CreateShaderTex();
        m_grassInfos = new GrassInfo[_meshVertexPos.Count*grassCountPerFace];
        
        
        for (int i = 0; i < _meshVertexPos.Count; i++)
        {
            for (int j = 0; j < grassCountPerFace; j++)
            {
                //1x1范围内随机分布
                Vector3 offset = _meshVertexPos[i] + new Vector3(Random.Range(0, 1f), 0,Random.Range(0, 1f) );
                //0到180度随机旋转
                float rot = Random.Range(0, 180);
                //构造变换矩阵
                var localToTerrian = Matrix4x4.TRS(offset, Quaternion.Euler(0, rot, 0), Vector3.one);
                m_grassInfos[i*grassCountPerFace+j] = new GrassInfo
                {
                    TRS = localToTerrian,
                    Pos = offset+new Vector3(debugFloat,debugFloat,debugFloat),
                    id= i*grassCountPerFace+j
                };
            }
        }
   
        m_grassInfo_buffer = new ComputeBuffer(_meshVertexPos.Count*grassCountPerFace, 64 + 12 + 4, ComputeBufferType.Default);

        m_grassInfo_buffer.SetData(m_grassInfos);
        _cs.SetBuffer(0,"GrassInfoBuffer",m_grassInfo_buffer);
        _cs.SetTexture(0,"Result",m_mainTex);
        m_rend.material.SetTexture("_BaseMap",m_mainTex);
        Debug.Log($"Grass buffer数量{m_grassInfo_buffer.count}");
        // 计算线程组数量
        int threadGroupsX = Mathf.CeilToInt((float)_meshVertexPos.Count*grassCountPerFace / threadGroupSizeX);
        int threadGroupsY = 1;  // 根据需要调整
        int threadGroupsZ = 1;  // 根据需要调整
        // _cs.Dispatch(0,10/10,10/1,1);
        _cs.Dispatch(0, threadGroupsX, threadGroupsY, threadGroupsZ);
        materialPropertyBlock.SetBuffer("_GrassInfoBuffer",m_grassInfo_buffer);
        m_grassMaterial.SetBuffer("_GrassInfoBuffer",m_grassInfo_buffer);
        Graphics.DrawMeshInstancedProcedural(CreateMesh(),0,m_grassMaterial,new Bounds(Vector3.zero, new Vector3(100f, 100f, 100f)),_meshVertexPos.Count*grassCountPerFace,materialPropertyBlock);
        m_grassInfo_buffer.Release();
    }
    private MaterialPropertyBlock _materialBlock;
    public MaterialPropertyBlock materialPropertyBlock{
        get{
            if(_materialBlock == null){
                _materialBlock = new MaterialPropertyBlock();
            }
            return _materialBlock;
        }
    }

    private void CreateShaderTex( )
    {
        m_mainTex = new RenderTexture(m_texsize, m_texsize, 0, RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();

        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;
    }

    // Update is called once per frame
    void Update()
    {
        SetShaderTex();
    }

    Mesh CreateMesh()
    {
        Mesh mesh = _grassMesh;
        

        return mesh;
    }
    
}
