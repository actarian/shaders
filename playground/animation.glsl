// Author: Luca Zampetti
// Title: vscode-glsl-canvas Animation example

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
#define uv gl_FragCoord.xy / u_resolution.xy
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define rx 1.0 / min(u_resolution.x, u_resolution.y)

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 tile(in vec2 p, vec2 w) { return fract(mod(p + w / 2.0, w)) - (w / 2.0); }
vec2 tile(in vec2 p, float w) { return tile(p, vec2(w)); }

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }

float sArc(in vec2 p, in float w, in float s, in float e) {    
    float a = distance(p, w * 0.5 * vec2(cos(s), sin(s)));
    float x = -PI;
    p *= mat2(cos(x - s), -sin(x - s), sin(x - s), cos(x - s));
    float b = clamp(atan(p.y, p.x), x, x + e);
    b = distance(p, w * 0.5 * vec2(cos(b), sin(b)));
    return min(a, b) * 2.0;
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
    vec2 p = st; float v = 0.0; float v2 = 0.0;

    totalTime(14.0);
        
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
        object.distance = line(p, 0.0, 0.5 * v);
    }

    if (between(0.25)) {
        v = easeSineOut(animation.pow);
        object.distance = line(p, PI_TWO / 2.0 * v, 0.5);
    }

    if (between(0.5)) {
        v = easeBounceOut(animation.pow);
        object.distance = line(p, PI_TWO / 2.0, 0.5 * (1.0 - v));
    }

    if (between(1.0, 0.25)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance = segment(p + vec2(mix(-0.5, 0.5, v), 0.0), st + vec2(mix(-0.5, 0.5, v2), 0.0), 0.004);
    }
    if (between(1.0, -0.8)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += segment(p + vec2(mix(-0.5, 0.5, v), -0.1), st + vec2(mix(-0.5, 0.5, v2), -0.1), 0.008);
    }
    if (between(1.0, -0.6)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += segment(p + vec2(mix(-0.5, 0.5, v), 0.1), st + vec2(mix(-0.5, 0.5, v2), 0.1), 0.012);
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
        object.distance = segment(p + vec2(0.0, mix(-0.5, 0.5, v)), st + vec2(0.0, mix(-0.5, 0.5, v2)), 0.004);
    }
    if (between(1.0, -0.8)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += segment(p + vec2(-0.1, mix(-0.5, 0.5, v)), st + vec2(-0.1, mix(-0.5, 0.5, v2)), 0.008);
    }
    if (between(1.0, -0.6)) {
        v = easeQuintOut(animation.pow);
        v2 = easeQuintIn(animation.pow);
        object.distance += segment(p + vec2(0.1, mix(-0.5, 0.5, v)), st + vec2(0.1, mix(-0.5, 0.5, v2)), 0.012);
    }

    if (between(1.6, 0.25)) {
        v = easeQuintOut(animation.pow);
        object.distance = arc(p, 0.3, PI_TWO + v * 0.1, TWO_PI * v * 0.7, 0.08);
    }
    if (between(1.4, -1.4)) {
        v = easeQuartOut(animation.pow);
        object.distance += arc(p, 0.46, PI_TWO + v * 0.1, TWO_PI * v * 0.8, 0.04);
    }
    if (between(1.2, -1.2)) {
        v = easeQuadOut(animation.pow);
        object.distance += arc(p, 0.56, PI_TWO + v * 0.1, TWO_PI * v * 0.9, 0.02);
    }

    if (between(1.0)) {
        v = easeCircularIn(animation.pow);
        object.distance = star(p, 0.5, 6 + int((1.0 - animation.pow) * 44.0), 0.04);
    }

    if (between(0.5)) {
        v = easeCircularIn(animation.pow);
        object.distance = star(p + vec2(0.0, mix(0.0, 0.5, v)), 0.5, 6, 0.04) * (1.0 - animation.pow);
    }

    vec3 color = AZUR;
    
    object.color = WHITE;
    
    color = mix(color, object.color, object.distance);

    gl_FragColor = vec4(color, 1.0);
}