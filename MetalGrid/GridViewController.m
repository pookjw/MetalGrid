//
//  GridViewController.m
//  MetalGrid
//
//  Created by Jinwoo Kim on 4/8/23.
//

#import "GridViewController.h"
#import <MetalKit/MetalKit.h>

#define GRID_BLOCK_COUNT 20

@interface GridViewController () <MTKViewDelegate> {
@private simd_float3 _coords[(GRID_BLOCK_COUNT - 1) * 4];
@private ushort _indices[(GRID_BLOCK_COUNT - 1) * 4];
}
@property (strong) MTKView *mtkView;
@property (strong) id<MTLDevice> device;
@property (strong) id<MTLCommandQueue> commandQueue;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLRenderPipelineState> pipelineState;
@property (strong) id<MTLBuffer> coordsBuffer;
@property (strong) id<MTLBuffer> indicesBuffer;
@end

@implementation GridViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        
        MTKView *mtkView = [MTKView new];
        mtkView.clearColor = MTLClearColorMake(1.f, 1.f, 0.9f, 1.f);
        mtkView.delegate = self;
        mtkView.device = device;
        
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        
        id<MTLLibrary> library = [device newDefaultLibrary];
        id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
        id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
        
        MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        vertexDescriptor.layouts[0].stride = sizeof(simd_float3);
        pipelineDescriptor.vertexDescriptor = vertexDescriptor;
        
        NSError * _Nullable error = nil;
        id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
        NSAssert((error == nil), error.localizedDescription);
        
        //
        
        float unit = 1.f / GRID_BLOCK_COUNT;
        
        for (NSUInteger i = 0; i < (GRID_BLOCK_COUNT - 1) * 2; i = i + 2) {
            float coord = -1.f + unit * (float)(i + 2);
            _coords[i] = simd_make_float3(-1.f, coord, 0.f);
            _coords[i + 1] = simd_make_float3(1.f, coord, 0.f);
            _coords[i + (GRID_BLOCK_COUNT - 1) * 2] = simd_make_float3(coord, -1.f, 0.f);
            _coords[i + (GRID_BLOCK_COUNT - 1) * 2 + 1] = simd_make_float3(coord, 1.f, 0.f);
        }
        
        for (NSUInteger i = 0; i < (GRID_BLOCK_COUNT - 1) * 4; i++) {
            _indices[i] = i;
        }
        
        id<MTLBuffer> coordsBuffer = [device newBufferWithBytes:_coords length:sizeof(_coords) options:0];
        id<MTLBuffer> indicesBuffer = [device newBufferWithBytes:_indices length:sizeof(_indices) options:0];
        
        //
        
        self.mtkView = mtkView;
        self.device = device;
        self.commandQueue = commandQueue;
        self.library = library;
        self.pipelineState = pipelineState;
        self.coordsBuffer = coordsBuffer;
        self.indicesBuffer = indicesBuffer;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    self.mtkView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mtkView];
    
    NSLayoutConstraint *topConstraint = [self.mtkView.topAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
    NSLayoutConstraint *leadingConstraint = [self.mtkView.leadingAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
    NSLayoutConstraint *trailingConstraint = [self.mtkView.trailingAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
    NSLayoutConstraint *bottomConstraint = [self.mtkView.bottomAnchor constraintGreaterThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
    
    topConstraint.priority = UILayoutPriorityDefaultHigh;
    leadingConstraint.priority = UILayoutPriorityDefaultHigh;
    trailingConstraint.priority = UILayoutPriorityDefaultHigh;
    bottomConstraint.priority = UILayoutPriorityDefaultHigh;
    
    [NSLayoutConstraint activateConstraints:@[
        topConstraint,
        leadingConstraint,
        trailingConstraint,
        bottomConstraint,
        [self.mtkView.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [self.mtkView.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
        [self.mtkView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.widthAnchor],
        [self.mtkView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.heightAnchor],
        [self.mtkView.widthAnchor constraintEqualToAnchor:self.mtkView.heightAnchor]
    ]];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size { 
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *descriptor = [view currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    
    [renderEncoder setRenderPipelineState:self.pipelineState];
    
    //
    
    [renderEncoder setVertexBuffer:self.coordsBuffer offset:0 atIndex:0];
    
    for (NSUInteger i = 0; i < (GRID_BLOCK_COUNT - 1) * 2; i++) {
        @autoreleasepool {
            [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeLine
                                      indexCount:2
                                       indexType:MTLIndexTypeUInt16
                                     indexBuffer:self.indicesBuffer
                               indexBufferOffset:sizeof(ushort) * i * 2];
        }
    }
    
    //
    
    [renderEncoder endEncoding];
    id<CAMetalDrawable> drawable = [view currentDrawable];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)drawInMTKView:(nonnull MTKView *)view { 
    
}

@end
