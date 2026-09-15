# 26 — Acessibilidade · novo · Acessibilidade e Steam Deck Verified

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Em janeiro de 2026 o Steam atualizou as etiquetas de acessibilidade e os programadores já preencheram o questionário para mais de 22 000 jogos. É agora um campo visível na loja — e é uma das poucas melhorias que aumenta o público sem custar design.

## Steam Deck Verified — os critérios reais

| Categoria | Critério | O teu estado |
| --- | --- | --- |
| Entrada | A configuração de comando por omissão dá acesso a todo o conteúdo | Resolvido por design — dois verbos (§24) |
| Entrada | Os glifos no ecrã correspondem ao dispositivo ativo | Implementar: trocar atlas de ícones por Input.get_joy_name |
| Entrada | Texto usa a API de entrada do Steamworks ou teclado próprio navegável | Só o nome do save — usa a API |
| Ecrã | Corre a 1280×800 ou 1280×720 | 1280×720 nativo. Perfeito. |
| Ecrã | Nenhum carácter abaixo de 9 px de altura a 1280×800; recomendado 12 px | Risco real — a tua fonte de pixel art tem de ser ≥ 12 px |
| Continuidade | Sem avisos de incompatibilidade; launcher navegável por comando | Sem launcher. Resolvido. |
| Desempenho | Jogável nas definições por omissão — 30 fps a 800p | Trivial para 2D; confirma com 300 unidades |
| Sistema | Sem incompatibilidades de Proton | Godot exporta Linux nativo. Testa cedo. |


> **O único risco de Verified que tens**
>
> O tamanho de texto. Uma fonte de pixel art a 8 px é linda e reprova a certificação. Decide na Fase 0: ou desenhas a tua fonte a 12 px de altura de carácter, ou tens duas fontes (uma decorativa para títulos, uma legível para conteúdo). Como o teu jogo quase não tem texto, isto é fácil — mas só se for decidido antes de desenhares a fonte.

## As funcionalidades a declarar no Steam

| Funcionalidade | Custo de implementação | Decisão |
| --- | --- | --- |
| Remapeamento completo de comandos | Baixo — InputMap + UI | Fazer. Fase 5. |
| Legendas para pistas sonoras | Baixo — 8 pistas (sino, crepúsculo, muro a cair...) | Fazer. Substitui o áudio para surdos. |
| Modos para daltonismo | Médio — a paleta é quente/fria, boa base | Fazer. Testa a Podridão contra o terreno em protanopia. |
| Controlos de contraste | Baixo — um shader de saturação/contraste global | Fazer. |
| Desligar screen shake e flashes | Trivial | Fazer. Obrigatório para fotossensibilidade. |
| Jogável ao teu próprio ritmo | Médio — slider de duração do dia (240–540 s) | Fazer. Também é um botão de dificuldade honesto. |
| Sem QTE | Zero — não tens | Declarar. |
| Jogável sem visão | Muito alto | Não. Sê honesto na etiqueta. |


O slider de duração do dia merece destaque: é uma linha de código (o GameClock já é uma variável), serve de acessibilidade, serve de dificuldade, e evita teres de desenhar três modos separados.
