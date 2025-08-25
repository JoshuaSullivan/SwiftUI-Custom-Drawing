//
//  Truchet.metal
//  SwiftUIShaders
//
//  Created by Joshua Sullivan on 8/2/25.
//

#include <metal_stdlib>
using namespace metal;

float hash21(float2 p) {
    p = fract(p * float2(234.567, 9345.678));
    p += dot(p, p + 34.567);
    return fract(p.x * p.y);
}

[[stitchable]] half4 truchetMaze(float2 position, half4 pixelColor, float2 imageSize, half4 foregroundColor, half4 backgroundColor) {
    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
        
    uv *= 8.0;
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    
    float n = hash21(id);
    float width = 0.25;
    
    if (n < 0.5) { gv.x *= -1.0; }
    float d = abs(abs(gv.x+gv.y)-0.5);
    float mask = smoothstep(0.01, -0.01, d - width);
    
    half4 col = mix(backgroundColor, foregroundColor, mask);
    return col * pixelColor.a;
}

[[stitchable]] half4 truchetCurve(float2 position, half4 pixelColor, float2 imageSize, half4 foregroundColor, half4 backgroundColor) {
    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
        
    uv *= 8.0;
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    
    float n = hash21(id);
    float width = 0.1;
    
    if (n < 0.5) { gv.x *= -1.0; }
    float2 cuv = gv - sign(gv.x + gv.y + 0.0001) * 0.5;
    float d = abs(length(cuv)-0.5);
    float mask = smoothstep(0.01, -0.01, abs(d) - width);
    
    half4 col = mix(backgroundColor, foregroundColor, mask);
    return col * pixelColor.a;
}

[[stitchable]] half4 truchetHalfTri(float2 position, half4 pixelColor, float2 imageSize, half4 foregroundColor, half4 backgroundColor) {
    float2 uv = (position - 0.5 * imageSize) / imageSize.y;
    
    uv *= 10.0;
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    float n = hash21(id);
    
    if (n < 0.25) {
        gv.x *= -1.0;
    } else if (n < 0.5) {
        gv.y *= -1.0;
    } else if (n < 0.75) {
        gv.x *= -1.0;
        gv.y *= -1.0;
    }
    float mask = smoothstep(0.01, -0.01, gv.x + gv.y);
    half4 col = mix(backgroundColor, foregroundColor, mask);
    return col * pixelColor.a;
}
