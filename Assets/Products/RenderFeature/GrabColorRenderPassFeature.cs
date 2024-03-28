using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrabColorRenderPassFeature : ScriptableRendererFeature
{
  
    public Setting setting;
    GrabColorPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new GrabColorPass(setting);
#if UNITY_EDITOR
        if (SceneView.currentDrawingSceneView)
        {
            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        }
        else
        {
            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        }
#else
          // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
#endif
       
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
#if UNITY_EDITOR
        if (SceneView.currentDrawingSceneView)
        {
            setting.scene_cameraColorTag = renderer.cameraColorTargetHandle;
        }
        else
        {
            setting.cameraColorTag = renderer.cameraColorTargetHandle;
        }
        #else
          setting.cameraColorTag = renderer.cameraColorTargetHandle;
#endif
       
      
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ScriptablePass.OnDispose();
    }
}
[System.Serializable]
public class Setting
{
    public string profileTag= "Grab Color Pass";
    public RTHandle cameraColorTag;
    public RTHandle scene_cameraColorTag;
    public RenderTexture scene_cameraRT;
}

class GrabColorPass : ScriptableRenderPass
{
    private Setting _setting;
    private RTHandle _grabRT_GameView;
    private RTHandle _grabRT_SceneView;
    public GrabColorPass(Setting setting)
    {
        _setting = setting;
    }
  
    // This method is called before executing the render pass.
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in a performant manner.
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
       // ConfigureClear(ClearFlag.All,Color.black);
       RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
       desc.depthBufferBits = 0;
       #if UNITY_EDITOR
        if (SceneView.currentDrawingSceneView)
        {
            RenderingUtils.ReAllocateIfNeeded(ref _grabRT_SceneView,desc );
            cmd.SetGlobalTexture("_KTGrabTex",_grabRT_SceneView.nameID);
           
        }
        else
        {
            RenderingUtils.ReAllocateIfNeeded(ref _grabRT_GameView,desc );
            cmd.SetGlobalTexture("_KTGrabTex",_grabRT_GameView.nameID);
        }
       
        
        #else
          RenderingUtils.ReAllocateIfNeeded(ref _grabRT_GameView,desc );
         cmd.SetGlobalTexture("_KTGrabTex",_grabRT_GameView.nameID);
       #endif
        
       
    }

    // Here you can implement the rendering logic.
    // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
    // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
    // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(_setting.profileTag);
      
        using (new ProfilingScope(cmd, profilingSampler)) 
        {  
            // cmd.Blit(_setting.cameraColorTag,_grabRT);
#if UNITY_EDITOR
            if (SceneView.currentDrawingSceneView)
            {
                Blitter.BlitCameraTexture(cmd,_setting.scene_cameraColorTag,_grabRT_SceneView);
            }
            else
            {
                
                    Blitter.BlitCameraTexture(cmd,_setting.cameraColorTag,_grabRT_GameView);
        
                }
          
            #else
       
              Blitter.BlitCameraTexture(cmd,_setting.cameraColorTag,_grabRT_GameView);
        
#endif
        }
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        CommandBufferPool.Release(cmd);
    }

    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
       
    }

    public void OnDispose()
    {
        _grabRT_GameView?.Release();
        _grabRT_SceneView?.Release();
    }
    
}
