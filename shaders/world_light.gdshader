// shaders/world_light.gdshader — o cenario com a luz que lhe chega (§80, ADR 0048).
//
// Substitui o `modulate` com a cor da fase que cada plano do cenario levava: esse
// multiplicava o plano inteiro pela mesma cor, e uma fogueira nao alumiava o chao a volta
// dela. Agora cada pixel leva o ambiente que o olho ve e as luzes que la chegam
// (world_light.gdshaderinc). A cor do que se desenha nao muda: muda a luz.
shader_type canvas_item;
render_mode unshaded;

#include "res://shaders/world_light.gdshaderinc"

void vertex() {
	LUZ_VERTEX
}

void fragment() {
	vec4 cor = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(cor.rgb * luz_aqui(ecra_luz, mundo_luz), cor.a);
}
