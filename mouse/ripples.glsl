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
    p *= vec2(-1.0, 1.0);
	return p;
}
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define px 1.0 / u_resolution.x

float ripple(vec2 p, float r) {
    vec2 dx = st - mx - p;
    float t = u_time * 2.0 + r * 0.02;
	float s = p.x * p.x * (1.0 - dx.x) + p.y * p.y * (1.0 - dx.y);
    s /= px * 10.0;
    float z = sin((t - s) * 4.0);	
    float c = 1.0 - smoothstep(0.0, r * px, length(p) * 2.0);
    return clamp(mix(0.0, z, c), 0.0, 1.0);
}

void main() {
    vec3 color = vec3(0.04);
    vec3 colorB = vec3(0.7);
    float radius = 50.0;
    for (int i = 0; i < 10; i++) {
        float pow = ripple(st - coord(u_trails[i]), radius * float(10 - i));
        color = mix(color, colorB, pow);
    }
    gl_FragColor = vec4(color, 1.0);
}