precision highp float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform vec2 u_trails[10];

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

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

float sSegment(in vec2 a, in vec2 b) {
    vec2 ba = a - b;
    float d = clamp(dot(a, ba) / dot(ba, ba), 0.0, 1.0);
    return length(a - ba * d) * 2.0;
}
float segment(in vec2 a, in vec2 b, float t) {
    float d = sSegment(a, b);
    return stroke(d, t);
}

float ripple(vec2 p, float r) {
    vec2 dx = st - mx - p;
    float t = u_time * 2.0 + r * 0.02;
	float s = p.x * p.x * (1.0 - dx.x) + p.y * p.y * (1.0 - dx.y);
    s /= rx * 10.0;
    float z = sin((t - s) * 4.0);	
    float c = 1.0 - smoothstep(0.0, r * rx, length(p) * 2.0);
    return clamp(mix(0.0, z, c), 0.0, 1.0);
}

void main() {
    vec3 color = vec3(0.04);
    vec3 colorB = vec3(0.7);
    float radius = 50.0;
    /*
    for (int i = 0; i < 10; i++) {
        float pow = ripple(st - coord(u_trails[i]), radius * float(10 - i));
        color = mix(color, colorB, pow);
    }
    */
    for (int i = 1; i < 10; i++) {
        vec2 a = st - coord(u_trails[i]);
        vec2 b = st - coord(u_trails[i - 1]);
        float d = segment(a, b, 0.1 / float(i) * distance(a, b));
        color = mix(color, colorB, d);
    }
    gl_FragColor = vec4(color, 1.0);
}

/*

ST -> https://www.shadertoy.com/view/Msy3D1

BUFFER A

// Riffing off tomkh's wave equation solver
// https://www.shadertoy.com/view/Xsd3DB
// article: http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
// 1-buffer version: https://www.shadertoy.com/view/4dK3Ww
// 1-buffer with half res sim to maintain wave speed: https://www.shadertoy.com/view/4dK3Ww

#define HEIGHTMAPSCALE 90.0

vec3 computePixelRay( in vec2 p, out vec3 cameraPos );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 e = vec3(vec2(1.)/iResolution.xy,0.);
    vec2 q = fragCoord.xy/iResolution.xy;

    vec4 c = textureLod(iChannel0, q, 0.);

    float p11 = c.x;

    float p10 = textureLod(iChannel1, q-e.zy, 0.).x;
    float p01 = textureLod(iChannel1, q-e.xz, 0.).x;
    float p21 = textureLod(iChannel1, q+e.xz, 0.).x;
    float p12 = textureLod(iChannel1, q+e.zy, 0.).x;

    float d = 0.;

    if( iMouse.z > 0. )
    {
        vec3 ro;
        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
        if( rd.y < 0. )
        {
            vec3 mp = ro + rd * ro.y/-rd.y;
            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
            float screenscale = iResolution.x/640.;
            d += .02*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
        }
    }

    // The actual propagation:
    d += -(p11-.5)*2. + (p10 + p01 + p21 + p12 - 2.);
    d *= .99; // damping
    d *= step(.1, iTime); // hacky way of clearing the buffer
    d = d*.5 + .5;

    fragColor = vec4(d, 0, 0, 0);
}

vec3 computePixelRay( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
	
    float camRadius = 60.;
	float theta = -3.141592653/2.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,20.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,0.);
     
    // camera frame
    vec3 fo = normalize(target-cameraPos);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .5;
	
    // ray direction
    vec3 rayDir = normalize(fo + fov*p.x*ri + fov*p.y*up);
	
	return rayDir;
}

// i tried to refactor the above into an explicit solve of the wave equation, which is correct
// for spatial sampling and temporal sampling, but the result was plagued with instabilities.
// i guess the stability happens when the wave speed exceeds the maximum rate of propagation of
// information (1 pixel per frame)? (theres a formal definition for this but the name eludes me
// right now)
// UPDATE i think the stabilities are normal for this resolution and time step, and the below
// is probably correct. its all about the CFL condition: https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition
//float hx = HEIGHTMAPSCALE / iResolution.x;
//float hy = HEIGHTMAPSCALE / iResolution.y;
//void mainImage( out vec4 fragColor, in vec2 fragCoord )
//{
//    vec2 q = fragCoord.xy/iResolution.xy;
//
//    // unpack nearby heights from texture
//    float p11		= texture(iChannel1, q).x;
//    float p11_prev	= texture(iChannel0, q).x;
//    float p10		= texture(iChannel1, q-dd.zy).x;
//    float p01		= texture(iChannel1, q-dd.xz).x;
//    float p21		= texture(iChannel1, q+dd.xz).x;
//    float p12		= texture(iChannel1, q+dd.zy).x;
//
//    // the force (or accel)
//    float d = 0.;
//
//    if( iMouse.z > 0. )
//    {
//        vec3 ro;
//        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
//        if( rd.y < 0. )
//        {
//            vec3 mp = ro + rd * ro.y/-rd.y;
//            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
//            float screenscale = iResolution.x/640.;
//            d += 30.*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
//        }
//    }
//
//    float dt = 1./60.;
//    
//	  // discrete laplacian
//    float L = (p01 + p21 - 2.0 * p11) / (hx*hx)
//        + (p10 + p12 - 2.0 * p11) / (hy*hy);
//    
//    // wave speed
//    float c = 4.25;
//    // wave equation
//    d += c*c*L;
//    // hacky way of clearing the buffer
//    d *= step(0.01, iTime);
//    
//    // prev vel - i guess this is a form of position based dynamics (PBD). i think this only
//    // works because shadertoy maintains a copy of of the target we're writing to
//    float v = (p11 - p11_prev) / dt; // technically, this is the wrong dt - should use prev dt
//    // integrate accel
//    v += d * dt;
//    // new height
//    float p_new = p11 + v * dt;
//    
//    // damping
//    p_new *= .99;
//    
//    fragColor = vec4(p_new, -v, 0., 0.);
//}

*/

