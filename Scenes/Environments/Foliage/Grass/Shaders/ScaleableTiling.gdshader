shader_type spatial;
render_mode blend_mix;

uniform vec4 mainColor : source_color = vec4(1.0);
uniform sampler2D albedoTex;
uniform float uvScale = 1.0;



varying vec2 tex_position;
void vertex(){
	tex_position = UV.xy * uvScale;
}

void fragment() {
	ALBEDO.rgb = mainColor.rgb*texture(albedoTex, tex_position).rgb;
}

void light(){
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * ALBEDO *LIGHT_COLOR;
}