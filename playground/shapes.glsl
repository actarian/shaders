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

float fill(in float d, in float size) { return 1.0 - smoothstep(size - rx, size + rx, d); }
float fill(in float d, in vec2 size) { return fill(d, max(size.x, size.y) ); }

float stroke(in float d, in float size, in float t) { return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d - size)); }
float stroke(in float d, in vec2 size, in float t) { return stroke(d, max(size.x, size.y), t); }

float sArc(in vec2 p, in float s, in float e, in float size) {
    e += s;
    float o = (s / 2.0 + e / 2.0 - PI);
	float a = mod(atan(p.y, p.x) - o, TWO_PI) + o;
	a = clamp(a, min(s, e), max(s, e));
	float d = distance(p, size / 2.0 * vec2(cos(a), sin(a)));
    return d + size;
}
float arc(in vec2 p, in float s, in float e, in float size) {
    /*
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    d = smoothstep(d - rx, d + rx, size / 2.0 * a);
    */
    float d = sArc(p, s, e, size);
    return fill(d, size);
}
float arc(in vec2 p, in float s, in float e, in float size, in float t) {
    float d = sArc(p, s, e, size);
    return stroke(d, size, t);
}

float sCircle(in vec2 p) {
    return length(p) * 2.0;
}
float circle(in vec2 p, in float size) {
    float d = sCircle(p);
    return fill(d, size);
}
float circle(in vec2 p, in float size, float t) {
    float d = sCircle(p);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d - size));
}

float sLine(in vec2 a, in vec2 b) {
    vec2 ba = a - b;
    float d = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    return length(a - ba * d);
}
float line(in vec2 a, in vec2 b, float t) {
    float d = sLine(a, b);
    return stroke(d, 0.0, t);
}

float sPie(in vec2 p, in float s, in float e) {
    s = mod(s, TWO_PI);
    e = mod(s + e, TWO_PI);
    float a = mod(atan(p.y, p.x), TWO_PI);
    a = abs(step(s, a) - step(e, a));
    a = s < e ? a : 1.0 - a;
    float d = length(p);
    return 1.0 - (a - d * 2.0);
}
float pie(in vec2 p, in float s, in float e, in float size) {    
    float d = sPie(p, s, e);
    return fill(d, size);
}
float pie(in vec2 p, in float s, in float e, in float size, in float t) {
    float d = sPie(p, s, e);
    return stroke(d, size, t);    
}

float sPlot(vec2 p, float y){
    return p.y + y;
}
float plot(vec2 p, float y, float t) {
    float d = sPlot(p, y);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float sPoly(in vec2 p, in int sides) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return d * 2.0;
}
float poly(in vec2 p, in float size, in int sides) {
    float d = sPoly(p, sides);
    return fill(d, size);
}
float poly(in vec2 p, in float size, in int sides, in float t) {
    /*
    float d = sPoly(p, size, sides);
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0)) - size / 2.0;
    */
    float d = sPoly(p, sides);
    return stroke(d, size, t);
    //return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d - size));
}

float sRect(in vec2 p, in vec2 size) {    
    float d = max(abs(p.x / size.x), abs(p.y / size.y)) * 2.0;
    return d * max(size.x, size.y);
}
float rect(in vec2 p, in vec2 size) {
    float d = sRect(p, size);
    return fill(d, size);
}
float rect(in vec2 p, in vec2 size, in float t) {
    float d = sRect(p, size);
    return stroke(d, size, t);
}

/*
CIRCLE
float circle(vec2 point, float radius) {
  return length(point) - radius;
}
BOX
float box(vec2 point, vec2 size) {
  vec2 d = abs(point) - size;
  return min(max(d.x, d.y),0.0) + length(max(d,0.0));
}
HEXAGON
float hexagon(vec2 point, float radius) {
  vec2 q = abs(point);
  return max((q.x * 0.866025 + q.y * 0.5), q.y) - radius;
}
*/

float sRectline(in vec2 p, in float a) {
    p *= rotate2d(a);
    return p.x;
}
float rectline(in vec2 p, in float a, in float t) {
    float d = sRectline(p, a);
    return stroke(d, 0.0, t);
}
float rectline(in vec2 p, in float a) { return rectline(p, a, 0.004); }
float rectline(in vec2 p) { return rectline(p, 0.0, 0.004); }


float sRectt(in vec2 p, in vec2 size) {    
    float d = max(abs(p.x / size.x), abs(p.y / size.y)) * 2.0;
    return d * max(size.x, size.y);
}
float sRoundrect(in vec2 p, in vec2 size, in float radius) {
    // radius *= 2.0; size /= 2.0;
    // float d = length(max(abs(p) -size + radius, 0.0)) - radius;
    float m = max(size.x, size.y);
    radius *= 2.0; size /= 2.0; size -= radius;
    float d = length(max(abs(p), size) - size) - radius;
    return d; // * m;
}
float roundrect(in vec2 p, in vec2 size, in float radius) {
    float d = sRoundrect(p, size, radius);
    return fill(d, 0.0);
}
float roundrect(in vec2 p, in vec2 size, in float radius, in float t) {
    float d = sRoundrect(p, size, radius);
    // radius *= 2.0; size /= 2.0; size -= radius;
    // float d = length(max(abs(p), size) - size) - radius;
    // return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
    return stroke(d, 0.0, t);
}

float sSpiral(in vec2 p, in float turns) {
    float r = dot(p, p);
    float a = atan(p.y, p.x);
    float d = abs(sin(fract(log(r) * (turns / 5.0) + a * 0.159)));
    return d;
}
float spiral(in vec2 p, in float turns) {    
    float d = sSpiral(p, turns);
    return fill(d, 0.5);
}

float sStar(in vec2 p, in int sides) {    
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m;
    return d;
}
float star(in vec2 p, in float size, in int sides) {
    float d = sStar(p, sides);
    return fill(d, size);
    /*
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m - size / 2.0;
    return 1.0 - smoothstep(0.0, rx * 2.0, d);
    */
}
float star(in vec2 p, in float size, in int sides, float t) {    
    float d = sStar(p, sides);
    return stroke(d, size, t);
    /*
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
    */
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

void main() {
    vec3 color = BLACK;
    
    color = mix(color, GREEN, grid(0.1));
    
    vec2 p = st; // + cos(u_time) * 0.1;

    float d = 0.0;
    
    d = arc(p, 0.0, PI_TWO, 0.3);
    // d = arc(p, 0.0, PI_TWO, 0.3, 0.004);
    // d = circle(p, 0.3);
    // d = circle(p, 0.3, 0.004);
    // d = line(p - vec2(0.15), p + vec2(0.15), 0.004);
    // d = pie(p, 0.0, PI_TWO, 0.3);
    // d = pie(p, 0.0, PI_TWO, 0.3, 0.004);
    // d = plot(p, -p.x, 0.004);
    // d = poly(p, 0.3, 3);
    // d = poly(p, 0.3, 3, 0.004);
    // d = rect(p, vec2(0.3));
    // d = rect(p, vec2(0.3), 0.004);
    // d = rectline(p, PI_TWO / 2.0, 0.004);
    // d = roundrect(p, vec2(0.3), 0.02);
    d = roundrect(p, vec2(0.2), 0.02, 0.004);
    // d = spiral(p, 1.0);
    // d = star(p, 0.3, 5);
    // d = star(p, 0.3, 5, 0.004);
    
    color = mix(color, WHITE, d);
    
    gl_FragColor = vec4(color, 1.0);
}
