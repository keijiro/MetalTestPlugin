#import <Foundation/Foundation.h>
#import <Metal/MTLBlitCommandEncoder.h>
#import <Metal/MTLCommandBuffer.h>
#import "IUnityGraphicsMetal.h"
#import "IUnityGraphics.h"

typedef struct
{
    UnityRenderBuffer source;
    UnityRenderBuffer destination;
    uint32 width;
    uint32 height;
} BlitParams;

static IUnityInterfaces* s_interfaces;
static IUnityGraphicsMetal* s_graphics;

static void BlitFunction(int eventId, void* data)
{
    if (s_graphics == NULL)
        s_graphics = UNITY_GET_INTERFACE(s_interfaces, IUnityGraphicsMetal);
    
    if (data == NULL) return;
    
    BlitParams* params = data;
    
    if (params->source == NULL || params->destination == NULL) return;

    id<MTLTexture> src = s_graphics->TextureFromRenderBuffer(params->source);
    id<MTLTexture> dst = s_graphics->TextureFromRenderBuffer(params->destination);

    if (src == nil || dst == nil) return;
    
    s_graphics->EndCurrentCommandEncoder();
    
    id<MTLBlitCommandEncoder> encoder = [s_graphics->CurrentCommandBuffer() blitCommandEncoder];

    [encoder copyFromTexture:src
                 sourceSlice:0
                 sourceLevel:0
                sourceOrigin:MTLOriginMake(0, 0, 0)
                  sourceSize:MTLSizeMake(params->width, params->height, 1)
                   toTexture:dst
            destinationSlice:0
            destinationLevel:0
           destinationOrigin:MTLOriginMake(0, 0, 0)];

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
