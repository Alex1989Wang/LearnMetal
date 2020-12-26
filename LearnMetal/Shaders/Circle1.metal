//
//  Circle1.metal
//  LearnMetal
//
//  Created by JiangWang on 2020/12/23.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

struct RasterizerData
{
    float4 position [[position]];
    float radius [[point_size]];
};

vertex RasterizerData single_cricle_point_vertex(device const VertexPoint *verts [[buffer(0)]],
                                                uint vid [[vertex_id]]) {
    RasterizerData out;
    out.position = float4(verts[vid].position, 1);
    out.radius = verts[vid].radius;
    return out;
}

fragment float4 single_circle_point_fragment(RasterizerData in [[stage_in]],
                                          device const CircleUniform &uniform [[buffer(0)]],
                                          float2 pointCoord [[point_coord]]) {
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return uniform.color;
}


