//
//  Circle.metal
//  LearnMetal
//
//  Created by JiangWang on 2020/12/8.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

struct RasterizerData
{
    float4 position [[position]];
};

vertex RasterizerData circle_vertex(device const Vertex *vert [[buffer(0)]],
                                    uint vid [[vertex_id]]) {
    RasterizerData out;
    out.position = float4(vert[vid].position, 1);
    return out;
}
                                    
fragment float4 circle_fragment(RasterizerData in [[stage_in]],
                                device const CircleUniform &uniform [[buffer(0)]],
                                device const Point *points [[buffer(1)]],
                                device const uint8_t &pCount [[buffer(2)]]) {
    float4 color = float4(0, 0, 0, 1);
    float radius = (float)uniform.diameter * 0.5;
    for (uint8_t idx = 0; idx < pCount; idx++) {
        float dist = fast::distance(float2(points[idx].x, points[idx].y), float2(radius, radius));
        if (dist <= radius) {
            color = uniform.color;
            break;
        }
    }
    return color;
}


