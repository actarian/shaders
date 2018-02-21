#ifdef GL_ES
    precision highp float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform float u_mix;

#define st vec2((gl_FragCoord.x / u_resolution.x - 0.5) * 1.0, ((gl_FragCoord.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * -1.0)
#define mx vec2((u_mouse.x / u_resolution.x - 0.5) * 1.0, ((u_mouse.y / u_resolution.y * u_resolution.y / u_resolution.x) + ((u_resolution.x - u_resolution.y) / u_resolution.x / 2.0) - 0.5) * -1.0)
// #define mxy smoothstep(0.01, 0.11, length(mx - st)) + sin(u_time) * 0.1

float ripple() {    	
	float x = (mx.x - st.x);
	float y = (mx.y - st.y);		
	float r = -(x * x + y * y);
	float z = 1.0 + 0.3 * sin((r + u_time * 0.01) / 0.0013);	
	return mix(0.0, z, 0.5 - length(st - mx));
}

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
    p += ripple();
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

float circle(in vec2 p, in float r){
    vec2 t = p - vec2(0.5);
    // t += vec2(cos(u_time * 3.0) * 0.2, sin(u_time * 3.0) * 0.2);
	return 1.0 - smoothstep(
        r - (r * 0.01),
        r + (r * 0.01),
        dot(t, t) * 4.0
    );
}

vec2 getUv() {
	return -1.0 + st * 2.0;
}

void main() {
    vec3 c = vec3(0.143,0.752,0.980);
    
    vec2 uv = gl_FragCoord.xy * 0.0105;
    
    float n = perlin(uv + mx * 0.5);
    vec3 c1 = c * c * c * 0.2;
    vec3 c2 = c * 1.8;
    vec3 color = mix(c1, c2, n * n + st.x * 0.4 - st.y * 0.05);

    vec3 g = vec3(0.0, 0.0, 0.5) * 0.1;
    color += g * smoothstep(fract(n), 0.4, 0.44);
    
    color = mix(color, vec3(0.0, 0.0, 0.0), clamp(ripple(), 0.0, 1.0));

    // color = mix(vec3(1.0, 0.0, 0.0), vec3(1.0), m);
    
    gl_FragColor = vec4(mix(c, color, u_mix), 1.0);
}