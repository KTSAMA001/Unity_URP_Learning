using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SSDepthMaskPassFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Setting
    {
        //标记目标模型的Layer
        public LayerMask targetLayer;
        public string profileTag= "Screen Space Object Depth Mask" ;
        //Render Queue的设置
        [Range(1000, 5000)]
        public int queueMin = 2000;
        [Range(1000, 5000)]
        public int queueMax = 3000;

        //使用的Material
        public Material material;
    }
    public Setting setting = new Setting();
    class CustomRenderPass : ScriptableRenderPass
    {
        //用于储存之后申请来的RT的ID
        public int soildColorID = 0;
        public ShaderTagId shaderTag1 = new ShaderTagId("UniversalForward");
        public Setting _setting;

        FilteringSettings filtering;

       

        //新的构造方法
        public CustomRenderPass(Setting setting)
        {
            this._setting = setting;

            //创建queue以用于两个FilteringSettings的赋值
            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = Mathf.Min(setting.queueMax, setting.queueMin);
            queue.upperBound = Mathf.Max(setting.queueMax, setting.queueMin);

            filtering = new FilteringSettings(queue, setting.targetLayer);
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
           CoreUtils.SetKeyword(cmd, "_DEPTH_MASK_COLOR",true);
           
           profilingSampler = new ProfilingSampler(_setting.profileTag);
           
           
           
           //使用与摄像机Texture同样的设置
           RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
           desc.depthBufferBits = 0;
           bool b= RenderingUtils.ReAllocateIfNeeded(  ref _tempRTH,
               /*new ScaleFunc(size => new Vector2Int(desc.width,desc.height)),*/
               desc,
               FilterMode.Bilinear,
               TextureWrapMode.Clamp,
               false,
               1,
               0f,
               "_DepthMaskColor"
           );
           // _tempRTH = RTHandles.Alloc(Vector2.one, depthBufferBits: DepthBits.Depth32, dimension: TextureDimension.Tex2D, name: "_DepthMaskColor");
        
           //获取一个ID，这也是我们之后在Shader中用到的Buffer名
           int temp = 0;
          
           
           temp=Shader.PropertyToID(_tempRTH.name);
           // _tempRTH=  RTHandles.Alloc(temp);
           CoreUtils.SetRenderTarget(cmd,_tempRTH);
           // cmd.GetTemporaryRT(temp, desc);
           // _tempRTH.
           // RenderTargetIdentifier renderTargetIdentifier = _tempRTH;
           cmd.SetGlobalTexture(temp, _tempRTH);
           soildColorID = temp;
           // 将这个RT设置为Render Target
           //   ConfigureTarget(temp);
           ConfigureTarget(_tempRTH);
           ConfigureClear(ClearFlag.All,Color.clear);
           
        }

        private RTHandle _tempRTH;
        private RenderTexture _rt;
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
           
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            
            CommandBuffer cmd = CommandBufferPool.Get(_setting.profileTag);
            using (new ProfilingScope(cmd, profilingSampler)) 
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                var draw1 = CreateDrawingSettings(shaderTag1, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                draw1.overrideMaterial = _setting.material;
                draw1.overrideMaterialPassIndex = 2;
                
                context.DrawRenderers(renderingData.cullResults, ref draw1, ref filtering);
               
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
          


        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            CoreUtils.SetKeyword(cmd, "_DEPTH_MASK_COLOR",false);
        //   cmd.ReleaseTemporaryRT(soildColorID);
         
        }

        public void Dispose()
        {
            _tempRTH?.Release();
        }
       
    }

    CustomRenderPass m_ScriptablePass;
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ScriptablePass.Dispose();
    }

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(setting);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
      
        renderer.EnqueuePass(m_ScriptablePass);
    }

   void OnEnable()
    {
       
    }
    private void OnDisable()
    {
        //Shader.DisableKeyword("_DEPTH_OFFSET_COLOR");
    }
}


