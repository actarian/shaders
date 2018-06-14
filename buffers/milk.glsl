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

#define st coord(gl_FragCoord.xy)
#define mx coord(u_mouse)
#define rx 1.0 / min(u_resolution.x, u_resolution.y)
#define ts abs(sin(u_time))

#define HEIGHTMAPSCALE 90.0
#define MARCHSTEPS 25
// #define RAYMARCH

// https://www.shadertoy.com/view/Msy3D1

vec3 getRay(in vec2 p, out vec3 pos) {
    float radius = 60.0;
	float theta = - 3.141592653 / 2.0;
    float xoff = radius * cos(theta);
    float zoff = radius * sin(theta);
    pos = vec3(xoff, 20.0, zoff);

    // camera target
    vec3 target = vec3(0.0, 0.0, 0.0);

    // camera frame
    vec3 fo = normalize(target - pos);
    vec3 ri = normalize(vec3(fo.z, 0.0, - fo.x));
    vec3 up = normalize(cross(fo, ri));

    // multiplier to emulate a fov control
    float fov = 0.5;

    // ray direction
    vec3 ray = normalize(fo + fov * p.x * ri + fov * p.y * up);

	return ray;
}

float getMouse() {
    float d = 0.0;
    if (u_mouse.x > 0.0) {
        vec3 ro;
        vec3 rd = getRay(2.0 * u_mouse.xy / u_resolution.xy - 1.0, ro);
        if (rd.y < 0.0) {
            vec3 mp = ro + rd * ro.y / - rd.y;
            vec2 uv = mp.xz / HEIGHTMAPSCALE + 0.5;
            float screenscale = u_resolution.x / 640.0;
            d += 0.02 * smoothstep(20.0 * screenscale, 5.0 * screenscale, length(uv * u_resolution.xy - gl_FragCoord.xy));
        }
    }
    return d;
}

// u_buffer_0

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 diff = vec3(vec2(1.0) / u_resolution.xy, 0.0);
    vec4 center = texture2D(u_buffer_0, uv, 0.0);
    float top = texture2D(u_buffer_0, uv - diff.zy, 0.0).r;
    float left = texture2D(u_buffer_0, uv - diff.xz, 0.0).r;
    float right = texture2D(u_buffer_0, uv + diff.xz, 0.0).r;
    float bottom = texture2D(u_buffer_0, uv + diff.zy, 0.0).r;
    float red = -(center.g - 0.5) * 2.0 + (top + left + right + bottom - 2.0);
    // red += getMouse();
    red += smoothstep(4.5, 0.5, length(u_mouse.xy - gl_FragCoord.xy)); // mouse
    red *= 0.99; // damping
    red *= step(0.1, u_time); // hacky way of clearing the buffer
    red = 0.5 + red * 0.5;
    gl_FragColor = vec4(red, center.r, 0.0, 0.0);
}

/* u_buffer_1

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec3 diff = vec3(vec2(1.0) / u_resolution.xy, 0.0);
    vec4 center = texture2D(u_buffer_0, uv, 0.0);
    float top = texture2D(u_buffer_1, uv - diff.zy, 0.0).r;
    float left = texture2D(u_buffer_1, uv - diff.xz, 0.0).r;
    float right = texture2D(u_buffer_1, uv + diff.xz, 0.0).r;
    float bottom = texture2D(u_buffer_1, uv + diff.zy, 0.0).r;
    float red = -(center.g - 0.5) * 2.0 + (top + left + right + bottom - 2.0);
    // red += getMouse();
    red += smoothstep(4.5, 0.5, length(u_mouse.xy - gl_FragCoord.xy)); // mouse
    red *= 0.99; // damping
    red *= step(0.1, u_time); // hacky way of clearing the buffer
    red = 0.5 + red * 0.5;
    gl_FragColor = vec4(red, center.r, 0.0, 0.0);
}
*/

// main

float h (vec3 p) { return 4.0 * texture2D(u_buffer_0, 0.5 + p.xz / HEIGHTMAPSCALE, 0.0).x; }
float DE (vec3 p) { return 1.2 * (p.y - h(p)); }

