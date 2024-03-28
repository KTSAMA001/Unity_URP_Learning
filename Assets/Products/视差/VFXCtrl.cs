using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class VFXCtrl : MonoBehaviour
{
    [SerializeField]Transform _mask;

    [SerializeField] private Material _mat_dissolve;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        _mat_dissolve.SetVector("_MaskPos",_mask.position);
        _mat_dissolve.SetVector("_BaseDir",_mask.up);
    }
}
