// Author: Luca Zampetti
// Title: vscode-glsl-canvas Easing examples

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

vec2 tile(in vec2 p, vec2 w) { return fract(mod(p + w / 2.0, w)) - (w / 2.0); }
vec2 tile(in vec2 p, float w) { return tile(p, vec2(w)); }

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }

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

float sPlot(vec2 p, float y){
    return p.y + y;
}
float plot(vec2 p, float y, float t) {
    float d = sPlot(p, y);
    return 1.0 - smoothstep(t / 2.0 - rx, t / 2.0 + rx, abs(d));
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
    t *= 2.0;
    float s = 1.70158;
    if (t < 1.0) return 0.5 * (t * t * (((s *= (1.525)) + 1.0) * t - s));
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
    t = t * 2.0;
    if ((t) < 1.0) return -0.5 * (sqrt(1.0 - t * t) - 1.0);
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
    t = t * 2.0;
    if (t < 1.0) return 0.5 * t * t * t;
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
    t = t * 2.0;
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
    t = t * 2.0;
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;
    if (t < 1.0) return 0.5 * pow(2.0, 10.0 * (t - 1.0));
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
    t = t * 2.0;
    if (t < 1.0) return 0.5 * t * t;
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
    t = t * 2.0;
    if (t < 1.0) return 0.5 * t * t * t * t;
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
    t = t * 2.0;
    if (t < 1.0) return 0.5 * t * t * t * t * t;
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
    t = t * 2.0;
    return -0.5 * (cos(PI * t) - 1.0);
}

void main() {           
    vec2 p = st * 1.2;
    float s = 1.0; float s2 = s / 2.0; float x = 0.5 - p.x;
    float t = fract(u_time * 0.5);

    float v = t; float y = x;
    // v = easexBackIn(t); y = easexBackIn(x);
    // v = easeBackOut(t); y = easeBackOut(x);
    // v = easeBackInOut(t); y = easeBackInOut(x);
    // v = easeBounceOut(t); y = easeBounceOut(x);
    // v = easeBounceIn(t); y = easeBounceIn(x);
    // v = easeBounceInOut(t); y = easeBounceInOut(x);
    // v = easeCircularIn(t); y = easeCircularIn(x);
    // v = easeCircularOut(t); y = easeCircularOut(x);
    // v = easeCircularInOut(t); y = easeCircularInOut(x);
    // v = easeCubicIn(t); y = easeCubicIn(x);
    // v = easeCubicOut(t); y = easeCubicOut(x);
    // v = easeCubicInOut(t); y = easeCubicInOut(x);
    // v = easeElasticIn(t); y = easeElasticIn(x);
    // v = easeElasticOut(t); y = easeElasticOut(x);
    // v = easeElasticInOut(t); y = easeElasticInOut(x);
    // v = easeExpoIn(t); y = easeExpoIn(x);
    // v = easeExpoOut(t); y = easeExpoOut(x);
    // v = easeExpoInOut(t); y = easeExpoInOut(x);
    // v = easeQuadIn(t); y = easeQuadIn(x);
    // v = easeQuadOut(t); y = easeQuadOut(x);
    // v = easeQuadInOut(t); y = easeQuadInOut(x);
    // v = easeQuartIn(t); y = easeQuartIn(x);
    // v = easeQuartOut(t); y = easeQuartOut(x);
    // v = easeQuartInOut(t); y = easeQuartInOut(x);
    // v = easeQuintIn(t); y = easeQuintIn(x);
    // v = easeQuintOut(t); y = easeQuintOut(x);
    // v = easeQuintInOut(t); y = easeQuintInOut(x);
    // v = easeSineIn(t); y = easeSineIn(x);
    // v = easeSineOut(t); y = easeSineOut(x);
    // v = easeSineInOut(t); y = easeSineInOut(x);

    vec3 color = AZUR;

    color = mix(color, BLACK, grid(p, 0.1));
    
    float d = plot(p, y - s2, 0.008);
    color = mix(color, WHITE, d * 0.5);

    vec2 c = vec2(t, v);
    d = 0.0;
    d += segment(p - vec2(s2, s2 + 0.01), p + vec2(-s2, s2 + 0.01), 0.004);
    d += segment(p + vec2(-s2 - 0.01, s2), p + vec2(s2 + 0.01, s2), 0.004);
    color = mix(color, BLACK, d * 0.3);
    
    d = circle(p - 0.5 + c, 0.04);
    color = mix(color, BLACK, d);
    
    gl_FragColor = vec4(color, 1.0);
}