/*
BUFFER B

// Riffing off tomkh's wave equation solver
// https://www.shadertoy.com/view/Xsd3DB
// article: http://freespace.virgin.net/hugo.elias/graphics/x_water.htm
// 1-buffer version: https://www.shadertoy.com/view/4dK3Ww
// 1-buffer with half res sim to maintain wave speed: https://www.shadertoy.com/view/4dK3Ww

#define HEIGHTMAPSCALE 90.0

vec3 computePixelRay( in vec2 p, out vec3 cameraPos );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 e = vec3(vec2(1.)/iResolution.xy,0.);
    vec2 q = fragCoord.xy/iResolution.xy;

    vec4 c = textureLod(iChannel0, q, 0.);

    float p11 = c.x;

    float p10 = textureLod(iChannel1, q-e.zy, 0.).x;
    float p01 = textureLod(iChannel1, q-e.xz, 0.).x;
    float p21 = textureLod(iChannel1, q+e.xz, 0.).x;
    float p12 = textureLod(iChannel1, q+e.zy, 0.).x;

    float d = 0.;

    if( iMouse.z > 0. )
    {
        vec3 ro;
        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
        if( rd.y < 0. )
        {
            vec3 mp = ro + rd * ro.y/-rd.y;
            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
            float screenscale = iResolution.x/640.;
            d += .02*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
        }
    }

    // The actual propagation:
    d += -(p11-.5)*2. + (p10 + p01 + p21 + p12 - 2.);
    d *= .99; // damping
    d *= step(.1, iTime); // hacky way of clearing the buffer
    d = d*.5 + .5;

    fragColor = vec4(d, 0, 0, 0);
}

vec3 computePixelRay( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
	
    float camRadius = 60.;
	float theta = -3.141592653/2.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,20.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,0.);
     
    // camera frame
    vec3 fo = normalize(target-cameraPos);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .5;
	
    // ray direction
    vec3 rayDir = normalize(fo + fov*p.x*ri + fov*p.y*up);
	
	return rayDir;
}


// i tried to refactor the above into an explicit solve of the wave equation, which is correct
// for spatial sampling and temporal sampling, but the result was plagued with instabilities.
// i guess the stability happens when the wave speed exceeds the maximum rate of propagation of
// information (1 pixel per frame)? (theres a formal definition for this but the name eludes me
// right now)
// UPDATE i think the stabilities are normal for this resolution and time step, and the below
// is probably correct. its all about the CFL condition: https://en.wikipedia.org/wiki/Courant%E2%80%93Friedrichs%E2%80%93Lewy_condition
//float hx = HEIGHTMAPSCALE / iResolution.x;
//float hy = HEIGHTMAPSCALE / iResolution.y;
//void mainImage( out vec4 fragColor, in vec2 fragCoord )
//{
//    vec2 q = fragCoord.xy/iResolution.xy;
//
//    // unpack nearby heights from texture
//    float p11		= texture(iChannel1, q).x;
//    float p11_prev	= texture(iChannel0, q).x;
//    float p10		= texture(iChannel1, q-dd.zy).x;
//    float p01		= texture(iChannel1, q-dd.xz).x;
//    float p21		= texture(iChannel1, q+dd.xz).x;
//    float p12		= texture(iChannel1, q+dd.zy).x;
//
//    // the force (or accel)
//    float d = 0.;
//
//    if( iMouse.z > 0. )
//    {
//        vec3 ro;
//        vec3 rd = computePixelRay( 2.*iMouse.xy/iResolution.xy - 1., ro );
//        if( rd.y < 0. )
//        {
//            vec3 mp = ro + rd * ro.y/-rd.y;
//            vec2 uv = mp.xz/HEIGHTMAPSCALE + 0.5;
//            float screenscale = iResolution.x/640.;
//            d += 30.*smoothstep(20.*screenscale,5.*screenscale,length(uv*iResolution.xy - fragCoord.xy));
//        }
//    }
//
//    float dt = 1./60.;
//    
//	  // discrete laplacian
//    float L = (p01 + p21 - 2.0 * p11) / (hx*hx)
//        + (p10 + p12 - 2.0 * p11) / (hy*hy);
//    
//    // wave speed
//    float c = 4.25;
//    // wave equation
//    d += c*c*L;
//    // hacky way of clearing the buffer
//    d *= step(0.01, iTime);
//    
//    // prev vel - i guess this is a form of position based dynamics (PBD). i think this only
//    // works because shadertoy maintains a copy of of the target we're writing to
//    float v = (p11 - p11_prev) / dt; // technically, this is the wrong dt - should use prev dt
//    // integrate accel
//    v += d * dt;
//    // new height
//    float p_new = p11 + v * dt;
//    
//    // damping
//    p_new *= .99;
//    
//    fragColor = vec4(p_new, -v, 0., 0.);
//}

*/

