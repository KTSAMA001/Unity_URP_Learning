using System.Collections;
using System.Collections.Generic;
using Unity.Collections;
using UnityEngine;
using UnityEngine.Serialization;

[ExecuteAlways]
public class SetNPRFacePosWS : MonoBehaviour
{
    [ReadOnly]
    [SerializeField]private Material _m;

    [SerializeField]private Transform _facePoint;
    [SerializeField]private Transform _headBone;
    [SerializeField]private bool _autoSetFaceRight = false;
    [FormerlySerializedAs("_autoSetForward")] [SerializeField]private bool _autoSetFaceForward = false;
    private Transform _transform;
    private static readonly int FaceShadowPosWs = Shader.PropertyToID("_FaceShadowPosWS");

    // Start is called before the first frame update
    void Start()
    {
        _m = GetComponent<SkinnedMeshRenderer>().sharedMaterial;
        _transform = transform;
    }
 
    // Update is called once per frame
    void Update()
    {
        if (_transform == null)
        {
            _transform = transform;
        }
       
        if (_m==null)
        {
            _m = GetComponent<SkinnedMeshRenderer>().sharedMaterial;
        }
        _m.SetVector(FaceShadowPosWs,_facePoint.position);
        if (_autoSetFaceRight&&_headBone!=null)
        {
         
            _m.SetVector("_FaceRight", - _headBone.forward);
        }

        if (_autoSetFaceForward&&_headBone!=null)
        {
            _m.SetVector("_FaceForward", _headBone.up);
        }
    }
}
