
precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform vec3 u_camera;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

#define PHI sqrt(5) * 0.5 + 0.5

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

float sPlane(vec3 origin, vec3 direction, vec3 normal, float dist) {
    float denom = dot(direction, normal);
    float d = -(dot(origin, normal) + dist) / denom;
    return d;
}

float sPlane2(vec3 p, vec4 n) {
    // n must be normalized
    return dot(p, n.xyz) + n.w;
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float sRoundbox(vec3 p, vec3 s, float r) {
  return length(max(abs(p) - s, 0.0)) - r;
}

float sSphere(vec3 point) {
    float radius = (sin(u_time) * 0.5 + 0.5) * 0.25;
    float d = length(point) - radius;
    return d;
}

float sSphereOffsetted(vec3 point) {
    float radius = (sin(u_time) * 0.5 + 0.5) * 0.25;
    float d = length(point - vec3(0.0, radius, 0.0)) - radius;
    return d;
}

float fill(in float d) { return 1.0 - smoothstep(0.0, rx * 2.0, d); }
float stroke(in float d, in float t) { return 1.0 - smoothstep(t - rx * 1.5, t + rx * 1.5, abs(d)); }

// field adapted from https://www.shadertoy.com/view/XsyGRW
vec3 field(float d) {
    const vec3 c1 = mix(WHITE, YELLOW, 0.4);
    const vec3 c2 = mix(WHITE, AZUR, 0.7);
    const vec3 c3 = mix(WHITE, ORANGE, 0.9);
    const vec3 c4 = BLACK;
    float d0 = abs(stroke(mod(d + 0.1, 0.2) - 0.1, 0.004));
    float d1 = abs(stroke(mod(d + 0.025, 0.05) - 0.025, 0.004));
    float d2 = abs(stroke(d, 0.004));
    float f = clamp(d * 0.85, 0.0, 1.0);
    vec3 gradient = mix(c1, c2, f);
    gradient = mix(gradient, c4, 1.0 - clamp(1.25 - d * 0.25, 0.0, 1.0));
    // gradient -= 1.0 - clamp(1.25 - d * 0.25, 0.0, 1.0);
    gradient = mix(gradient, c3, fill(d));
    gradient = mix(gradient, c4, max(d2 * 0.85, max(d0 * 0.25, d1 * 0.06125)) * clamp(1.25 - d, 0.0, 1.0));
    return gradient;
}

// draw Distance Field by https://www.shadertoy.com/view/XsyGRW
vec3 dfLine(float d) {
    const float aa = 3.0;
    const float t = 0.0025;
    return vec3(smoothstep(0.0, aa / u_resolution.y, max(0.0, abs(d) - t)));
}

float dfSolid(float d) {
    return smoothstep(0.0, 3.0 / u_resolution.y, max(0.0, d));
}

vec3 dfDraw(float d, vec2 p) {
    float t = clamp(d * 0.85, 0.0, 1.0);
    vec3 gradient = mix(vec3(1, 0.8, 0.5), vec3(0.3, 0.8, 1), t);
    float d0 = abs(1.0 - dfLine(mod(d + 0.1, 0.2) - 0.1).x);
    float d1 = abs(1.0 - dfLine(mod(d + 0.025, 0.05) - 0.025).x);
    float d2 = abs(1.0 - dfLine(d).x);
    vec3 rim = vec3(max(d2 * 0.85, max(d0 * 0.25, d1 * 0.06125)));
    gradient -= rim * clamp(1.25 - d, 0.0, 1.0);
    gradient -= 1.0 - clamp(1.25 - d * 0.25, 0.0, 1.0);
    gradient -= mix(vec3(0.05, 0.35, 0.35), vec3(0.0), dfSolid(d));
    return gradient;
}

mat3 mLookAt(vec3 origin, vec3 target, float roll) {
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

vec3 vNormal(vec3 p, float eps) {
    const vec3 v1 = vec3( 1.0, -1.0, -1.0);
    const vec3 v2 = vec3(-1.0, -1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0, -1.0);
    const vec3 v4 = vec3( 1.0, 1.0, 1.0);
    return normalize(v1 * sSphere(p + v1 * eps) + v2 * sSphere(p + v2 * eps) + v3 * sSphere(p + v3 * eps) + v4 * sSphere(p + v4 * eps));
}

vec3 vRay(vec3 origin, vec3 target, vec2 p, float lensLength) {
    mat3 camMat = mLookAt(origin, target, 0.0);
    return normalize(camMat * vec3(p, lensLength));
}

// ##################
// ###  SPECULAR  ###
// ##################

float lBeckmannDistribution(float x, float roughness) {
    float NdotH = max(x, 0.0001);
    float cos2Alpha = NdotH * NdotH;
    float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
    float roughness2 = roughness * roughness;
    float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
    return exp(tan2Alpha / roughness2) / denom;
}

float lCookTorranceSpecular(vec3 lightDirection, vec3 viewDirection, vec3 surfaceNormal, float roughness, float fresnel) {
    float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
    float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);
    // Half angle vector
    vec3 H = normalize(lightDirection + viewDirection);
    // Geometric term
    float NdotH = max(dot(surfaceNormal, H), 0.0);
    float VdotH = max(dot(viewDirection, H), 0.000001);
    float x = 2.0 * NdotH / VdotH;
    float G = min(1.0, min(x * VdotN, x * LdotN));
    // Distribution term
    float D = lBeckmannDistribution(NdotH, roughness);
    // Fresnel term
    float F = pow(1.0 - VdotN, fresnel);
    // Multiply terms and done
    return  G * F * D / max(3.14159265 * VdotN * LdotN, 0.000001);
}

// ################
// ###  CAMERA  ###
// ################

const float CAMERA_FOV      	= 0.06;
const float CAMERA_NEAR     	= 0.01;
const float CAMERA_FAR      	= 100.0;
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

const int RAYMARCH_STEPS    	= 64; // 256
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
	const float threshold = 0.9; 
    
    vec3 direction = vRay(camera.position, camera.target, st, 15.0);
    // normalize(camera.forward + camera.fov * st.x * camera.right + camera.fov * st.y * camera.up)

    Marcher marcher = Marcher(
		camera.position,
		direction,
		scale,
		threshold,
		0.0,
		0.0
	);
	return marcher;
}

