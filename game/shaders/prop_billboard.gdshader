// Pixel-art props in the 3D diorama (trees, bushes, flowers, village things):
// a quad that turns around the Y axis to face the camera, swaying in the wind
// (more at the top than at the foot), crisp pixels, alpha cut.
// INSTANCE_CUSTOM.x = wind phase (0..1), .y = sway factor of this instance.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D tex : source_color, filter_nearest;
uniform float sway = 0.0;
uniform float alpha_cut = 0.5;
uniform float emission = 0.0;
uniform vec3 emission_color : source_color = vec3(1.0, 0.7, 0.35);

void vertex() {
	float top = 1.0 - UV.y;
	float phase = INSTANCE_CUSTOM.x * 6.2831;
	float w = sin(TIME * 1.6 + phase) * 0.6 + sin(TIME * 0.7 + phase * 1.7) * 0.4;
	VERTEX.x += w * sway * INSTANCE_CUSTOM.y * top * top;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < alpha_cut) {
		discard;
	}
	ALBEDO = c.rgb * COLOR.rgb;
	EMISSION = emission_color * emission * c.rgb;
	ROUGHNESS = 1.0;
}
