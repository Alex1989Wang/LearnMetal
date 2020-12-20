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

bool is_point_between_lines(float2 point, array<Point, 2> line_points, float range) {
    Point p1 = line_points[0];
    Point p2 = line_points[1];
    if (p1.x == p2.x) {
        return point.x >= p1.x - range && point.x <= p1.x + range;
    }
    if (p1.y == p2.y) {
        return point.y >= p1.y - range && point.y <= p1.y + range;
    }
    // line
    float k = (p1.y - p2.y)/(p1.x - p2.x);
    float d1 = p1.y + length(float2(1, k)) * range - k * p1.x;
    float d2 = p1.y - length(float2(1, k)) * range - k * p1.x;

    return k * point.x + d1 >= point.y && k * point.x + d2 <= point.y;
}

float4 color_for_point(float2 point, float4 base_color, float4 target_color, device const Point *reference_points, uint8_t pcount, float dis) {
    if (pcount <= 0) { return base_color; }
    if (pcount == 1) {
        float dist = fast::distance(float2(reference_points[0].x, reference_points[0].y), point);
        if (dist <= dis) {
            base_color = target_color;
        }
    }
    // two points to form a line
    Point last = reference_points[0];
    for (uint8_t idx = 1; idx < pcount; idx++) {
        array<Point, 2> line_points = {last, reference_points[idx]};
        if (is_point_between_lines(point, line_points, dis)) {
            base_color = target_color;
            break;
        }
        last = reference_points[idx];
    }
    return base_color;
}

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
//    for (uint8_t idx = 0; idx < pCount; idx++) {
//        float dist = fast::distance(float2(points[idx].x, points[idx].y), in.position.xy);
//        if (dist <= radius) {
//            color = uniform.color;
//            break;
//        }
//    }
    color = color_for_point(in.position.xy, color, uniform.color, points, pCount, radius);
    return color;
}

