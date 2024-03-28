using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSOutLinePassFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Setting
    {
        public string profileTag= "Screen Space OutLine" ;
        public float InsiteEdgeWidth = 5;
        public Color EdgeColor = Color.white;
        public RTHandle cameraColorTag;
        
        public SSOutLineVolume ssol;

        //使用的Material
        public Material material;
    }
    public Setting setting = new Setting();
    class CustomRenderPass : ScriptableRenderPass
    {
        public Setting _setting;
        //新的构造方法
        public CustomRenderPass(Setting setting)
        {
            this._setting = setting;

        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
           
            profilingSampler = new ProfilingSampler(_setting.profileTag);
            ConfigureInput(ScriptableRenderPassInput.Color);
            ConfigureTarget(_setting.cameraColorTag);
            GetTempRT(renderingData);
        }
//作者：可盖大人ProMAX https://www.bilibili.com/read/cv29054886/ 出处：bilibili
        public void GetTempRT(in RenderingData data) {
            RenderingUtils.ReAllocateIfNeeded(ref _tempRT, data.cameraData.cameraTargetDescriptor);
        } 

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
         
        }

        private RTHandle _tempRT;
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(_setting.profileTag);
            // context.ExecuteCommandBuffer(cmd);
            // cmd.Clear();
            // setting.material.SetFloat("_InsiteEdgeWidth",setting.InsiteEdgeWidth);
            // setting.material.SetColor("_EdgeColor",setting.EdgeColor);
            //这样就可以使用Volume后处理 组件来调节参数了
            _setting.material.SetFloat("_InsiteEdgeWidth",_setting.ssol._edgeWidth.value);
            _setting.material.SetColor("_EdgeColor",_setting.ssol._edgeColor.value);
            using (new ProfilingScope(cmd, profilingSampler)) 
            {   
             
               CoreUtils.SetRenderTarget(cmd,_tempRT);
               Blitter.BlitTexture(cmd,_setting.cameraColorTag,new Vector4(1,1,0,0),_setting.material,0);
               CoreUtils.SetRenderTarget(cmd,_setting.cameraColorTag);
               Blitter.BlitTexture(cmd,_tempRT,_setting.cameraColorTag,_setting.material,0);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
            
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            _tempRT?.Release();
        }
        
    }

    CustomRenderPass m_ScriptablePass;
    private VolumeStack _volumeStack;
    private SSOutLineVolume ssol;
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(setting);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        _volumeStack = VolumeManager.instance.stack;
        ssol = _volumeStack.GetComponent<SSOutLineVolume>();
     
        setting.ssol = ssol;
        
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // if (!ShouldRender(in renderingData))
        // {
        //     //Camera sceneCamera = SceneView.currentDrawingSceneView.camera.targetTexture;
        //
        //     return;
        // }
        if(ssol.isEnabled.value)
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
       // if (!ShouldRender(in renderingData)) return;
        setting.cameraColorTag = renderer.cameraColorTargetHandle;
        
    }
    protected override void Dispose(bool disposing) {
        base.Dispose(disposing);
#if UNITY_EDITOR
        //如有需要,在此处销毁生成的资源,如Material等
        if (EditorApplication.isPlaying) {
            // Destroy(null_Material);
        } else {
            // DestroyImmediate(null_Material);
        }
#else
           //   Destroy(material);
#endif
    }
    bool ShouldRender(in RenderingData data) {
        if (!data.cameraData.postProcessEnabled || data.cameraData.cameraType != CameraType.Game) {
            return false;
        }
        if (m_ScriptablePass == null) {
            Debug.LogError($"RenderPass = null!");
            return false;
        }
        return true;
    } 
    void OnEnable()
    {
       
    }
    private void OnDisable()
    {
        //Shader.DisableKeyword("_DEPTH_OFFSET_COLOR");
    }
}


