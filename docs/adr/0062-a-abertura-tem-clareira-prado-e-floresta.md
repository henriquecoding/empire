# ADR 0062 — A abertura tem clareira, prado e floresta

- **Estado:** aceite no âmbito do pedido do dono; números novos são propostas reversíveis.
- **Data:** 2026-10-04
- **Tarefa:** `docs/backlog/RG-20.md`.
- **Complementa:** ADR 0060 e ADR 0061. Substitui a garantia de todas as espécies no primeiro
  trecho da ADR 0058/0061 e a toca regional do javali. A caça junto da sede do §25 fica obsoleta.

## Problema e pesquisa

O afastamento da ADR 0061 resolve a praça cheia de animais, mas não limita a densidade das
terras geradas, não considera o alcance de fuga do animal e não impede respawn depois de uma
muralha ou obra ocupar o campo. O fundo também desenhava fortalezas decorativas antes de fundar.

O dono pediu pesquisa de Kingdom e a implementação do relatório. O vídeo indicado é de
New Lands, não Two Crowns: a transcrição apresenta fundação, recrutamento, ferramentas,
renda de caça e uma decisão de não ampliar a muralha para preservar o campo de coelhos.
As entrevistas dos criadores e o blog oficial 2.0 sustentam espaço legível, causa e efeito,
menos sobreposição e fauna perigosa mais distante. Fontes e limites estão no relatório
`docs/recovery/ABERTURA-KINGDOM-2026-10-04.md`.

## Decisão

1. **Preservar a main recente.** Mantêm-se o coelho dos arrabaldes a −830 px, o veado a
   −1692 e a raposa a −1860, a quota de um coelho e nenhum faisão regional da ADR 0061.
   Não se devolve a população gratuita nem a cidade fantasma da ADR 0060.
2. **Habitat por espécie.** `wildlife.csv.habitat_min_px` separa a pequena caça, bosque e
   fauna perigosa. A distância considera `max(roam_px, flee_px) + shadow_width / 2`, não
   apenas o centro da toca. Um segmento só recebe espécies cujo alcance inteiro respeita
   a distância à sede. Os valores constam de `_proposed`, sem aprovação numérica presumida.
3. **Javali exterior.** Sem toca regional. Continua nos segmentos de floresta elegíveis,
   com vida, dano, moedas e ritmo anteriores; não se elimina a espécie nem o risco.
4. **Menos é mais.** O primeiro trecho garante uma fonte pequena elegível, não cada espécie.
   A autoria deixa 192 px entre centros de tocas, como geometria de composição; os 640 px
   de um trecho com assunto comportam no máximo duas. As quotas por espécie continuam em CSV.
5. **Ocupar campo tem consequência.** Antes de a caça crescer no tick, `HuntHabitats.reserve`
   encerra tocas cujo alcance invade a sede, o recinto até muralhas próprias de pé ou a
   superfície de uma obra própria paga, em curso ou de pé. Um convite vazio não ocupa terra.
   Muralhas estrangeiras, torres e obras subterrâneas não reclamam recinto.
6. **Sem desaparecimento artificial.** A expansão só encerra novos nascimentos. Animais já
   presentes e moedas do caçador continuam; uma defesa cair não reabre automaticamente uma
   toca urbana, porque `Burrows.alive` já é persistido.
7. **Abertura compreensível.** O guia de renda explica a caça nos prados e a recolha junto
   dos arqueiros, em PT e EN. O circuito de gestos existente conserva fundação, recrutamento,
   ferramentas, canteiro e defesa. A noite e os custos não são alterados para forçar um teste.
8. **Cenário honesto.** Saem as fortalezas decorativas repetidas do horizonte inicial;
   preservam-se árvores, relevo, fortalezas reais vizinhas e edifícios construídos.
9. **Save v9.** A migração reautora apenas fauna e tocas antigas, uma vez. Conserva receita
   já ganha, bolsas de caçadores, pessoas, edifícios, dia, sementes e mundo gerado. Antes
   do primeiro crescimento aplica-se a ocupação do reino carregado, sem criar animais no recinto.

## Limites e reversão

A implementação não copia os portais, ilhas, inverno ou números exatos de Kingdom. A Podridão
continua a ser a fonte de ameaças noturnas; a emboscada no escuro mantém o contrato próprio.
Não há dependências novas nem alteração a `art/` ou `audio/`. A simulação continua pura.

Para afinar distância ou quota, editar CSV e regenerar recursos. Alterar só cenário não altera
o combate. Uma reversão deve manter a migração v9 legível: saves já gravados não devem recuar
de versão. O avanço de estágios, identidades dos sítios e ofícios não é reposicionado.

## Verificação

Teste vermelho do excesso de proximidade antes da implementação. Testes puros de margem,
elegibilidade e ocupação; integração da primeira vista, densidade, expansão, migração e
abertura só por gestos. Suite, portões, vistoria e export web após integrar a main recente.
Resultados finais ficam no PR; vistoria mede invariantes, não prova diversão ou equilíbrio.
