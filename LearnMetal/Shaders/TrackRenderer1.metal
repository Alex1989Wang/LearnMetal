//
//  TrackRenderer1.metal
//  LearnMetal
//
//  Created by 王江 on 2020/12/22.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

struct RasterizerData
{
    float4 position [[position]];
};

vertex RasterizerData single_track_point_vertex(device const VertexPoint *verts [[buffer(0)]],
                                                uint vid [[vertex_id]]) {
    RasterizerData out;
    out.position = float4(verts[vid].position, 1);
    return out;
}

fragment float4 single_track_point_fragment(RasterizerData in [[stage_in]],
                                          device const CircleUniform &uniform [[buffer(0)]],
                                          float2 pointCoord [[point_coord]]) {
    float radius = (float)uniform.diameter * 0.5;
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return uniform.color;
}


