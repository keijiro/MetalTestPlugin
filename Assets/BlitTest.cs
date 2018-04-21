using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Collections;
using System;
using System.Runtime.InteropServices;

public class BlitTest : MonoBehaviour
{
    [SerializeField] MeshRenderer _renderer;

    [DllImport ("MetalTestPlugin")]
    static extern System.IntPtr Plugin_GetBlitFunction();

    struct BlitParams
    {
        public IntPtr source;
        public IntPtr destination;
        public uint width;
        public uint height;
    };

    NativeArray<BlitParams> _params;
    CommandBuffer _command;
    RenderTexture _target;

    void Start()
    {
        _params = new NativeArray<BlitParams>(new BlitParams[2], Allocator.Persistent);
        _command = new CommandBuffer();
    }

    void OnDestroy()
    {
        if (_target != null) RenderTexture.ReleaseTemporary(_target);

        _params.Dispose();
        _command.Dispose();
    }

    unsafe void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_target != null)
        {
            if (_target.width != source.width || _target.height != source.height)
            {
                RenderTexture.ReleaseTemporary(_target);
                _target = null;
            }
        }
            
        if (_target == null)
        {
            _target = RenderTexture.GetTemporary(source.width, source.height, 24);
            _target.Create();
            _renderer.material.mainTexture = _target;
        }

        // A heisenbug is here; We have to compare the following pointers
        // to avoid getting an invalid render buffer.
        var ptsrc = source.GetNativeTexturePtr();
        var pbsrc = source.colorBuffer.GetNativeRenderBufferPtr();
        if (ptsrc == pbsrc) return;

        var p = new NativeSlice<BlitParams>(_params, Time.frameCount & 1);

        p[0] = new BlitParams {
            source = pbsrc,
            destination = _target.colorBuffer.GetNativeRenderBufferPtr(),
            width = (uint)source.width,
            height = (uint)source.height
        };

        _command.Clear();
        _command.IssuePluginEventAndData(
            Plugin_GetBlitFunction(), 0,
            (System.IntPtr)p.GetUnsafeReadOnlyPtr()
        );

        Graphics.ExecuteCommandBuffer(_command);
        Graphics.Blit(source, destination);
    }
}
