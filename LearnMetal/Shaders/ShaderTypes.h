//
//  AAPLShaderTypes.h
//  LearnMetal
//
//  Created by JiangWang on 2020/11/28.
//

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#include <simd/simd.h>

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    vector_float3 position;
    vector_float4 color;
} VertexColor;

typedef struct
{
    vector_float3 position;
    vector_float2 textCoord;
} VertexTextureCoord ;

#endif /* AAPLShaderTypes_h */
