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

const bool OCCLUSION_ENABLED 	= false;
const bool FOG_ENABLED 			= true;
const int OCCLUSION_STEPS   	= 4;
const int RAYMARCH_STEPS    	= 256;	
const float CAMERA_FOV      	= 0.40;
const float CAMERA_NEAR     	= 0.01;
const float CAMERA_FAR      	= 20.0;
const vec3 LIGHT_COLOR			= vec3(0.9, 0.9, 0.9);
const vec3 LIGHT_POSITION		= vec3(0.2, 0.9, -1.8);

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
	if (false) {
		point = vec4(uv, 0.0, 1.0);
		matrix = rotationAxis(
			RAD * 360.0 * u_time * 0.2 + st.x * st.y, 
			vec3(1.0, 1.0, 1.0)
		);
		point *= matrix;
	} else {
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
		matrix = rotationAxis(RAD * 360.0 * u_time * .02, vec3(1.0, 1.0, 1.0));
		point *= matrix;
	}
	// pixel = vec2(1.0) / u_resolution * 100.0;
	pixel = vec2(0.003);
}

// ################
// ###  NOISES  ###
// ################

vec3 filtering(sampler2D texture, vec2 uv) {
	return texture2D(texture, uv, -1000.0).xyz;
	/*
	float size = 64.0;
	uv = uv * size + 0.5;
	vec2 iuv = floor(uv);
	vec2 fuv = fract(uv);
	uv = iuv + fuv * fuv * (3.0 - 2.0 * fuv); // fuv*fuv*fuv*(fuv*(fuv*6.0-15.0)+10.0);;
	uv = (uv - 0.5) / size;
	return texture2D(texture, uv, -1000.0).xyz;
	*/
}

float noiset(vec3 p) {
	vec3 t = p * 0.2;	
	vec2 dxy = vec2(0.0); // vec2(cos(u_time) * 0.05, sin(u_time) * 0.05);
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
	
    float a = filtering(u_texture_0, ta.xy).r;
    float b = filtering(u_texture_1, tb.xy).r;
    return clamp(mix(a * 0.4, b * 0.4, t.z), -1.0, 1.0);
}

float perlinTexture(vec3 p) {	

	return 0.01; // noiset(p * 0.01);

	// return snoiseFractal(p);

	float p1 = 9.0 * noiset(p * 1.2);
	float p2 = 3.0 * noiset((p + vec3(0.1, 0.2, 0.3)) * 1.1);
	float p3 = 1.0 * noiset((p + vec3(0.3, 0.2, 0.1)) * 1.0);
	
	return p1 * p2 * p3;
		
	/*
	float x = 0.0;
    x += noiset(p * pow(2.0, 1.0)) * pow(0.5, 1.0);
	x += noiset(p * pow(2.0, 2.0)) * pow(0.5, 2.0);
	x += noiset(p * pow(2.0, 3.0)) * pow(0.5, 3.0);
	return x;
	*/

	// return perlinNoiseT(p);

	/*
	vec3 p1 = (p * 0.5 + cos(u_time * 0.01));
	vec3 p2 = (p1 + sin(u_time * 0.01));
	vec3 p3 = (p2 * 1.5 + cos(u_time * 0.03));
	
	float n1 = 10.0 * noiset(p1 * 1.0);
	float n2 = 2.0 * noiset(p2 * 2.0);
	float n3 = 1.0 * noiset(p3 * 4.0);
		
	return n1 * n2 * n3;
	*/
	/*
	float n1 = 2.0 * snoise(p1 * 3.0);
	float n2 = 1.0 * snoise(p2 * 6.0);
	float n3 = 1.5 * fbm(p3 * 12.0);
	return n1 * n2 * n3;
	*/
}

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

float noiset_(vec3 p) {
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

float perlinNoiseT(vec3 p) {
    float x = 0.0;
    for (float i = 0.0; i < 3.0; i += 1.0) {
        x += noiset(p * pow(2.0, i)) * pow(0.5, i);
	}
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

// ####################
// ###  GEOMETRIES  ###
// ####################

float sphere(vec3 p, float s) {
    return length(p) - s;
}

float ubox(vec3 p, vec3 b) {
    return length(max(abs(p) - b, 0.0));
}

float roundBox(vec3 p, vec3 b, float r) {
    return length(max(abs(p) -b, 0.0)) - r;
}

float box(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;  
    return min(max(d.x, max(d.y,d.z)), 0.0) + length(max(d, 0.0));
}

float torus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float cylinder(vec3 p, vec3 c) {
    return length(p.xz - c.xy) - c.z;
}

float cone(vec3 p, vec2 c) {
    // c must be normalized
    float q = length(p.xy);
    return dot(c, vec2(q,p.z));
}

float plane(vec3 p, vec4 n) {
    // n must be normalized
    return dot(p, n.xyz) + n.w;
}

float hexPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z - h.y,max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x);
}

float triPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float capsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0 );
    return length(pa - ba * h) - r;
}

float cappedCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float cappedCone(in vec3 p, in vec3 c) {
    vec2 q = vec2( length(p.xz), p.y );
    vec2 v = vec2( c.z*c.y/c.x, -c.z );
    vec2 w = v - q;
    vec2 vv = vec2( dot(v,v), v.x*v.x );
    vec2 qv = vec2( dot(v,w), v.x*w.x );
    vec2 d = max(qv,0.0)*qv/vv;
    return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
}

float ellipsoid(in vec3 p, in vec3 r) {
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

// ###################
// ###  PARTICLES  ###
// ###################

float particles (vec3 p) {
	vec3 pos = p;
	pos.y -= u_time * 0.02;
	float n = fbm(20.0 * pos);
	n = pow(n, 5.0);
	float brightness = noise(10.3 * p);
	float threshold = 0.26;
	return smoothstep(threshold, threshold + 0.15, n) * brightness * 90.0;
}

// ##################
// ###  BOOLEANS  ###
// ##################

float bIntersect(float da, float db) {
    return max(da, db);
}
float bUnion(float da, float db) {
    return min(da, db);
}
float bDifference(float da, float db) {
    return max(da, -db);
}

// ################
// ###  BLENDS  ###
// ################

// blend smooth min
#define S_TYPE 1
#if S_TYPE == 1
// exponential smooth min (k = 32);
float smin(float a, float b, float k) {
    float res = exp(-k * a) + exp(-k * b);
    return -log(res) / k;
}
#elif S_TYPE == 2
// polynomial smooth min (k = 0.1);
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
#else
// power smooth min (k = 8);
float smin(float a, float b, float k) {
    a = pow(a, k); b = pow(b, k);
    return pow((a * b) / (a + b), 1.0 / k);
}
#endif

// ################
// ###  REPEAT  ###
// ################

vec3 repeat(vec3 p, vec3 c) {
    return mod(p, c) -0.5 * c;
}

float opRep(vec3 p, vec3 c) {
    vec3 q = mod(p, c) -0.5 * c;
    return sphere(q, 0.05);
	// return sphere(q, 0.05 + 0.03 * cos(u_time * 3.0 + q.y * 90.0 + q.x * 30.0));
}

// ###############
// ###  BENDS  ###
// ###############

vec3 twist(vec3 p, float t) {
    float c = cos(t * p.y);
    float s = sin(t * p.y);
    mat2  m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

float twistedCube(vec3 p) {
    vec3 q = rotateY(p, 0.5 * p.y);
    return box(q, vec3(0.2));
}

float opTwist(vec3 p) {
    float c = cos((2.0 + 12.0 * cos(u_time * .3)) * p.y);
    float s = sin((2.0 + 12.0 * cos(u_time * .3)) * p.y);
    mat2  m = mat2(c, -s, s, c);
    vec3  q = vec3(m * p.xz, p.y);
    return torus(q, vec2(0.6, 0.2));
}

vec3 rotatePoint(vec3 p) {
	return (vec4(p, 1.0) * matrix).xyz;
}

// ##################
// ###  DISPLACE  ###
// ##################

float displacement(vec3 p) {
	return sin(8.0 * cos(u_time) * p.x) * sin(2.0 * sin(u_time * .4) * p.y) * sin(2.0 * cos(u_time) * p.z);
}

float opDisplace(vec3 p) {
    float d1 = sphere(p, .5);
    float d2 = displacement(p);
    return d1 + d2;
}

// ###############
// ###  SCENE  ###
// ###############

float getPlane(vec3 p) {
	float c = cos(u_time);
	float a = plane(p, vec4(0.0, 2.0, 0.0, 1.0));	
	p = repeat(p, vec3(7.0, 0.0, 7.0));
	p = twist(p, 1.0 + c * 1.0);
	float b = roundBox(p, vec3(0.3, 0.3, 2.0 + c * 2.0), 0.02);	
	a = smin(a, b, 0.9);
	return a + (a < 0.01 ? perlinTexture(p) * 1.0 : 0.0);
}

int materialId = 1;
float scene(vec3 p) {
	float		z = 1000000.0;
	float		a = getPlane(p);
	/*
	if (b < a) {
		a = b;
		materialId = 6;
	}
	*/
	return a;
}

// #################
// ###  NORMALS  ###
// #################

#define N_TYPE 1
vec3 getNormal(in vec3 p) {
#if N_TYPE == 1
	// 6-tap normalization. Probably the most accurate, but a bit of a cycle waster.
	return normalize(vec3(
		scene(vec3(p.x + EPSILON, p.y, p.z)) - scene(vec3(p.x - EPSILON, p.y, p.z)),
		scene(vec3(p.x, p.y + EPSILON, p.z)) - scene(vec3(p.x, p.y - EPSILON, p.z)),
		scene(vec3(p.x, p.y, p.z + EPSILON)) - scene(vec3(p.x, p.y, p.z - EPSILON))
	));
#elif  N_TYPE == 2
	// Shorthand version of the above. The fewer characters used almost gives the impression that it involves fewer calculations. Almost.
	vec2 e = vec2(EPSILON, 0.0);
	return normalize(vec3(scene(p + e.xyy) - scene(p - e.xyy), scene(p + e.yxy) - scene(p - e.yxy), scene(p + e.yyx) - scene(p - e.yyx)));
#elif  N_TYPE == 3
    // If speed is an issue, here's a slightly-less-accurate, 4-tap version. If fact, visually speaking, it's virtually the same, so on a
    // lot of occasions, this is the one I'll use. However, if speed is really an issue, you could take away the "normalization" step, then
    // divide by "EPSILON," but I'll usually avoid doing that.
    float ref = scene(p);
	return normalize(vec3(
		scene(vec3(p.x + EPSILON, p.y, p.z)) - ref,
		scene(vec3(p.x, p.y + EPSILON, p.z)) - ref,
		scene(vec3(p.x, p.y, p.z + EPSILON)) - ref
	));
#elif  N_TYPE == 4
	// The tetrahedral version, which does involve fewer calculations, but doesn't seem as accurate on some surfaces... I could be wrong,
	// but that's the impression I get.
	vec2 e = vec2(-0.5 * EPSILON, 0.5 * EPSILON);
	return normalize(e.yxx * scene(p + e.yxx) + e.xxy * scene(p + e.xxy) + e.xyx * scene(p + e.xyx) + e.yyy * scene(p + e.yyy));
#endif
}

// ################
// ###  CAMERA  ###
// ################

struct Camera {
    vec3 position;
    vec3 target;
    vec3 forward;
    vec3 right;
    vec3 up;
    float fov;
	float near;
	float far;
};
Camera getCamera(vec3 position, vec3 target) {
	Camera camera = Camera(position, target, normalize(target - position), vec3(0.0), vec3(0.0), CAMERA_FOV, CAMERA_NEAR, CAMERA_FAR);
	camera.right = normalize(vec3(camera.forward.z, 0.0, -camera.forward.x));
	camera.up = normalize(cross(camera.forward, camera.right));
	return camera;
}

// #################
// ###  MARCHER  ###
// #################

struct Marcher {
    vec3 origin;
    vec3 direction;
	float scale;
	float threshold;
	float distance;
	float depth;
};
Marcher getMarcher(Camera camera) {
	const float scale = 0.5;
	const float threshold = 0.005; // I'm not quite sure why, but thresholds in the order of a pixel seem to work better for me... most times.
	// origin. Ray origin. Every ray starts from this point, then is cast in the rd direction.
    // direction. Ray direction. This is our one-unit-long direction ray.
    Marcher marcher = Marcher(
		camera.position,
		normalize(camera.forward + camera.fov * uv.x * camera.right + camera.fov * uv.y * camera.up),
		scale,
		threshold,
		0.0,
		0.0
	);	
	return marcher;
}

// #################
// ###  SURFACE  ###
// #################

struct Surface {
    vec3 position;
    vec3 normal;
	vec3 rgb;
};
Surface getSurface(Marcher marcher) {
	vec3 position = marcher.origin + marcher.direction * marcher.distance;
	vec3 normal = getNormal(position);
	Surface surface = Surface(position, normal, vec3(0.0));
	return surface;
}

// ###############
// ###  LIGHT  ###
// ###############

float getOcclusion(vec3 p, vec3 d) {
	float occ = 1.0;
	p += d;
	for (int i = 0; i < OCCLUSION_STEPS; i++) {
		float distance = scene(p);
		p += d * distance;
		occ = min(occ, distance);
	}
	return max(0.0, occ);
}
struct Light {
	vec3 color;
	vec3 position;
	vec3 direction;
	vec3 reflected;
	float distance;
	float attenuation;
	float diffuse;
	float specular;
	float occlusion;
};
Light getLight(vec3 color, vec3 position, Material material, Surface surface, Camera camera) {
	const float specularity = 16.0;
	Light light = Light(color, position, vec3(0.0), vec3(0.0), 0.0, 0.0, 0.0, 0.0, 1.0);
	light.direction = light.position - surface.position;
	light.distance = length(light.direction);
	light.direction /= light.distance; // Normalizing the light-to-surface, aka light-direction, vector.
	light.attenuation = min(1.0 / (0.25 * light.distance * light.distance), 1.0); // Keeps things between 0 and 1.
	light.reflected = reflect(-light.direction, surface.normal);
	light.diffuse = max(0.0, dot(surface.normal, light.direction));
	light.specular = max(0.0, dot(light.reflected, normalize(camera.position - surface.position)));
	light.specular = pow(light.specular, specularity); // Ramping up the specular value to the specular power for a bit of shininess.
	if (OCCLUSION_ENABLED) {
		float diffuseOcclusion = getOcclusion(surface.position, light.direction);
		float specularOcclusion = getOcclusion(surface.position, light.reflected);
		light.diffuse *= diffuseOcclusion;
		light.specular *= specularOcclusion;
		light.occlusion = getOcclusion(surface.position, surface.normal);
		if (true) {
			light.occlusion += diffuseOcclusion + specularOcclusion;
			light.occlusion *= .3;
		}
	}	
	return light;
}
vec3 calcLight (Light light, Material material) {
	//	return vec3(light.occlusion);
	return (material.color * (material.ambient * light.occlusion + light.diffuse * material.glossiness) + light.specular * material.shininess) * light.color * light.attenuation;	
}

// ################
// ###  RENDER  ###
// ################

float getRayDistance(Marcher marcher, Camera camera) {
	marcher.distance = 0.0;
	marcher.depth = camera.near; // Ray depth. "start" is usually zero, but for various reasons, you may wish to start the ray further away from the origin.
	for (int i = 0; i < RAYMARCH_STEPS; i++ ) {
		marcher.distance = scene(marcher.origin + marcher.direction * marcher.depth);
    if ((marcher.distance < marcher.threshold) || (marcher.depth >= camera.far)) {
			break;
		}
		marcher.depth += marcher.distance * marcher.scale;
	}
	if (marcher.distance >= marcher.threshold) {
		marcher.depth = camera.far;
	} else {
		marcher.depth += marcher.distance;
	} 
	return marcher.depth;
}

vec3 render() {
	// BACKGROUND
	vec3 background = vec3(0.3, 0.3, 0.9);
	// CAMERA
	float radius = 8.0 + sin(u_time * 0.04) * 4.0;
	Camera camera = getCamera(
		// vec3(4.0, 1.0, 4.0), 
		vec3(radius * sin(u_time * 0.04), 2.0, radius * cos(u_time * 0.04)), // position
		vec3(0.0, 0.0, 0.0) // target
	);
	// MARCHER
	Marcher marcher = getMarcher(camera);
	marcher.distance = getRayDistance(marcher, camera);
	if (marcher.distance >= camera.far) {
	    return background;
			// discard; // If you want to return without rendering anything, I think.
	}
	// SURFACE. If we've made it this far, we've hit something. 
	Surface surface = getSurface(marcher);
	Material material = getMaterial(materialId);
	// LIGHT
	Light light = getLight(
		LIGHT_COLOR, // color
		vec3(cos(u_time) * 4.0, 4.0, -2.0 + sin(u_time) * 4.0), // position
		// LIGHT_POSITION, // position
		material,
		surface,
		camera
	);
	// LAMBERT
	surface.rgb = calcLight(light, material);
	// FOG
	if (FOG_ENABLED) {
		surface.rgb = mix(surface.rgb, background, clamp(marcher.distance / CAMERA_FAR, 0.0, 1.0));
	}
	// Clamping the lit pixel between black and while, then putting it on the screen. We're done. Hooray!
	return clamp(surface.rgb, 0.0, 1.0); // from 0 to 1
}

// ##############
// ###  MAIN  ###
// ##############

void main() {
	setVars();
	
	/*
	vec2 res = u_resolution; // iResolution.xy;

	vec2 st = gl_FragCoord.xy / res.xy;
    st.x *= (res.x / res.y);

    vec3 color = vec3(0.);
    color = vec3(st.x, st.y, abs(sin(u_time)));

    gl_FragColor = vec4(color,1.0);
	*/

	vec3 rgb = vec3(0.0);
    rgb += render();

	gl_FragColor = vec4(rgb, 1.0);
}