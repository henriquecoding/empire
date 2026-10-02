// shaders/flash_white.gdshader — o flash branco de um golpe, com a forma do sprite (§24).
//
// Pinta de branco o que o sprite tem de opaco, e mais nada: a transparencia do
// contorno fica, e por isso o flash e o corpo e nao um rectangulo por cima dele.
// O alfa do vertice e quanto do flash ainda resta (CombatFx.flash).
shader_type canvas_item;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	COLOR = vec4(1.0, 1.0, 1.0, src.a * COLOR.a);
}
