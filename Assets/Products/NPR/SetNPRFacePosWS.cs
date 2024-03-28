using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
[ExecuteAlways]
public class SetNPRFacePosWS : MonoBehaviour
{
    [ReadOnly]
    [SerializeField]private Material _m;

    [SerializeField]private Transform _facePoint;

    private static readonly int FaceShadowPosWs = Shader.PropertyToID("_FaceShadowPosWS");

    // Start is called before the first frame update
    void Start()
    {
        _m = GetComponent<SkinnedMeshRenderer>().sharedMaterial;
        
    }
 
    // Update is called once per frame
    void Update()
    {
        if (_m==null)
        {
            _m = GetComponent<SkinnedMeshRenderer>().material;
        }
        _m.SetVector(FaceShadowPosWs,_facePoint.position);
    }
}
