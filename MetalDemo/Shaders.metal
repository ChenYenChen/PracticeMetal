//
// Shaders.metal
//
// Created by Ray on 2018/7/25.
//  Copyright © 2018年 Ray. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
};

vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    return vertices[vid];
}

fragment float4 fragment_func(Vertex vert [[stage_in]]) {
    return float4(1, 0.8, 0.9, 0);
}
