// Soft round contact shadow under characters, Lingshou and props: grounds the
// flat sprites in the diorama (classic RPG drop shadow, pixel-stepped).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform float strength = 0.38;

void fragment() {
	vec2 d = (UV - 0.5) * 2.0;
	float r = length(d);
	float a = (1.0 - smoothstep(0.55, 1.0, r)) * strength;
	a = floor(a * 6.0) / 6.0;
	ALBEDO = vec3(0.05, 0.04, 0.08);
	ALPHA = a;
}
