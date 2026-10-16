shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(1.0);
uniform bool autumn = false;
uniform bool frost = false;
uniform bool aurora = false;
uniform bool warm_lights = false;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	vec3 base = original.rgb;
	bool leaf = base.g > base.r * 1.1 && base.g > base.b * 1.1;
	if (autumn && leaf) {
		base = vec3(base.g * 1.14, base.g * 0.72, base.b * 0.58);
	}
	if (frost && leaf) {
		base = mix(base, vec3(0.75, 0.84, 0.82), 0.52);
	}
	vec3 painted = base * tint.rgb;
	if (warm_lights && original.r > 0.7 && original.g > 0.4 && original.b < 0.45) {
		painted = mix(painted, original.rgb, 0.65);
	}
	if (aurora) {
		vec2 pixel = floor(UV * vec2(320.0, 180.0));
		float band = abs(pixel.y - 42.0 - floor(sin(pixel.x * 0.024) * 10.0));
		if (band < 4.0) {
			painted = mix(painted, vec3(0.31, 0.62, 0.54), 0.55);
		}
	}
	COLOR = vec4(painted, step(0.5, original.a));
}
