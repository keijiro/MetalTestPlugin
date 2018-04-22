#import <Metal/MTLDevice.h>
#import <Metal/MTLTexture.h>
#import "IUnityGraphicsMetal.h"

static IUnityInterfaces* s_interfaces;
static IUnityGraphicsMetal* s_graphics;

static id<MTLDevice> GetMetalDevice()
{
    if (!s_graphics) s_graphics = UNITY_GET_INTERFACE(s_interfaces, IUnityGraphicsMetal);
    return s_graphics ? s_graphics->MetalDevice() : nil;
}

void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* interfaces)
{
    s_interfaces = interfaces;
}

void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginUnload(void)
{
    s_interfaces = NULL;
    s_graphics = NULL;
}

void* Plugin_CreateIOSurfaceBackedTexture(int width, int height)
{
    id<MTLDevice> dev = GetMetalDevice();
    if (!dev) return NULL;

    NSDictionary* attribs = @{(NSString*)kIOSurfaceIsGlobal: @YES,
                              (NSString*)kIOSurfaceWidth: @(width),
                              (NSString*)kIOSurfaceHeight: @(height),
                              (NSString*)kIOSurfaceBytesPerElement: @4u};

    IOSurfaceRef surface = IOSurfaceCreate((CFDictionaryRef)attribs);

    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];

    return (__bridge_retained void*)[dev newTextureWithDescriptor:desc iosurface:surface plane:0];
}

void* Plugin_LookUpIOSurfaceBackedTexture(uint surfaceID)
{
    id<MTLDevice> dev = GetMetalDevice();
    if (!dev) return NULL;

    IOSurfaceRef surface = IOSurfaceLookup(surfaceID);
    
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                    width:IOSurfaceGetWidth(surface)
                                                                                   height:IOSurfaceGetHeight(surface)
                                                                                mipmapped:NO];
    
    return (__bridge_retained void*)[dev newTextureWithDescriptor:desc iosurface:surface plane:0];
}

void Plugin_DestroyIOSurfaceBackedTexture(void* pointer)
{
    id<MTLTexture> texture = (__bridge_transfer id<MTLTexture>)pointer;
    CFRelease(texture.iosurface);
}

IOSurfaceID Plugin_GetIOSurfaceBackedTextureID(void* pointer)
{
    id<MTLTexture> texture = (__bridge id<MTLTexture>)pointer;
    return IOSurfaceGetID(texture.iosurface);
}
