# ADR 0073 — Uma HUD compacta com detalhe a pedido

- **Estado:** aceite no âmbito do pedido de revisão da HUD do dono, 05–06/10/2026.
- **Tarefa:** [UX-05](../backlog/UX-05.md).
- **Fundamentação:** [pesquisa de interfaces móveis](../ux/HUD-MOBILE.md).
- **Estende:** ADR 0047 (toque), ADR 0053/Q-193 (corrida mantida) e UX-03 (mão e alavanca).

## Problema

A captura enviada mostra a mesma ação em dois sítios, estatísticas em letra pequena numa fita
larga, o objetivo afastado da sua moldura e uma grande área ocupada pelos controlos. O painel
de contexto tem altura fixa, apesar de também explicar consequências da fundação. Encolher
toda a interface aumenta a área de jogo, mas torna o texto ilegível.

## Decisão

1. `HudLayout` define a geometria, `HudRibbon` desenha e preenche os mesmos retângulos e
   `HudStyle` partilha cores, margens e uma fonte que não volta a encolher quando a HUD
   compensa a escala do canvas. A arte do mundo conserva o seu filtro.
2. A informação permanente é saldo/capacidade, dia/fase e objetivo. A estação ocupa a
   segunda linha do relógio; no toque, a aljava ocupa essa linha quando o corpo conduzido
   usa flechas. A estação continua disponível na pausa.
3. Abaixo de 760 unidades de interface, o objetivo ocupa o painel contextual quando não
   existe uma interação local. Nos restantes tamanhos tem cartão próprio, até 520 unidades
   de largura, que cresce para acomodar o texto. Não se elimina texto com reticências.
4. `ContextPanel` cresce com a ação e as consequências. Em teclado reserva o canto do
   combate; numa janela estreita passa para baixo dele. Avisos e legendas seguem o fim dos
   painéis visíveis, em vez de partilharem coordenadas fixas.
5. No toque esconde-se `CombatBar`, mantendo o seu encaminhamento de recusas. O ataque e a
   habilidade continuam nos controlos de toque, com indicação de recarga; a Vigília consulta
   a mesma recusa do painel de combate. Não se muda a disponibilidade nem o significado dos
   gestos para reduzir o número de botões.
6. Os controlos formam duas filas compactas nos cantos. A pausa passa para o cabeçalho.
   Mantêm-se a margem de toque para além do desenho, o espelho para canhotos, FIXAR e o
   CORRER mantido. O aro de interação deixa de pulsar permanentemente.
7. `RealmReadout` alimenta «Estado do reino» na pausa: tropas, soldo, núcleo, nobres, ânimo,
   archotes, sementes, moedas e estação. Uma sede por fundar diz «Por fundar»; um núcleo
   construído e destruído continua a dizer 0%. O painel não é uma nova mecânica.

## Limites e verificação

Os testes medem limites, separação, alternância de dispositivo, texto longo PT/EN, flechas,
legendas, estado por fundar e navegação da pausa. As capturas usam o jogo real em OpenGL.
Isso não certifica conforto físico dos polegares, legibilidade ao sol ou comportamento do
Safari num iPhone real. A validação web continua a pertencer ao CI existente.

A revisão aproxima a versão jogável da hierarquia discreta do §24; não declara concluída
a sinalização diegética final nem a configuração independente de tamanho de texto.
