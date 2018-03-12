// Author: Luca Zampetti
// Title: vscode-glsl-canvas Colors examples

precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

#define BLACK           vec3(0.0, 0.0, 0.0)
#define WHITE           vec3(1.0, 1.0, 1.0)
#define RED             vec3(1.0, 0.0, 0.0)
#define GREEN           vec3(0.0, 1.0, 0.0)
#define BLUE            vec3(0.0, 0.0, 1.0)
#define YELLOW          vec3(1.0, 1.0, 0.0)
#define CYAN            vec3(0.0, 1.0, 1.0)
#define MAGENTA         vec3(1.0, 0.0, 1.0)
#define ORANGE          vec3(1.0, 0.5, 0.0)
#define PURPLE          vec3(1.0, 0.0, 0.5)
#define LIME            vec3(0.5, 1.0, 0.0)
#define ACQUA           vec3(0.0, 1.0, 0.5)
#define VIOLET          vec3(0.5, 0.0, 1.0)
#define AZUR            vec3(0.0, 0.5, 1.0)

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

vec2 tile(in vec2 p, vec2 size) { return fract(mod(p + size / 2.0, size)) - (size / 2.0); }
vec2 tile(in vec2 p, float size) { return tile(p, vec2(size)); }

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }

// field adapted from https://www.shadertoy.com/view/XsyGRW
vec3 field(float d) {
    const vec3 c1 = mix(WHITE, YELLOW, 0.4);
    const vec3 c2 = mix(WHITE, AZUR, 0.7);
    const vec3 c3 = mix(WHITE, ORANGE, 0.9);
    const vec3 c4 = BLACK;
    float d0 = abs(stroke(mod(d + 0.1, 0.2) - 0.1, 0.004));
    float d1 = abs(stroke(mod(d + 0.025, 0.05) - 0.025, 0.004));
    float d2 = abs(stroke(d, 0.004));
    float f = clamp(d * 0.85, 0.0, 1.0);
    vec3 gradient = mix(c1, c2, f);
    gradient = mix(gradient, c4, 1.0 - clamp(1.25 - d * 0.25, 0.0, 1.0));
    // gradient -= 1.0 - clamp(1.25 - d * 0.25, 0.0, 1.0);          
    gradient = mix(gradient, c3, fill(d));
    gradient = mix(gradient, c4, max(d2 * 0.85, max(d0 * 0.25, d1 * 0.06125)) * clamp(1.25 - d, 0.0, 1.0));
    return gradient;
}

float sCircle(in vec2 p, in float size) {
    return length(p) * 2.0 - size;
}
float circle(in vec2 p, in float size) {
    float d = sCircle(p, size);
    return fill(d);
}
float circle(in vec2 p, in float size, float t) {
    float d = sCircle(p, size);
    return stroke(d, t);
}

/* Boolean functions */
float sUnion(float a, float b) {
    return min(a, b);
}
float sIntersect(float a, float b) {
    return max(a, b);
}
float sDifference(float a, float b) {
    return max(a, -b);
}

void main() {
    vec2 p = st;

    vec3 color = BLACK;
    
    float a = circle(p - cos(u_time) * 0.2, 0.3, 0.05);
    float b = circle(p + cos(u_time) * 0.2, 0.3, 0.05);

    color += mix(BLACK, RED, a);
    color += mix(BLACK, GREEN, b);

    gl_FragColor = vec4(color, 1.0);
}
