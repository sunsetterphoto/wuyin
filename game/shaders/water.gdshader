// Water of the diorama: the region's water texture drifting in two layers,
// pixel-snapped so it stays crisp, with slowly moving sparkles and a soft
// specular glint. Still (silent) water passes flow = 0.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float flow = 1.0;
uniform float texels_per_unit = 32.0;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	p = floor(p * texels_per_unit) / texels_per_unit;
	float t = floor(TIME * 6.0) / 6.0 * flow;
	vec2 uv1 = p * 0.5 + vec2(t * 0.03, t * 0.012);
	vec2 uv2 = p * 0.5 * 0.83 + vec2(-t * 0.02, t * 0.027) + vec2(0.37, 0.11);
	vec3 a = texture(tex, uv1).rgb;
	vec3 b = texture(tex, uv2).rgb;
	vec3 c = mix(a, b, 0.45);
	float sparkle = step(0.985, fract(sin(dot(floor(p * 8.0) + floor(t * 0.5), vec2(12.9898, 78.233))) * 43758.5453));
	ALBEDO = c * tint + vec3(sparkle * 0.35 * flow);
	ROUGHNESS = 0.18;
	METALLIC = 0.0;
	SPECULAR = 0.7;
}
