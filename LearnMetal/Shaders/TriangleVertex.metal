//
//  TriangleVertex.metal
//  LearnMetal
//
//  Created by 王江 on 2020/11/24.
//

#include <metal_stdlib>
#include "AAPLShaderTypes.h"
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

vertex RasterizerData basic_vertex(const device VetexColor *vertex_array [[ buffer(0) ]],
                           unsigned int vid [[ vertex_id ]]) {
    RasterizerData data;
    data.position = float4(vertex_array[vid].position, 1);
    data.color = vertex_array[vid].color;
    return data;
}
