// Battle transition: the screen fills with growing pixel diamonds (classic RPG wipe).
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float cell = 48.0;
uniform vec4 color : source_color = vec4(0.06, 0.05, 0.09, 1.0);

void fragment() {
	vec2 p = FRAGCOORD.xy / cell;
	vec2 f = abs(fract(p) - 0.5);
	float d = f.x + f.y;
	float delay = (sin(floor(p.x) * 0.7 + floor(p.y) * 1.3) * 0.5 + 0.5) * 0.25;
	float t = clamp((progress - delay) / 0.75, 0.0, 1.0);
	COLOR = color;
	COLOR.a = step(d, t * 1.05);
}
