// Author: Luca Zampetti
// Title: vscode-glsl-canvas Pixel Units examples

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
vec2 pos(in float x, in float y) { return st + vec2(x * rx, y * rx); }
vec2 pos(in float x) { return pos(x, x); }
vec2 pos(in vec2 p) { return pos(p.x, p.y); }
float pix(in float x) { return x * rx; }
vec2 pix(in float x, in float y) { return vec2(x * rx, y * rx); }
float swing (float size) { return (1.0 + cos(u_time)) / 2.0 * pix(size); }
vec2 swing (in float x, in float y) { return (1.0 + cos(u_time)) / 2.0 * pix(x, y); }

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 tile(in vec2 p, vec2 size) { return fract(mod(p + size / 2.0, size)) - (size / 2.0); }
vec2 tile(in vec2 p, float size) { return tile(p, vec2(size)); }

float pi = atan(1.0) * 4.0;
float tau = atan(1.0) * 8.0;
float arc(in vec2 p, in float s, in float e, in float size) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    d = smoothstep(d - rx, d + rx, size / 2.0 * a);
    return d;
}
float arc(in vec2 p, in float s, in float e, in float size, in float t) {
    e += s;
    float o = (s / 2.0 + e / 2.0 - pi);
	float a = mod(atan(p.y, p.x) - o, tau) + o;
	a = clamp(a, min(s, e), max(s, e));
	float d = distance(p, size / 2.0 * vec2(cos(a), sin(a)));
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

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

float pie(in vec2 p, in float s, in float e, in float size) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    d = smoothstep(d - rx, d + rx, size / 2.0 * a);
    return d;
}
float pie(in vec2 p, in float s, in float e, in float size, in float t) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p * a) - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float plot(vec2 p, float y, float t){
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(p.y + y));
}

float poly(in vec2 p, in float size, in int sides) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return 1.0 - smoothstep(size / 2.0 - rx, size / 2.0 + rx, d);
}
float poly(in vec2 p, in float size, in int sides, in float t) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0)) - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float rect(in vec2 p, in vec2 size) {
    float d = max(abs(p.x / size.x), abs(p.y / size.y));
    return 1.0 - smoothstep(0.5 - rx, 0.5 + rx, d);
}
float rect(in vec2 p, in vec2 size, in float t) {
    float a = abs(max(abs(p.x / (size.x + t)), abs(p.y / (size.y + t))));
    float b = abs(max(abs(p.x / (size.x - t)), abs(p.y / (size.y - t))));
    return smoothstep(0.5 - rx, 0.5 + rx, b) - smoothstep(0.5 - rx, 0.5 + rx, a);
}

float rectline(in vec2 p, in float t, in float a) {
    p *= rotate2d(a);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(p.x));
}
float rectline(in vec2 p, in float t) { return rectline (p, t, 0.0); }
float rectline(in vec2 p) { return rectline (p, 1.0, 0.0); }

float roundrect(in vec2 p, in vec2 size, in float radius) {
    radius *= 2.0; size /= 2.0;
    float d = length(max(abs(p) -size + radius, 0.0)) - radius;
    return 1.0 - smoothstep(0.0, rx * 2.0, d);
}
float roundrect(in vec2 p, in vec2 size, in float radius, in float t) {
    radius *= 2.0; size /= 2.0; size -= radius;
    float d = length(max(abs(p), size) - size) - radius;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float spiral(in vec2 p, in float turn) {    
    float r = dot(p, p);
    float a = atan(p.y, p.x);
    float d = abs(sin(fract(log(r) * (turn / 5.0) + a * 0.159)));
    return 1.0 - smoothstep(0.5 - rx, 0.5 + rx, d);
}

float star(in vec2 p, in float size, in int sides) {    
    float r = 0.5; float s = float(sides); float m = 0.5 / s;
    float segment = atan(p.y, p.x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a), sin(a)), p)) + m - size / 2.0;
    return 1.0 - smoothstep(0.0, rx * 2.0, d);
}
float star(in vec2 p, in float size, in int sides, float t) {    
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s;
    float segment = atan(p.y, p.x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a), sin(a)), p)) + m - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float grid(in float size) {
    float d = 0.0;
    d += rectline(tile(st, size), 0.002);
    d += rectline(tile(st, size), 0.002, PI_TWO);
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
    
    color = mix(color, WHITE, 
        grid(pix(50.0))
    );
    
    float d = 0.0;
    
    d = arc(pos(0.0), 0.0, PI_TWO, pix(150.0));
    // d = arc(pos(0.0), 0.0, PI_TWO, pix(150.0), pix(2.0));
    // d = circle(pos(0.0), pix(150.0));
    // d = circle(pos(0.0), pix(150.0), pix(2.0));    
    // d = line(pos(-75.0, -75.0), pos(75.0, 75.0), pix(2.0));
    // d = pie(pos(0.0), 0.0, PI_TWO, pix(150.0));
    // d = pie(pos(0.0), 0.0, PI_TWO, pix(150.0), pix(2.0));
    // d = plot(pos(0.0), -st.x, pix(2.0));
    // d = poly(pos(0.0), pix(150.0), 3);
    // d = poly(pos(0.0), pix(150.0), 3, pix(2.0));
    // d = rect(pos(0.0), pix(150.0, 150.0));
    // d = rect(pos(0.0), pix(150.0, 150.0), pix(2.0));
    // d = rectline(pos(0.0), pix(150.0), PI_TWO / 2.0);
    // d = roundrect(pos(0.0), pix(150.0, 150.0), pix(10.0));
    // d = roundrect(pos(0.0), pix(150.0, 150.0), pix(10.0), pix(2.0));
    // d = spiral(pos(0.0), 1.0);
    // d = star(pos(0.0), pix(150.0), 6);
    // d = star(pos(0.0), pix(150.0), 6, pix(2.0));
    
    color = mix(color, WHITE, d);

    gl_FragColor = vec4(color, 1.0);
}
