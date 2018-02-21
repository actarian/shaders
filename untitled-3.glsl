precision mediump float;

/***   u n i f o r m s   ***/

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

/***   c o n s t a n t s   ***/

#define st vec2((gl_FragCoord.x / u_resolution.x - 0.5) * 1.0, ((gl_FragCoord.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * -1.0)
#define mx vec2((u_mouse.x / u_resolution.x - 0.5) * 1.0, ((u_mouse.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * -1.0)

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

#define RED             vec3(1.0, 0.0, 0.0)
#define BLUE            vec3(0.0, 0.0, 1.0)
#define YELLOW          vec3(1.0, 1.0, 0.0)

/*
vec2 getSt() {
	vec2 st = gl_FragCoord.xy / u_resolution.xy;
    // correct aspect ratio
	st.y *= u_resolution.y / u_resolution.x;
	st.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    // centering
    st -= 0.5;
    st *= vec2(-1.0, 1.0);
	return st;
}

vec2 getMx() {
	vec2 mx = u_mouse / u_resolution.xy;
    // correct aspect ratio
	mx.y *= u_resolution.y / u_resolution.x;
	mx.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    // centering
    mx -= 0.5;
    mx *= vec2(1.0, -1.0);
	return mx;
}

#define st getSt()
#define mx getMx()
*/

/***   m a t h   ***/

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

/***   s h a p e s   ***/

float plot(vec2 p, float pct) {
  return smoothstep(pct - 0.002, pct, p.y) - smoothstep(pct, pct + 0.002, p.y);
}

float polygon(vec2 p, int sides) {
    // p -= 0.5;
    // Angle and radius from the current pixel
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    // Shaping function that modulate the distance
    float d = cos(floor(0.5 + a / r) * r - a) * length(p);
    return 1.0 - smoothstep(0.1, 0.1001, d);
}

float rect(vec2 p, vec2 size) {
    vec2 s2 = size / -2.0;
    vec2 bl = smoothstep(vec2(s2 - 0.001), vec2(s2), p);
    vec2 tr = smoothstep(vec2(s2 + 1.0), vec2(s2 + 1.0 + 0.001), 1.0 - p);
    return bl.x * bl.y * tr.x * tr.y;
}

float circle(vec2 p, float r) {
    return 1.0 - smoothstep(
        r - (r * 0.1),
        r + (r * 0.1),
        dot(p, p) * 4.0
    );
}

vec2 move(vec2 p, float d) {
    return p + vec2(
        cos(u_time * d) * 0.2, 
        sin(u_time * d) * 0.2
    );
}

/***   o b j e c t s   ***/

struct Object { float distance; vec3 color; };
Object object = Object(1000000.0, vec3(0.0));

/***   a n i m a t i o n   ***/

struct Animation { float time; float pow; };
Animation animation = Animation(0.0, 0.0);
void totalTime(float t, float d) { animation.time = mod(u_time + d, t); }
void totalTime(float t) { totalTime(t, 0.0); }
bool between(float duration) {
    float p = animation.time / duration;
    animation.pow = p;
    animation.time -= duration;
    return (p >= 0.0 && p <= 1.0);
}

vec3 repeat(vec3 p, vec3 r) { return mod(p, r) -0.5 * r; }
vec2 repeat(vec2 p, vec2 r) { return mod(p, r) -0.5 * r; }

vec2 tile(vec2 p, float zoom) { p *= zoom; return fract(p); }

/***   e a s i n g s   ***/
/* Easing Bounce Out equation */
/* Adapted from Robert Penner easing equations */
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
/* Easing Elastic Out equation */
/* Adapted from Robert Penner easing equations */
#define TWO_PI			6.283185307179586
float easeElasticOut(float t) {
    if (t == 0.0) { return 0.0; }
    if (t == 1.0) { return 1.0; }
    float p = 0.3;
    float a = 1.0; 
    float s = p / 4.0;
    return (a * pow(2.0, -10.0 * t) * sin((t - s) * TWO_PI / p) + 1.0);
}

/////////////////

// Cellular noise ("Worley noise") in 2D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.
// https://github.com/stegu/webgl-noise

// Modulo 289 without a division (only multiplications)
vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 7 without a division
vec4 mod7(vec4 x) {
  return x - floor(x * (1.0 / 7.0)) * 7.0;
}

// Permutation polynomial: (34x^2 + x) mod 289
vec4 permute(vec4 x) {
  return mod289((34.0 * x + 1.0) * x);
}

