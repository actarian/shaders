// Author: Luca Zampetti
// Title: vscode-glsl-canvas Tile examples

precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform vec3 u_color;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

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

vec2 tile(in vec2 p, vec2 w) { return fract(mod(p + w / 2.0, w)) - (w / 2.0); }
vec2 tile(in vec2 p, float w) { return tile(p, vec2(w)); }

float poly(in vec2 p, in float w, in int sides) {
    float a = atan(p.x, p.y) + PI;
    float r = TWO_PI / float(sides);
    float d = cos(floor(0.5 + a / r) * r - a) * length(max(abs(p) * 1.0, 0.0));
    return 1.0 - smoothstep(w / 2.0 - rx, w / 2.0 + rx, d);
}

float rect(in vec2 p, in vec2 w) {
    w /= 2.0;
    float d = length(max(abs(p) -w, 0.0));
    return 1.0 - smoothstep(0.0, 0.0 + rx * 2.0, d);
}

void main() {
    vec3 color = AZUR;
    
    vec2 s = vec2(0.2, 0.2);

    float t = fract(u_time * 0.5);
    float d = 0.0;
    
    d = rect(tile(st + vec2(0.1, 0.0 + t * s.y), s), vec2(0.1));
    color = mix(color, BLACK, d);

    d = poly(tile(st + vec2(-0.1 + t * s.x, 0.01), s), 0.07, 3);
    color = mix(color, WHITE, d);
    
    gl_FragColor = vec4(color, 1.0);
}