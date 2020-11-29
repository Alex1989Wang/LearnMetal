//
//  TexturePassThrough.metal
//  LearnMetal
//
//  Created by 王江 on 2020/11/29.
//

#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

struct RasterizerData
{
    float4 position [[position]];
    float2 texture_coord;
};

vertex RasterizerData texture_pass_through_vertex(const device VertexTextureCoord *vertex_data [[buffer(0)]],
                                                  const unsigned int vid [[vertex_id]]) {
    RasterizerData data;
    data.position = float4(vertex_data[vid].position, 1);
    data.texture_coord = vertex_data[vid].textCoord;
    return data;
}

fragment float4 texture_passs_through_fragment(RasterizerData in [[stage_in]],
                                               texture2d<half> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const half4 sample = texture.sample(textureSampler, in.texture_coord);
    return float4(sample);
}
