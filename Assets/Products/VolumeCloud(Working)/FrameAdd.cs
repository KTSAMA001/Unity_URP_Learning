using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FrameAdd : MonoBehaviour
{
    private Material m;

    private RenderTexture rt;
    private RenderTexture rt2;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (m == null)
        {
            m.shader=Shader.Find("Hidden/BlendFrame");
        }

        if (rt == null)
        {
            rt = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
        }  if (rt2 == null)
        {
            rt2 = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
        }
     
        Graphics.Blit(source,rt,m);
        Graphics.Blit(rt,rt2,m);
        Graphics.Blit(rt,destination);
        
    }
}
