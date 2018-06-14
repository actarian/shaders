

#extension GL_OES_standard_derivatives : enable

precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform vec3 u_camera;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

#define RAD				0.01745329251
#define EPSILON			0.001
#define PHI             sqrt(5) * 0.5 + 0.5

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

// #define OCCLUSION
// #define OCCLUSION_

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

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float sBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

float sRotatingBox(vec3 p, vec3 b) {
    mat4 matrix = rotationAxis(
        RAD * 360.0 * u_time * 0.2 + st.x * st.y, 
        vec3(0.0, 1.0, 0.0)
    );
    p = (vec4(p, 1.0) * matrix).xyz;
    return sBox(p, b);
}

// ###############
// ###  SCENE  ###
// ###############
int materialId = -1;
struct Material {
	vec3 color;
	float ambient;
	float glossiness;
	float shininess;
};
Material getMaterial(int m) {
	Material material;
	// if (m == 1) {
		material = Material(
			vec3(0.0, 0.0, 1.0), // color
			0.3, // ambient,
			0.6, // glossiness
			1.9 // shininess
		);
	// }
	return material;
}
/*
float sScene(vec3 origin, vec3 direction, float depth) {
    vec3 p = origin + direction * depth;
	float z = 1000000.0;
	float b = sBox(p, vec3(0.1));
    if (b < z) {
		z = b;
		materialId = 2;
	}
	return z;
}
*/
float scene(vec3 p) {
	float 	 z = 1000000.0
			,a = sRotatingBox(p, vec3(0.05));
    materialId = 2;
	return a;
}

vec3 getNormal(in vec3 p) {
    // If speed is an issue, here's a slightly-less-accurate, 4-tap version. If fact, visually speaking, it's virtually the same, so on a
    // lot of occasions, this is the one I'll use. However, if speed is really an issue, you could take away the "normalization" step, then
    // divide by "EPSILON," but I'll usually avoid doing that.
    float ref = scene(p);
	return normalize(vec3(
		scene(vec3(p.x + EPSILON, p.y, p.z)) - ref,
		scene(vec3(p.x, p.y + EPSILON, p.z)) - ref,
		scene(vec3(p.x, p.y, p.z + EPSILON)) - ref
	));
}

// ################
// ###  CAMERA  ###
// ################

#define CAMERA_FOV      	0.03
#define CAMERA_NEAR     	0.01
#define CAMERA_FAR      	100.0
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
    vec3 forward = normalize(target - position);
    vec3 right = vec3(0.0);
    vec3 up = vec3(0.0);
	Camera camera = Camera(position, target, forward, right, up, CAMERA_FOV, CAMERA_NEAR, CAMERA_FAR);
	camera.right = normalize(vec3(camera.forward.z, 0.0, -camera.forward.x));
	camera.up = normalize(cross(camera.forward, camera.right));
	return camera;
}

// MARCHER
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
    vec2 xy = gl_FragCoord.xy / u_resolution.xy - 0.5;
    Marcher marcher = Marcher(
		camera.position,
		normalize(
            camera.forward + 
            (camera.fov * camera.right * xy.x) + 
            (camera.fov * camera.up * xy.y)
        ),
		scale,
		threshold,
		0.0,
		0.0
	);	
	return marcher;
}

// SURFACE
struct Surface {
    vec3 position;
    vec3 normal;
	vec3 rgb;
};
Surface getSurface(Marcher marcher) {
	// Use the "dist" value from marcher to obtain the surface postion, which can be passed down the pipeline for lighting.
	vec3 position = marcher.origin + marcher.direction * marcher.distance;
	// We can use the surface position to calculate the surface normal using a bit of vector math. I remember having to give long, drawn-out,
	// sleep-inducing talks at uni on implicit surface geometry (or something like that) that involved normals on 3D surfaces and such.
	// I barely remember the content, but I definitely remember there was always this hot chick in the room with a gigantic set of silicons who
	// looked entirely out of place amongst all the nerds... and this was back in the days when those things weren't as common... Um, I forgot
	// where I was going with this.
	// Anyway, check out the function itself. It's a standard, but pretty clever way to get a surface normal on difficult-to-differentiate surfaces.
	vec3 normal = getNormal(position);
	Surface surface = Surface(position, normal, vec3(0.0));
	return surface;
}

