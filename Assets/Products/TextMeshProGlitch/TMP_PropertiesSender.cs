using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
[ExecuteAlways]
public class TMP_PropertiesSender : MonoBehaviour
{
    [Range(0,1)]
    [SerializeField] private float _DebugFloat;
    [SerializeField] private float _Offset_Block=10;
    [SerializeField] private float _Speed=10;
    [SerializeField] private float _BlockLayer1_U=-4.21f;
    [SerializeField] private float _BlockLayer1_V=-5.1f;
    [SerializeField] private float _BlockLayer2_U=5.04f;
    [SerializeField] private float _BlockLayer2_V=-2.94f;
    [SerializeField] private float _BlockLayer1_Indensity=2.4f;
    [SerializeField] private float _BlockLayer2_Indensity=5.8f;
    [SerializeField] private float _RGBSplit_Indensity=0.28f;
    [SerializeField] private bool _Depth_Mask_Color_Local=false;
    [SerializeField] private Vector2 _DepthOffset=new Vector2(100,0);
    
    [SerializeField] private Color _DepthMaskColor1=Color.white;
    [SerializeField] private Color _DepthMaskColor2=Color.black;
    [Range(0,1)]
    [SerializeField] private float _Alpha=1f;
    private TMP_Text m_TextComponent;
    // Start is called before the first frame update
    void Start()
    {
        m_TextComponent = GetComponent<TMP_Text>();
    }

    // Update is called once per frame
    void Update()
    {
        if (System.Object.ReferenceEquals(m_TextComponent, null))
        {
            m_TextComponent = GetComponent<TMP_Text>();
        }
        // Shader.SetGlobalFloat("_DebugFloat",_DebugFloat);
        // Shader.SetGlobalFloat("_Offset_Block",_Offset_Block);
        // Shader.SetGlobalFloat("_BlockLayer1_U",_BlockLayer1_U);
        // Shader.SetGlobalFloat("_BlockLayer1_V",_BlockLayer1_V);
        // Shader.SetGlobalFloat("_BlockLayer2_U",_BlockLayer2_U);
        // Shader.SetGlobalFloat("_BlockLayer2_V",_BlockLayer2_V);
        // Shader.SetGlobalFloat("_BlockLayer1_Indensity",_BlockLayer1_Indensity);
        // Shader.SetGlobalFloat("_BlockLayer2_Indensity",_BlockLayer2_Indensity);
        // Shader.SetGlobalFloat("_RGBSplit_Indensity",_RGBSplit_Indensity);
        // Shader.SetGlobalFloat("_Alpha",_Alpha);
        m_TextComponent.materialForRendering.SetFloat("_DebugFloat",_DebugFloat);
        m_TextComponent.materialForRendering.SetFloat("_Speed",_Speed);
        m_TextComponent.materialForRendering.SetFloat("_Offset_Block",_Offset_Block);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer1_U",_BlockLayer1_U);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer1_V",_BlockLayer1_V);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer2_U",_BlockLayer2_U);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer2_V",_BlockLayer2_V);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer1_Indensity",_BlockLayer1_Indensity);
        m_TextComponent.materialForRendering.SetFloat("_BlockLayer2_Indensity",_BlockLayer2_Indensity);
        m_TextComponent.materialForRendering.SetFloat("_RGBSplit_Indensity",_RGBSplit_Indensity);
        if (_Depth_Mask_Color_Local)
        {
            m_TextComponent.materialForRendering.EnableKeyword("_DEPTH_MASK_COLOR_LOCAL_ON");
        }
        else
        {
            m_TextComponent.materialForRendering.DisableKeyword("_DEPTH_MASK_COLOR_LOCAL_ON");
        }
        m_TextComponent.materialForRendering.SetVector("_DepthOffset",_DepthOffset);
        m_TextComponent.materialForRendering.SetColor("_DepthMaskColor1",_DepthMaskColor1);
        m_TextComponent.materialForRendering.SetColor("_DepthMaskColor2",_DepthMaskColor2);
        m_TextComponent.materialForRendering.SetFloat("_Alpha",_Alpha);
    }
}
