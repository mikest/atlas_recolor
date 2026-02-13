shader_type spatial;
render_mode depth_prepass_alpha;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform sampler2D background : source_color, hint_default_transparent;
uniform vec4[8*2] row1: source_color;
uniform vec4[8*2] row2: source_color;
uniform vec4[8*2] row3: source_color;
uniform vec4[8*2] row4: source_color;

vec4 mask_color(vec4 light, vec4 dark, vec2 uv, float posx, float posy, float width, float height) {
	float position = smoothstep(posy * height, (posy + 1.) * height, uv.y);
	vec4 grad = mix(light, dark, position);
	vec4 sampled = texture(background, uv);
	vec4 combined = vec4(0.);
	
	float minx = posx * width;
	float maxx = (posx+1.) * width;
	float miny = posy * height;
	float maxy = (posy+1.) * height;
	
	if( uv.x >= minx && uv.x <= maxx &&
		uv.y >= miny && uv.y <= maxy )
		combined = mix(sampled, grad, grad.a);
	
	return combined;
}

void fragment() {
	vec2 size = vec2(1./8., 1./4.);
	ALBEDO = vec3(0.);
	ALPHA = 0.;
	
	vec4 color = vec4(0.);
	for(int col=0; col<8; col++) {
		color += mask_color(row1[col*2], row1[col*2+1], UV, float(col), 0., size.x, size.y);
		color += mask_color(row2[col*2], row2[col*2+1], UV, float(col), 1., size.x, size.y);
		color += mask_color(row3[col*2], row3[col*2+1], UV, float(col), 2., size.x, size.y);
		color += mask_color(row4[col*2], row4[col*2+1], UV, float(col), 3., size.x, size.y);
	}
	ALBEDO = color.rgb;
	ALPHA = color.a;
}