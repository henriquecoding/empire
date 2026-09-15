# 24 — Interface · novo · Controlos, HUD diegético e feedback

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A v2 dizia "dois verbos" e parava aí. Isto é o mapa completo. Um jogo com 48 mecânicas e dois botões só funciona se cada contexto estiver escrito — e o Steam Deck obriga-te a resolver isto antes da demo, não depois.

## O mapa de comando

| Ação | Comando | Teclado | Contexto |
| --- | --- | --- | --- |
| Mover | Stick esquerdo / D-pad | A · D · ← → | Sempre |
| Verbo 1 — Largar moeda | A / ✕ (toque) | Espaço | Sempre. Contexto define o alvo. |
| Largar em contínuo | A / ✕ (manter) | Espaço (manter) | Pagar vários níveis de uma vez |
| Verbo 2 — Assumir | X / ▢ | E | Trocar de classe, montar, entrar em passagem, subir em criatura |
| Descer / subir de faixa | Verbo 2 sobre passagem | E sobre passagem | Só onde há passagem descoberta |
| Roda do rei | Y / △ (manter) | Tab (manter) | Só com o monarca assumido. É o corpo dele, não um menu. |
| Marcar alvo | Gatilho direito | Botão dir. do rato | Só classe Arqueiro |
| Impulso real | Roda do rei → segmento | Tab → 1–5 | Um por dia (§15) |
| Câmara livre | Stick direito | Q · Z ou rato na margem | Reconhecimento; volta sozinha em 2 s |
| Pausa / opções | Start | Esc | Sempre |


> **A roda do rei é o único menu do jogo**
>
> Manter Y abre uma roda de seis segmentos desenhada como um vitral do trono: construir · recrutar · ofícios · impulso · expedição · sucessão. Cada segmento é um ícone entalhado, nunca uma palavra — a mesma regra da sinalética das lojas (§01). Selecionar é apontar o stick e largar. É gamepad-first por construção, funciona sem rato no Steam Deck, e não custa localização.

## HUD diegético — o que existe no ecrã, e onde vive

| Informação | Como se mostra | Onde |
| --- | --- | --- |
| Moedas | O saco do personagem enche visivelmente; moedas caem quando está cheio | No sprite |
| Hora do dia | Cor da luz ambiente + posição do sol/lua no céu | No mundo |
| Podridão a chegar | A mancha no horizonte + stem de tensão a subir | No mundo |
| Vida de tropa | Camada face muda para ferido abaixo de 50% | No sprite |
| Nível de muralha | Material e silhueta (§10) | No mundo |
| Ganância do rei | Nº de nobres visíveis na varanda do castelo | No mundo |
| Dívida e prazo | Único elemento não-diegético: contador de 6 dias no canto | Canto superior direito |
| Sementes Reais | Roda do rei, segmento de sucessão | Sob pedido |


Um único elemento de HUD permanente — o relógio da dívida — e só quando há dívida. Tudo o resto é o mundo a dizer-te as coisas. É corajoso e é o que distingue este género.

## Feedback — a lista de juice que não é opcional

Num jogo sem UI, o feedback é a interface. Cada item abaixo é barato e cada um deles falta na maioria dos clones do Kingdom:

- Moeda largada — arco parabólico, som com pitch variável, pequeno bounce e sombra. Isto acontece milhares de vezes por partida: é a animação mais importante do jogo.
- Impacto — flash branco de 80 ms, 3 px de knockback, partícula de 4 px na direção do golpe.
- Screen shake — só para o muro a cair e o Aríete a acertar. Nunca para golpes normais. Amplitude máx. 4 px, e com opção de desligar (§26).
- Amanhecer — sino + varrimento de luz da esquerda para a direita a 900 px/s + as tropas a saírem dos postos em cascata, não todas ao mesmo tempo.
- Conquista — o kit de arquitetura novo aparece na roda do rei com o ícone a ser entalhado em madeira em 6 frames.
- Cegueira do Cavaleiro Selado — vinheta que fecha até 40% do ecrã, som abafado, e a câmara deixa de antecipar o movimento. A perda tem de sentir-se.
