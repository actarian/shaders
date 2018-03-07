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
    // correct aspect ratio
    if (u_resolution.x > u_resolution.y) {
        p.x *= u_resolution.x / u_resolution.y;
        p.x += (u_resolution.y - u_resolution.x) / u_resolution.y / 2.0;
    } else {
        p.y *= u_resolution.y / u_resolution.x;
	    p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    }
    // centering
    p -= 0.5;
    p *= vec2(-1.0, 1.0);
	return p;
}
vec2 getuv(in vec2 p) {
	p = p / u_resolution.xy;
	return p;
}
#define st coord(gl_FragCoord.xy)
#define uv getuv(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
vec2 pos(in float x, in float y) { return st + vec2(x * rx, y * rx); }
vec2 pos(in float x) { return pos(x, x); }
vec2 pos(in vec2 p) { return pos(p.x, p.y); }

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

/***   t i l i n g   ***/
vec2 tile(in vec2 p, vec2 size) { return fract(mod(p + size / 2.0, size)) - (size / 2.0); }
vec2 tile(in vec2 p, float size) { return tile(p, vec2(size)); }
vec3 repeat(in vec3 p, in vec3 r) { return mod(p, r) -0.5 * r; }
vec2 repeat(in vec2 p, in vec2 r) { return mod(p, r) -0.5 * r; }

/***   e a s i n g s   ***/
/* Easing Bounce Out equation */
/* Adapted from Robert Penner easing equations */
float easeBounceOut(in float t) {
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
float easeElasticOut(in float t) {
    if (t == 0.0) { return 0.0; }
    if (t == 1.0) { return 1.0; }
    float p = 0.3;
    float a = 1.0; 
    float s = p / 4.0;
    return (a * pow(2.0, -10.0 * t) * sin((t - s) * TWO_PI / p) + 1.0);
}

/***   s h a p e s   ***/

float line(in vec2 a, in vec2 b, float size) {
    vec2 ba = a - b;
    float f = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    f = length(a - ba * f);
    return smoothstep(size * rx + rx, size * rx - rx, f);
}

float circle(in vec2 p, in float size) {
    float d = length(p) * 2.0;
    return 1.0 - smoothstep(size * rx - rx, size * rx + rx, d);
}
float circle(in vec2 p, in float size, float t) {
    float d = length(abs(p)) - size * rx / 2.0;
    return 1.0 - smoothstep(t * rx - rx, t * rx + rx, abs(d));
}

float rect(in vec2 p, in vec2 size) {
    size *= rx; size /= 2.0;
    float d = length(max(abs(p) -size, 0.0));
    return 1.0 - smoothstep(0.0, 0.0 + rx * 2.0, d);
}
float rect(in vec2 p, in vec2 size, in float t) {
    size *= rx; size /= 2.0; float t2 = t * rx / 2.0;
    float d = length(max(abs(p), size - t * rx) - size + t * rx) - t * rx * 2.0;
    return 1.0 - smoothstep(t * rx - rx, t * rx + rx, abs(d));
}

float roundrect(in vec2 p, in vec2 size, in float radius) {
    radius *= rx * 2.0; size *= rx; size /= 2.0;
    float d = length(max(abs(p) -size + radius, 0.0)) - radius;
    return 1.0 - smoothstep(0.0, 0.0 + rx * 2.0, d);
}
float roundrect(in vec2 p, in vec2 size, in float radius, in float t) {
    radius *= rx * 2.0; size *= rx; size /= 2.0; size -= radius;
    float d = length(max(abs(p), size) - size) - radius;
    return 1.0 - smoothstep(t * rx - rx, t * rx + rx, abs(d));
}

float polygon(in vec2 p, in float size, in int sides) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return 1.0 - smoothstep(size * rx / 2.0 - rx, size * rx / 2.0 + rx, d);
}

float polygon(in vec2 p, in float size, in int sides, in float t) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0)) - size * rx / 2.0;
    return 1.0 - smoothstep(t * rx - rx, t * rx + rx, abs(d));
}

float plot(in vec2 p, in float t, in float a) {
    p *= rotate2d(a);
    return 1.0 - smoothstep(t / 2.0 * rx - rx, t / 2.0 * rx + rx, abs(p.x));
}
float plot(in vec2 p, in float t) { return plot (p, t, 0.0); }
float plot(in vec2 p) { return plot (p, 1.0, 0.0); }

/////////////////

float rect_(vec2 p, vec2 size) {
    size *= rx; size /= -2.0;
    vec2 bl = smoothstep(vec2(size - 0.001), vec2(size), p);
    vec2 tr = smoothstep(vec2(size + 1.0), vec2(size + 1.0 + 0.001), 1.0 - p);
    return bl.x * bl.y * tr.x * tr.y;
}

float _line(vec2 a, vec2 b, vec2 p, float size) {
    vec2 ba = b - a;
    vec2 perp = vec2(ba.y, -ba.x);
    vec2 dir = a - p;
    float f = abs(dot(normalize(perp), dir));
    return smoothstep(size * rx + rx, size * rx - rx, f);
}

