// Author: Luca Zampetti
// Title: vscode-glsl-canvas Easing examples

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

float random(in vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}
float noise(vec2 p) {
    vec2 ua = p + u_time * 0.02;
    vec2 ub = p * 0.8 + u_time * 0.04;
    float n = texture2D(u_texture_0, ua).r * texture2D(u_texture_0, ub).r;
    return n;
}
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
#define uv gl_FragCoord.xy / u_resolution.xy
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define ee noise(gl_FragCoord.xy / u_resolution.xy)
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
// #define rx ee * 0.05 + 1.0 / min(u_resolution.x, u_resolution.y)

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
float circle(in vec2 p, in float size, in float t) {
    float d = length(abs(p)) - size / 2.0;
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
}

float line(in vec2 a, in vec2 b, in float t) {
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
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m - size / 2.0;
    return 1.0 - smoothstep(0.0, rx * 2.0, d);
}
float star(in vec2 p, in float size, in int sides, float t) {    
    float r = 0.5; float s = max(5.0, float(sides)); float m = 0.5 / s; float x = PI_TWO / s * (2.0 - mod(s, 2.0)); 
    float segment = (atan(p.y, p.x) - x) / TWO_PI * s;    
    float a = ((floor(segment) + r) / s + mix(m, -m, step(r, fract(segment)))) * TWO_PI;
    float d = abs(dot(vec2(cos(a + x), sin(a + x)), p)) + m - size / 2.0;
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

// Easing Equations adapted from Robert Penner easing functions.
// Back, Bounce, Circular, Cubic, Elastic, Expo, Quad, Quart, Quint, Sine

// Back
float easexBackIn(float t) {
    float s = 1.70158;
    return t * t * ((s + 1.0) * t - s);
}
float easeBackOut(float t) {
    float s = 1.70158;
    return ((t = t - 1.0) * t * ((s + 1.0) * t + s) + 1.0);
}
float easeBackInOut(float t) {
    float s = 1.70158;
    if ((t / 2.0) < 1.0) return 0.5 * (t * t * (((s *= (1.525)) + 1.0) * t - s));
    return 0.5 * ((t -= 2.0) * t * (((s *= (1.525)) + 1.0) * t + s) + 2.0);
}
// Bounce
float easeBounceOut(float t) {
    if (t < (1.0 / 2.75)) {
        return (7.5625 * t * t);
    } else if (t < (2.0 / 2.75)) {
        return (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75);
    } else if (t < (2.5 / 2.75)) {
        return (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375);
    } else {
        return (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375);
    }
}
float easeBounceIn(float t) {
    return 1.0 - easeBounceOut(1.0 - t);
}
float easeBounceInOut(float t) {
    if (t < 0.5) return easeBounceIn(t * 2.0) * 0.5;
    else return easeBounceOut(t * 2.0 - 1.0) * 0.5 + 0.5;
}
// Circular
float easeCircularIn(float t) {
    return -1.0 * (sqrt(1.0 - t * t) - 1.0);
}
float easeCircularOut(float t) {
    return sqrt(1.0 - (t = t - 1.0) * t);
}
float easeCircularInOut(float t) {
    if ((t / 2.0) < 1.0) return -0.5 * (sqrt(1.0 - t * t) - 1.0);
    return 0.5 * (sqrt(1.0 - (t -= 2.0) * t) + 1.0);
}
// Cubic
float easeCubicIn(float t) {
    return t * t * t;
}
float easeCubicOut(float t) {
    return ((t = t - 1.0) * t * t + 1.0);
}
float easeCubicInOut(float t) {
    if ((t / 2.0) < 1.0) return 0.5 * t * t * t;
    return 0.5 * ((t -= 2.0) * t * t + 2.0);
}
// Elastic
float easeElasticIn(float t) {
    if (t == 0.0) { return 0.0; }
    if (t == 1.0) { return 1.0; }
    float p = 0.3;
    float a = 1.0; 
    float s = p / 4.0;
    return -(a * pow(2.0, 10.0 * (t -= 1.0)) * sin((t - s) * TWO_PI / p));
}
float easeElasticOut(float t) {
    if (t == 0.0) { return 0.0; }
    if (t == 1.0) { return 1.0; }
    float p = 0.3;
    float a = 1.0; 
    float s = p / 4.0;
    return (a * pow(2.0, -10.0 * t) * sin((t - s) * TWO_PI / p) + 1.0);
}
float easeElasticInOut(float t) {
    if (t == 0.0) { return 0.0; }
    if ((t / 2.0) == 2.0) { return 1.0; }
    float p = (0.3 * 1.5);
    float a = 1.0; 
    float s = p / 4.0;
    if (t < 1.0) {
        return -0.5 * (a * pow(2.0, 10.0 * (t -= 1.0)) * sin((t - s) * TWO_PI / p));
    }
    return a * pow(2.0, -10.0 * (t -= 1.0)) * sin((t - s) * TWO_PI / p) * 0.5 + 1.0;
}
// Exponential
float easeExpoIn(float t) {
    return (t == 0.0) ? 0.0 : pow(2.0, 10.0 * (t - 1.0));
}
float easeExpoOut(float t) {
    return (t == 1.0) ? 1.0 : (-pow(2.0, -10.0 * t) + 1.0);
}
float easeExpoInOut(float t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    if ((t / 2.0) < 1.0) return 0.5 * pow(2.0, 10.0 * (t - 1.0));
    return 0.5 * (-pow(2.0, -10.0 * --t) + 2.0);
}
// Quadratic
float easeQuadIn(float t) {
    return t * t;
}
float easeQuadOut(float t) {
    return -1.0 * t * (t - 2.0);
}
float easeQuadInOut(float t) {
    if ((t / 2.0) < 1.0) return 0.5 * t * t;
    return -0.5 * ((--t) * (t - 2.0) - 1.0);
}
// Quartic
float easeQuartIn(float t) {
    return t * t * t * t;
}
float easeQuartOut(float t) {
    return -1.0 * ((t = t - 1.0) * t * t * t - 1.0);
}
float easeQuartInOut(float t) {
    if ((t / 2.0) < 1.0) return 0.5 * t * t * t * t;
    return -0.5 * ((t -= 2.0) * t * t * t - 2.0);
}
// Quintic
float easeQuintIn(float t) {
    return t * t * t * t * t;
}
float easeQuintOut(float t) {
    return ((t = t - 1.0) * t * t * t * t + 1.0);
}
float easeQuintInOut(float t) {
    if ((t / 2.0) < 1.0) return 0.5 * t * t * t * t * t;
    return 0.5 * ((t -= 2.0) * t * t * t * t + 2.0);
}
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

struct Object { float distance; vec3 color; };
Object object = Object(0.0, vec3(0.0));

struct Animation { float time; float pow; };
Animation animation = Animation(0.0, 0.0);
void totalTime(in float t, in float offset) { animation.time = mod(u_time + offset, t); }
void totalTime(in float t) { totalTime(t, 0.0); }
bool between(in float duration, in float offset) {
    float p = (animation.time - offset) / duration;
    animation.pow = p;
    animation.time -= (duration + offset);
    return (p >= 0.0 && p <= 1.0);
}
bool between(in float duration) {
    return between(duration, 0.0);
}

void main() {
    vec2 p = st - ee * 0.03;
    float v = 0.0;
    float v2 = 0.0;

    totalTime(12.0);
        
    if (between(0.5)) {
        v = easeElasticOut(animation.pow);
        object.distance = circle(p, 0.1 + 0.1 * v);
    }

    if (between(0.5, -0.25)) {
        v = easeElasticOut(animation.pow);
        object.distance = rect(p * rotate2d(PI_TWO / 2.0 * v), vec2(0.3), 0.04);
    }

    if (between(0.25, -0.25)) {
        object.distance = circle(p, 0.2 + 1.3 * animation.pow, 0.1) * (1.0 - animation.pow);
    }

    if (between(0.5, 0.25)) {
        v = easeElasticOut(animation.pow);
        object.distance = rectline(p, 0.5 * v);
    }

    if (between(0.25)) {
        v = easeSineInOut(animation.pow);
        object.distance = rectline(p, 0.5, PI_TWO / 2.0 * v);
    }

    if (between(0.5)) {
        v = easeBounceOut(animation.pow);
        object.distance = rectline(p, 0.5 * (1.0 - v), PI_TWO / 2.0);
    }

    if (between(1.0, 0.25)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance = line(p + vec2(mix(-0.5, 0.5, v), 0.0), st + vec2(mix(-0.5, 0.5, v2), 0.0), 0.004);
    }
    if (between(1.0, -0.8)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += line(p + vec2(mix(-0.5, 0.5, v), -0.1), st + vec2(mix(-0.5, 0.5, v2), -0.1), 0.008);
    }
    if (between(1.0, -0.6)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += line(p + vec2(mix(-0.5, 0.5, v), 0.1), st + vec2(mix(-0.5, 0.5, v2), 0.1), 0.012);
    }

    if (between(1.0, 0.25)) {
        v = easeBounceOut(animation.pow);
        object.distance = circle(p + vec2(0.0, mix(-0.3, 0.3, v)), 0.2, 0.02);
    }

    if (between(0.5)) {
        v = easeSineOut(animation.pow);
        object.distance = circle(p + vec2(0.3 * cos(PI_TWO + v * 2.0 * PI), 0.3 * sin(PI_TWO + v * 2.0 * PI)), 0.2, 0.02);
    }

    if (between(1.0)) {
        v = easeElasticOut(animation.pow);
        object.distance = circle(p + vec2(0.0, mix(0.3, 0.0, v)), 0.2 + 0.4 * v, 0.02 + 0.06 * v);
    }

    if (between(0.15)) {
        v = easeSineOut(animation.pow);
        object.distance = circle(p, 0.6 - 0.5 * v, 0.08) * (1.0 - v);
    }

    if (between(0.5)) {
        v = easeElasticOut(animation.pow);
        object.distance = poly(p * rotate2d(PI), 0.1 + 0.2 * v, 3, 0.06);
    }

    if (between(0.35)) {
        v = easeCircularOut(animation.pow);
        object.distance = poly(p * rotate2d(PI) + vec2(0.0, mix(0.6, 0.0, v)), 0.1, 3, 0.02);
    }
    if (between(0.35)) {
        v = easeCircularIn(animation.pow);
        object.distance = poly(p * rotate2d(PI) + vec2(0.0, mix(0.0, -0.6, v)), 0.1, 3, 0.02);
    }

    if (between(1.0, 0.25)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance = line(p + vec2(0.0, mix(-0.5, 0.5, v)), st + vec2(0.0, mix(-0.5, 0.5, v2)), 0.004);
    }
    if (between(1.0, -0.8)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += line(p + vec2(-0.1, mix(-0.5, 0.5, v)), st + vec2(-0.1, mix(-0.5, 0.5, v2)), 0.008);
    }
    if (between(1.0, -0.6)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += line(p + vec2(0.1, mix(-0.5, 0.5, v)), st + vec2(0.1, mix(-0.5, 0.5, v2)), 0.012);
    }

    if (between(1.0)) {
        v = easeCircularIn(animation.pow);
        object.distance = star(p, 0.5, 6 + int((1.0 - animation.pow) * 44.0), 0.04);
    }

    if (between(0.5)) {
        v = easeCircularIn(animation.pow);
        object.distance = star(p + vec2(0.0, mix(0.0, 0.5, v)), 0.5, 6, 0.04) * (1.0 - animation.pow);
    }

    vec3 color = BLACK + 0.015;
    
    // object.color = WHITE;
    object.color = vec3(0.0, 0.6, 0.9);
    // object.color = vec3(abs(cos(p.x)), abs(sin(p.y)), abs(cos(u_time * 0.1)));
    // object.color = vec3(abs(cos(p.x + ee)), abs(sin(p.y - ee)), abs(sin(u_time * 5.0 + ee)));
    // color = mix(color, WHITE, grid(0.1));
    
    object.color += ee * 0.1 - random(st) * length(st) * 0.5;
    
    color = mix(color, object.color, object.distance);
    
    gl_FragColor = vec4(color, 1.0);
}