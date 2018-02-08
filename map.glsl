// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by L.Zampetti (C) 2018 

#extension GL_OES_standard_derivatives : enable

#ifdef GL_ES
	precision mediump float;
#endif

// ##################
// ###  Uniforms  ###
// ##################

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_texture_0;
uniform sampler2D u_texture_1;
	
#define PI				3.14159265359
#define TWO_PI			6.28318530718
#define RAD				0.01745329251
#define EPSILON			0.001

const int OCCLUSION_STEPS   = 4;
const int RAYMARCH_STEPS    = 128;	
const float CAMERA_FOV      = 0.30;
const float CAMERA_NEAR     = 0.05;
const float CAMERA_FAR      = 40.0;

vec2 st;
vec2 uv;
vec2 vp;
vec2 mx;
vec2 pixel;
vec4 point;
mat4 matrix;

// COLORS
vec3 white = 	vec3(1.0, 1.0, 1.0);
vec3 red = 		vec3(1.0, 0.0, 0.0);
vec3 green = 	vec3(0.0, 1.0, 0.0);
vec3 blue = 	vec3(0.0, 0.0, 1.0);
vec3 yellow = 	vec3(1.0, 1.0, 0.0);
vec3 magenta = 	vec3(1.0, 0.0, 1.0);
vec3 cyan = 	vec3(0.0, 1.0, 1.0);

// ##################
// ###  MATERIAL  ###
// ##################

struct Material {
	vec3 color;
	float ambient; 
	float glossiness;
	float shininess;
};
Material getMaterial(int m) {
	Material material = Material(
		vec3(1.0, 0.3, 0.3), // color
		0.2, // ambient,
		0.9, // glossiness
		0.2 // shininess
	);
	return material;
}

// ##############
// ###  MATH  ###
// ##############

const mat4 projection = mat4(
	vec4(3.0 / 4.0, 0.0, 0.0, 0.0),
	vec4(     0.0, 1.0, 0.0, 0.0),
	vec4(     0.0, 0.0, 0.5, 0.5),
	vec4(     0.0, 0.0, 0.0, 1.0)
);
mat4 scale = mat4(
	vec4(4.0 / 3.0, 0.0, 0.0, 0.0),
	vec4(     0.0, 1.0, 0.0, 0.0),
	vec4(     0.0, 0.0, 1.0, 0.0),
	vec4(     0.0, 0.0, 0.0, 1.0)
);
mat4 rotation = mat4(
	vec4(1.0,          0.0,         0.0, 	0.0),
	vec4(0.0,  cos(u_time), sin(u_time),  	0.0),
	vec4(0.0, -sin(u_time), cos(u_time),  	0.0),
	vec4(0.0,          0.0,         0.0, 	1.0)
);
mat4 rotationAxis(float angle, vec3 axis) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}
vec2 toScreen(vec4 p) {
	vec4 screen = projection * scale * p;
	float perspective = screen.z * 0.5 + 1.0;
    screen /= perspective;
	return screen.xy;
}
vec3 rotateX(vec3 p, float angle) {
	mat4 rmy = rotationAxis(angle, vec3(1.0, 0.0, 0.0));
	return (vec4(p, 1.0) * rmy).xyz;
}
vec3 rotateY_(vec3 p, float angle) {
	mat4 rmy = rotationAxis(angle, vec3(0.0, 1.0, 0.0));
	return (vec4(p, 1.0) * rmy).xyz;
}
vec3 rotateZ(vec3 p, float angle) {
	mat4 rmy = rotationAxis(angle, vec3(0.0, 0.0, 1.0));
	return (vec4(p, 1.0) * rmy).xyz;
}
vec3 rotateY(vec3 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    mat4 r = mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
	return (vec4(p, 1.0) * r).xyz;
}

