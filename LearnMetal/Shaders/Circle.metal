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
    float2 texture_coord;
};

vertex RasterizerData circle_vertex(device const VertexTextureCoord *vert [[buffer(0)]],
                                    uint vid [[vertex_id]]) {
    RasterizerData out;
    out.position = float4(vert[vid].position, 1);
    out.texture_coord = vert[vid].textCoord;
    return out;
}
                                    
fragment float4 circle_fragment(RasterizerData in [[stage_in]],
                                device const CircleUniform &uniform [[buffer(0)]],
                                device const Point *points [[buffer(1)]],
                                device const uint8_t &pCount [[buffer(2)]],
                                texture2d<half> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const half4 sample = texture.sample(textureSampler, in.texture_coord);
    float4 color = float4(sample);
    float radius = (float)uniform.diameter * 0.5;
    for (uint8_t idx = 0; idx < pCount; idx++) {
        float dist = fast::distance(float2(points[idx].x, points[idx].y), in.position.xy);
        if (dist <= radius) {
            color = uniform.color;
            break;
        }
    }
    return color;
}


