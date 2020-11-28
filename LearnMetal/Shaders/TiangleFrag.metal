//
//  TiangleFrag.metal
//  LearnMetal
//
//  Created by 王江 on 2020/11/24.
//

#include <metal_stdlib>
using namespace metal;

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    // The [[position]] attribute of this member indicates that this value
    // is the clip space position of the vertex when this structure is
    // returned from the vertex function.
    float4 position [[position]];

    // Since this member does not have a special attribute, the rasterizer
    // interpolates its value with the values of the other triangle vertices
    // and then passes the interpolated value to the fragment shader for each
    // fragment in the triangle.
    float4 color;
};

fragment float4 basic_fragment(RasterizerData in [[stage_in]]) {
    return in.color;
}