// ##############
// ###  VARS  ###
// ##############

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
vec4 getNormal() {
	return vec4(normalize( cross( dFdx( point.xyz ), dFdy( point.xyz ) ) ), 1.0);
}
void setVars() {
	st = getSt();
	uv = getUv(st);
	mx = getMx();

    vec2 p01 = gl_FragCoord.xy / u_resolution.xy;
    float 	r = .8, 
            s = p01.y * 1.0 * TWO_PI, 
            t = p01.x * 1.0 * PI;
    point = vec4(
        r * cos(s) * sin(t),
        r * sin(s) * sin(t),
        r * cos(t),
        1.0
    );

    // matrix = rotationAxis(RAD * 360.0 * u_time * .02, vec3(1.0, 1.0, 1.0));
    // point *= matrix;

	// pixel = vec2(1.0) / u_resolution * 100.0;

	pixel = vec2(0.003);
}

// ################
// ###  NOISES  ###
// ################

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 random3(vec3 p) {
	float j = 4096.0 * sin(dot(p, vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0 * j);
	j *= .125;
	r.x = fract(512.0 * j);
	j *= .125;
	r.y = fract(512.0 * j);
	return r - 0.5;
}

float fmod(float a, float b) {
    float m=a-floor((a+0.5)/b)*b;
    return floor(m+0.5);
}

float noiset(vec3 p) {
    
    vec3 t = p * 0.04;

	t = vec3(
		mod(t.x, 1.0), 
		mod(t.y, 1.0), 
		mod(t.z, 1.0)
	);

	float size = 10.0;

	t.z = fract(t.z) * size;

    float floorz = floor(t.z);
    
    vec2 offset_a = vec2(1.0) * (floorz) / size;
    vec2 offset_b = vec2(1.0) * (floorz + 1.0) / size;
    
    float a = texture2D(u_texture_0, t.xy + offset_a, -1000.0).r;
    float b = texture2D(u_texture_0, t.xy + offset_b, -1000.0).r;
    float fractz = fract(t.z);

    return mix(a, b, fractz);    
}

vec3 filtering(vec2 uv) {
	float size = 64.0;
	uv = uv * size + 0.5;
	vec2 iuv = floor(uv);
	vec2 fuv = fract(uv);
	uv = iuv + fuv * fuv * (3.0 - 2.0 * fuv); // fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);;
	uv = (uv - 0.5) / size;
	return texture2D(u_texture_0, uv, -1000.0).xyz;
}

float noiset2d(vec2 p) {    
	float z = random(p);

    vec3 t = vec3(p.x, p.y, z) * 3.0;
	
	vec2 dxy = vec2(cos(u_time) * 0.05, sin(u_time) * 0.05);
    vec2 offset_a = (vec2(0.216487, 0.446545) + dxy) * (t.x);
    vec2 offset_b = (vec2(0.897544, 0.398715) + dxy) * (t.y + 1.0);
    
    vec3 ta = vec3(
		mod(t.z + offset_a.x, 1.0), 
		mod(t.y + offset_a.y, 1.0), 
		mod(t.x, 1.0)
	);
	
    vec3 tb = vec3(
		mod(t.z + offset_b.x, 1.0), 
		mod(t.x + offset_b.y, 1.0), 
		mod(t.y, 1.0)
	);
	
    float a = filtering(ta.xy).r;
    float b = filtering(tb.xy).r;

    return mix(a * 0.2, b * 0.2, t.z);
}

float perlinNoiseT(vec3 p) {
    float x = 0.0;
    for (float i = 0.0; i < 6.0; i += 1.0)
        x += noiset(p * pow(2.0, i)) * pow(0.5, i);
    return x;
}

float noiset1(in vec3 p) {
	vec3 t = p * 0.04;

	t = vec3(mod(t.x, 1.0), mod(t.y, 1.0), mod(t.z, 1.0));

    vec3 f = fract(t);
	f = f * f * f;

	vec4 rgb = texture2D(u_texture_0, t.xy);
	return mix(rgb.x, rgb.y, rgb.z); // (rgb.x + rgb.y + rgb.z) / 3.0);

	/*
    vec3 d = floor(p);
	vec2 uv = (d.xy + vec2(37.0, 17.0) * d.z) + f.xy;
	vec2 rg = texture2D(u_texture_0, (uv + 0.5) / 256.0, 0.0).yx;
	return mix(rg.x, rg.y, f.z);
	*/
}

float fbmt(in vec3 p) {
	mat3 m = mat3(
		 0.00,  0.80,  0.60,
		-0.80,  0.36, -0.48,
		-0.60, -0.48,  0.64
	);
	float f;
	f  = 0.5000 * noiset(p); p = m * p * 2.02;
	f += 0.2500 * noiset(p); p = m * p * 2.03;
	f += 0.1250 * noiset(p); //p = m * p * 2.01;
	//f += 0.0625 * noise(p);
	return f;
	/*
    float rz = 0.0;
    float a = 0.35;
    for (int i = 0; i < 2; i++) {
        rz += noiset(p) * a;
        a *= 0.35;
        p *= 4.0;
    }
    return rz;
	*/
}

float mapt(vec3 p) {
    return p.y * 0.07 + (fbmt(p * 0.3) - 0.1) + sin(p.x * 0.24 + sin(p.z * .01) * 7.) * 0.22 + 0.15 + sin(p.z * 0.08) * 0.05;
}

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float noise(in vec3 p) {
	vec3 f = floor(p);
	vec3 r = fract(p);
	r = r * r * (3.0 - 2.0 * r);
	float n = f.x + f.y * 57.0 + 113.0 * f.z;
	float res = mix(mix(mix(hash(n + 0.0),   hash(n + 1.0), r.x),
						mix(hash(n + 57.0),  hash(n + 58.0), r.x), r.y),
					mix(mix(hash(n + 113.0), hash(n + 114.0), r.x),
						mix(hash(n + 170.0), hash(n + 171.0), r.x), r.y), r.z);
	return res;
}

float fbm(vec3 p) {
	mat3 m = mat3(
		 0.00,  0.80,  0.60,
		-0.80,  0.36, -0.48,
		-0.60, -0.48,  0.64
	);
	float f;
	f  = 0.5000 * noise(p); p = m * p * 2.02;
	f += 0.2500 * noise(p); p = m * p * 2.03;
	f += 0.1250 * noise(p); //p = m * p * 2.01;
	//f += 0.0625 * noise(p);
	return f;
}

float snoise(vec3 p) {
    float F3 =  0.3333333;
    float G3 =  0.1666667;
	vec3 s = floor(p + dot(p, vec3(F3)));
	vec3 x = p - s + dot(s, vec3(G3));	 
	vec3 e = step(vec3(0.0), x - x.yzx);
	vec3 i1 = e*(1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy*(1.0 - e);	 	
	vec3 x1 = x - i1 + G3;
	vec3 x2 = x - i2 + 2.0*G3;
	vec3 x3 = x - 1.0 + 3.0*G3;	 
	vec4 w, d;	 
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);	 
	w = max(0.6 - w, 0.0);	 
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.0), x3);	 
	w *= w;
	w *= w;
	d *= w;	 
	return dot(d, vec4(52.0));
}

