precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

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

float circle(vec2 p, float r) {
    r *= px;
    return 1.0 - smoothstep(r - px, r + px, length(p) * 2.0);
}

float stroke(float f, float t) {
    float e = 0.5;
    float d = step(e, f + t * 0.5) - step(e, f - t * 0.5);
    return clamp(d, 0.0, 1.0);
}

void main() {
    vec3 color = vec3(1.0, 1.0, 1.0);
    color = mix(vec3(0.0), color, circle(st - mx, 40.0));
    gl_FragColor = vec4(color, 1.0);
}