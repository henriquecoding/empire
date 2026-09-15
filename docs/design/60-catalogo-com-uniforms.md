# 60 — Shaders · Catálogo, com uniforms

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

| Shader | Uniforms | Aplicado a | Fase |
| --- | --- | --- | --- |
| palette_lut | lut: Texture2D, mix: float | Todos os sprites de jogo. Faz hora do dia, variante de povo, encantamento e estado — um shader, quatro trabalhos. | 0 |
| dither_reveal | progress: float, matrix: Texture2D | Cavidades a abrir no corte de solo | 3 |
| outline_dilate | width: int, color: vec4 | Silhueta de cenário → 2 px sem redesenhar (§01) | 1 |
| dissolve | progress: float, edge_color: vec4 | Podridão a espalhar-se, morte de unidades | 1 |
| water_ripple | amp: float, speed: float | Lago do castelo, portos, pesqueiros | 2 |
| fake_fog | density: float, tint: vec4 | Cavidades, crepúsculo | 3 |
| blind_vignette | closure: float | Cavaleiro Selado sem montaria | 6 |
| normal_palette_light | palette: Texture2D, ramp: Texture2D, palette_size: int, normal_mod: float | Só objetos-herói: núcleo, castelo, muralhas, forja. Nunca 300 unidades. | 5+ |


> **A armadilha, e o que a resolve**
>
> PointLight2D não respeita o filtro Nearest em normal maps e sombras — os pixels ficam suaves à volta das luzes, o que destrói tudo. A solução é normal_palette_light: codifica o índice de paleta num canal e o brilho da normal noutro, e descodifica através de uma textura de gradiente, para a cor iluminada cair sempre numa cor da paleta. Testa isto na Fase 0 com um spike de duas horas, não na Fase 5.
