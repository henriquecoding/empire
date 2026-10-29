# ADR 0101 — A Forja fecha a entrega pela cadeia e pelo conceito

- Estado: aceite, a pedido do dono
- Data: 2026-10-29
- Tarefa: [FORJA-15](../backlog/FORJA-15.md)
- Complementa: ADR 0093, 0094, 0097 e 0099
- Origem: a [auditoria de fidelidade de 29/10](../art/research/2026-10-29-forja-fidelidade-elenco/AUDITORIA.md) sobre
  os 15 sprites v3 do elenco. As dimensões certas e os pixels protegidos não conservaram a poção nem a personalidade:
  os dois frascos 13×20 tinham bojos diferentes, a restrição partilhada não tinha leitor, os quatro dentes da
  mercenária sumiram com pureza 0,970, a etapa final dizia `erased_cells=0` por começar numa base já nativa, os pinos
  saíam da própria adaptação e `usable_sprite` era verdadeiro em todos com a entrega pendente. O dono: *«Implemente
  essas correções e faça merge na main»*.

## Decisão

1. **Uma cadeia por candidato (`forja.lineage/1`).** Cada `forge` grava o hash dos pixels à entrada e à saída, a
   transformação das coordenadas, as caixas editadas e as perdas novas, e leva as da etapa anterior (`--lineage`) pelas
   coordenadas desta; o `patch` também (`--lineage`). Uma etapa só se liga à anterior pelo hash. A perda numa região
   obrigatória é crítica e fica aberta até uma resolução (`forja.loss_resolutions/1`): reparo provado nesta imagem
   exata, exceção com autor e data, ou revisão inconclusiva (continua aberta). Uma base já nativa sem a etapa anterior
   nem `--native-root` não fecha.
2. **Um fecho só.** O `forge` diz `raster_valid` e nunca `release_ready`; `usable_sprite` sai. O
   `forja fidelity --candidate --forge-json [--resolutions]` diz `deliverable`/`release_ready` só com os quatro estados
   em `pass` e a cadeia sem perda crítica aberta; o resto é um estudo (`label: study`) ou `blocked`. Um estudo
   exporta-se; não se chama mestre concluído.
3. **O objeto partilhado tem leitor e molde.** `shared_prop_constraints` valida-se (par, escala, medida dentro da
   tela, variações permitidas) e confere-se no elenco (o par existe e declara o mesmo). O frasco é uma família do
   equipamento (bojo, gargalo, aro, rolha, líquido, brilho) e compara-se com um modelo nativo `forja.prop_model/1`
   desenhado a partir do conceito: envelope, largura por linha de cada parte e sobreposição, sem a cor e sem o que um
   oclusor declarado tapa. Um modelo proposto nunca dá `pass`. `forja par` junta as duas imagens da dupla e a pega.
4. **A ficha facial vem do conceito (`forja.face_sheet/1`).** Por personagem: a intenção da expressão, os marcos
   (olho, pálpebra, pupila, sobrancelha, nariz, cantos da boca, dentes, pelos) com caixa no conceito e caixa reservada
   na grade, e as relações medidas em agrupamentos de pixels (olhar, assimetria, acima, peças, extensão). O estado 2
   conta só os sinais herdados da autoridade; os pinos tirados do candidato protegem-no e não provam fidelidade. A
   ficha entra no pedido fiel como regra do dono.
5. **A recuperação mostra a escolha.** Cada célula apagada leva os votos alternativos, a margem e a confiança da grade;
   o voto não muda. Uma perda crítica numa grade duvidosa ou num traço mais fino que a célula pede redesenho nativo da
   região ou marcação explícita (`redraw_region`), nunca uma redução para caber.
6. **O conceito prevalece sobre o guia genérico.** Os trechos do `EXPRESSION_GUIDE.md` que contrariam os conceitos
   aprovados (sobrancelha como ruído, boca assimétrica proibida em repouso, Horta vegetal) ficam marcados como
   superados. `forja lote` dá uma entrada por personagem do elenco, sem omitir os que não mudaram.

## Estado e limites

A ferramenta mede o que foi declarado e observado; a revisão visual e o dono decidem o que não é determinístico. O
molde do frasco e as caixas nativas dos marcos estão por desenhar e aprovar (Q-304, Q-305); até lá o par e a ficha
ficam pendentes, de propósito. Os limiares (IoU 0,85, 1 px por linha, 60 % visível, grade duvidosa abaixo de 0,75)
são provisórios (Q-306). Os 15 sprites v3 continuam estudos: não houve nova geração, revisão artística nem integração.
Sem dependências novas; sem escrita em `art/`, `audio/`, `src/`, `scenes/` ou `data/`.
