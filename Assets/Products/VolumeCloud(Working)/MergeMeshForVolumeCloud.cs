using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.SceneManagement;
using UnityEngine;
[ExecuteAlways]
public class MergeMeshForVolumeCloud : MonoBehaviour
{
    [Header("这里存放所有合并的体积后处理的Mesh，使用同一个材质")]
    public MeshFilter[] _meshs_volumeCloud;
    [Header("这里的是云（体积）的材质")]
    public Material _material_Volume;

    private Mesh _volumeMesh;
    private Transform _transform;
    private GameObject _gameObject;

    private void Awake()
    {
        _transform = transform;
        _gameObject = gameObject;
    }

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        //UpdateMeshMerge();
    }

    [ContextMenu("UpdateMeshMerge")]
    private void UpdateMeshMerge()
    {
        
        if (_meshs_volumeCloud.Length<=0)
        {
            Debug.LogError($"{_gameObject.name}:没有需要合并的网格！");
            return;
        }
        
        CombineInstance[] combines = new CombineInstance[_meshs_volumeCloud.Length];
        _volumeMesh = new Mesh();
        for (int i = 0; i < _meshs_volumeCloud.Length; i++)
        {
            
            combines[i].mesh = _meshs_volumeCloud[i].sharedMesh;
            combines[i].transform = _transform.worldToLocalMatrix * _meshs_volumeCloud[i].transform.localToWorldMatrix;
            _volumeMesh.CombineMeshes(combines,true);
        }

        if (GetComponent<MeshFilter>()==null)
        {
            MeshFilter mf = _gameObject.AddComponent<MeshFilter>();
            mf.mesh = _volumeMesh;
            MeshRenderer mr=_gameObject.AddComponent<MeshRenderer>();
            if (_material_Volume != null)
            {
                mr.material = _material_Volume;    
            }
            else
            {
                Debug.LogError($"{_gameObject.name}:没有指定要使用的体积材质！");
                return;
            }
            
            
        }

        for (int i = 0; i < _meshs_volumeCloud.Length; i++)
        {
            _meshs_volumeCloud[i].gameObject.SetActive(false);
        }
    }
}
