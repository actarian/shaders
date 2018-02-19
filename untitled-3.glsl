precision mediump float;

/***   u n i f o r m s   ***/

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

/***   c o n s t a n t s   ***/

#define st vec2((gl_FragCoord.x / u_resolution.x - 0.5) * -1.0, ((gl_FragCoord.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * 1.0)
#define mx vec2((u_mouse.x / u_resolution.x - 0.5) * 1.0, ((u_mouse.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * -1.0)

#define PI				3.14159265359
#define TWO_PI			6.28318530718

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

/***   e a s i n g s   ***/

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

float tween(float a, float b, float v) { return a + (b - a) * v; }
vec2 tween(vec2 a, vec2 b, float v) { return a + (b - a) * v; }
vec3 tween(vec3 a, vec3 b, float v) { return a + (b - a) * v; }
vec4 tween(vec4 a, vec4 b, float v) { return a + (b - a) * v; }

vec3 repeat(vec3 p, vec3 r) { return mod(p, r) -0.5 * r; }
vec2 repeat(vec2 p, vec2 r) { return mod(p, r) -0.5 * r; }

vec2 tile(vec2 p, float zoom) { p *= zoom; return fract(p); }

void animate(vec2 p, float diff) {
    float v; // assume values between 0.0 && 1.0
    vec3 c = vec3(0.0); // color

    p *= 1.5;
    // p = tile(p, 4.0);
    
    /*
    p *= 10.0;
    p = repeat(p, vec2(2.0, 2.0));
    */

    totalTime(3.5, diff);
    if (between(1.0)) {
        v = easeInOutQuad(animation.pow);
        p = p + vec2(0.5 - v, 0.0);
        object.color = tween(RED, BLUE, v);
    }

    if (between(1.0)) {
        v = easeOutBounce(animation.pow);
        p = p + vec2(-0.5 + v, 0.0);
        object.color = tween(BLUE, RED, v);
    }

    if (between(0.5)) {
        v = easeInOutQuad(animation.pow);
        p = p + vec2(0.5 * cos(v * PI), 0.5 * sin(v * PI));
        object.color = tween(RED, YELLOW, v);
    }
    
    if (between(1.0)) {
        v = easeOutBounce(animation.pow);
        p = p + vec2(-0.5 + v, 0.0);
        object.color = tween(YELLOW, RED, v);
    }

    object.distance = circle(p, 0.005);
    // object.distance = rect(p, vec2(0.005));
}

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 samplePoint) {
    return sphereSDF(samplePoint);
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */
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
            
/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * p: the x,y coordinate of the pixel in the output image
 * size: resolution of the output image
 */
vec3 rayDirection(float fieldOfView, vec2 p, vec2 size) {
    vec2 xy = p - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

void main() {
    vec3 color = vec3(1.0, 1.0, 1.0);
    
    animate(st * rotate2d(u_time * 0.1), 0.0);
    color = mix(color, object.color, object.distance); // drawing object on color

    animate(st * rotate2d(-u_time * 0.1), 0.4);
    color = mix(color, object.color, object.distance); // drawing object on color

    vec3 dir = rayDirection(120.0, gl_FragCoord.xy, u_resolution.xy);
    vec3 eye = vec3(0.0, 0.0, 5.0);
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);

    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
		return;
    }
    
    gl_FragColor = vec4(color, 1.0);
}