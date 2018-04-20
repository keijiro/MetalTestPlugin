using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Collections;
using System.Runtime.InteropServices;

unsafe public class Test : MonoBehaviour
{
    [SerializeField] RenderTexture _rt1;
    [SerializeField] RenderTexture _rt2;

    [DllImport ("MetalTestPlugin")]
    static extern System.IntPtr Plugin_GetBlitFunction();

    NativeArray<System.IntPtr> _params1;
    NativeArray<System.IntPtr> _params2;
    CommandBuffer _cmd;

    void Start()
    {
        _rt1.Create();
        _rt2.Create();

        _params1 = new NativeArray<System.IntPtr>(new System.IntPtr[2], Allocator.Persistent);
        _params2 = new NativeArray<System.IntPtr>(new System.IntPtr[2], Allocator.Persistent);
        _cmd = new CommandBuffer();
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        var p = (Time.frameCount & 1) == 0 ? _params1 : _params2;

        p[0] = _rt1.colorBuffer.GetNativeRenderBufferPtr();
        p[1] = _rt2.colorBuffer.GetNativeRenderBufferPtr();

        _cmd.Clear();

        var ptr = (System.IntPtr)p.GetUnsafeReadOnlyPtr();
        _cmd.IssuePluginEventAndData(Plugin_GetBlitFunction(), 0, ptr);

        Graphics.ExecuteCommandBuffer(_cmd);

        Graphics.Blit(src, dst);
    }

    void OnDestroy()
    {
        _params1.Dispose();
        _params2.Dispose();
        _cmd.Dispose();
    }
}
