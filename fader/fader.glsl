precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 coord(in vec2 p) {
	p = p / u_resolution.xy;
    if (u_resolution.x > u_resolution.y) {
        p.x *= u_resolution.x / u_resolution.y;
        p.x += (u_resolution.y - u_resolution.x) / u_resolution.y / 2.0;
    } else {
        p.y *= u_resolution.y / u_resolution.x;
	    p.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    }
    p -= 0.5;
    p *= vec2(-1.0, 1.0);
	return p;
}
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
#define uv gl_FragCoord.xy / u_resolution.xy
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)

uniform sampler2D u_texture_4;
uniform sampler2D u_texture_5;

void main() {
    vec3 color = vec3(1.0);
    float v = fract(u_time * 0.3);
    float r = (1.0 - texture2D(u_texture_5, uv).r);
    r = 1.0 - smoothstep(v, v + 0.1, r);
    r = clamp(r, 0.0, 1.0);
    color = mix(color, texture2D(u_texture_4, uv).rgb, r);
    gl_FragColor = vec4(color, 1.0);
}