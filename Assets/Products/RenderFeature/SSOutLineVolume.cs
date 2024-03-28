using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;
[VolumeComponentMenu("KTSAMA_PostProcessing/ScreenSpaceOutLine")]
public class SSOutLineVolume : VolumeComponent,IPostProcessComponent
{
    public BoolParameter isEnabled=new BoolParameter(false);
    public FloatParameter _edgeWidth = new FloatParameter(4,true);
    public ColorParameter _edgeColor = new ColorParameter(Color.white, true);
    public bool IsActive()
    {
        return isEnabled.value;
    }

    public bool IsTileCompatible()
    {
        return false;
    }

}
