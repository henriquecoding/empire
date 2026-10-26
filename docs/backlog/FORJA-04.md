# FORJA-04 — a Forja vê a cor no espaço: o relatório de 25/10 sobre pixels, cores e continuidade

Estado parcial — incrementos 1 a 5 do relatório aplicados com testes, provas do pacote invertidas e a prova do arqueiro
          (agrupamento por região com rosto, braços, arco e corda presos); calibração, efeitos, correspondência por
          regiões anotadas, rei, escudeiro e a interface de revisão (incremento 6) por fazer

## Pedido

O dono, a 26/10/2026, com o relatório «Forja — pixels coerentes, cores e continuidade visual» (pesquisa de 25/10), o
dossiê dos 200 vídeos da PixelLab e o pacote para o Claude
([arquivados](../art/research/2026-10-25-forja-pixels-cores/README.md)): *«Trabalhe densamente analisando e aplicando
esses arquivos ao meu jogo, faça por etapas, não tenha pressa, faça bem feito»*. O relatório (§19, §22) pede seis
incrementos por ordem de risco e uma prova pequena com o arqueiro antes de qualquer expansão ao elenco.

## Spec e autoridade

[Relatório](../art/research/2026-10-25-forja-pixels-cores/RELATORIO.md), [guia da Forja](../art/FORJA.md),
[ADR 0088](../adr/0088-a-forja-de-pixel-art.md), [ADR 0089](../adr/0089-a-forja-pede-uma-vez-e-mede.md),
[ADR 0091](../adr/0091-a-forja-julga-o-equipamento.md), [ADR 0092](../adr/0092-a-forja-ve-a-cor-no-espaco.md),
ASSET_BIBLE §1 (paleta, dois tons por material, contorno, dither, cluster do cenário), PIXEL_ART_STUDY_GUIDE,
CHARACTER_PRODUCTION_GUIDE, AGENTS.md (regras 1, 8, 9 e 10).

## Entrega

| Incremento do relatório | O que entrou | Evidência |
| --- | --- | --- |
| 1 — observação e estados | `clusters.py`: componentes N4/N8, fragmentos de 1–3 px com descritores e estado (`review`, `protected`, `expected`, `inconclusive`), S8, F e U por região, `n/a` com área zero; o lint informa (`fragments`, `info`) sem mudar a validade raster; eixo `color_coherence` | `test_coherence` (as fixtures dispersa e agrupada do relatório) |
| 2 — preservação | `guard.py`: a proteção repõe-se depois da paleta e do contorno e mede-se no PNG final (E(P)); conflito com a paleta obrigatória é erro, com o pixel exato | `test_guard.ProtectionTest` |
| 3 — paleta e material | `quantize.apply`/`subset`: `--colors` com paleta é subconjunto dela ou conflito; `materials.py` e `forja cores`: rampas por região dentro da paleta mestra, agrupamento com as quatro provas locais da §11.5, C(R) | `test_guard.BudgetTest`, `test_materials`, `test_cores` |
| 4 — temporalidade | `temporal.py`: diagnóstico antes da correção; `--static` e `--action` no `sheet`; sem região estática nada muda; o comentário do `drift_threshold` corrigido | `test_temporal` (piscar, faixa móvel, ruído numa região parada) |
| 5 — estrutura fina | `min_cluster` com 8 vizinhos e caixas protegidas; `footprint` (área, caixa, bloco); `blocks` no lint do cenário como `info`; força 0 do dither = sem dither | `test_shapes` |
| Prova do arqueiro (§22) | Observação de 19 regiões e plano; 44 pixels agrupados, 0 de 1054 presos mudados, 0 fora da zona, alfa igual; equipamento igual; com a corda do FORJA-03, a geometria passa | [README da pesquisa](../art/research/2026-10-25-forja-pixels-cores/README.md), `test_cores.ArcherColourProofTest` |

O script de provas do pacote corre sem alteração contra o código novo: o que o relatório pede que mude mudou, e o que
deve ficar igual (a validade raster das duas fixtures, a área de uma mancha) ficou. O rei e o escudeiro foram recuperados da figura de 24/10 com as nove medidas do pacote iguais e têm
só diagnóstico.

## Por fazer

- Incremento 6: a revisão que mostra nativo, ampliação, versão anterior e diferenças lado a lado no `report.html` e
  deixa marcar um detalhe como intencional para o reutilizar (hoje as imagens saem do `forja cores`).
- O conjunto de calibração da §18 (48 imagens, 8 sequências, anotações revistas por um humano) e a calibração do
  limite de 1–3 px; a política de cor dos efeitos (`fx` fica `not_evaluated`).
- A correspondência temporal por regiões e âncoras anotadas (hoje: vizinhança 3×3 deslocada até 2 px).
- O rei e o escudeiro com observação e plano, depois de o dono julgar o arqueiro a 1× e no jogo.
- As decisões do dono: Q-277 (cluster por área ou por bloco), Q-278 (três ou dois verdes), Q-279 (o quase-preto
  interior no acabamento), Q-280 (a proposta do arqueiro) e a Q-273, que continua aberta.

## Limite

Sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`; sem dependências novas; sem geração nem chamada paga;
sem aprovação artística; a paleta mestra não mudou. O candidato do arqueiro é uma proposta dentro da pasta da pesquisa.

## Verificação

`make forja` (a prova da Forja e a suíte, com os testes novos); `python3
docs/art/research/2026-10-25-forja-pixels-cores/prova_cores.py`; o script do pacote contra `tools/forja`; portões
estáticos locais; CI do PR.
