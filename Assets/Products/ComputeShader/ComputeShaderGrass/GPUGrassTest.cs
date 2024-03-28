using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Serialization;
using Random = UnityEngine.Random;
[ExecuteAlways]
public class GPUGrassTest : MonoBehaviour
{
    public float _heigheOffsetColor2=2;
    public Vector3 _noiseOffset =new Vector3(1f,3.57f,3.28f);
    public Color GrassColor1;
    public Color GrassColor2;
    private Transform _transform;
    public Transform _playerTrans;
    [Header("每单位面积（三角面面积）草的数量，默认为10")] public int _grass_PreUnit = 10;
    public Mesh _grassMesh;
    [FormerlySerializedAs("_m")] public Material _grassMaterial;
    Camera cam;
    uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
    private int cellCountX = -1;

    private int cellCountZ = -1;
    private Matrix4x4 _pivotTRS;
    private static readonly int PlayerPos = Shader.PropertyToID("_PlayerPos");
   

    //smaller the number, CPU needs more time, but GPU is faster
    public MeshFilter[] _terrianMeshGroup;

    private Plane[] cameraFrustumPlanes = new Plane[6];
    public float drawDistance = 125; //this setting will affect performance a lot!

    // private float Local_minX, Local_minZ, Local_maxX, Local_maxZ;
    private int visibleCount = -1;

    struct GrassInfo
    {
        public Matrix4x4 TRS;
    }

    class GrassInfosGroup
    {
        public Vector3 Center;
        public GrassInfo[] GrassInfos;
    }

    public MaterialPropertyBlock materialPropertyBlock
    {
        get
        {
            if (_materialBlock == null)
            {
                _materialBlock = new MaterialPropertyBlock();
            }

            return _materialBlock;
        }
    }

    private List<GrassInfo> _grassInfos = new List<GrassInfo>();

    /// <summary>
    /// 草数据的Buffer
    /// </summary>
    private ComputeBuffer _grassInfo_buffer;

    private ComputeBuffer _cullResult_buffer;

    public ComputeShader _fc_cs;

    // private GraphicsBuffer _graphicsBuffer;
    private static readonly int GrassInfoBuffer = Shader.PropertyToID("_GrassInfoBuffer");
    private static readonly int OffsetPos = Shader.PropertyToID("_OffsetPos");

    private GrassInfosGroup[] _grassUnitGroup;


    private MaterialPropertyBlock _materialBlock;

    private Vector3 scale;
    private int FrustumCullingKernel;
    private ComputeBuffer argsBuffer;

    [Header("-----------Debug--------------")]
    public bool EnableDraw = true;

    public bool EnableUpdate = true;
    // public Color _gizmoBoundColor = new Color(1, 0, 0, 0.3f);
    // public Vector3 _boundSize = Vector3.one * 0.9f;


    private List<Vector3> DebugCellPos = new List<Vector3>();
    private List<Vector3> DebugCellSize = new List<Vector3>();
    private static readonly int VpMatrix = Shader.PropertyToID("_VPMatrix");
    private static readonly int MaxDrawDistance = Shader.PropertyToID("_MaxDrawDistance");
    private static readonly int CulllResult = Shader.PropertyToID("CulllResult");
    private static readonly int InstanceCount = Shader.PropertyToID("instanceCount");
    private static readonly int GrassInfos = Shader.PropertyToID("GrassInfos");
    private static readonly int Offset = Shader.PropertyToID("Offset");
    private static readonly int PivotTRS = Shader.PropertyToID("_PivotTRS");
    // Start is called before the first frame update
    private void Awake()
    {
        _transform = transform;
    }

