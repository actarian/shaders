// Author: Luca Zampetti
// Title: vscode-glsl-canvas Coords examples

precision highp float;

/***   u n i f o r m s   ***/

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

/***   c o n s t a n t s   ***/

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

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 tile(in vec2 p, vec2 size) { return fract(mod(p + size / 2.0, size)) - (size / 2.0); }
vec2 tile(in vec2 p, float size) { return tile(p, vec2(size)); }

float circle(in vec2 p, in float size) {
    float d = length(p) * 2.0;
    return 1.0 - smoothstep(size - rx, size + rx, d);
}
float circle(in vec2 p, in float size, float t) {
    float d = length(abs(p)) - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float line(in vec2 a, in vec2 b, float t) {
    vec2 ba = a - b;
    float d = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    d = length(a - ba * d);
    return smoothstep(t / 2.0 + rx, t / 2.0 - rx, d);
}

float plot(in vec2 p, in float t, in float a) {
    p *= rotate2d(a);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(p.x));
}
float plot(in vec2 p, in float t) { return plot (p, t, 0.0); }
float plot(in vec2 p) { return plot (p, 1.0, 0.0); }

float grid(in float size) {
    float d = 0.0;
    d += plot(tile(st, size), 0.002);
    d += plot(tile(st, size), 0.002, PI_TWO);
    d *= 0.1;
    vec2 p = tile(st, vec2(size * 5.0, size * 5.0));
    float s = size / 10.0;
    float g = 0.0;
    g += line(p + vec2(-s, 0.0), p + vec2(s, 0.0), 0.004);
    g += line(p + vec2(0.0, -s), p + vec2(0.0, s), 0.004);
    return d + g;
}

void main() {
    vec3 color = BLACK;

    color = mix(color, WHITE, grid(0.1));    

    color = mix(color, WHITE, circle(mx - st, 0.1));    
    
    gl_FragColor = vec4(color, 1.0);
}