// LIGHT
const int OSTEPS = 4;
float getOcclusion(vec3 p, vec3 d) {
	float occ = 1.0;
	p += d;
	for (int i = 0; i < OSTEPS; i++) {
		float distance = scene(p);
		p += d * distance;
		occ = min(occ, distance);
	}
	return max(0.0, occ);
}
float getSoftShadow(in vec3 ro, in vec3 rd, float mint, float k, in vec4 c ) {
    return 1.0;
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
Light getLight(
    vec3 color, 
    vec3 position, 
    Material material, 
    Surface surface, 
    Camera camera
    ) {
	// Light needs to have a position, a direction and a color. Obviously, it should be positioned away from the
	// object's surface. The direction vector is the normalized vector running from the light position to the object's surface point that we're
	// going to illuminate. You can choose any light color you want, but it's probably best to choose a color that works best with the colors
	// in the scene. I've gone for a warmish white.
	// color. Light color. I have it in my head that light globes give off this color, but I swear I must have pulled that information right out of my a... Choose any color you want.
	// position. I've arranged for it to move in a bit of a circle about the xy-plane a couple of units away from the spherical object.
	// direction. Light direction. The point light direction goes from the light's position to the surface point we've hit on the sphere. I haven't normalized it yet, because I'd like to take the length first, but it will be.
	// reflected. The unit-length, reflected vector. Angle of incidence equals angle of reflection, if you remember rudimentary highschool physics, or math.
	// Anyway, the incident (incoming... for want of a better description) vector is the vector representing our line of sight from the light position
	// to the point on the suface of the object we've just hit. We get the reflected vector on the surface of the object by doing a quick calculation
	// between the incident vector and the surface normal. The reflect function is ( ref=incidentNorm-2.0*dot(incidentNorm, surfNormal)*surfNormal ),
	// or something to that effect. Either way, there's a function for it, which is used below.
	// The reflected vector is useful, because we can use it to calculate the specular reflection component. For all intents and purposes, specular light
	// is the light gathered in the mirror direction. I like it, because it looks pretty, and I like pretty things. One of the most common mistakes made
	// with regard to specular light calculations is getting the vector directions wrong, and I've made the mistake more than a few times. So, if you
	// notice I've got the signs wrong, or anything, feel free to let me know.
	// distance. Distance from the light to the surface point.
	// attenuation. Light falloff (attenuation), which depends on how far the surface point is from the light. Most of the time, I guess the falloff rate should be
	// mixtures of inverse distance powers, but in real life, it's far more complicated than that. Either way, most of the time you should simply
	// choose whatever makes the lighting look a little prettier. For instance, if things look too dark, I might decide to make the falloff drop off
	// linearly, without any other terms. In this case, the light is falling off with the square of the distance, and no other terms.
	// diffuse. The object's diffuse value, which depends on the angle that the light hits the object.
	// specular. The object's specular value, which depends on the angle that the reflected light hits the object, and the viewing angle... kind of.
	// specularity. The power of the specularity. Higher numbers can give the object a harder, shinier look.
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
	// light.shadow = getSoftShadow(surface.position, light.position, 0.001, 64.0, vec4(color, 1.0));
#ifdef OCCLUSION
		float diffuseOcclusion = getOcclusion(surface.position, light.direction);
		float specularOcclusion = getOcclusion(surface.position, light.reflected);
		light.diffuse *= diffuseOcclusion;
		light.specular *= specularOcclusion;
		light.occlusion = getOcclusion(surface.position, surface.normal);
    #ifdef OCCLUSION_
			light.occlusion += diffuseOcclusion + specularOcclusion;
			light.occlusion *= .3;
	#endif
#endif	
	return light;
}
vec3 calcLight(Light light, Material material) {
	// Bringing all the lighting components together to color the screen pixel. By the way, this is a very simplified version of Phong lighting.
	// It's "kind of" correct, and will suffice for this example. After all, a lot of lighting is fake anyway.
	// return vec3(light.occlusion);
	return (material.color * (material.ambient * light.occlusion + light.diffuse * material.glossiness) + light.specular * material.shininess) * light.color * light.attenuation;
}

const int STEPS = 64; // 128	
float getRayDistance(Marcher marcher, Camera camera) {
	marcher.distance = 0.0;
	marcher.depth = camera.near; // Ray depth. "start" is usually zero, but for various reasons, you may wish to start the ray further away from the origin.
	for (int i = 0; i < STEPS; i++ ) {
		// Distance from the point along the ray to the nearest surface point in the scene.
		marcher.distance = scene(marcher.origin + marcher.direction * marcher.depth);
        // Irregularities between browsers have forced me to use this logic. I noticed that Firefox was interpreting two "if" statements inside a loop
        // differently to Chrome, and... 20 years on the web, so I guess I should be used to this kind of thing.
        // Anyway, belive it or not, the stop threshold is one of the most important values in your entire application. Smaller numbers are more
        // accurate, but can slow your program down - drastically, at times. Larger numbers can speed things up, but at the cost of aesthetics.
        // Swapping a number, like "0.001," for something larger, like "0.01," can make a huge difference in framerate.
		if ((marcher.distance < marcher.threshold) || (marcher.depth >= camera.far)) {
		    // (rayDepth >= end) - We haven't used up all our iterations, but the ray has reached the end of the known universe... or more than
		    // likely, just the far-clipping-plane. Either way, it's time to return the maximum distance.
		    // (scene.distance < marcher.threshold) - The distance is pretty close to zero, which means the point on the ray has effectively come into contact
		    // with the surface. Therefore, we can return the distance, which can be used to calculate the surface point.
			// I'd rather neatly return the value above. Chrome and IE are OK with it. Firefox doesn't like it, etc... I don't know, or care,
			// who's right and who's wrong, but I would have thought that enabling users to execute a simple "for" loop without worring about what
			// will work, and what will not, would be a priority amongst the various parties involved. Anyway, that's my ramble for the day. :)
			break;
		}
		// We haven't hit anything, so increase the depth by a scaled factor of the minimum scene distance. It'd take too long to explain why
		// we'd want to increase the ray depth by a smaller portion of the minimum distance, but it can help, believe it or not.
		marcher.depth += marcher.distance * marcher.scale;
	}
	// I'd normally arrange for the following to be taken care of prior to exiting the loop, but Firefox won't execute anything before
	// the "break" statement. Why? I couldn't say. I'm not even game enough to put more than one return statement.
	// Normally, you'd just return the rayDepth value only, but for some reason that escapes my sense of logic - and everyone elses, for
	// that matter, adding the final, infinitessimal scene distance value (sceneDist) seems to reduce a lot of popping artifacts. If
	// someone could put me out of my misery and prove why I should either leave it there, or get rid of it, it'd be appreciated.
	if (marcher.distance >= marcher.threshold) {
		marcher.depth = camera.far;
	} else {
		marcher.depth += marcher.distance;
	} 
	// We've used up our maximum iterations. Damn, just a few more, and maybe we could have hit something, or maybe there was nothing to hit.
	// Either way, return the maximum distance, which is usually the far-clipping-plane, and be done with it.
	return marcher.depth;
}

vec3 render() {
	// BACKGROUND
	vec3 background = vec3(.01, .01, .01);
	
    // CAMERA
	float radius = 10.0;
	Camera camera = getCamera(
		u_camera * radius, // vec3(radius * sin(u_time * 0.04), 10.0, radius * cos(u_time * 0.04)), // position
		vec3(0.0, 0.0, 0.0) // target
	);

	// MARCHER
	Marcher marcher = getMarcher(camera);
	marcher.distance = getRayDistance(marcher, camera);
	if (marcher.distance >= camera.far) {
	    // I prefer to do it this way in order to avoid an if-statement below, but I honestly couldn't say whether it's more
	    // efficient. It feels like it would be. Does that count? :)
	    return background;
		//discard; // If you want to return without rendering anything, I think.
	}
	
    // SURFACE. If we've made it this far, we've hit something. 
	Surface surface = getSurface(marcher);
	Material material = getMaterial(materialId);
	
	// LIGHT
	Light light = getLight(
		vec3(0.9, 0.9, 0.9), // color
		vec3(0.6, 0.5, 1.5), // position
		material,
		surface,
		camera
	);

	// LAMBERT
	surface.rgb = calcLight(light, material);

	// Clamping the lit pixel between black and while, then putting it on the screen. We're done. Hooray!
	return clamp(surface.rgb, 0.0, 1.0); // from 0 to 1
}

void main() {

    vec3 color = render();

    /*
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
        gl_FragColor = vec4(color, 1.0);
        return;
        // discard; // If you want to return without rendering anything,
	}

    // MATERIAL
    if (materialId == 2) {
        vec3 p = marcher.origin + marcher.direction * marcher.distance;
        vec3 normal = getNormal(p);
        vec3 ldir = normalize(vec3(0.0, 1.0, 0.2));
        float magnitude = max(0.2, dot(normal, ldir));
        magnitude = pow(magnitude, 0.3545) * 1.75; // magnitude = 0.0;
        color = vec3(0.95, 0.45, 0.15) * magnitude;
        // color += lCookTorranceSpecular(ldir, -marcher.direction, normal, 1.0, 3.25) * 1.5;
    }
    */

    gl_FragColor = vec4(color, 1.0);
}