# ADR 0091 — A Forja julga o equipamento: intenção, observação e veredito, e o reparo só na máscara

- Estado: aceite
- Data: 2026-10-25
- Secção do dossiê: §22 (a gramática do desenho, o contorno), §58 (os slots)
- Complementa: ADR 0088 (a Forja) e ADR 0089 (pede uma vez e mede); ASSET_BIBLE §2 (slots, espelho) e
  ANIMATION_BIBLE (sockets, tags), que não mudam
- Tarefa: [FORJA-03](../backlog/FORJA-03.md)
- Origem: o [relatório de 24–25/10](../art/research/2026-10-24-forja-armas/RELATORIO.md) e o pedido do dono de 25/10,
  *«Aplique os relatórios»*

## Contexto

O dono criticou as armas e o equipamento de três personagens (rei, arqueiro, escudeiro) que tinham passado nos
critérios técnicos da Forja. O relatório de 24–25/10 mostrou porquê: um ficheiro pode ter a tela, a paleta e o
contorno certos — e passar no lint com 0 erros — enquanto tem uma lâmina bifurcada, duas guardas ou nenhuma arma.
Isso reproduziu-se aqui com fixtures, e a corda do arqueiro da entrega mede 2 px de largura em 22 linhas, a 1,55 px
da reta entre as pontas. O defeito já vinha da fonte gerada; a Forja não o via porque não tinha onde o escrever.

O relatório também apontou: `init_strength or 300` troca um zero explícito por 300; o pedido do rei pedia três
quartos com a câmara em perfil estrito; o contorno global engrossa uma corda de 1 px para 3 e fecha um vazio de 2 px;
e uma camada «só com alterações» deixa o objeto antigo por baixo (guia de inpainting do PixelLab, 22/07/2026).

## Decisão

1. **Sete vereditos que não se misturam** (`verdicts.py`): contrato raster, geometria do equipamento, pose
   funcional, identidade, continuidade no tempo, aprovação artística e integração. Sem média nem nota. O que não foi
   avaliado diz `not_evaluated` e nunca vira `pass`; avaliado em parte é `inconclusive`; a aprovação artística só
   pode ser `pending` na ferramenta e a integração só passa fora dela, vista no motor. A revisão automática de
   figuras e pranchas passa a trazer estes vereditos ao lado de `contract_valid`.
2. **Três registos separados** (`equipment.py`). A **intenção** é um manifesto (`forja.equipment/1`) com cada
   objeto, a família (`sword_straight`, `bow_simple`, `shield`, `storage`), o slot da ASSET_BIBLE §2, o estado de
   uso, as partes e quantidades, os contactos com o corpo, a oclusão e o material. A **observação**
   (`forja.observation/1`) são regiões e âncoras marcadas numa imagem cujo hash traz, com autor, método, data e
   incerteza; uma observação de outra imagem é recusada. O **veredito** compara os dois. O manifesto recusa campos
   de jogo (capacidade, munição, dano, preço): descreve apresentação.
3. **A geometria mede o que se mede em pixels nativos** (`geometry.py`), sobre a observação, e não deteta objetos:
   quantas instâncias de cada parte (a oclusão declarada e as junções da família ligam as peças), um só traçado por
   linha de varrimento entre a base e a ponta da lâmina, a corda com no máximo a largura pedida, perto da reta e
   ligada às pontas nos estados em que não está puxada, a guarda entre a lâmina e a empunhadura, e os contactos. A
   escada de uma diagonal raster não é curvatura; a curva da madeira do arco não se mede; guarda e pomo são partes
   diferentes. Uma região com incerteza alta não deixa passar.
4. **O reparo declara o método e prova o que ficou** (`compose.py`, `masks.py`, `inpaint.py`): a zona pode ser uma
   máscara qualquer, na convenção de cada gerador (OpenAI: alfa 0 edita; PixelLab: branco gera, preto preserva);
   `add`, `replace` e `remove` são diferentes, e o relatório diz quanto do objeto antigo continua visível, fora da
   máscara ou por baixo de uma camada nova. Uma máscara que cobre uma região protegida é recusada; fora da máscara
   os pixels ficam byte a byte e `verify` repete a prova depois do acabamento.
5. **Uma linha simples conserta-se na grade** (`repair.py`, `forja line`): a corda refaz-se a 1 px entre as âncoras,
   sem desenhar por cima de um oclusor declarado; o pixel que sai de cima de outra peça herda a cor dos vizinhos e
   fica registado como inferido. O resultado é uma proposta: julga-se de novo com a observação reaplicada.
6. **Zonas sem contorno global declaradas** (`--bare`): o contorno não entra nelas e o lint não as conta na parte da
   borda com contorno. É uma exceção escrita no relatório, não uma regra nova de arte: a corda de 1 px sem contorno
   continua por decidir pelo dono (Q-272).
7. **O pedido resolve a câmara num campo só**: um assunto que pede três quartos, frente, costas ou vista de cima, ou
   que vira a figura ao contrário de `--facing`, invalida o plano antes de qualquer rede; o `forja prompt` diz o
   conflito. O mesmo verificador serve para um prompt expandido por um gerador quando um adaptador o devolver.
   A força da imagem inicial respeita o zero explícito.

## Alternativas consideradas

- **Só melhorar o prompt ou trocar de gerador.** O relatório e as fixtures mostram que o contrato raster não
  exprime a finalidade semântica; nenhum texto de prompt dá à Forja uma maneira de recusar duas guardas.
- **Um detector automático de armas (modelo visual).** Pode sugerir regiões, mas não aprovar sozinho; e não há
  conjunto de avaliação. A marcação humana por caixa e cores é reprodutível, barata e diz quem viu o quê.
- **Uma nota única de qualidade.** Esconderia uma segunda lâmina atrás de uma paleta boa: recusada pelo relatório e
  por esta ADR.
- **Pôr a anatomia no contrato raster (`contracts.json`).** O contrato de tela e paleta é por tipo de asset; o de
  equipamento é por personagem e por pose. Ficam separados, como o relatório pede.
- **Reparar a corda com outra geração (inpainting pago).** Para uma linha reta entre duas pontas, a grade basta; a
  comparação entre o `inpaint-v3` e o Pro Flash fica para quando houver chave, teto e um caso que a peça.

## Consequências

- Nenhuma dependência nova; os comandos novos (`equip`, `line`) e as opções novas (`--mask`, `--method`,
  `--protect` no `inpaint`; `--bare` no `forge`) chegam também ao servidor MCP, que os deriva da CLI.
- A prova do arqueiro (pesquisa de 24/10) corre num teste: a corda da entrega falha, a refeita passa, fora da zona
  nada muda. As fixtures do relatório entram nos testes com controlos positivos (diagonal raster, empunhadura tapada
  pela mão, arco curvo, corda cruzada pelo braço).
- Fica por fazer: identidade e continuidade no tempo continuam `not_evaluated`; espada do rei e escudo do escudeiro;
  as operações PixelLab além da imagem estática; rampas por material; o inventário compilado no prompt. Ver
  FORJA-03.
- Se a decisão for revertida: tirar `equipment.py`, `geometry.py`, `verdicts.py`, `compose.py`, `masks.py`,
  `repair.py`, `annotate.py` e `cmd_equip.py`, e voltar `inpaint.py`, `outline.py`, `lint.py`, `pipeline.py`,
  `plan.py` e `prompts.py` ao commit anterior — e a Forja volta a aprovar uma espada com duas guardas.
