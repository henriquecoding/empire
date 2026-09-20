shader_type canvas_item;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float light = max(tint.r, max(tint.g, tint.b));
	// A painted dark pixel must not multiply the night into unreadable black.
	// The same warm silhouette survives across materials; lamps reveal native colour.
	float reveal = smoothstep(0.12, 0.55, light);
	vec3 silhouette = vec3(16.0, 13.0, 9.0) / 255.0;
	COLOR = vec4(mix(silhouette, src.rgb * tint.rgb, reveal), src.a * tint.a);
}
