# Auditoria dos cenários de 28/10, aplicada (FORJA-12)

A [auditoria do dono](AUDITORIA.md) (base `91d3521`, o FORJA-11 já na `main`) reproduziu sete contraexemplos que os
verificadores de cenas deixavam passar e propôs uma ordem de trabalho. Este pacote fecha os contraexemplos e as três
correções que a auditoria ligou a eles; o resto da ordem fica no [FORJA-12](../../../backlog/FORJA-12.md).

Cada contraexemplo virou um teste em `tools/forja/tests/test_cenarios_auditoria.py`. Treze dos catorze testes falham
no `91d3521` e passam agora; o décimo quarto (a casa sobre postes) passa nos dois e guarda que a correção do apoio não
rejeita uma tipologia legítima.

| ID | O que passava | O que mudou | Teste |
| --- | --- | --- | --- |
| A1 | Uma porta de 2 px de largura | O contrato recusa a caixa abaixo da largura livre da régua (`door_clear_width`); a revisão mede a largura útil na metade de baixo do vão (percentil 10 das filas: um puxador não decide a porta, uma fenda continua fenda) | `OpeningTest` |
| A2 | Uma casa suspensa 8 px «assente» num bloco solto | O apoio é o da estrutura principal (a maior peça opaca ligada); as peças soltas no chão contam-se e não a seguram; postes ligados ao corpo seguram | `SupportTest` |
| A3 | Duas faixas opacas, uma clara e outra escura, «emendadas» | A emenda tem dois critérios que não se somam, alfa e cor (OKLab), cada um contra o percentil 90 do interior mais uma folga (uma célula; 0,02 OKLab); entre vizinhos diferentes a mudança de cor fica para rever (material intencional) | `SeamTest` |
| A4 | Um `damaged` igual ao `done` | Cada estado prova duas coisas: nada mudou fora das zonas e alguma coisa mudou dentro; mudar fica `inconclusive` (ruído também muda pixels: o significado vê-se a olho) | `StateTest` |
| A5 | Um conceito registado no plano PixelLab que não chegava ao modelo | Registada e enviada são campos diferentes (`sent`); no PixelLab o conceito vai como `init_image` (no tamanho do pedido, sem redimensionar em silêncio) e o mestre de estilo como `style_image` (bitforge); os outros papéis são recusados | `TransportTest` |
| A6 | `states: []` aceite e a revisão a rebentar | O contrato recusa a lista vazia; um estado sem zonas em `state_changes` dá aviso | `StateTest` |
| A7 | Um vão de 84 filas medido com 85 | A altura conta filas: `masks.bbox` tem o máximo exclusivo; o mínimo da régua confere-se na fronteira exata | `OpeningTest` |
| Gemini | 8:1 a 1K estimado 2896×368 | A tabela publicada, linha a linha, em [`gemini_pixels.json`](../../../../tools/forja/backends/gemini_pixels.json) (lida a 28/10 em `image-generation.md.txt`): 3072×384; sem tabela (flash-lite), a estimativa pela área; o 3-pro liga-se à tabela «3.1 Pro Image» por inferência | `GeminiPixelsTest` |
| Mestre | Igual a uma imagem dada contava como igual ao mestre | `forja estrutura --master … --refs registo.json`: só o mestre `approved` no registo faz passar a igualdade; sem registo fica `inconclusive` | `AuthorityTest` |
| Perfil | As medidas propostas funcionavam como regra | `scenery.json` diz `metrics_profile: proposal (Q-295)`; cada métrica e cada verificação de vão levam `rule_status` e a pergunta | `ProfileTest` |

## O que mudou no piloto

A [prova dos cenários](../2026-10-28-forja-cenarios/prova.json) passa de 22 para 26 verificações e diz agora:

- o plano sem rede é válido no gpt-image e no Gemini; o PixelLab recusa as referências dos quatro contratos
  (composição e material não têm entrada no `create-image`; o conceito em alta resolução não está no tamanho do
  pedido). Antes ficavam escritas no plano e não chegavam ao modelo;
- a baía da oficina reduzida tem 118 px livres (eram 119 com o erro de uma fila) e a da oficina encolhida 20 (eram 21);
- os contratos declaram estados e condições sem dizer onde mudam: o contrato avisa. As zonas são do dono;
- o Gemini pede e espera os pixels da tabela publicada (`output_size_known: true`).

## Escolhas e limites

- A baía de trabalho chega à soleira com a altura de uma porta, mas não é passagem: o interior mobilado à vista
  tira-lhe a largura livre. A largura exige-se à porta, ao portão e ao arco; na baía reporta-se (Q-301).
- A folga de cor (0,02 OKLab, a diferença que `color.delta` documenta como «mal se vê») é provisória: calibra-se com
  pares aceites e rejeitados quando houver módulos reais.
- O significado de um estado não se mede: a mudança dentro das zonas fica `inconclusive` até à revisão humana.
- As sondas são imagens sintéticas; não medem a frequência destes casos em imagens reais.

## Fica para o FORJA-12

A ordem 3 a 8 da auditoria: ligar o contrato à obra (`buildings.csv`, `SiteStage`) e a máscaras semânticas de vãos e
apoios; transportar o contrato no Aseprite e no export; consumir os candidatos na galeria Godot que já existe
(`tools/native_scenery_review.tscn`); o piloto Enramados completo; os adaptadores de ambiente do PixelLab; e o
catálogo de módulos. Nenhum deles se faz sem decisões do dono (Q-295 a Q-301) ou sem geração paga.
