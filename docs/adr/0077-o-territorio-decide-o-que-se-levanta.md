# ADR 0077 — O território decide o que se levanta

- **Estado:** aceite como protótipo pedido pelo dono em 07/10/2026 («aplique esse relatório»).
- **Tarefa:** `docs/backlog/RG-28.md`.
- **Fonte:** relatório mestre de auditoria e evolução territorial, com Civilization VII como referência, em
  `docs/reports/TERRITORIO-CIVILIZATION-VII.md` (corte a 06/10/2026, código auditado `bafeb11`).
- **Estende:** ADR 0066 (a caravana escolhe onde o império nasce), ADR 0070 (a floresta é território) e a Q-130 (a
  cavidade é rocha).
- **Conserva:** a fundação livre num sítio fisicamente válido, a sede original, o mundo em faixas, a moeda física, os
  ids dos sítios de obra, o formato do save (v12) e a regra de que o bioma diz o que *pode* haver.

## Contexto

O relatório achou que a elegibilidade das obras não acompanhava a fundação (A01): a assinatura da fundação lia o
bioma do sítio escolhido, mas o `Greybox.cabe_no_bioma()` lia o recurso do segmento fixo `enramados_start_base_01`, e a
reancoragem da fundação livre (`LastCartWatch.reanchor(..., false)`) levava o pesqueiro e os poços de minério com a
sede para onde ela fosse, com água e passagem ou sem elas. A assinatura descrevia o bioma e não a economia acessível
(A02); a água era uma etiqueta (A03); a cavidade valia como jazida em qualquer sítio (A04). A resposta do dono à
Q-221 no painel (05/10/2026) pede o mesmo do outro lado: no primeiro dia o imperador explora, vê os recursos e o que
há em cada região, e só então decide onde fundar.

## Decisão

1. **Uma fonte tem sítio no mundo.** Uma fonte é um intervalo de uma faixa com uma necessidade: `water`, `forest` ou
   `rock` (os três valores de `requires_biome_feature`). As fontes desta entrega:
   - a água que o segmento de partida autora (o lago do castelo-árvore, `biomes.csv`), em `Greybox.AGUAS_X`, com
     `water_half_px` de meia largura. Fica onde está numa fundação livre; anda com o terreno nas escolhas de estrada e
     bosque, como as passagens;
   - a água dos segmentos `water` das terras, à volta do assunto (`wild_water_half_px`), e o mar de uma borda `sea`,
     que começa onde o caminho acaba;
   - as árvores de pé, uma a uma;
   - a rocha lá em baixo: o porão de cada passagem, entre as muralhas à volta dela — a mesma regra com que o
     `UnderWatch` mete o poço de minério no porão — e as cavernas das falhas de rocha.
2. **Um avaliador comum** (`PlacementRules`, puro). Uma obra que precisa de uma fonte só cabe com fontes dessa
   necessidade, **na mesma faixa**, com o meio a `alcance` px da borda delas (`water_reach_px`, `forest_reach_px`,
   `rock_reach_px`); a floresta pede `forest_min` árvores. A resposta é o *PlacementResult* do §16.4 do relatório:
   se cabe, as razões (chaves de texto), as fontes usadas e a distância à mais perto.
3. **Um perfil derivado** (`TerritoryProfile`, puro). Para cada sítio que precisa de uma fonte, a resposta do
   avaliador; por necessidade, quantos cabem de quantos. Não vai no save: recalcula-se a partir do que vai.
4. **Quem pergunta** (`TerritoryWatch`): o `Greybox` ao pôr o pesqueiro, a reancoragem (fundação livre e escolhas
   antigas), o carregar de um save e cada segmento novo das terras. Cada sítio fica com `terrain_bar`, a razão ou
   vazio. O `RealmGrowth` recusa (`Need.TERRAIN`) e esconde a obra intacta que o território recusa; como o
   `BuildSystem.can_climb` e o alvo da moeda já perguntam ao `RealmGrowth`, nenhum caminho de pagamento a contorna.
5. **A previsão é a confirmação.** O painel da fundação (`FoundationGuide.territory`) diz, por obra que já se sabe
   fazer, se tem a fonte ao alcance naquele sítio, com a mesma conta que a confirmação faz depois — não um índice de
   «qualidade». A fotografia da fundação (`site_signature`, versão 2) guarda o perfil por necessidade do momento; o
   perfil vivo muda com o mundo.
6. **Compatibilidade explícita.** Só a obra intacta (nível 0, nada pago, por começar) fica fechada. A que um save de
   antes já pagou, está a erguer ou tem de pé longe da fonte fica: tolera-se, o inspetor (TAB) di-lo, e a tolerância
   não abre cópias. Nada se cria para justificar uma obra antiga: nem água, nem jazida, nem árvores.
7. **Fundar num sítio pobre continua a ser possível.** A recusa é da obra, não da fundação; as outras fontes de
   comida (canteiros, galinheiros, caça) não pedem fonte.

## Dados e saves

`territory.csv` é novo, chave/valor; todos os números são valores de ensaio, em `_proposed` (Q-249). O `terrain_bar`
e a água autorada são derivados e não entram no save; o formato continua no v12. A assinatura da fundação passa à
versão 2 com o campo `territory`; as de antes ficam como estão.

## Fora desta decisão

A rede de água com tipos (ribeira, rio navegável, lago, mar), o cais e o porto (A03, AUD-CIV-05/06 — Q-250); os
contratos mercenários e o livro de obrigações (A06–A08, AUD-CIV-09 a 11 — Q-251); direitos de passagem e exploração,
transporte, especialização de vassalos, clima regional e despertar social (A09–A11, AUD-CIV-13 a 16 — Q-252 e RG-24);
o acesso que muda com a escora fechada (T07) e o corte de madeira com fonte (nenhuma obra da região o pede ainda).
Ficam em RG-28 como lacunas, não como exceções permanentes.
