// shaders/accessibility.gdshader — contraste e daltonismo, por cima do mundo (§26).
//
// Um filtro de ecra: le o que o mundo ja desenhou e devolve-o com duas contas.
// As contas NAO estao aqui: as matrizes vem do AccessibilityFilter como
// uniforms, e e la que estao escritas e testadas. Um shader com os numeros dele
// e um GDScript com os mesmos numeros eram duas verdades.
//
// Sem modo e com contraste 1, o no esta escondido e este shader nao corre.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_nearest;
// Como um olho com esta deficiencia ve a cor (Machado et al., 2009).
uniform mat3 simulacao = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, 1.0));
// Para onde se leva o que ele nao ve (Fidaner et al., 2005). Zero e "sem modo".
uniform mat3 correcao = mat3(vec3(0.0), vec3(0.0), vec3(0.0));
uniform float contraste = 1.0;

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	vec3 visto = c * simulacao;
	c = clamp(c + (c - visto) * correcao, 0.0, 1.0);
	c = clamp((c - 0.5) * contraste + 0.5, 0.0, 1.0);
	COLOR = vec4(c, 1.0);
}
