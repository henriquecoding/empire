// shaders/world_light.gdshaderinc — a luz que chega a um pixel do cenario (§80, ADR 0048).
//
// O mesmo que o Glow e o Lighting fazem a um corpo, feito aqui a cada pixel: o ambiente
// que o olho ve, mais cada luz que la chega. Uma luz e tres paragens — nucleo, meio,
// bordo — e nunca um gradiente; entre duas paragens, e do bordo para o escuro, a passagem
// e um dither de dois estados (Bayer 4x4) na grelha de 2 px do §80. As contas vivem no
// GDScript (Glow, Lighting, SceneryLight) e la se testam; aqui so se aplicam.
//
// As luzes chegam em px de ECRA (o SceneryLight passa-as pela transformada do canvas),
// porque os planos de parallax andam a velocidades diferentes e a luz tem de cair onde a
// fogueira se ve, e nao onde ela estaria se o monte do fundo fosse o chao. A grelha do
// dither, essa, fica presa ao plano: com a camara a andar, o padrao nao rasteja.

const int MAX_LUZES = 16;

uniform vec3 ambiente = vec3(1.0);
uniform int luzes = 0;
// x, y e raio em px de ecra; w e a forca, ja com o ganho e o escuro da hora.
uniform vec4 onde[MAX_LUZES];
uniform vec3 nucleo[MAX_LUZES];
uniform vec3 meio[MAX_LUZES];
uniform vec3 bordo[MAX_LUZES];
// Quanto as luzes chegam a este plano: 1 no plano de jogo, menos ao fundo (§80 §1).
uniform float alcance = 1.0;
// O pixel do dither em px de mundo, e quantos px de ecra vale um px de mundo.
uniform float luz_celula = 2.0;
uniform float escala = 1.0;
// A fraccao do raio por onde o bordo se dissolve no escuro.
uniform float dissolve = 0.14;
uniform float teto = 1.6;

varying vec2 ecra_luz;
varying vec2 mundo_luz;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

// Um varying so se escreve dentro do vertex(): isto e o que la se poe.
#define LUZ_VERTEX mundo_luz = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; ecra_luz = (CANVAS_MATRIX * vec4(mundo_luz, 0.0, 1.0)).xy;

float luz_limiar(vec2 quadrado) {
	ivec2 i = ivec2(mod(quadrado, 4.0));
	return (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
}

// A luz que chega a este pixel: o ambiente, mais o que as luzes la deixam.
// Chama-se do fragment() com os dois varyings: luz_aqui(ecra_luz, mundo_luz).
vec3 luz_aqui(vec2 ecra, vec2 mundo) {
	vec2 quadrado = floor(mundo / luz_celula);
	vec2 centro = (quadrado + 0.5) * luz_celula;
	vec2 p = ecra + (centro - mundo) * escala;
	float limiar = luz_limiar(quadrado);
	vec3 soma = vec3(0.0);
	for (int i = 0; i < MAX_LUZES; i++) {
		if (i >= luzes) {
			break;
		}
		float raio = onde[i].z;
		float d = distance(p, onde[i].xy);
		float fora = raio * (1.0 + dissolve);
		if (raio <= 0.0 || d > fora) {
			continue;
		}
		vec3 cor = bordo[i];
		if (d > raio) {
			if (limiar < (d - raio) / max(fora - raio, 0.001)) {
				continue;
			}
		} else {
			float terco = raio / 3.0;
			float s = d / terco;
			int k = int(min(floor(s), 2.0));
			float banda = min(1.0, 2.0 * luz_celula * escala / terco);
			float f = s - float(k);
			if (k < 2 && f > 1.0 - banda && limiar < (f - (1.0 - banda)) / banda) {
				k += 1;
			}
			cor = k == 0 ? nucleo[i] : (k == 1 ? meio[i] : bordo[i]);
		}
		soma += cor * onde[i].w;
	}
	return min(ambiente + soma * alcance, vec3(teto));
}
