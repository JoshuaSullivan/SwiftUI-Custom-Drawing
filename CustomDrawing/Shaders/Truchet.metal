//
//  Truchet.metal
//  SwiftUIShaders
//
//  Created by Joshua Sullivan on 8/2/25.
//

#include <metal_stdlib>
using namespace metal;

float hash21(float2 p) {
    p = fract(p * float2(234.567, 345.678));
    p += dot(p, p + 34.567);
    return fract(p.x * p.y);
}

[[stitchable]] half4 truchetMaze(float2 position, half4 pixelColor, float2 imageSize) {
    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
    
    half3 col = half3(0.0);
    
    uv *= 8.0;
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    
    float n = hash21(id);
    float width = 0.25;
    
    if (n < 0.5) { gv.x *= -1.0; }
    float d = abs(abs(gv.x+gv.y)-0.5);
    float mask = smoothstep(0.01, -0.01, d - width);
    
    col += mask;
    return half4(col * pixelColor.a, pixelColor.a);
}

[[stitchable]] half4 truchetCurve(float2 position, half4 pixelColor, float2 imageSize, float time) {
    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
    
    half3 col = half3(0.0);
    
    uv += time * 0.1;
    uv *= 8.0;
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    
    float n = hash21(id);
    float width = 0.1;
    
    if (n < 0.5) { gv.x *= -1.0; }
    float2 cuv = gv - sign(gv.x + gv.y + 0.0001) * 0.5;
    float d = abs(length(cuv)-0.5);
    float mask = smoothstep(0.01, -0.01, abs(d) - width);
//    float checker = mod(id.x + id.y, 2.0) * 2.0 - 1.0;
    
    col += mask;
    return half4(col * pixelColor.a, pixelColor.a);
}

//[[stitchable]] half4 truchetHalfTri(float2 position, half4 pixelColor, float2 imageSize) {
//    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
//    
//    half3 col = half3(0.0);
//    
//    uv *= 8.0;
//    float2 gv = fract(uv) - 0.5;
//    float2 id = floor(uv);
//    
//    float n = hash21(id);
//    if (n < 0.5) { gv.x *= -1.0; }
//    float2 cuv = gv - sign(gv.x + gv.y + 0.0001) * 0.5;
//    
//}
