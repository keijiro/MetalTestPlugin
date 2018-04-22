using System;
using System.Runtime.InteropServices;
using UnityEngine;

public class BlitTest : MonoBehaviour
{
    [SerializeField] MeshRenderer _renderer;

    [DllImport("MetalTestPlugin")]
    static extern IntPtr Plugin_CreateIOSurfaceBackedTexture(int width, int height);

    [DllImport("MetalTestPlugin")]
    static extern IntPtr Plugin_LookUpIOSurfaceBackedTexture(uint surfaceID);

    [DllImport("MetalTestPlugin")]
    static extern void Plugin_DestroyIOSurfaceBackedTexture(IntPtr texture);

    [DllImport("MetalTestPlugin")]
    static extern uint Plugin_GetIOSurfaceBackedTextureID(IntPtr texture);

    Texture2D _sourceTexture;
    Texture2D _targetTexture;

    void Start()
    {
        _sourceTexture = Texture2D.CreateExternalTexture(
            512, 512, TextureFormat.RGBA32, false, false,
            Plugin_CreateIOSurfaceBackedTexture(512, 512)
        );

        _targetTexture = Texture2D.CreateExternalTexture(
            512, 512, TextureFormat.RGBA32, false, false,
            Plugin_LookUpIOSurfaceBackedTexture(Plugin_GetIOSurfaceBackedTextureID(_sourceTexture.GetNativeTexturePtr()))
        );

        _renderer.material.mainTexture = _targetTexture;
    }

    void OnDestroy()
    {
        Plugin_DestroyIOSurfaceBackedTexture(_sourceTexture.GetNativeTexturePtr());
        Plugin_DestroyIOSurfaceBackedTexture(_targetTexture.GetNativeTexturePtr());

        Destroy(_sourceTexture);
        Destroy(_targetTexture);
    }

    unsafe void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        var temp = RenderTexture.GetTemporary(512, 512, 0, RenderTextureFormat.Default, RenderTextureReadWrite.Linear);
        Graphics.Blit(source, temp);
        Graphics.CopyTexture(temp, _sourceTexture);
        RenderTexture.ReleaseTemporary(temp);
        Graphics.Blit(source, destination);
    }
}
