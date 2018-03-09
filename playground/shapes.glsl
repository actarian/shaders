// Author: Luca Zampetti
// Title: vscode-glsl-canvas Shapes examples

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

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { 
    // return 1.0 - smoothstep(t - rx, t + rx, abs(d));
    return 1.0 - smoothstep(0.0, rx * 2.0, max(0.0, abs(d) - t));
}

/*
float draw_line(float d, float t) {
    return smoothstep(0.0, rx * 2.0, max(0.0, abs(d) - t));
}

float shape_box2d(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float shape_line(vec2 p, vec2 a, vec2 b) {
    vec2 dir = b - a;
    return abs(dot(normalize(vec2(dir.y, -dir.x)), a - p));
}

float shape_segment(vec2 p, vec2 a, vec2 b) {
    float d = shape_line(p, a, b);
    float d0 = dot(p - b, b - a);
    float d1 = dot(p - a, b - a);
    return d1 < 0.0 ? length(a - p) : d0 > 0.0 ? length(b - p) : d;
}
// r^2 = x^2 + y^2, r = sqrt(x^2 + y^2), r = length([x y]), 0 = length([x y]) - r
float shape_circle(vec2 p) {
    return length(p) - 0.5;
}

// y = sin(5x + t) / 5, 0 = sin(5x + t) / 5 - y
float shape_sine(vec2 p) {
    return p.y - sin(p.x * 5.0) * 0.2;
}
*/

float sArc(in vec2 p, in float size, in float s, in float e) {
    e += s;
    float o = (s + e - PI);
	float a = mod(atan(p.y, p.x) - o, TWO_PI) + o;
	a = clamp(a, min(s, e), max(s, e));
	float d = distance(p, size * 0.5 * vec2(cos(a), sin(a)));
    return d;
}
float arc(in vec2 p, in float size, in float s, in float e) {
    /*
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    d = smoothstep(d - rx, d + rx, size / 2.0 * a);
    */
    float d = sArc(p, size, s, e);
    // return d;
    return fill(d);
}
float arc(in vec2 p, in float size, in float s, in float e, in float t) {
    float d = sArc(p, size, s, e);
    return stroke(d, t);
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

float sHex(in vec2 p, in float size) {
    vec2 q = abs(p);
    float d = max((q.x * 0.866025 + q.y * 0.5), q.y) - size * 0.5; // * 0.4330125
    return d * 2.0;
}
float hex(in vec2 p, in float size) {    
    float d = sHex(p, size);
    return fill(d);
}
float hex(in vec2 p, in float size, in float t) {
    float d = sHex(p, size);
    return stroke(d, t);    
}

float sLine(in vec2 a, in vec2 b) {
    vec2 ba = a - b;
    float d = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    return length(a - ba * d) * 2.0;
}
float line(in vec2 a, in vec2 b, float t) {
    float d = sLine(a, b);
    return stroke(d, t);
}

float sPie(in vec2 p, in float s, in float e, in float size) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    return 1.0 - (a - d * 2.0) - size;
}
float pie(in vec2 p, in float s, in float e, in float size) {    
    float d = sPie(p, s, e, size);
    return fill(d);
}
float pie(in vec2 p, in float s, in float e, in float size, in float t) {
    float d = sPie(p, s, e, size);
    return stroke(d, t);    
}

float sPlot(vec2 p, float y){
    return p.y + y;
}
float plot(vec2 p, float y, float t) {
    float d = sPlot(p, y);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float sPoly(in vec2 p, in int sides, in float size) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return d * 2.0 - size;
}
float poly(in vec2 p, in float size, in int sides) {
    float d = sPoly(p, sides, size);
    return fill(d);
}
float poly(in vec2 p, in float size, in int sides, in float t) {
    float d = sPoly(p, sides, size);
    return stroke(d, t);
}

float sRect(in vec2 p, in vec2 size) {    
    float d = max(abs(p.x / size.x), abs(p.y / size.y)) * 2.0;
    float m = max(size.x, size.y);
    return d * m - m;
}
float rect(in vec2 p, in vec2 size) {
    float d = sRect(p, size);
    return fill(d);
}
float rect(in vec2 p, in vec2 size, in float t) {
    float d = sRect(p, size);
    return stroke(d, t);
}

float sRectline(in vec2 p, in float a) {
    p *= rotate2d(a);
    return p.x * 2.0;
}
float rectline(in vec2 p, in float a, in float t) {
    float d = sRectline(p, a);
    return stroke(d, t);
}
float rectline(in vec2 p, in float a) { return rectline(p, a, 0.004); }
float rectline(in vec2 p) { return rectline(p, 0.0, 0.004); }