void main() {
    vec2 q = gl_FragCoord.xy / u_resolution.xy;
#ifdef RAYMARCH
    float eps = 0.1;
    vec2 qq = q * 2.0 - 1.0;
    vec3 L = normalize(vec3(0.3, 0.5, 1.0));
    // raymarch the milk surface
    vec3 ro;
    vec3 rd = getRay(qq, ro);
    float t = 0.0;
    float d = DE(ro + t * rd);
    for (int i = 0; i < MARCHSTEPS; i++) {
        if (abs(d) < eps) {
            break;
        }
        float dNext = DE(ro + (t + d) * rd);
        // detect surface crossing
        // https://www.shadertoy.com/view/Mdj3W3
		float dNext_over_d = dNext / d;
        if (dNext_over_d < 0.0) {
            // estimate position of crossing
			d /= 1.0 - dNext_over_d;
			dNext = DE(ro + rd * (t + d));
        }
		t += d;
		d = dNext;
    }
    float znear = 95.0;
    float zfar  = 230.0;
    // hit the milk
    if (t < zfar) {
    // if (d < eps) { // just assume always hit, turns out its hard to see error from this
        vec3 p = ro + t * rd;
	    gl_FragColor = vec4(texture2D(u_buffer_0, 0.5 + p.xz / HEIGHTMAPSCALE, 0.0).x);
        // finite difference normal
        float h0 = h(p);
        vec2 dd = vec2(0.01, 0.0);
        vec3 n = normalize(vec3(h0 - h(p + dd.xyy), dd.x, h0 - h(p + dd.yyx)));
        // improvised milk shader, apologies for hacks!
        vec3 R = reflect(rd, n);
        float s = 0.4 * pow(clamp(dot(L, R), 0.0, 1.0), 4000.0);
        float ndotL = clamp(dot(n, L), 0.0, 1.0);
        float dif = 1.42 * (0.8 + 0.2 * ndotL);
        // occlude valleys a little and boost peaks which gives a bit of an SSS look
        float ao = mix(0.8, 0.99, smoothstep(0.0, 1.0, (h0 + 1.5) / 6.0));
        // milk it up
        vec3 difCol = vec3(0.82, 0.82, 0.79);
        gl_FragColor.xyz = difCol * (dif) * ao + vec3(1.0, .79, 0.74) * s;
        // for bonus points, emulate an anisotropic phase function by creaming up the region
        // between lit and unlit
        float creamAmt = smoothstep(0.2, 0.0, abs(ndotL - 0.2));
        gl_FragColor.xyz *= mix(vec3(1.0), vec3(1.0, 0.985, 0.975), creamAmt);
    }
    // fade to background
    vec3 bg = vec3(0.5) + 0.5 * pow(clamp(dot(L, rd), 0.0, 1.0), 20.0);
    bg *= vec2(1.0, 0.97).yxx;
    gl_FragColor.xyz = mix(gl_FragColor.xyz, bg, smoothstep(znear, zfar, t));
	// vignette (borrowed from donfabio's Blue Spiral)
	vec2 uv =  q.xy - 0.5;
	float distSqr = dot(uv, uv);
	gl_FragColor.xyz *= 1.0 - 0.5 * distSqr;
#else
    float c = texture2D(u_buffer_0, q).r;
    vec3 color;
    color = vec3(c);
    // color = vec3(exp(pow(c - 0.25, 2.0) * - 5.0), exp(pow(c - 0.4, 2.0) * - 5.0), exp(pow(c - 0.7, 2.0) * - 20.0));
    gl_FragColor = vec4(color, 1.0);
#endif
}

// i tried to refactor the above into an explicit solve of the wave equation, which is correct
// for spatial sampling and temporal sampling, but the result was plagued with instabilities.
// i guess the stability happens when the wave speed exceeds the maximum rate of propagation of
// information (1 pixel per frame)? (theres a formal definition for this but the name eludes me
// right now)
// UPDATE i think the stabilities are normal for this resolution and time step, and the below
// is probably correct. its all about the CFL condition: https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition
// float hx = HEIGHTMAPSCALE / iResolution.x;
// float hy = HEIGHTMAPSCALE / iResolution.y;