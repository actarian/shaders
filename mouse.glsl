precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float circle(vec2 p, float r) {
    p += 0.0;
    return 1.0 - smoothstep(
        r - (r * 0.01),
        r + (r * 0.01),
        dot(p, p) * 4.0
    );
}

vec2 getSt() {
	vec2 st = gl_FragCoord.xy / u_resolution.xy;
    // correct aspect ratio
	st.y *= u_resolution.y / u_resolution.x;
	st.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
    // centering
    st -= 0.5;
    st *= vec2(1.0, -1.0);
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
    vec3 color = vec3(1.0, 1.0, 1.0);
    color = mix(vec3(0.0), color, circle(st - mx, 0.005));
    gl_FragColor = vec4(color, 1.0);
}