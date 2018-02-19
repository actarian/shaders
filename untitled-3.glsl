precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

/* Shape polygon 2d return float */
#define PI				3.14159265359
#define TWO_PI			6.28318530718

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float plot(vec2 st, float pct) {
  return smoothstep(pct - 0.002, pct, st.y) - smoothstep(pct, pct + 0.002, st.y);
}

float polygon(vec2 p, int sides) {
    p -= 0.5;
    // Angle and radius from the current pixel
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    // Shaping function that modulate the distance
    float d = cos(floor(0.5 + a / r) * r - a) * length(p);
    return 1.0 - smoothstep(0.1, 0.1001, d);
}

float rect(vec2 p, vec2 size){
	size = 0.25 - size * 0.25;
    vec2 uv = step(size, p * (1.0 - p));
	return uv.x * uv.y;
}

float circle(vec2 p, float r) {
    p += 0.0;
    return 1.0 - smoothstep(
        r - (r * 0.01),
        r + (r * 0.01),
        dot(p, p) * 4.0
    );
}

vec2 move(vec2 p, float d) {
    return p + vec2(
        cos(u_time * d) * 0.2, 
        sin(u_time * d) * 0.2
    );
}

// t: current time, b: begInnIng value, c: change In value, d: duration	
float easeInOutQuad(float t, float b, float c, float d) {
    if ((t /= d / 2.0) < 1.0) {
        return c / 2.0 * t * t + b;
    } else {
        return -c / 2.0 * ((--t) * (t - 2.0) - 1.0) + b;
    }
}
float easeInOutQuad(float t) { return easeInOutQuad(t, 0.0, 1.0, 1.0); }
float easeOutBounce(float t) {
    float b = 0.0;
    float c = 1.0; 
    float d = 1.0;
    if ((t /= d) < (1.0/2.75)) {
        return c * (7.5625 * t * t) + b;
    } else if (t < (2.0 / 2.75)) {
        return c * (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75) + b;
    } else if (t < (2.5 / 2.75)) {
        return c * (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375) + b;
    } else {
        return c * (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375) + b;
    }
}

struct Stepper { float time; float pow; };
Stepper step = Stepper(0.0, 0.0);
void totalTime(float t, float d) { step.time = mod(u_time + d, t); }
void totalTime(float t) { totalTime(t, 0.0); }
bool between(float duration) {
    float p = step.time / duration;
    step.pow = p;
    step.time -= duration;
    return (p >= 0.0 && p <= 1.0);
}
float tween(float a, float b, float v) { return a + (b - a) * v; }
vec2 tween(vec2 a, vec2 b, float v) { return a + (b - a) * v; }
vec3 tween(vec3 a, vec3 b, float v) { return a + (b - a) * v; }
vec4 tween(vec4 a, vec4 b, float v) { return a + (b - a) * v; }

vec3 repeat(vec3 p, vec3 r) { return mod(p, r) -0.5 * r; }
vec2 repeat(vec2 p, vec2 r) { return mod(p, r) -0.5 * r; }

vec2 tile(vec2 p, float zoom) {
    p *= zoom;
    return fract(p);
}

vec3 render(vec2 st, vec3 color, float diff) {

    vec3 red = vec3(1.0, 0.0, 0.0);
    vec3 blue = vec3(0.0, 0.0, 1.0);
    vec3 yellow = vec3(1.0, 1.0, 0.0);
    
    float v;
    vec2 p;
    vec3 c = vec3(0.0);

    st *= 1.5;
    // st = tile(st, 4.0);
    
    /*
    st *= 10.0;
    st = repeat(st, vec2(2.0, 2.0));
    */

    totalTime(3.5, diff);
    if (between(1.0)) {
        v = easeInOutQuad(step.pow);
        p = st + vec2(0.5 - v, 0.0);
        c = tween(red, blue, v);
    }

    if (between(1.0)) {
        v = easeOutBounce(step.pow);
        p = st + vec2(-0.5 + v, 0.0);
        c = tween(blue, red, v);
    }

    if (between(0.5)) {
        v = easeInOutQuad(step.pow);
        p = st + vec2(0.5 * cos(v * PI), 0.5 * sin(v * PI));
        c = tween(red, yellow, v);
    }
    
    if (between(1.0)) {
        v = easeOutBounce(step.pow);
        p = st + vec2(-0.5 + v, 0.0);
        c = tween(yellow, red, v);
    }

    return mix(color, c, circle(p, 0.005));
    // return mix(color, c, rect(p, vec2(0.005)));
}

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

void main() {
    vec2 st = getSt();
    vec2 mx = getMx();

    vec3 color = vec3(1.0, 1.0, 1.0); // u_color;
    
    // color = mix(vec3(0.0), color, circle(st + mx, 0.005));

    color = render(st * rotate2d(u_time * 0.1), color, 0.0);
    color = render(st * rotate2d(-u_time * 0.1), color, 0.4);

    gl_FragColor = vec4(color, 1.0);
}