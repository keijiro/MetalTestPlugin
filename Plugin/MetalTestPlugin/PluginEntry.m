#import <Foundation/Foundation.h>
#import "IUnityGraphicsMetal.h"
#import "IUnityGraphics.h"
#import <Metal/MTLBlitCommandEncoder.h>
#import <Metal/MTLCommandBuffer.h>

static IUnityInterfaces* s_interfaces;
static IUnityGraphicsMetal* s_metal;

static void BlitFunction(int eventId, void* data)
{
    if (s_metal == NULL)
        s_metal = UNITY_GET_INTERFACE(s_interfaces, IUnityGraphicsMetal);

    UnityRenderBuffer* buffers = data;
    
    id<MTLTexture> src = s_metal->TextureFromRenderBuffer(buffers[0]);
    id<MTLTexture> dst = s_metal->TextureFromRenderBuffer(buffers[1]);

    NSLog(@"MetalTestPlugin: %@, %@", src, dst);
    
    s_metal->EndCurrentCommandEncoder();
    id<MTLBlitCommandEncoder> encoder = [s_metal->CurrentCommandBuffer() blitCommandEncoder];
    [encoder copyFromTexture:src sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0) sourceSize:MTLSizeMake(256, 256, 1) toTexture:dst destinationSlice:0 destinationLevel:0 destinationOrigin:MTLOriginMake(0, 0, 0)];
    [encoder endEncoding];
}

void UNITY_INTERFACE_EXPORT UNITY_INTERFACE_API UnityPluginLoad(IUnityInterfaces* interfaces)
{
    s_interfaces = interfaces;
}

UnityRenderingEventAndData Plugin_GetBlitFunction()
{
    return BlitFunction;
}
