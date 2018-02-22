#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;  

float Band(float t, float start, float end, float blur){
    float step1 = smoothstep(start - blur, start + blur, t);
    float step2 = smoothstep(end + blur, end - blur, t);
    float band = step1 * step2;
    return band;
}

float remap01(float a, float b, float t) {
    return (t - a) / (b - a);
}

float remap(float a, float b, float c, float d, float t) {
    return remap01(a, b, t) * (d - c) + c;
}

float Rect(vec2 uv, float left, float right, float bottom, float top, float blur){
    float band1 = Band(uv.x, left, right, blur);
    float band2 = Band(uv.y, bottom, top, blur);
    float rect = band1 * band2;
    
    return rect;
}

void main(){
	vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv -= 0.5;
    
    float t = 1.5 + u_time * 3.0;

    float x = uv.x;
    float magic = sin(t + x * 8.) * 0.1;
    float y = uv.y - magic;
    
    // x += x * sin(iTime * 7.) * 0.2;
    // 1x += y * cos(iTime * 7.) * 0.2;
    // y += x * cos(iTime * 7.) * 0.2;
        
    y += y - magic;
    
    // float band = Band(x, -0.2, 0.2, 0.001);
    // float band2 = Band(y, -0.2, 0.2, 0.001);
    // float rect = band * band2;
    
    float blur = remap(0.5, -0.5, 0.001, 0.5, x);
    blur = pow(blur * 2.5, 2.5);
    
    float rect = Rect(vec2(x, y), -0.5, 0.5, -0.05, 0.05, blur);
      
    
    vec4 baseColor = vec4(0.4 + sin(u_time * 0.6 + x * y) , 0.2, 0.9, 1.0);
    
    vec3 col = vec3(0.9, 0.8, 0.2) * vec3(rect);
    
    float rect2 = Rect(vec2(x, y), -0.3, 0.5, -0.02, 0.0, blur);
    
    vec3 col2 = vec3(0.2, 0.8, 0.8) * vec3(rect);
    
	gl_FragColor = vec4(vec3(col2 + col),1.0) + baseColor;
    
}