float snoiseFractal(vec3 p) {
	return      0.5333333 * snoise(p) + 
                0.2666667 * snoise(2.0 * p) + 
                0.1333333 * snoise(4.0 * p) + 
                0.0666667 * snoise(8.0 * p);
}

float warps(vec3 p) {
	vec3 p1 = (p * 0.5 + cos(u_time * 0.01));
	vec3 p2 = (p1 + sin(u_time * 0.01));
	vec3 p3 = (p2 * 1.5 + cos(u_time * 0.03));
	
	/*
	vec4 t1 = texture2D(u_texture_0, vec2(p1.x, p2.y));
	vec4 t2 = texture2D(u_texture_0, vec2(p2.y, p3.z));
	vec4 t3 = t1 * t2;	
	return t3.x * t3.y * t3.z;
	*/

	float n1 = 2.0 * noiset(p1 * 3.0);
	float n2 = 1.0 * noiset(p2 * 6.0);
	float n3 = 1.5 * fbmt(p3 * 12.0);
	return n1; // * n2 * n3;

	/*
	float n1 = 2.0 * snoise(p1 * 3.0);
	float n2 = 1.0 * snoise(p2 * 6.0);
	float n3 = 1.5 * fbm(p3 * 12.0);
	return n1 * n2 * n3;
	*/
}

// ##############
// ###  MAIN  ###
// ##############

void main() {
	setVars();
	
	vec3 rgb = vec3(0.0);
    
    // rgb += noiset(point.xyz);
    rgb += noiset2d(st);

	gl_FragColor = vec4(rgb, 1.0);
}