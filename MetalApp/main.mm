#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

// Shader source compiled at runtime so this target needs no .metal build step.
// The vertex shader rotates a hard-coded triangle by an angle passed in a
// constant buffer; the fragment shader interpolates per-vertex color.
static const char *kShaderSource = R"(
#include <metal_stdlib>
using namespace metal;

struct V2F { float4 position [[position]]; float3 color; };

vertex V2F vmain(uint vid [[vertex_id]], constant float &angle [[buffer(0)]]) {
    float2 verts[3] = { float2(0.0,  0.6), float2(-0.6, -0.5), float2(0.6, -0.5) };
    float3 cols[3]  = { float3(1, 0.3, 0.3), float3(0.3, 1, 0.3), float3(0.3, 0.5, 1) };
    float c = cos(angle), s = sin(angle);
    V2F o;
    o.position = float4(verts[vid].x * c - verts[vid].y * s,
                        verts[vid].x * s + verts[vid].y * c, 0, 1);
    o.color = cols[vid];
    return o;
}

fragment float4 fmain(V2F in [[stage_in]]) { return float4(in.color, 1); }
)";

@interface MetalView : MTKView <MTKViewDelegate>
- (void)tick;
@end

@implementation MetalView {
    id<MTLCommandQueue> _queue;
    id<MTLRenderPipelineState> _pso;
    float _angle;
}

- (instancetype)initWithFrame:(NSRect)frame device:(id<MTLDevice>)device {
    if ((self = [super initWithFrame:frame device:device])) {
        self.delegate = self;
        self.clearColor = MTLClearColorMake(0.08, 0.08, 0.12, 1.0);
        // Drive frames from our timer instead of the built-in display link.
        self.paused = YES;
        self.enableSetNeedsDisplay = YES;
        _queue = [device newCommandQueue];

        NSError *err = nil;
        id<MTLLibrary> lib = [device newLibraryWithSource:@(kShaderSource) options:nil error:&err];
        NSAssert(lib, @"Shader compile failed: %@", err);

        MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
        desc.vertexFunction = [lib newFunctionWithName:@"vmain"];
        desc.fragmentFunction = [lib newFunctionWithName:@"fmain"];
        desc.colorAttachments[0].pixelFormat = self.colorPixelFormat;
        _pso = [device newRenderPipelineStateWithDescriptor:desc error:&err];
        NSAssert(_pso, @"Pipeline failed: %@", err);
    }
    return self;
}

- (void)tick {
    _angle += 0.03f;
    [self setNeedsDisplay:YES];
}

- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if (!rpd) return;
    id<MTLCommandBuffer> cb = [_queue commandBuffer];
    id<MTLRenderCommandEncoder> enc = [cb renderCommandEncoderWithDescriptor:rpd];
    [enc setRenderPipelineState:_pso];
    [enc setVertexBytes:&_angle length:sizeof(_angle) atIndex:0];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [enc endEncoding];
    [cb presentDrawable:view.currentDrawable];
    [cb commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size { (void)view; (void)size; }
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}
@end

int main(int argc, const char *argv[]) {
    (void)argc; (void)argv;
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        AppDelegate *delegate = [AppDelegate new];
        app.delegate = delegate;

        const NSRect frame = NSMakeRect(0, 0, 640, 480);
        const NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                        NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable;

        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                       styleMask:style
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        window.title = @"MacResizeLoopMetal";
        window.releasedWhenClosed = NO;
        [window center];

        MetalView *view = [[MetalView alloc] initWithFrame:frame device:MTLCreateSystemDefaultDevice()];
        view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        window.contentView = view;

        __weak MetalView *weakView = view;
        NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 / 60.0
                                                repeats:YES
                                                  block:^(NSTimer *t) {
                                                      (void)t;
                                                      [weakView tick];
                                                  }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

        [window makeKeyAndOrderFront:nil];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
