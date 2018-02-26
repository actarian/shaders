#ifdef GL_ES
    precision highp float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform float u_mix;
uniform vec2 u_trails[10];
uniform vec2 u_trail_0;

vec2 coord(in vec2 p) {
	p = p / u_resolution.xy;
    // correct aspect ratio
	p.y *= u_resolution.y / u_resolution.x;
	p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    // centering
    p -= 0.5;
    p *= vec2(1.0, -1.0);
	return p;
}
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define px 1.0 / u_resolution.x

float random(float x) { 
    return fract(x * 0.3142536475869708); // fract(sin(x) * 10000.0);          
}

float noise(vec2 p) {
    return random(p.x + p.y * 12345.0); // 10000.0);            
}

vec2 sw(vec2 p) { return vec2(floor(p.x), floor(p.y)); }
vec2 se(vec2 p) { return vec2(ceil(p.x), floor(p.y)); }
vec2 nw(vec2 p) { return vec2(floor(p.x), ceil(p.y)); }
vec2 ne(vec2 p) { return vec2(ceil(p.x), ceil(p.y)); }

float snoise(vec2 p) {
    vec2 interp = smoothstep(0., 1., fract(p));
    float s = mix(noise(sw(p)), noise(se(p)), interp.x);
    float n = mix(noise(nw(p)), noise(ne(p)), interp.x);
    return mix(s, n, interp.y);        
}

float fbm(vec2 p) {
    float x = 0.;
    x += snoise(p);
    // x += snoise(p * 2.0 ) / 1.0;
    x += snoise(p * 4.0 ) / 2.0;
    x += snoise(p * 8.0 ) / 4.0;
    x += snoise(p * 16.0 ) / 8.0;
    // x += snoise(p * 32.0) / 16.0;
    x *= 1.2 / (1.0 + 1.0 / 2.0 + 1.0 / 4.0 + 1.0 / 8.0 + 1.0 / 16.0);
    return x;            
}

float afbm(vec2 p) { 
    float x = fbm(p + u_time * .2);
    float y = fbm(p - u_time * .6);
    return fbm(p + vec2(x, y));       
}

float perlin(vec2 p) {    
    float x = afbm(p);
    float y = afbm(p + 100.);
    return afbm(p + vec2(x, y));
    
}

float circle(vec2 p, float r) {
    return 1.0 - smoothstep(
        r - (r * 0.01),
        r + (r * 0.01),
        dot(p, p) * 4.0
    );
}

float ripple(vec2 p, float r) {
    vec2 dx = st - mx - p;
    float t = u_time * 2.0 + r * 0.02;
	float s = p.x * p.x * (1.0 - dx.x) + p.y * p.y * (1.0 - dx.y);
    s /= px * 10.0;
    float z = sin((t - s) * 4.0);	
    float c = 1.0 - smoothstep(0.0, r * px, length(p) * 2.0);
    return clamp(mix(0.0, z, c), 0.0, 1.0);
}

vec2 getUv() {
	return -1.0 + st * 2.0;
}

void main() {
    
    float r = 0.0;
    for (int i = 0; i < 10; i++) {
        r += 0.8 * ripple(st - coord(u_trails[i]), 40.0 * float(10 - i));
    }

    vec3 c = vec3(0.143,0.752,0.980);
    vec2 uv = gl_FragCoord.xy * 0.0105;
    uv += r;
    float n = perlin(uv + mx * 0.1);
    vec3 c1 = c * c * c * 0.2;
    vec3 c2 = c * 1.8;
    vec3 color = mix(c1, c2, n * n + st.x * 0.4 - st.y * 0.05);

    vec3 g = vec3(0.0, 0.0, 0.5) * 0.1;
    color += g * smoothstep(fract(n), 0.4, 0.44);
    
    // color = mix(color, vec3(0.0, 0.0, 0.0), clamp(ripple(), 0.0, 1.0));

    // color = mix(vec3(1.0, 0.0, 0.0), vec3(1.0), m);
    
    gl_FragColor = vec4(mix(c, color, u_mix), 1.0);
}