/*
IMAGE

// riffing off tomkh's wave equation solver: https://www.shadertoy.com/view/Xsd3DB

// i spent some time experimenting with different ways to speed up the raymarch.
// at one point i even slowed down the ray march steps around the mouse, as this was
// where the sharpest/highest peaks tend to be, which kind of worked but was complicated.
// in the end the best i could do was to boost the step size by 20% and after
// iterating, shade the point whether it converged or not, which gives plausible
// results. some intersections will be missed completely, for the current settings
// its not super noticeable. to fix divergence at steep surfaces facing
// the viewer, i used the hybrid sphere march from https://www.shadertoy.com/view/Mdj3W3
// which, at surface crossings, uses a first order interpolation to estimate the
// intersection point.

// i think the best and most robust way to speed up the raymarch would be to downsample
// the height texture, where each downsample computes the max of an e.g. 4x4 neighborhood,
// and then raymarch against this instead, using the full resolution texture to compute
// exact intersections.

#define RAYMARCH
#define HEIGHTMAPSCALE 90.
#define MARCHSTEPS 25


vec3 computePixelRay( in vec2 p, out vec3 cameraPos );

float h( vec3 p ) { return 4.*textureLod(iChannel0, p.xz/HEIGHTMAPSCALE + 0.5, 0. ).x; }
float DE( vec3 p ) { return 1.2*( p.y - h(p) ); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy/iResolution.xy;
    vec2 qq = q*2.-1.;
    float eps = 0.1;
    
#ifdef RAYMARCH
    
    vec3 L = normalize(vec3(.3,.5,1.));
    
    // raymarch the milk surface
    vec3 ro;
    vec3 rd = computePixelRay( qq, ro );
    float t = 0.;
    float d = DE(ro+t*rd);
    
    for( int i = 0; i < MARCHSTEPS; i++ )
    {
        if( abs(d) < eps )
            break;
        
        float dNext = DE(ro+(t+d)*rd);
        
        // detect surface crossing
        // https://www.shadertoy.com/view/Mdj3W3
		float dNext_over_d = dNext/d;
        if( dNext_over_d < 0.0 )
        {
            // estimate position of crossing
			d /= 1.0 - dNext_over_d;
			dNext = DE( ro+rd*(t+d) );
        }
        
		t += d;
		d = dNext;
    }
    
    float znear = 95.;
    float zfar  = 130.;
    
    // hit the milk
    if( t < zfar )
    //if( d < eps ) // just assume always hit, turns out its hard to see error from this
    {
        vec3 p = ro+t*rd;
        
	    fragColor = vec4( textureLod(iChannel0, p.xz/HEIGHTMAPSCALE+0.5, 0. ).x );
        
        // finite difference normal
        float h0 = h(p);
        vec2 dd = vec2(0.01,0.);
        vec3 n = normalize(vec3( h0-h(p + dd.xyy), dd.x, h0-h(p + dd.yyx) ));
        
        // improvised milk shader, apologies for hacks!
        vec3 R = reflect( rd, n );
        float s = .4*pow( clamp( dot( L, R ), 0., 1. ), 4000. );
        float ndotL = clamp(dot(n,L),0.,1.);
        float dif = 1.42*(0.8+0.2*ndotL);

        // occlude valleys a little and boost peaks which gives a bit of an SSS look
        float ao = mix( 0.8, .99, smoothstep(0.,1.,(h0+1.5)/6.));

        // milk it up
        vec3 difCol = vec3(0.82,0.82,0.79);
        fragColor.xyz = difCol*(dif)*ao + vec3(1.,.79,0.74)*s;
        
        // for bonus points, emulate an anisotropic phase function by creaming up the region
        // between lit and unlit
        float creamAmt = smoothstep( 0.2, 0., abs(ndotL - 0.2) );
        fragColor.xyz *= mix( vec3(1.), vec3(1.,0.985,0.975), creamAmt );
    }
    
    // fade to background
    vec3 bg = vec3(0.5) + 0.5*pow(clamp(dot(L,rd),0.,1.),20.);
    bg *= vec2(1.,0.97).yxx;
    fragColor.xyz = mix( fragColor.xyz, bg, smoothstep(znear,zfar,t) );
    
	// vignette (borrowed from donfabio's Blue Spiral)
	vec2 uv =  q.xy-0.5;
	float distSqr = dot(uv, uv);
	fragColor.xyz *= 1.0 - .5*distSqr;
    
#else
    float sh = 1. - texture(iChannel0, q).x;
    vec3 c =
       vec3(exp(pow(sh-.25,2.)*-5.),
            exp(pow(sh-.4,2.)*-5.),
            exp(pow(sh-.7,2.)*-20.));
    fragColor = vec4(c,1.);
#endif
}

vec3 computePixelRay( in vec2 p, out vec3 cameraPos )
{
    // camera orbits around origin
	
    float camRadius = 60.;
	float theta = -3.141592653/2.;
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    cameraPos = vec3(xoff,20.,zoff);
     
    // camera target
    vec3 target = vec3(0.,0.,0.);
     
    // camera frame
    vec3 fo = normalize(target-cameraPos);
    vec3 ri = normalize(vec3(fo.z, 0., -fo.x ));
    vec3 up = normalize(cross(fo,ri));
     
    // multiplier to emulate a fov control
    float fov = .5;
	
    // ray direction
    vec3 rayDir = normalize(fo + fov*p.x*ri + fov*p.y*up);
	
	return rayDir;
}

*/