float __line(vec2 p1, vec2 p2, vec2 p, float size) {
    float a = p1.y - p2.y;
    float b = p2.x - p1.x;
    float f = abs(a * p.x + b * p.y + p1.x * p2.y - p2.x * p1.y) / sqrt(a * a + b * b);
    return smoothstep(size * rx + rx, size * rx - rx, f);
}

float ___liner(vec2 a, vec2 b, float t) {
    vec2 p = (b + a) / 2.0;
    float angle = PI_TWO - atan(b.x - a.x, a.y - b.y);
    vec2 size = vec2(distance(a, b) * u_resolution.x, t);
    p *= rotate2d(angle);
    return rect(p, size);
}

float grid(in float size) {
    size *= rx;
    float f = 0.0;
    f += plot(tile(st, size), 1.0);
    f += plot(tile(st, size), 1.0, PI_TWO);
    f *= 0.1;
    vec2 p = tile(st, vec2(size * 5.0, size * 5.0));
    float s = size / 10.0;
    float g = 0.0;
    g += line(p + vec2(-s, 0.0), p + vec2(s, 0.0), 1.0);
    g += line(p + vec2(0.0, -s), p + vec2(0.0, s), 1.0);
    return f + g;
}

void animate(in float diff) {
    vec3 c = vec3(0.0);

    vec2 p = st;
    
    // p *= rotate2d(u_time);

    float r = 250.0 * rx;

    totalTime(10.0, diff);

    float v; // assume values between 0.0 && 1.0
    if (between(2.0)) {
        v = easeBounceOut(animation.pow);
        p += vec2(mix(-r, r, v), 0.0);
        object.color = mix(YELLOW, WHITE, v);
        object.distance = circle(p, 50.0, 2.0);
    }

    if (between(6.0)) {
        v = easeElasticOut(animation.pow);
        p = p + vec2(r * cos(v * 2.0 * PI), r * sin(v * 2.0 * PI));
        object.color = mix(WHITE, GREEN, v);
        object.distance = roundrect(p, vec2(50.0), 5.0, 2.0);
    }
    
    if (between(2.0)) {
        v = easeBounceOut(animation.pow);
        p += vec2(mix(r, -r, v), 0.0);
        object.color = mix(GREEN, YELLOW, v);
        object.distance = polygon(p, 50.0, 4, 2.0);
    }

    // object.distance = smoothstep(0.9 - rx, 0.9 + rx, object.distance);
    // object.distance = circle(p, 30.0 + 20.0 * v);
}

void main() {
    vec3 color = BLACK;
    
    color = mix(color, GREEN, grid(50.0));

    animate(0.0);

    color = mix(color, 
        object.color, object.distance
    );

    color = mix(color, 
        MAGENTA, roundrect((pos(-125.0, -125.0)) * rotate2d(-u_time), vec2(100.0, 100.0), 10.0)
    );

    color = mix(color, 
        MAGENTA, roundrect((pos(125.0, -125.0)) * rotate2d(u_time), vec2(100.0, 100.0), 10.0, 1.0)
    );

    color = mix(color, 
        MAGENTA, circle(pos(-125.0, 125.0), 30.0)
    );

    color = mix(color, 
        MAGENTA, circle(pos(125.0, 125.0), 30.0, 1.0)
    );
  
    color = mix(color, 
        MAGENTA, rect(pos(-125.0, 225.0), 
        vec2(90.0 + sin(u_time) * 60.0, 90.0 + cos(u_time) * 60.0))
    );

    color = mix(color, 
        MAGENTA, rect(pos(125.0, 225.0), 
        vec2(90.0 + cos(u_time) * 60.0, 90.0 + sin(u_time) * 60.0), 1.0)
    );

    color = mix(color, 
        YELLOW, polygon(pos(-125.0, -225.0), 30.0, 3)
    );

    color = mix(color, 
        YELLOW, polygon(pos(125.0, -225.0), 30.0, 3, 4.0)
    );

    color = mix(color, 
        YELLOW, line(pos(50.0 * cos(u_time), 0.0), pos(150.0 * sin(u_time), 150.0), 5.0)
    );

    color = mix(color, 
        YELLOW, line(pos(-50.0 * cos(u_time), 0.0), pos(-150.0 * sin(u_time), 150.0), 5.0)
    );

    /*
    vec2 a = pos(50.0, 0.0) * vec2(cos(st.x + u_time), sin(st.y + u_time));
    vec2 b = pos(150.0, 150.0) * vec2(sin(st.x * u_time), cos(st.y - u_time));
    color = mix(color, 
        BLUE, line(a, b, 3.0)
    );
    */


    vec4 tx = texture2D(u_texture_0, uv);

    color = mix(color, tx.rgb, 
        rect(st, vec2(100.0))
    );


    float c = 0.0; // cos(u_time * 60.0) * 0.05;

    gl_FragColor = vec4(color + c * length(st), 1.0);
}