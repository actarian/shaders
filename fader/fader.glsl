precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

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

uniform sampler2D u_texture_3;
uniform sampler2D u_texture_4;

void main() {
    vec3 color = vec3(0.0);    
    
    float r = texture2D(u_texture_4, uv).r;
    color = mix(color, texture2D(u_texture_3, uv).rgb, r);

    /*
    fixed4 colorMultiply = IN.color; colorMultiply.a = 1;
    fixed4 c = SampleSpriteTexture(IN.texcoord) * colorMultiply;
    fixed4 fadeInColor = tex2D(_FadeInTex, IN.fadeincoord);
    float fadeInBrightness = fadeInColor.r;
    float lerpLevel = clamp(0,1,(IN.color.a - fadeInBrightness) / _Softness);
    c.a = lerp(0, c.a, lerpLevel);
    c.rgb *= c.a;
    */

    gl_FragColor = vec4(color, 1.0);
}