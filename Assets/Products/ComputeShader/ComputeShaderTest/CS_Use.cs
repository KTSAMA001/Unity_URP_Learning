using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class CS_Use : MonoBehaviour
{
    public ComputeShader _cs;
    public Texture _tex;
    

    [FormerlySerializedAs("_rt")] public RenderTexture _maintex;

    private int _texsize = 256;

    private Renderer _rend;
    // Start is called before the first frame update
    void Start()
    {
        CreateShaderTex();
        _cs.SetTexture(0,"Result",_maintex);
        _cs.SetTexture(0,"ColTex",_tex);
        _rend.material.SetTexture("_BaseMap",_maintex);
        _cs.Dispatch(0,_texsize/8,_texsize/8,1);
    }

    private void CreateShaderTex()
    {
        _maintex = new RenderTexture(_texsize, _texsize, 0, RenderTextureFormat.ARGB32);
        _maintex.enableRandomWrite = true;
        _maintex.Create();

        _rend = GetComponent<Renderer>();
        _rend.enabled = true;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
