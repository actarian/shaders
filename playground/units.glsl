// Author: Luca Zampetti
// Title: vscode-glsl-canvas Pixel Units examples

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
vec2 pos(in float x, in float y) { return st + vec2(x * rx, y * rx); }
vec2 pos(in float x) { return pos(x, x); }
vec2 pos(in vec2 p) { return pos(p.x, p.y); }
float size(in float x) { return x * rx; }
vec2 size(in float x, in float y) { return vec2(x * rx, y * rx); }

vec2 tile(in vec2 p, vec2 w) { return fract(mod(p + w / 2.0, w)) - (w / 2.0); }
vec2 tile(in vec2 p, float w) { return tile(p, vec2(w)); }

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

float sArc(in vec2 p, in float w, in float s, in float e) {
    e += s;
    float o = (s + e - PI);
	float a = mod(atan(p.y, p.x) - o, TWO_PI) + o;
	a = clamp(a, min(s, e), max(s, e));
    vec2 r = vec2(cos(a), sin(a));
	float d = distance(p, w * 0.5 * r);
    return d * 2.0;
}
float arc(in vec2 p, in float w, in float s, in float e, in float t) {
    float d = sArc(p, w, s, e);
    return stroke(d, t);
}

float sCircle(in vec2 p, in float w) {
    return length(p) * 2.0 - w;
}
float circle(in vec2 p, in float w) {
    float d = sCircle(p, w);
    return fill(d);
}
float circle(in vec2 p, in float w, float t) {
    float d = sCircle(p, w);
    return stroke(d, t);
}

float sHex(in vec2 p, in float w) {
    vec2 q = abs(p);
    float d = max((q.x * 0.866025 + q.y * 0.5), q.y) - w * 0.5; // * 0.4330125
    return d * 2.0;
}
float hex(in vec2 p, in float w) {    
    float d = sHex(p, w);
    return fill(d);
}
float hex(in vec2 p, in float w, in float t) {
    float d = sHex(p, w);
    return stroke(d, t);    
}

float sLine(in vec2 a, in vec2 b) {
    vec2 p = b - a;
    float d = abs(dot(normalize(vec2(p.y, -p.x)), a));
    return d * 2.0;
}
float line(in vec2 a, in vec2 b) {
    float d = sLine(a, b);
    return fill(d);
}
float line(in vec2 a, in vec2 b, in float t) {
    float d = sLine(a, b);
    return stroke(d, t);
}
float line(in vec2 p, in float a, in float t) {
    vec2 b = p + vec2(sin(a), cos(a));
    return line(p, b, t);
}

float sPie(in vec2 p, in float w, in float s, in float e) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    return 1.0 - (a - d * 2.0) - w;
}
float pie(in vec2 p, in float w, in float s, in float e) {    
    float d = sPie(p, w, s, e);
    return fill(d);
}
float pie(in vec2 p, in float w, in float s, in float e, in float t) {
    float d = sPie(p, w, s, e);
    return stroke(d, t);    
}

float sPlot(vec2 p, float y){
    return p.y + y;
}
float plot(vec2 p, float y, float t) {
    float d = sPlot(p, y);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float sPoly(in vec2 p, in float w, in int sides) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return d * 2.0 - w;
}
float poly(in vec2 p, in float w, in int sides) {
    float d = sPoly(p, w, sides);
    return fill(d);
}
float poly(in vec2 p, in float w, in int sides, in float t) {
    float d = sPoly(p, w, sides);
    return stroke(d, t);
}

float sRect(in vec2 p, in vec2 w) {    
    float d = max(abs(p.x / w.x), abs(p.y / w.y)) * 2.0;
    float m = max(w.x, w.y);
    return d * m - m;
}
float rect(in vec2 p, in vec2 w) {
    float d = sRect(p, w);
    return fill(d);
}
float rect(in vec2 p, in vec2 w, in float t) {
    float d = sRect(p, w);
    return stroke(d, t);
}

float sRoundrect(in vec2 p, in vec2 w, in float corner) {
    vec2 s = w * 0.5 - corner;
    float m = max(s.x, s.y);
    float d = length(max(abs(p) - s, 0.00001)) * m / corner;
    return (d - m) / m * corner * 2.0;
}
float roundrect(in vec2 p, in vec2 w, in float corner) {
    float d = sRoundrect(p, w, corner);
    return fill(d);
}
float roundrect(in vec2 p, in vec2 w, in float corner, in float t) {
    float d = sRoundrect(p, w, corner);
    return stroke(d, t);
}

float sSegment(in vec2 a, in vec2 b) {
    vec2 ba = a - b;
    float d = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    return length(a - ba * d) * 2.0;
}
float segment(in vec2 a, in vec2 b, float t) {
    float d = sSegment(a, b);
    return stroke(d, t);
}

float sSpiral(in vec2 p, in float turns) {
    float r = dot(p, p);
    float a = atan(p.y, p.x);
    float d = abs(sin(fract(log(r) * (turns / 5.0) + a * 0.159)));
    return d - 0.5;
}
float spiral(in vec2 p, in float turns) {    
    float d = sSpiral(p, turns);
    return fill(d);
}

float sStar(in vec2 p, in float w, in int sides) {    
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m;
    return (d - rx) * 2.0 - w;
}
float star(in vec2 p, in float w, in int sides) {
    float d = sStar(p, w, sides);
    return fill(d);
}
float star(in vec2 p, in float w, in int sides, float t) {    
    float d = sStar(p, w, sides);
    return stroke(d, t);
}

float grid(in vec2 p, in float w) {
    vec2 l = tile(p, w);
    float d = 0.0;
    d += line(l, l + vec2(0.0, 0.1), 0.002);
    d += line(l, l + vec2(0.1, 0.0), 0.002);
    d *= 0.2;
    p = tile(p, vec2(w * 5.0));
    float s = w / 10.0;
    float g = 0.0;
    g += segment(p + vec2(-s, 0.0), p + vec2(s, 0.0), 0.004);
    g += segment(p + vec2(0.0, -s), p + vec2(0.0, s), 0.004);
    return d + g;
}

void main() {
    vec3 color = AZUR;
    
    color = mix(color, BLACK, grid(st, size(50.0)));
    
    float d = 0.0;
    
    d = arc(pos(0.0), size(150.0), 0.0, PI_TWO, size(2.0));
    // d = circle(pos(0.0), size(150.0));
    // d = circle(pos(0.0), size(150.0), size(2.0));    
    // d = line(pos(-75.0, -75.0), pos(75.0, 75.0), size(2.0));
    // d = pie(pos(0.0), size(150.0), 0.0, PI_TWO);
    // d = pie(pos(0.0), size(150.0), 0.0, PI_TWO, size(2.0));
    // d = plot(pos(0.0), -st.x, size(2.0));
    // d = poly(pos(0.0), size(150.0), 3);
    // d = poly(pos(0.0), size(150.0), 3, size(2.0));
    // d = rect(pos(0.0), size(150.0, 150.0));
    // d = rect(pos(0.0), size(150.0, 150.0), size(2.0));
    // d = roundrect(pos(0.0), size(150.0, 150.0), size(10.0));
    // d = roundrect(pos(0.0), size(150.0, 150.0), size(10.0), size(2.0));
    // d = segment(pos(-75.0, -75.0), pos(75.0, 75.0), size(2.0));
    // d = spiral(pos(0.0), 1.0);
    // d = star(pos(0.0), size(150.0), 5);
    // d = star(pos(0.0), size(150.0), 5, size(2.0));
    
    color = mix(color, WHITE, d);

    gl_FragColor = vec4(color, 1.0);
}