// ################
// ###  RENDER  ###
// ################

int materialId = -1;
float sScene(vec3 origin, vec3 direction, float depth) {
    vec3 p = origin + direction * depth;
	float z = 1000000.0;
	float a = sPlane2(p, vec4(0.0, 1.0, 0.0, 0.0));
    float radius = 0.1;
    float b = fBox(p, vec3(radius));
    // float b = sRoundbox(p, vec3(radius), 0.01);
    
	if (b < a) {
		z = b;
		materialId = 2;
	} else {
        z = a;
        materialId = 1;
    }
	return z;
}

float sRayDistance(Marcher marcher, Camera camera) {
    marcher.distance = camera.near;
    marcher.depth = -1.0;
    for (int i = 0; i < RAYMARCH_STEPS; i++) {
		if (marcher.distance < camera.near || marcher.depth > camera.far) {
        	break;
		}
		marcher.distance = sScene(marcher.origin, marcher.direction, marcher.depth);
        marcher.depth += marcher.distance;
	}
    return marcher.depth;
}

void drawA() {
    vec3 background = BLACK;

    // CAMERA
	float radius = 10.0;
	Camera camera = getCamera(
		u_camera * radius, // vec3(radius * sin(u_time * 0.04), 10.0, radius * cos(u_time * 0.04)), // position
		vec3(0.0, 0.0, 0.0) // target
	);

	// MARCHER
	Marcher marcher = getMarcher(camera);
	marcher.distance = sRayDistance(marcher, camera);

	if (marcher.distance >= camera.far) {
        gl_FragColor = vec4(background, 1.0);
        return;
        // discard; // If you want to return without rendering anything,
	}

    // MATERIAL
    vec3 color;
    if (materialId == 1) {
        float a = sPlane(marcher.origin, marcher.direction, vec3(0.0, 1.0, 0.0), -CAMERA_NEAR);
        // float a = sPlane2(marcher.origin + marcher.direction, vec4(0.0, 1.0, 0.0, 0.0));
        vec3 p = marcher.origin + marcher.direction * a;
        color = field(sSphere(p) - 0.0125);

    } else if (materialId == 2) {
        // gl_FragColor = vec4(RED, 1.0);
        // return;
        vec3 p = marcher.origin + marcher.direction * marcher.distance;
        vec3 normal = vNormal(p, 0.002);
        vec3 ldir = normalize(vec3(0.0, 1.0, 0.2));
        float magnitude = max(0.2, dot(normal, ldir));
        magnitude = pow(magnitude, 0.3545) * 1.75; // magnitude = 0.0;
        color = vec3(0.95, 0.45, 0.15) * magnitude;
        color += lCookTorranceSpecular(ldir, -marcher.direction, normal, 1.0, 3.25) * 1.5;

    }
    gl_FragColor = vec4(color, 1.0);
}

void drawB() {
    float time = u_time * 2.5;
    // vec2 uv = 2.0 * gl_FragCoord.xy / u_resolution - 1.0;
    vec2 p = st;
    vec3 ro = vec3(sin(time) * 2.0, 1.0, cos(time) * 2.0);
    vec3 ta = vec3(0.0);
    vec3 rd = vRay(ro, ta, p, 2.0);

    float latest = 1.0;
    float d = -1.0;
    for (int i = 0; i < 30; i++) {
        if (latest < 0.01 || d > 10.0) {
            break;
        }
        d += (latest = sSphere(ro + rd * d));
    }

    float tPlane = sPlane(ro, rd, vec3(0.0, 1.0, 0.0), 0.0);

    if (tPlane > -0.5 && tPlane < d) {
        vec3 pos = ro + rd * tPlane;
        gl_FragColor = vec4(dfDraw(sSphere(pos) - 0.0125, pos.xz), 1);

    } else if (d > 10.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

    } else {
        vec3 pos = ro + rd * d;
        vec3 normal = vNormal(pos, 0.002);
        vec3 ldir = normalize(vec3(0.0, 1.0, 0.2));
        float mag = max(0.2, dot(normal, ldir));
        mag = pow(mag, 0.3545);
        mag *= 1.75;
        //mag = 0.0;
        gl_FragColor = vec4(mag * vec3(0.95, 0.45, 0.15), 1.0);
        gl_FragColor.rgb += lCookTorranceSpecular(ldir, -rd, normal, 1.0, 3.25) * 1.5;
    }
}

void main() {
    drawA();
}