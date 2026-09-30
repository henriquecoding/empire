// shaders/dither_reveal.gdshader — a terra dissolve-se e revela o corte de solo (§11, §60).
//
// O catalogo da §60 da-lhe dois uniforms, e sao estes: `progress` (0 tapado, 1 aberto) e
// `matrix`, a matriz de Bayer que diz a ordem em que cada quadrado se vai. A matriz e os
// limiares estao no SoilReveal, e e la que se testam; aqui so se compara.
//
// O quadrado esta preso ao MUNDO e nao ao ecra: com a camara a andar a meio da
// dissolucao, o padrao fica onde esta em vez de rastejar pela terra.
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D matrix : filter_nearest, repeat_enable;

// Um quadrado do dither, em px de mundo: um pixel da arte a escala 2 (§80: "dither de 2 px").
const float QUADRADO = 2.0;

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 lado = vec2(textureSize(matrix, 0));
	vec2 celula = mod(floor(mundo / QUADRADO), lado);
	if (texture(matrix, (celula + 0.5) / lado).r < progress) {
		discard;
	}
}
