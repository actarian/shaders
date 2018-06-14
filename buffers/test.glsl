#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform sampler2D u_buffer_0;
uniform sampler2D u_buffer_1;

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

#define uv gl_FragCoord.xy / u_resolution.xy
#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
#define ts abs(sin(u_time))

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }
float sCircle(in vec2 p, in float w) { return length(p) * 2.0 - w; }

// u_buffer_0

void main() {
    float v = fill(sCircle(st - 0.1 * ts, 0.1));
    gl_FragColor = vec4(v, 0.0, 0.0, 1.0);
}

// u_buffer_1

void main() {
    float v = fill(sCircle(st + 0.1 * ts, 0.1));
    vec3 color = texture2D(u_buffer_0, uv).rgb;
    color = mix(color, vec3(0.0, v, 0.0), v); 
    gl_FragColor = vec4(color, 1.0);
}

// main

void main() {
    vec3 color = texture2D(u_buffer_1, uv).rgb;    
    gl_FragColor = vec4(color, 1.0);
}
