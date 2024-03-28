using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialMatrixShow : MonoBehaviour
{
    public GameObject _testGameObject;
    [Header("矩阵范围")]
    public int _index;
    [Header("间隔")]
    public float _inv=0.1f;

    public Transform _center;

    public string _matellicPropName="_Metallic";
    public string _roughnessPropName="_Roughness";
    // Start is called before the first frame update
    void Start()
    {
        float h = _inv * (_index-1);
        float w = _inv * (_index-1);
        float l = _inv *  (_index-1);
        float def_m = 0;
        float def_f = 0;
        Vector3 startPos = _center.position - new Vector3(l / 2, h / 2, w / 2);
        GameObject temp;
        Vector3 pos = Vector3.zero;
        pos = startPos;
        for (int i=0;i<_index;i++)
        {
            
            for (int j = 0; j < _index; j++)
            {
                
                for (int k = 0; k < _index; k++)
                {
                    pos= startPos+Vector3.right*_inv*k+Vector3.forward*_inv*j+Vector3.up*_inv*i;
                    temp=Instantiate(_testGameObject,_center);
                    temp.transform.position =pos;
                    temp.GetComponent<MeshRenderer>().material.SetFloat(_matellicPropName,Mathf.Min(1,((float)k+0.2f)/(float)_index));
                    //Debug.Log(temp.GetComponent<MeshRenderer>().material.GetFloat(_matellicPropName));
                    temp.GetComponent<MeshRenderer>().material.SetFloat(_roughnessPropName,Mathf.Min(1,((float)j+0.2f)/(float)_index));
                    temp.GetComponent<MeshRenderer>().material.color=Color.white*(((float)i+0.2f)/(float)_index);
                }
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