// Cellular noise, returning F1 and F2 in a vec2.
// Speeded up by using 2x2 search window instead of 3x3,
// at the expense of some strong pattern artifacts.
// F2 is often wrong and has sharp discontinuities.
// If you need a smooth F2, use the slower 3x3 version.
// F1 is sometimes wrong, too, but OK for most purposes.
vec2 cellular2x2(vec2 P) {
#define K 0.142857142857 // 1/7
#define K2 0.0714285714285 // K/2
#define jitter 0.8 // jitter 1.0 makes F1 wrong more often
	vec2 Pi = mod289(floor(P));
 	vec2 Pf = fract(P);
	vec4 Pfx = Pf.x + vec4(-0.5, -1.5, -0.5, -1.5);
	vec4 Pfy = Pf.y + vec4(-0.5, -0.5, -1.5, -1.5);
	vec4 p = permute(Pi.x + vec4(0.0, 1.0, 0.0, 1.0));
	p = permute(p + Pi.y + vec4(0.0, 0.0, 1.0, 1.0));
	vec4 ox = mod7(p)*K+K2;
	vec4 oy = mod7(floor(p*K))*K+K2;
	vec4 dx = Pfx + jitter*ox;
	vec4 dy = Pfy + jitter*oy;
	vec4 d = dx * dx + dy * dy; // d11, d12, d21 and d22, squared
	// Sort out the two smallest distances
#if 0
	// Cheat and pick only F1
	d.xy = min(d.xy, d.zw);
	d.x = min(d.x, d.y);
	return vec2(sqrt(d.x)); // F1 duplicated, F2 not computed
#else
	// Do it right and find both F1 and F2
	d.xy = (d.x < d.y) ? d.xy : d.yx; // Swap if smaller
	d.xz = (d.x < d.z) ? d.xz : d.zx;
	d.xw = (d.x < d.w) ? d.xw : d.wx;
	d.y = min(d.y, d.z);
	d.y = min(d.y, d.w);
	return sqrt(d.xy);
#endif
}

/////////////////

void animate(vec2 p, float diff) {
    vec3 c = vec3(0.0); // color

    p *= 1.5;
    // p = tile(p, 2.0);
    
    /*
    p *= 10.0;
    p = repeat(p, vec2(1.5, 0.5));
    */
    
    totalTime(6.0, diff);

    float v; // assume values between 0.0 && 1.0
    if (between(1.0)) {
        v = easeBounceOut(animation.pow);
        p = p + vec2(-0.5 + v, 0.0);
        object.color = mix(BLUE, RED, v);
    }

    if (between(4.0)) {
        v = easeElasticOut(animation.pow);
        p = p + vec2(0.5 * cos(v * 2.0 * PI), 0.5 * sin(v * 2.0 * PI));
        object.color = mix(RED, YELLOW, v);
    }
    
    if (between(1.0)) {
        v = easeBounceOut(animation.pow);
        p = p + vec2(0.5 - v, 0.0);
        object.color = mix(YELLOW, BLUE, v);
    }

    // p *= rotate2d(u_time);
    
    vec2 w = cellular2x2(p / (v * fract(u_time * 0.1))) * 10.0; // fract(u_time)


    object.distance = smoothstep(w.x, w.x * p.y + 0.3, p.y * p.y / w.y);
    object.color.r += object.color.g * p.x * w.y + 0.1;

    // object.distance = circle(p, 0.01 + 0.01 * v);
    // object.distance = rect(p, vec2(0.1));
    // object.distance = polygon(p, 4);
    // object.distance = circle(vec2(length(p)), 2.1);
}

/*
const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

float sceneSDF(vec3 samplePoint) {
    return sphereSDF(samplePoint);
}

float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 rayDirection(float fieldOfView, vec2 p, vec2 size) {
    vec2 xy = p - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}
*/

void main() {
    vec3 color = vec3(0.1);
    
    // color = vec3(p.x, p.y, 1.0);

    animate(st, 0.0);
    color = mix(color, object.color, object.distance); // drawing object on color



    /*
    animate(st * rotate2d(-u_time * 0.1), 0.4);
    color = mix(color, object.color, object.distance); // drawing object on color
    */

/*
    vec3 dir = rayDirection(120.0, gl_FragCoord.xy, u_resolution.xy);
    vec3 eye = vec3(0.0, 0.0, 5.0);
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);

    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
    }
*/

    gl_FragColor = vec4(color, 1.0);
}