# FORJA-11 — a Forja desenha cenários e construções pela régua dos atores

Estado parcial — a régua, o contrato de cena, o pedido, o plano sem rede, a revisão estrutural, as emendas Wang, a
          bancada e a escala das referências, com testes e a prova do piloto; a geração paga do piloto, os endpoints de
          ambiente do PixelLab e a aprovação do dono por fazer

## Pedido

O dono, a 28/10/2026, com o relatório *A construção de um mundo em pixel art* (revisão 2, 32 páginas) e o pacote
`Pacote-Forja-Cenarios-Construcoes-Claude-2026-10-28`: *«Chegou o momento de transformar a forja também em uma
ferramenta/estrutura pronta para desenvolver cenários e construções em um jogo pixel arte, não é só visualmente, mas
estruturalmente como os jogos de pixel arte elaboram e montam para ser coeso e bem feito […] quero que aprofunde
paralelamente ainda mais essa pesquisa e conhecimentos sobre como fazer isso e como pegar uma referencia e adequar ela
corretamente para personagens no caso do meu jogo que estão sendo gerados em 64x64 e 80x80.»*

## Spec e autoridade

[Pesquisa, método e piloto](../art/research/2026-10-28-forja-cenarios/README.md) (o relatório do dono em
[`pacote/`](../art/research/2026-10-28-forja-cenarios/pacote/), e as pesquisas A, B e C),
[Guia da Forja](../art/FORJA.md), [ADR 0098](../adr/0098-a-forja-desenha-cenarios-pela-regua-dos-atores.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [ADR 0093](../adr/0093-a-forja-protege-o-mestre-aprovado.md),
[Asset Bible §1](../art/ASSET_BIBLE.md), [cenários nativos](../art/NATIVE_SCENERY.md), AGENTS.md (regras 1, 8 e 9).

## Entrega

| Handoff do pacote | O que entrou | Evidência |
| --- | --- | --- |
| Dimensão explícita por tipo; sem 64×64 por omissão | `prompts.geometry` recusa um contrato sem tela; a extensão vem do `forja.scene/1` | `test_cenarios.PromptTest` |
| Vocabulário arquitetónico e papéis de referência | `scene_prompt.py`: projeção, chão, régua, vãos, sinais, materiais, telhado, cada linha com origem; seis papéis (`scenery.json`) | `PromptTest`, `prova.json` §cenas |
| Projeção do mundo separada da orientação do ator | `camera_conflicts(..., "elevation")`: a fachada é a vista lateral; isométrica, três quartos e perspetiva continuam conflito | `PromptTest` |
| Fundo e bordas | `--bg keep` num plano opaco; a cor-chave para quem não devolve alfa; a origem da cena no `forge`; o contorno dito em pixels lógicos (`constraints.outline`) | `test_cenarios.OpaquePlaneTest`, `test_cenarios_revisao` |
| Adaptador por capacidades | `scene_plan.py`: gpt-image, Gemini e PixelLab nas células; partição quando excede; `plan`/`auto --scene`; hash `ae1f76eb…` do PixelLab conferido (63/63) | `ScenePlanTest`, `contrato-2026-10-28.json` |
| Régua e fase | `regua.py`: atores, mundo e fase da arte do dono lidos dos ficheiros; métricas com origem | `test_cenarios.ReguaTest` |
| Módulos, emendas, estados | `estrutura.py` (extensão, grade, base, vãos, sinais, repetição, conectores, estados); `tiles.pairs` e `tiles.junctions` (64+64 pares, 512 cruzamentos) | `test_estrutura` |
| Montagem | `montagem.py`: bancada com os atores reais, cada peça pela sua âncora (`scene.place`), dia e noite aproximada; `forja escala` por marcos | `MontagemTest`, `test_cenarios_revisao.AnchorTest`, `evidencias/` |
| Piloto | quatro contratos (a oficina como marco, a forja jogável comprimida, o carvalho, o terreno), a escala das referências contra a pegada da simulação, a oficina reduzida revista e montada e o contraexemplo da oficina encolhida | `prova_cenarios.py`, `prova.json` |

## Por fazer

1. Gerar o piloto (a forja jogável, o carvalho, o terreno; a oficina como marco) com teto aprovado pelo dono, forjar com o `expect.json`, rever com
   `estrutura` e `montagem`, e registar a decisão dele (`forja refs`).
2. Ligar os endpoints de ambiente do PixelLab (`create-tileset-sidescroller`, `generate-image-v2`, `map-objects`,
   `inpaint-image-pro-flash`) com testes e uma sondagem paga (pesquisa C, P-1 a P-3).
3. A tabela de pixels do Gemini agora publicada, e as proporções 4:1/8:1 para as tiras de parallax (C, P-8).
4. A grade por janelas em cenas largas (C, P-6) e o lint de retilinearidade de telhados e paredes (C, P-7).
5. A família 1D de tiles da superfície (B §7b) e a camada emissiva por edifício (B §5.4), se o dono as aceitar.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem chamada paga; sem aprovação
artística. As métricas de arquitetura são propostas (Q-295).

## Verificação

`make forja` (a prova da Forja, a suíte, as provas de 24/10, 25/10 e 27/10 e a prova dos cenários sem deriva);
`python3 docs/art/research/2026-10-28-forja-cenarios/prova_cenarios.py`; portões estáticos locais; CI do PR.
