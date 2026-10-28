// Foam where water meets the shore: a pixel-stepped white line that breathes
// in and out with the waves.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = floor(TIME * 5.0) / 5.0;
	float wave = sin(t * 1.3 + world_pos.x * 2.1 + world_pos.z * 1.7) * 0.5 + 0.5;
	float band = step(UV.y, 0.35 + wave * 0.45);
	float dots = step(0.55, fract(sin(dot(floor(world_pos.xz * 16.0), vec2(12.9898, 78.233))) * 43758.5453));
	ALBEDO = vec3(0.92, 0.97, 1.0);
	ALPHA = band * (0.55 + dots * 0.35);
}
