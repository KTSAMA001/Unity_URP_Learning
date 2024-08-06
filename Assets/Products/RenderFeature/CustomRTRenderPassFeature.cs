using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;

public class CustomRTRenderPassFeature : ScriptableRendererFeature
{
   
    [System.Serializable]
    public class Setting
    {
        //标记头发模型的Layer
        public LayerMask Layer;
        public string profileTag= "CustomRT";
        public string RTName= "CustomRT1";
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
        public ShaderTagId shaderTag1 = new ShaderTagId("DepthOnly");
        public ShaderTagId shaderTag2 = new ShaderTagId("UniversalForward");
        public Setting _setting;

        FilteringSettings filtering1;
        FilteringSettings filtering2;

       

        //新的构造方法
        public CustomRenderPass(Setting setting)
        {
            this._setting = setting;

            //创建queue以用于两个FilteringSettings的赋值
            RenderQueueRange queue = new RenderQueueRange();
            queue.lowerBound = Mathf.Min(setting.queueMax, setting.queueMin);
            queue.upperBound = Mathf.Max(setting.queueMax, setting.queueMin);

            filtering1 = new FilteringSettings(queue, setting.Layer);
        }
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            
            profilingSampler = new ProfilingSampler(_setting.profileTag);
            
            
            //获取一个ID，这也是我们之后在Shader中用到的Buffer名
            int temp = Shader.PropertyToID(_setting.RTName);
            //使用与摄像机Texture同样的设置
            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(temp, desc);
            soildColorID = temp;
            //将这个RT设置为Render Target
            ConfigureTarget(temp);
            //将RT清空为黑
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
          

        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(_setting.profileTag);
            
            // if (SceneView.currentDrawingSceneView)
            // {
            //    
            // }
            //
            
            Profiler.BeginSample(profilingSampler.name);
            cmd.BeginSample(profilingSampler.name);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            var draw1 = CreateDrawingSettings(shaderTag1, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw1.overrideMaterial = _setting.material;
            draw1.overrideMaterialPassIndex = 0;
            context.DrawRenderers(renderingData.cullResults, ref draw1, ref filtering1);
            var draw2 = CreateDrawingSettings(shaderTag1, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
            draw2.overrideMaterial = _setting.material;
            draw2.overrideMaterialPassIndex = 1;
            context.DrawRenderers(renderingData.cullResults, ref draw2, ref filtering1);

           
            cmd.EndSample(profilingSampler.name);
            
            Profiler.EndSample();
            
            /*using (new ProfilingScope(cmd, profilingSampler)) 
            {   
              
            }*/
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            
            cmd.ReleaseTemporaryRT(soildColorID);
        }
    }

    CustomRenderPass m_ScriptablePass;

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
}


