precision mediump float;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 coord(in vec2 p) {
	p = p / u_resolution.xy;
    if (u_resolution.x > u_resolution.y) {
        p.x *= u_resolution.x / u_resolution.y;
        p.x += (u_resolution.y - u_resolution.x) / u_resolution.y / 2.0;
    } else {
        p.y *= u_resolution.y / u_resolution.x;
	    p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    }
    p -= 0.5;
    p *= vec2(-1.0, 1.0);
	return p;
}
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
#define uv gl_FragCoord.xy / u_resolution.xy
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)

uniform sampler2D u_texture_4;
uniform sampler2D u_texture_5;

// Sine
float easeSineIn(float t) {
    return -1.0 * cos(t * PI_TWO) + 1.0;
}
float easeSineOut(float t) {
    return sin(t * PI_TWO);
}
float easeSineInOut(float t) {
    return -0.5 * (cos(PI * t) - 1.0);
}

void main() {
    vec3 color = vec3(1.0);
    // time
    float v = fract(u_time * 0.2);
    // easing
    v = easeSineInOut(v);
    // mouse
    // v = 1.0 - (mx.x + 0.5);
    // mask
    float r = (1.0 - texture2D(u_texture_5, uv).r);
    r = 1.0 - smoothstep(v, v + 0.1, r);
    r = clamp(r, 0.0, 1.0);
    // colors
    float s = mix(0.1, 0.0, v);
    vec3 colorA = vec3(1.0);
    vec3 colorB = texture2D(u_texture_4, uv * (1.0 - s) + s / 2.0).rgb;
    float l = length(colorB.r) / 3.0;
    l = mix(0.0, 0.05, l * (1.0 - v));
    vec3 colorC = texture2D(u_texture_4, (uv * (1.0 - s) + s / 2.0) + (1.0 + l)).rgb;
    // mix
    color = mix(colorA, colorC, r);
    gl_FragColor = vec4(color, 1.0);
}