    void Start()
    {
     
        cam = Camera.main;
        scale = _transform.localScale;
        //_terrianMesh = GetComponent<MeshFilter>().mesh;
        Mesh _terrianMesh = CreateTerrianMesh();
        FrustumCullingKernel = _fc_cs.FindKernel("FrustumCulling");
        var indices = _terrianMesh.triangles;
        var vertices = _terrianMesh.vertices;
        _grassUnitGroup = new GrassInfosGroup[indices.Length / 3];
        for (var j = 0; j < indices.Length / 3; j++)
        {
            var index1 = indices[j * 3];
            var index2 = indices[j * 3 + 1];
            var index3 = indices[j * 3 + 2];
            var v1 = new Vector3(vertices[index1].x * scale.x, vertices[index1].y * scale.y,
                vertices[index1].z * scale.z);
            var v2 = new Vector3(vertices[index2].x * scale.x, vertices[index2].y * scale.y,
                vertices[index2].z * scale.z);
            var v3 = new Vector3(vertices[index3].x * scale.x, vertices[index3].y * scale.y,
                vertices[index3].z * scale.z);

            //面得到法向
            var normal = GetFaceNormal(v1, v2, v3);

            //计算up到faceNormal的旋转四元数
            var upToNormal = Quaternion.FromToRotation(Vector3.up, normal);

            //三角面积
            var arena = GetAreaOfTriangle(v1, v2, v3);

            //计算在该三角面中，需要种植的数量
            var countPerTriangle = Mathf.CeilToInt(Mathf.Max(1, _grass_PreUnit * arena));
            _grassUnitGroup[j] = new GrassInfosGroup();
            _grassUnitGroup[j].Center = (v1 + v2 + v3) / 3;
            _grassUnitGroup[j].GrassInfos = new GrassInfo[countPerTriangle];
            for (var i = 0; i < countPerTriangle; i++)
            {
                var positionInTerrian = RandomPointInsideTriangle(v1, v2, v3);
                float rot = Random.Range(0, 180);
                Vector3 S = new Vector3(1, Random.Range(0.3f, 1f), 1);
                var localToTerrian = Matrix4x4.TRS(positionInTerrian,upToNormal*  Quaternion.Euler(0, rot, 0), S);

                GrassInfo grassinfo = new GrassInfo
                {
                    TRS = localToTerrian,
                };
                _grassInfos.Add(grassinfo);


                _grassUnitGroup[j].GrassInfos[i] = grassinfo;
            }
        }


        if (argsBuffer != null)
            argsBuffer.Release();

        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);

        args[0] = (uint)CreateMesh().GetIndexCount(0);
        args[1] = (uint)_grassInfos.Count;
        args[2] = (uint)CreateMesh().GetIndexStart(0);
        args[3] = (uint)CreateMesh().GetBaseVertex(0);
        args[4] = 0;
        argsBuffer.SetData(args);
        _cullResult_buffer = new ComputeBuffer(_grassInfos.Count,64,ComputeBufferType.Append);
        if (_grassInfo_buffer != null)
        {
            _grassInfo_buffer.Release();
        }

        _grassInfo_buffer = new ComputeBuffer(_grassInfos.Count, 64);
        _grassInfo_buffer.SetData(_grassInfos);
        
        _fc_cs.SetBuffer(FrustumCullingKernel,GrassInfos,_grassInfo_buffer);
     
