precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform vec2 u_trails[10];

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

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

float ripple(vec2 p, float r) {
    vec2 dx = st - mx - p;
    float t = u_time * 0.5;
	float s = p.x * p.x * (1.0 - dx.x) + p.y * p.y * (1.0 - dx.y);
    s /= px * 20.0;
    float z = sin((t - s) * r * 0.05);	
    float c = 1.0 - smoothstep(0.0, r * px, length(p) * 2.0);
    return mix(0.0, z, c);
}

void main() {
    vec3 color = vec3(0.04);
    for (int i = 0; i < 10; i++) {
        float d;        
        d = ripple(st - coord(u_trails[i]), 40.0 * float(10 - i));
        vec3 c = vec3(0.7);
        color = mix(color, c, d);
    }
    gl_FragColor = vec4(color, 1.0);
}