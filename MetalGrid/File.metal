//
//  File.metal
//  MetalGrid
//
//  Created by Jinwoo Kim on 4/8/23.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_main(
                          simd_float3 position [[attribute(0)]] [[stage_in]]
                          )
{
    return float4(position.x, position.y, position.z, 1.f);
}

fragment float4 fragment_main() {
    return float4(0.f, 0.f, 0.f, 1.f);
}
