// shaders/palette_lut.gdshader — um shader, quatro trabalhos (§22 degrau 3, §60).
//
// A hora do dia, a variante de povo, o encantamento do bardo e o estado da
// unidade sao o MESMO efeito: passar a cor por uma rampa. Muda a rampa e a
// quantidade, nao o shader. E por isso que o catalogo da §60 lhe da dois
// uniforms e nao oito — e sao estes dois, com estes nomes.
//
// A rampa e 1D e indexa-se pela luminancia. Sem rampa ligada, mix fica a zero e
// o sprite sai como entrou: o shader nunca e um requisito para ver arte.
// A rampa em si e do ART-02; este ficheiro e so o mecanismo.
shader_type canvas_item;

uniform sampler2D lut : filter_nearest, repeat_disable, source_color;
uniform float mix : hint_range(0.0, 1.0) = 0.0;

// Coeficientes de luminancia perceptual (Rec. 601). Nao sao afinacao: sao a
// definicao de "quao clara e esta cor".
const vec3 LUMA = vec3(0.299, 0.587, 0.114);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float l = clamp(dot(src.rgb, LUMA), 0.0, 1.0);
	vec3 graded = texture(lut, vec2(l, 0.5)).rgb;

	// Interpolacao escrita a mao de proposito: chamar mix() com um uniform
	// chamado `mix` no mesmo ambito compila, mas ninguem quer ler isso.
	vec3 saida = src.rgb + (graded - src.rgb) * mix;

	// A transparencia nunca passa pela rampa: um pixel vazio tem de continuar
	// vazio, senao o contorno do sprite ganha halo a noite.
	COLOR = vec4(saida, src.a) * COLOR;
}