float sRoundrect(in vec2 p, in vec2 size, in float radius) {
    float m = max(size.x, size.y);
    vec2 s = (size * 0.5) - radius;
    float d = length(max(abs(p) - s, 0.0)) / radius * m;
    return d - m;
}
float roundrect(in vec2 p, in vec2 size, in float radius) {
    float d = sRoundrect(p, size, radius);
    return fill(d);
}
float roundrect(in vec2 p, in vec2 size, in float radius, in float t) {
    size = vec2(0.4); radius = 0.1; t = 0.1;
    float d = sRoundrect(p, size, radius);
    // return d;
    float m = max(size.x - radius, size.y - radius);
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

float sStar(in vec2 p, in float size, in int sides) {    
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m;
    return (d - rx) * 2.0 - size;
}
float star(in vec2 p, in float size, in int sides) {
    float d = sStar(p, size, sides);
    return fill(d);
}
float star(in vec2 p, in float size, in int sides, float t) {    
    float d = sStar(p, size, sides);
    return stroke(d, t);
}

float grid(in float size) {
    float d = 0.0;
    d += rectline(tile(st, size), 0.0, 0.002);
    d += rectline(tile(st, size), PI_TWO, 0.002);
    d *= 0.2;
    vec2 p = tile(st, vec2(size * 5.0, size * 5.0));
    float s = size / 10.0;
    float g = 0.0;
    g += line(p + vec2(-s, 0.0), p + vec2(s, 0.0), 0.004);
    g += line(p + vec2(0.0, -s), p + vec2(0.0, s), 0.004);
    return d + g;
}

float sUnion(float a, float b) {
    return min(a, b);
}

// sblend or smoothmin by iquilezles.org
float sBlendExpo(float a, float b, float k) {
    float res = exp(-k * a) + exp(-k * b);
    return -log(res) / k;
}
float sBlendPoly(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float sBlendPower(float a, float b, float k) {
    a = pow(a, k); b = pow(b, k);
    return pow((a * b) / (a + b), 1.0 / k);
}

// draw Distance Field by https://www.shadertoy.com/view/XsyGRW
vec3 dfLine(float d) {
    const float aa = 3.0;
    const float t = 0.0025;
    return vec3(smoothstep(0.0, aa / u_resolution.y, max(0.0, abs(d) - t)));
}    
float dfSolid(float d) {
    return smoothstep(0.0, 3.0 / u_resolution.y, max(0.0, d));
}
vec3 dfDraw(float d, vec2 p) {
    float t = clamp(d * 0.85, 0.0, 1.0);
    vec3 gradient = mix(vec3(1, 0.8, 0.5), vec3(0.3, 0.8, 1), t);
    float d0 = abs(1.0 - dfLine(mod(d + 0.1, 0.2) - 0.1).x);
    float d1 = abs(1.0 - dfLine(mod(d + 0.025, 0.05) - 0.025).x);
    float d2 = abs(1.0 - dfLine(d).x);
    vec3 rim = vec3(max(d2 * 0.85, max(d0 * 0.25, d1 * 0.06125)));
    gradient -= rim;
    gradient -= mix(vec3(0.05, 0.35, 0.35), vec3(0.0), dfSolid(d));
    return gradient;
}

void main() {
    vec3 color = BLACK;
    
    color = mix(color, GREEN, grid(0.1));
    
    vec2 p = st; // + cos(u_time) * 0.1;

    float d = 0.0;
    
    d = arc(p, 0.3, 0.0, PI_TWO);
    // d = arc(p, 0.3, 0.0, PI_TWO, 0.05);
    // d = circle(p, 0.3);
    // d = circle(p, 0.3, 0.1);
    // d = hex(p, 0.3);
    // d = hex(p, 0.3, 0.1);
    // d = line(p - vec2(0.15), p + vec2(0.15), 0.1);
    // d = pie(p, 0.0, PI_TWO, 0.3);
    // d = pie(p, 0.0, PI_TWO, 0.3, 0.1);
    // d = plot(p, -p.x, 0.1);
    // d = poly(p, 0.3, 3);
    // d = poly(p, 0.3, 3, 0.1);
    // d = rect(p, vec2(0.3));
    // d = rect(p, vec2(0.3), 0.1);
    // d = rectline(p, PI_TWO / 2.0, 0.1);
    // d = roundrect(p, vec2(0.3), 0.1);
    // d = roundrect(p, vec2(0.3), 0.1, 0.1);
    // d = spiral(p, 1.0);
    // d = star(p, 0.3, 6);
    // d = star(p, 0.3, 6, 0.05);
    
    color = mix(color, WHITE, d);

    color = dfDraw(sCircle(p, 0.3), p);
    // color = dfDraw(sHex(p, 0.3), p);    
    // color = dfDraw(sRoundrect(p, vec2(0.3), 0.1) + 0.005, p);
    
    // float c = sBlendPoly(sCircle(p - 0.1, 0.3), sCircle(p + 0.1, 0.3), 0.5);
    // color = dfDraw(c, p);

    gl_FragColor = vec4(color, 1.0);
}
