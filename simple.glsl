// Author:
// Title:

#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform float u_strength;

float plot(vec2 st, float pct){
  return smoothstep(pct - 0.002, pct, st.y) - smoothstep(pct, pct + 0.002, st.y);
}

/* Shape polygon 2d return float */
#define PI				3.14159265359
#define TWO_PI			6.28318530718

float polygon(vec2 p, int sides) {
    p -= 0.5;
    p *= 30.0;
    // Angle and radius from the current pixel
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);

    // Shaping function that modulate the distance
    float d = cos(floor(0.5 + a / r) * r - a) * length(p);
    return smoothstep(0.6, 0.61, d);
}

float circle(in vec2 p, in float r){
    vec2 t = p - vec2(0.5);
    t += vec2(cos(u_time * 3.0) * 0.2, sin(u_time * 3.0) * 0.2);
	return 1.0 - smoothstep(
        r - (r * 0.01),
        r + (r * 0.01),
        dot(t, t) * 4.0
    );
}

vec2 getSt() {
	vec2 st = gl_FragCoord.xy / u_resolution.xy;
	st.y *= u_resolution.y / u_resolution.x;
	st.y += (u_resolution.x - u_resolution.y) / u_resolution.x / 2.0;
	return st;
}
vec2 getUv(vec2 st) {
	vec2 uv = -1.0 + st * 2.0;
	return uv;
}
vec2 getMx() {
	return -1.0 + u_mouse / u_resolution.xy * 2.0;
}

void main() {
    vec2 st = getSt();
    vec2 mx = getMx();

    vec3 color = vec3(
        abs(cos((st.x + u_time * 0.123) * mx.x)), 
        abs(sin((st.y + u_time * 0.456) * mx.y)), 
        abs(sin(u_time))
    );

    float f = circle(st, 0.01);

    color -= f;

    f = plot(st, st.x);

    color -= f;

    color += polygon(st, 3);

    gl_FragColor = vec4(color, 1.0);
}