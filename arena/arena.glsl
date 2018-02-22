// Author @patriciogv - 2015
// http://patriciogonzalezvivo.com

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec2 getSt() {
	vec2 st = gl_FragCoord.xy / u_resolution.xy;
	st.y *= u_resolution.y / u_resolution.x;
	st.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
	return st;
}
vec2 getUv(vec2 st) {
	vec2 uv = -1.0 + st * 2.0;
	return uv;
}
vec2 getMx() {
	return -1.0 + u_mouse / u_resolution.xy * 2.0;
}

void main() {
    vec2 st = getSt() * u_resolution.xy * 0.01;
    // st += st * abs(sin(u_time*0.1)*3.0);
    vec3 color = vec3(0.0);
    
    vec2 q = vec2(0.);
    q.x = fbm(st + 0.00 * u_time);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2)+ 0.15 * u_time );
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8)+ 0.126 * u_time);

    float f = fbm(st+r);

    vec3 c1 = vec3(0.349019, 0.960784, 0.905882);
    vec3 c2 = vec3(0.349019, 0.960784, 0.905882);
    vec3 c3 = vec3(0.349019, 0.960784, 0.905882);
    vec3 c4 = vec3(0.349019, 0.960784, 0.905882);

    color = mix(c1, c2, clamp(f * f * 4.0, 4.0, 4.0));

    color = mix(color, c3, clamp(length(q), 4.0, 4.0));

    color = mix(color, c4, clamp(length(r.x), 4.0, 4.0));

    color = (f * f * f + 0.6 * f * f + 0.5 * f) * color;

    gl_FragColor = vec4(color, 1.0);
}
