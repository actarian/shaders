// Author: Luca Zampetti
// Title: vscode-glsl-canvas Buffers examples

precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_buffer0;
uniform sampler2D u_buffer1;
uniform sampler2D u_texture_0;

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

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }

float sCircle(in vec2 p, in float w) {
    return length(p) * 2.0 - w;
}
float circle(in vec2 p, in float w) {
    float d = sCircle(p, w);
    return fill(d);
}
float circle(in vec2 p, in float w, float t) {
    float d = sCircle(p, w);
    return stroke(d, t);
}

#if defined(BUFFER_0)

void main() {
    vec3 color = vec3(
        0.5 + cos(u_time) * 0.5,
        0.5 + sin(u_time) * 0.5,
        1.0
    );
    vec3 buffer = texture2D(u_buffer1, uv, 0.0).rgb;
    buffer *= 0.99;

    vec2 p = vec2(
        st.x + cos(u_time * 5.0) * 0.3, 
        st.y + sin(u_time * 2.0) * 0.3
    );
    float c = circle(p, 0.2 + 0.1 * sin(u_time));

    buffer = mix(buffer, color, c * 1.0);

    gl_FragColor = vec4(buffer, 1.0);
}

#elif defined(BUFFER_1)

void main() {
    vec3 color = vec3(
        0.5 + cos(u_time) * 0.5,
        0.5 + sin(u_time) * 0.5,
        1.0
    );
    vec3 buffer = texture2D(u_buffer0, uv, 0.0).rgb;
    buffer *= 0.99;

    vec2 p = vec2(
        st.x + sin(u_time * 2.0) * 0.3, 
        st.y + cos(u_time * 6.0) * 0.3
    );
    float c = circle(p, 0.2 + 0.1 * cos(u_time));

    buffer = mix(buffer, color, c * 1.0);
    
    gl_FragColor = vec4(buffer, 1.0);
}

#else

void main() {
    vec3 color = BLACK;
    
    // vec3 b0 = texture2D(u_buffer0, uv).rgb;
    vec3 b1 = texture2D(u_buffer1, uv).rgb;

    // color += b0;
    color += b1;

    gl_FragColor = vec4(color, 1.0);
}

#endif
