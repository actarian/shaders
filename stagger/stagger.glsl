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

#define RED             vec3(1.0, 0.0, 0.0)
#define BLUE            vec3(0.0, 0.0, 1.0)
#define YELLOW          vec3(1.0, 1.0, 0.0)

vec2 coord(in vec2 p) {
	p = p / u_resolution.xy;
    // correct aspect ratio
	p.y *= u_resolution.y / u_resolution.x;
	p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    // centering
    p -= 0.5;
    p *= vec2(-1.0, 1.0);
	return p;
}
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define px 1.0 / u_resolution.x

/***   m a t h   ***/

mat2 rotate2d(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
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

// vec2 tile(vec2 p, float zoom) { p *= zoom; return fract(p); }

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


/***   s h a p e s   ***/

float plot(vec2 p, float t, float a) {
    t *= px / 2.0;
    p *= rotate2d(a);
    float f = smoothstep(-t - px, -t, p.x) - smoothstep(t, t + px, p.x);
    /*
    float size = 200.0 * px;
    f *= (1.0 - smoothstep(size - px, size + px, length(p) * 2.0));
    */
    return f;
}
float plot(vec2 p, float t) { return plot (p, t, 0.0); }
float plot(vec2 p) { return plot (p, 1.0, 0.0); }

float polygon(vec2 p, float size, int sides) {
    size *= px;
    // Angle and radius from the current pixel
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    // Shaping function that modulate the distance
    float d = cos(floor(0.5 + a / r) * r - a) * length(p);
    return 1.0 - smoothstep(size - px, size + px, d * 2.0);
}

float circle(vec2 p, float size) {
    size *= px;
    return 1.0 - smoothstep(size - px, size + px, length(p) * 2.0);
}

float rect(vec2 p, vec2 size) {
    size *= px;
    size /= -2.0;
    vec2 bl = smoothstep(vec2(size - 0.001), vec2(size), p);
    vec2 tr = smoothstep(vec2(size + 1.0), vec2(size + 1.0 + 0.001), 1.0 - p);
    return bl.x * bl.y * tr.x * tr.y;
}

vec2 move(vec2 p, float d) {
    return p + vec2(
        cos(u_time * d) * 0.2, 
        sin(u_time * d) * 0.2
    );
}

/////////////////

void animate(vec2 p, float diff) {
    vec3 c = vec3(0.0); // color

    // p = tile(p, 2.0);
    
    /*
    p *= 10.0;
    p = repeat(p, vec2(1.5, 0.5));
    */
    
    // p *= rotate2d(u_time);

    float r = 0.3; // 100.0 * px; // 0.5;

    totalTime(6.0, diff);

    float v; // assume values between 0.0 && 1.0
    if (between(1.0)) {
        v = easeBounceOut(animation.pow);
        p += vec2(mix(-r, r, v), 0.0);
        object.color = mix(BLUE, RED, v);
        object.distance = circle(p, 30.0);
    }

    if (between(4.0)) {
        v = easeElasticOut(animation.pow);
        p = p + vec2(r * cos(v * 2.0 * PI), r * sin(v * 2.0 * PI));
        object.color = mix(RED, YELLOW, v);
        object.distance = rect(p, vec2(30.0));
    }
    
    if (between(1.0)) {
        v = easeBounceOut(animation.pow);
        p += vec2(mix(r, -r, v), 0.0);
        object.color = mix(YELLOW, BLUE, v);
        object.distance = polygon(p, 30.0, 5);
    }

    // object.distance = circle(p, 30.0 + 20.0 * v);
}

float _line(vec2 a, vec2 b, vec2 p) {
    vec2 ba = b - a;
    vec2 perp = vec2(ba.y, -ba.x);
    vec2 dir = a - p;
    float f = abs(dot(normalize(perp), dir));
    return smoothstep(f - px, f + px, px * 2.0);
}

float __line(vec2 p1, vec2 p2, vec2 p) {
    float a = p1.y - p2.y;
    float b = p2.x - p1.x;
    float f = abs(a * p.x + b * p.y + p1.x * p2.y - p2.x * p1.y) / sqrt(a * a + b * b);
    return smoothstep(f - px, f + px, 0.1);
}

float __line(vec2 a, vec2 b) {
	vec2 ba = b - a;
	float h = clamp(dot(ba, a) / dot(ba, ba), 0.0, 1.0);
	vec2 v = a + (ba * -h);
    float f = dot(v, v);
    float size = 1.0;
    return smoothstep(size + px, size - px, f * 10000.0);
}

float liner(vec2 a, vec2 b, float t) {
    vec2 p = (b + a) / 2.0;
    float angle = PI_TWO - atan(b.x - a.x, a.y - b.y);
    vec2 size = vec2(distance(a, b) * u_resolution.x, t);
    p *= rotate2d(angle);
    return rect(p, size);
}

float line(in vec2 a, in vec2 b, float size) {
    vec2 ba = a - b;
    float f = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    f = length(a - ba * f);
    // f = clamp(((1.0 - f) - 0.99) * 100.0, 0.0, 1.0);
    // return 1.0 - f;
    return smoothstep(size * px + px, size * px - px, f);
}

vec2 tile(in vec2 p, float size) {
    // Here is where the offset is happening
    p += (size / 2.0);
    p = mod(p, size);
    return fract(p) - (size / 2.0);
}

float grid(inout vec3 color) {
    float f = 0.0;
    f += plot(mod(st, 0.1));
    f += plot(mod(st, 0.1), 1.0, PI_TWO);

    color = mix(color, vec3(0.0, 1.0, 0.5), f * 0.1);

    float g = 0.0;
    vec2 p = tile(st, 0.5);
    g += line(p + vec2(-0.025, 0.0), p + vec2(0.025, 0.0), 1.0);
    g += line(p + vec2(0.0, -0.025), p + vec2(0.0, 0.025), 1.0);

    color = mix(color, vec3(0.0, 1.0, 0.5), g);
    return f + g;
}

void main() {
    vec3 color = vec3(0.1);
    // color = vec3(p.x, p.y, 1.0);

    animate(st, 0.0);
    color = mix(color, object.color, object.distance); // drawing object on color

    grid(color);

    color = mix(color, vec3(0.0, 0.0, 1.0), line(
        st + vec2(0.1, 0.0), 
        st + vec2(-0.2, 0.3),
        1.0
    )); // drawing object on color

    color = mix(color, vec3(1.0, 0.0, 1.0), rect(
        st + vec2(0.4, 0.4), 
        st + vec2(20.0, 20.0) 
    )); // drawing object on color
    
    color = mix(color, vec3(1.0, 1.0, 0.0), liner(
        st + vec2(0.0, -0.0), 
        st + vec2(0.3, 0.3),
        2.0
    )); // drawing object on color
    
    gl_FragColor = vec4(color, 1.0);
}