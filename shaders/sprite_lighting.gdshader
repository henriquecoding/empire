// shaders/sprite_lighting.gdshader — um sprite com a luz que lhe chega (§80, ADR 0048).
//
// A cor do vertice e a LUZ no sitio do corpo (Lighting.on): o ambiente que o olho ve e
// as luzes que la chegam. Perto de uma luz ve-se a cor do sprite com ela; longe, a
// silhueta quente do §80 — um valor so, igual para toda a gente, porque um pixel pintado
// de escuro multiplicado pela noite dava um preto que nao se lia.
//
// Os limiares sao os da noite que se ve (ADR 0048): com so o ambiente da noite (0,42) o
// sprite fica a meio caminho — ve-se a forma e um pouco da cor —, e a borda de qualquer
// fogueira ja chega para o revelar todo. Ao crepusculo (0,73) ja nao ha silhueta.
shader_type canvas_item;
render_mode unshaded;
#include "res://shaders/world_light.gdshaderinc"

varying vec4 tint;

const vec3 SILHUETA = vec3(16.0, 13.0, 9.0) / 255.0;
const float REVELA_DE = 0.15;
const float REVELA_ATE = 0.7;

void vertex() {
	tint = COLOR;
	mundo_luz = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float light = max(tint.r, max(tint.g, tint.b));
	float reveal = smoothstep(REVELA_DE, REVELA_ATE, light);
	vec3 illumination = tint.rgb;
	if (luzes > 0 && reveal > 0.0 && src.a > 0.0) {
		vec3 surface = texture(NORMAL_TEXTURE, UV).rgb;
		// The default normal texture has B=255. The packed atlas reserves it too.
		if (surface.b < 1.0) {
			vec2 xy = surface.rg * 2.0 - 1.0;
			xy = mix(xy, vec2(0.0), lessThan(abs(xy), vec2(0.004)));
			vec3 normal = normalize(vec3(xy.x, -xy.y, sqrt(max(0.0, 1.0 - dot(xy, xy)))));
			illumination = luz_surface(mundo_luz, mundo_luz, normal, surface.b * 255.0 / 254.0);
		}
	}
	COLOR = vec4(mix(SILHUETA, src.rgb * illumination, reveal), src.a * tint.a);
}
