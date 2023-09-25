shader_type spatial;
render_mode blend_mix;
//render_mode unshaded;
render_mode cull_disabled;

uniform vec4 mainColor : source_color = vec4(1.0);
uniform vec4 rootColor : source_color = vec4(1.0);
uniform vec4 subsurfColor : source_color = vec4(0.0, 0.0, 0.0, 1.0);
//uniform vec4 mainColor = hint_color = vec4(1.0);
uniform sampler2D albedoTex;
uniform sampler2D noiseText;
uniform float pinch=0.0;


// grass interactivity:
uniform vec3 playerPosition = vec3(10000000.0); //default is a large value so that if a potiion is not sent, the default is unlikely to appear on this object.
uniform float interactionStrength = 0.1;
uniform float radius = 1.0;


varying vec2 tex_position;
void vertex(){
	// from: https://github.com/Arnklit/TutorialResources/blob/main/grass_interact/grass.shader 
	// licensed as CC0: https://github.com/Arnklit/TutorialResources/blob/main/LICENSE
	vec3 world_vert = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; // model space to world space
	vec3 direction = world_vert - playerPosition;
	direction.y = 0.0;
	direction = normalize(direction);
	float dist = distance(playerPosition, world_vert);
	float power = smoothstep(radius, 0.0, dist);
	direction = (vec4(direction, 1.0) * MODEL_MATRIX).xyz; // world space direction to model space
	VERTEX += direction * power * interactionStrength * (1.0 - UV.y);
	// end copied segment
	
	
	// for offset randomiation, combine x and y, and use a small digit of their position as the modulo value
	float texOffset = 0.25*float(mod(floor((NODE_POSITION_WORLD.x+NODE_POSITION_WORLD.y)*100000.0),4.0));
	tex_position = UV.xy+vec2(texOffset,0);
	
	//pinches the grass tips
	VERTEX.x = VERTEX.x*(1.0-(pinch*VERTEX.y));
}

void fragment() {
	vec4 gradColor = mainColor*(1.0-UV.y) + rootColor*(UV.y);
	ALBEDO.rgb = texture(albedoTex, tex_position).rgb * gradColor.rgb;
	ALPHA = clamp(texture(albedoTex, tex_position).a -(tex_position.y*tex_position.y*tex_position.y), 0, 1);
	
}

void light(){
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * ALBEDO *LIGHT_COLOR;
	DIFFUSE_LIGHT += clamp(dot(-1.0*NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * (subsurfColor.rgb*subsurfColor.a)*clamp(dot(LIGHT_COLOR,subsurfColor.rgb),0.0,1.0); //backface color
}