        _fc_cs.SetInt(InstanceCount,_grassInfos.Count);
    }

    private Mesh CreateTerrianMesh()
    {
        CombineInstance[] combines = new CombineInstance[_terrianMeshGroup.Length];
        Mesh mesh = new Mesh();
        for (int i = 0; i < _terrianMeshGroup.Length; i++)
        {
            combines[i].mesh = _terrianMeshGroup[i].sharedMesh;
            combines[i].transform = _transform.worldToLocalMatrix * _terrianMeshGroup[i].transform.localToWorldMatrix;
            mesh.CombineMeshes(combines,true);
        }

        return mesh;
    }

  

    // Update is called once per frame
    void Update()
    {
        Quaternion r = _transform.rotation;
        Vector3 pos = _transform.position;
        _pivotTRS.SetTRS(pos,r,Vector3.one);
        _pivotTRS.SetTRS(pos,r,Vector3.one);
        _grassMaterial.SetMatrix(PivotTRS,_pivotTRS);
        _grassMaterial.SetVector(PlayerPos,_playerTrans.position);
        _grassMaterial.SetColor("_BaseColor",GrassColor1);
        _grassMaterial.SetColor("_BaseColor2",GrassColor2);
        _grassMaterial.SetFloat("_HeightOffset_BaseColor2",_heigheOffsetColor2);
        _grassMaterial.SetVector("_NoiseOffset",_noiseOffset);
        _grassMaterial.SetVector(PlayerPos,_playerTrans.position);
        //_pivotTRS.SetTRS(Vector3.zero, transform.rotation,Vector3.one);
        _fc_cs.SetMatrix(PivotTRS,_pivotTRS);
        if (EnableUpdate)
        {
              _cullResult_buffer.SetCounterValue(0);
        _fc_cs.SetBuffer(FrustumCullingKernel,CulllResult,_cullResult_buffer);
        
        float cameraOriginalFarPlane = cam.farClipPlane;
        cam.farClipPlane = drawDistance; //allow drawDistance control    
        GeometryUtility.CalculateFrustumPlanes(cam, cameraFrustumPlanes);//Ordering: [0] = Left, [1] = Right, [2] = Down, [3] = Up, [4] = Near, [5] = Far
        cam.farClipPlane = cameraOriginalFarPlane; //revert far plane edit
        //find all instances's posWS XZ bound min max

       
        /*DebugCellPos.Clear();
        DebugCellSize.Clear();
        for (int i = 0; i < _grassUnitGroup.Length; i++)
        {
            //create cell bound
            Vector3 centerPosWS = _grassUnitGroup[i].Center;
           
            
            centerPosWS+= transform.position;
            Vector3 sizeWS = new Vector3(_boundSize.x*scale.x,_boundSize.y*scale.y,_boundSize.z*scale.z);
            Bounds cellBound = new Bounds(centerPosWS, sizeWS);
            
            if (GeometryUtility.TestPlanesAABB(cameraFrustumPlanes, cellBound))
            {
                
                DebugCellPos.Add(centerPosWS);
                DebugCellSize.Add(sizeWS);
                //_visibleGrassList.Add(_grassUnitGroup[i].GrassInfos[0]);
               //_visibleGrassList.Add(m_grassInfos[cellPosWSsList[i][0]]);
            }
        }
        */
        


        //  if (visibleCount!=  _visibleCellIDList.Count&&_visibleCellIDList.Count>0)
       
        // visibleCount = _visibleCellIDList.Count;
      

        Matrix4x4 v = cam.worldToCameraMatrix;
        Matrix4x4 p = cam.projectionMatrix;
        Matrix4x4 vp = p * v;
        
        _fc_cs.SetMatrix(VpMatrix,vp);
        _fc_cs.SetFloat(MaxDrawDistance,drawDistance);
        //_fc_cs.SetVector(Offset,transform.position);
        _fc_cs.Dispatch(FrustumCullingKernel, 1 + (_grassInfos.Count / 640), 1, 1);
        
         ComputeBuffer.CopyCount(_cullResult_buffer, argsBuffer, sizeof(uint));
        // if (_visibleCellIDList.Count > 0)
        //_grassInfo_buffer.SetData(_visibleGrassList);
        //materialPropertyBlock.SetBuffer(GrassInfoBuffer, _grassInfo_buffer);
        //materialPropertyBlock.SetVector(OffsetPos, transform.position);
        _grassMaterial.SetVector(OffsetPos, transform.position);
        _grassMaterial.SetBuffer(GrassInfoBuffer, _cullResult_buffer);
        }
      
        if (EnableDraw)
        {
            Bounds renderBound = new Bounds(transform.position, new Vector3(1000f, 1000f, 1000f));
            // renderBound.SetMinMax(new Vector3(Local_minX, 0, Local_minZ), new Vector3(Local_maxX, 0, Local_maxZ));//if camera frustum is not overlapping this bound, DrawMeshInstancedIndirect will not even render
            // renderBound.SetMinMax(new Vector3(Local_minX, 0, Local_minZ), new Vector3(Local_maxX, 0, Local_maxZ));//if camera frustum is not overlapping this bound, DrawMeshInstancedIndirect will not even render

            // Graphics.DrawMeshInstancedProcedural(CreateMesh(),
            //     0,
            //     _m,
            //     renderBound,
            //     _visibleGrassList.Count,
            //     materialPropertyBlock);

            Graphics.DrawMeshInstancedIndirect(CreateMesh(), 0, _grassMaterial, renderBound, argsBuffer);
            // Graphics.DrawMeshInstancedIndirect(CreateMesh(),0,_m,new Bounds(Vector3.zero, new Vector3(100f, 100f, 100f)),m_grassInfo_buffer,grassCount,materialPropertyBlock);
            //_m. SetBuffer(GrassInfoBuffer,_graphicsBuffer);
        }

       
    }

    // void OnDrawGizmos()
    // {
    //     for (int i = 0; i < DebugCellPos.Count; i++)
    //     {
    //         // 设置Gizmos颜色
    //         Gizmos.color = _gizmoBoundColor;
    //
    //         // 在指定坐标上绘制一个点
    //         Gizmos.DrawCube(DebugCellPos[i], DebugCellSize[i] * 0.9f + Vector3.up * 0.01f);
    //     }
    // }

    private void OnDisable()
    {
        ReleaseBuffer(argsBuffer);
        ReleaseBuffer(_cullResult_buffer);
        ReleaseBuffer(_grassInfo_buffer);
    }

    private void ReleaseBuffer(ComputeBuffer cb)
    {
        if (cb!=null)
        {
            cb.Release();
            cb = null;
        }
    }

    Mesh CreateMesh()
    {
        if (!_grassMesh)
        {
            //if not exist, create a 3 vertices hardcode triangle grass mesh
            _grassMesh = new Mesh();

            //single grass (vertices)
            Vector3[] verts = new Vector3[3];
            verts[0] = new Vector3(-0.2f, 0);
            verts[1] = new Vector3(+0.2f, 0);
            verts[2] = new Vector3(-0.0f, 1f);
            //single grass (Triangle index)
            int[] trinagles = new int[3] { 2, 1, 0, }; //order to fit Cull Back in grass shader

            _grassMesh.SetVertices(verts);
            _grassMesh.SetTriangles(trinagles, 0);
            _grassMesh.SetUVs(0, new List<Vector2>() { new Vector2(1, 0), new Vector2(0, 0), new Vector2(0.5f, 1) });
        }

        return _grassMesh;
    }

    //计算三角形面积
    public float GetAreaOfTriangle(Vector3 p1, Vector3 p2, Vector3 p3)
    {
        var vx = p2 - p1;
        var vy = p3 - p1;
        var dotvxy = Vector3.Dot(vx, vy);
        var sqrArea = vx.sqrMagnitude * vy.sqrMagnitude - dotvxy * dotvxy;
        return 0.5f * Mathf.Sqrt(sqrArea);
    }

    public Vector3 GetFaceNormal(Vector3 p1, Vector3 p2, Vector3 p3)
    {
        var vx = p2 - p1;
        var vy = p3 - p1;
        return Vector3.Cross(vx, vy);
    }

    /// <summary>
    /// 三角形内部，取平均分布的随机点
    /// </summary>
    public Vector3 RandomPointInsideTriangle(Vector3 p1, Vector3 p2, Vector3 p3)
    {
        var x = Random.Range(0, 1f);
        var y = Random.Range(0, 1f);
        if (y > 1 - x)
        {
            //如果随机到了右上区域，那么反转到左下
            var temp = y;
            y = 1 - x;
            x = 1 - temp;
        }

        var vx = p2 - p1;
        var vy = p3 - p1;
        return p1 + x * vx + y * vy;
    }
}