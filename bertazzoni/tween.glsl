precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

uniform sampler2D u_texture_0;
uniform sampler2D u_texture_1;
uniform sampler2D u_texture_2;
uniform sampler2D u_texture_3;
uniform sampler2D u_texture_4;
uniform sampler2D u_texture_5;
uniform sampler2D u_texture_6;
uniform sampler2D u_texture_7;

uniform vec2 u_texture_6Resolution;
uniform vec2 u_texture_7Resolution;

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

vec3 draw(in sampler2D t, in vec2 pos, in vec2 w) { vec2 s = w / 1.0; s.x *= -1.0; return texture2D(t, pos / s + 0.5).rgb; }

float circle(vec2 p, float r) {
    r *= rx;    
    return 1.0 - smoothstep(r - rx, r + rx, length(p) * 2.0);
}

vec2 cropCenter(vec2 p, vec2 res) {
    vec2 ratio = u_resolution / res;
    p *= ratio;
    p /= max(ratio.x, ratio.y);
    // p += (max(ratio.x, ratio.y) - min(ratio.x, ratio.y));
    return p;
}

void main() {
    vec2 m = u_resolution / u_mouse;
    vec3 color = vec3(1.0, 1.0, 1.0);
    float powx = clamp(mx.x * 2.0, 0.0, 1.0);
    float powy = m.x - 0.5; // clamp((powx - 0.5) * 2.0, 0.0, 1.0);

    vec2 p = uv * powy;

    vec3 f1 = texture2D(u_texture_1, cropCenter(uv, u_texture_6Resolution)).rgb;    
    vec3 t1 = texture2D(u_texture_6, cropCenter(p, u_texture_6Resolution)).rgb;    
    vec3 t2 = texture2D(u_texture_7, cropCenter(p, u_texture_7Resolution)).rgb;     

    color = mix(t1, t2, powx);
    // color = mix(t1, vec3(1.0), circle(st - mx, 40.0));
    gl_FragColor = vec4(color, 1.0);
}