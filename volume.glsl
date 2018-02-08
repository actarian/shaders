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

// Volumetric clouds. It performs level of detail (LOD) for faster rendering

vec3 mmod(vec3 v) {
    return fract(v);
}

float noiset(in vec3 p) {

    float t = u_time * 0.1;

    p = p * 2.5;
    
    vec2 oa = (vec2(0.567, 0.123)) + (p.x - fract(t) * 1.0);
    vec2 ob = (vec2(0.765, 0.321)) - (oa.y * 2.0 + fract(t) * 1.2);
    vec2 oc = (vec2(0.345, 0.543)) + (ob.y * 0.5 - fract(t) * 1.4);
    /*
	vec2 oa = (vec2(0.567, 0.123)) + (p.x * cos(p.y) - t * 1.0);
    vec2 ob = (vec2(0.765, 0.321)) - (oa.y * 2.0 * sin(oa.x) + t * 1.2);
    vec2 oc = (vec2(0.345, 0.543)) + (ob.y * 0.5 * cos(ob.x) - t * 1.4);
    */  
    
    vec3 ta = mmod(vec3(
		p.z + oa.x, 
		p.y + oa.y, 
		p.x
	));
	
    vec3 tb = mmod(vec3(
		p.z + ob.x, 
		p.x + ob.y, 
		p.y
	));
	
    vec3 tc = mmod(vec3(
		p.z + oc.x, 
		p.y + oc.y, 
		p.x
	));
	
    // float z = fract(p.z);

    float a = texture2D(u_texture_0, ta.yz, -1000.0).r;
    float b = texture2D(u_texture_0, tb.yz, -1000.0).r;
    float c = texture2D(u_texture_0, tc.yz, -1000.0).r;

    float v = mix(a * 0.4, b * 0.4, 0.5);
    v = mix(v, c * 0.4, 0.5) * 3.0;
    v = v * v * v;
    return v;
    // return clamp(mix(a * 0.4, b * 0.4, z), -1.0, 1.0);

    /*
    vec3 floorp = floor(p);
    vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

    // vec2 uv = p.xy * floorp.xy + p.z * f.xy;

    vec2 uv = p.xy;

    uv = vec2(
		mod(uv.x + u_time, 1.0), 
		mod(uv.y + u_time, 1.0)
	);

    vec4 rgba = texture2D(u_texture_1, uv, -1000.0);

	return rgba.r; // mix(rgba.r, rgba.g, f.z);
    */
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

float noise(vec3 p) {
    // float f = fract(u_time * 0.1);
    // p = p + f;
    float F3 =  0.3333333;
    float G3 =  0.1666667;
	vec3 s = floor(p + dot(p, vec3(F3)));
	vec3 x = p - s + dot(s, vec3(G3));	 
	vec3 e = step(vec3(0.0), x - x.yzx);
	vec3 i1 = e * (1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy * (1.0 - e);	 	
	vec3 x1 = x - i1 + G3;
	vec3 x2 = x - i2 + 2.0 * G3;
	vec3 x3 = x - 1.0 + 3.0 * G3;	 
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

vec3 wind = vec3(0.2, 0.3, 0.4);

float map5(vec3 p) {
	vec3 q = p - wind * u_time;
	float f;
    f  = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q); q = q * 2.01;
    f += 0.06250 * noise(q); q = q * 2.02;
    f += 0.03125 * noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

float map4(vec3 p) {
	vec3 q = p - wind * u_time;
	float f;
    f  = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q); q = q * 2.01;
    f += 0.06250 * noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

float map3(vec3 p) {
	vec3 q = p - wind * u_time;
	float f;
    f  = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q); q = q * 2.03;
    f += 0.12500 * noise(q);
	return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

float map2(vec3 p) {
	vec3 q = p - wind * u_time;
	float f;
    f  = 0.50000 * noise(q); q = q * 2.02;
    f += 0.25000 * noise(q);;
	return clamp(1.5 - p.y - 2.0 + 1.75 * f, 0.0, 1.0);
}

vec3 sundir = normalize(vec3(-1.0, 0.0, -1.0));

vec4 integrate(in vec4 sum, in float dif, in float den, in vec3 bgcol, in float t) {
    // lighting
    vec3 lin = vec3(0.65,0.7,0.75)  *  1.4 + vec3(1.0, 0.6, 0.3)  *  dif;        
    vec4 col = vec4(mix(vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den), den);
    col.xyz *= lin;
    col.xyz = mix(col.xyz, bgcol, 1.0 - exp(-0.003 * t * t));
    // front to back blending    
    col.a *= 0.4;
    col.rgb *= col.a;
    return sum + col * (1.0 - sum.a);
}

#define MARCH(STEPS, MAPLOD) for(int i=0; i<STEPS; i++) { vec3  pos = ro + t*rd; if(pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99) break; float den = MAPLOD(pos); if(den>0.01) { float dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0); sum = integrate(sum, dif, den, bgcol, t); } t += max(0.05,0.02*t); }

/*
void doMarch(int STEPS, in float MAPLOD) {
    for (int i = 0; i < STEPS; i++) { 
        vec3 pos = ro + t * rd; 
        if (pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99) {
            break; 
        }
        float den = MAPLOD(pos); 
        if (den>0.01) { 
            float dif =  clamp((den - MAPLOD(pos + 0.3 * sundir)) / 0.6, 0.0, 1.0); 
            sum = integrate(sum, dif, den, bgcol, t); 
        } 
        t += max(0.05,0.02*t); 
    }
}
*/

vec4 raymarch(vec3 ro, vec3 rd, vec3 bgcol, vec2 px) {
	vec4 sum = vec4(0.0);

	float t = 0.0; // 0.05 * texture2D(u_texture_0, px&255, 0).x;

    MARCH(5, map5);
    // MARCH(5, map4);
    // MARCH(5, map3);
    // MARCH(5, map2);

    return clamp(sum, 0.0, 1.0);
}

mat3 setCamera(vec3 ro, vec3 ta, float cr) {
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize(cross(cw,cp));
	vec3 cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

vec4 render(vec3 ro, vec3 rd, vec2 px) {

    // background sky     
	float sun = clamp(dot(sundir, rd), 0.0, 1.0);
	vec3 col = vec3(0.6, 0.71, 0.75) - rd.y * 0.2 * vec3(1.0, 0.5, 1.0) + 0.15 * 0.5;
	col += 0.2 * vec3(1.0, 0.6, 0.1) * pow(sun, 8.0);

    col = vec3(0.2);

    // clouds    
    vec4 res = raymarch(ro, rd, col, px);
    col = col * (1.0 - res.w) + res.xyz;
    
    // sun glare    
	col += 0.2 * vec3(1.0, 0.4, 0.2) * pow(sun, 3.0);

    return vec4(col, 1.0);
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

vec3 cameraOrbit(vec2 p) {
    float u = 90.0 - 180.0 * p.x;
    float v = -180.0 + 360.0 * p.y;
    float radius = 10.0;
    float lat = u * 2.0;
    float lon = v + 180.0;
	float x = radius * cos(lat * RAD) * cos(lon * RAD);
	float y = radius * cos(lat * RAD) * sin(lon * RAD);
	float z = radius * sin(lat * RAD);
	return vec3(x, y, z);
}

void main() {
    vec2 st = getSt();
    vec2 uv = getUv(st);

    vec2 m = u_mouse.xy / u_resolution.xy;
    
    // camera
    vec3 ro = normalize(cameraOrbit(m)); // normalize(vec3(4.0 * sin(m.x), 0.0 * m.y, 4.0 * cos(m.x)));
	vec3 ta = vec3(0.0, 0.0, 0.0);
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray
    vec3 rd = ca * normalize(vec3(uv.xy, 1.0));

    gl_FragColor = render(ro, rd, vec2(gl_FragCoord - 0.5));
}

void main_() {
    vec2 st = getSt();
    vec2 uv = getUv(st);

    vec2 m = u_mouse.xy / u_resolution.xy;
    
    // camera
    vec3 ro = cameraOrbit(m); // normalize(vec3(4.0 * sin(m.x), 0.0 * m.y, 4.0 * cos(m.x)));
	vec3 ta = vec3(0.0, 0.0, 0.0);
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray
    vec3 rd = ca * normalize(vec3(uv.xy, 1.0));

    gl_FragColor = vec4(1.0) * noise(rd);
}
