# Oficina da Coroa — implementação no Godot

Pedido aprovado em 18/10/2026; integração e revisão em 20/10/2026. UX-11 e ADR 0087.
As imagens desta página são capturas do jogo no Godot 4.7.2, com o cenário real.

## Exploração

![Exploração em movimento](oficina/exploracao.png)

Bolsa/capacidade à esquerda; dia/fase e pausa à direita. Não há painel de objetivos,
logótipo ou barra de gestão permanente. Contexto e instruções conservam HintCue:
só aparecem depois de parar, durante a leitura, e recolhem ao andar. Estação e
informação detalhada continuam acessíveis em Estado do reino. O combate mantém os
comandos; no toque, o botão de ataque mostra as flechas disponíveis. O painel surge para corpos de classe ou durante a recarga do monarca.

## Roda aberta a pedido

![Roda no jogo](oficina/roda.png)

Manter Tab, Y ou Coroa no toque abre as seis famílias com posições estáveis.
Apontar e largar escolhe; o centro cancela. Teclado: 1–6 escolhe a família;
Impulsos abre outra escolha, onde 1–6 apresenta o preço e Enter confirma. Esc fecha.
F3 conserva o inspetor separado. A roda usa o abrandamento configurável existente.

Construção, recrutamento e ofícios apresentam as instruções e custos locais do
jogo; não criam nem pagam objetos à distância. Fundação, expedição e sucessão abrem
as ações existentes quando o monarca está no local apropriado. Falta de moedas ou
indisponibilidade de um impulso é explicada e não envia uma intenção inválida.

![Roda em janela de telefone](oficina/roda-toque.png)

No telefone, a roda e a explicação ficam lado a lado. Durante este estado os
controlos de movimento/combate ficam recolhidos; Coroa e Pausa permanecem. Ao fechar,
os controlos normais regressam. Perda de foco ou pausa cancela a seleção.

## Pausa

![Pausa central](oficina/pausa.png)

Retomar, Estado do reino, Opções e Sair ocupam o menu principal. Controlos, ecrã
inteiro, reinício e exportação estão nas Opções. O foco inicial é Retomar; reiniciar
continua a exigir confirmação com Cancelar selecionado. A política de guardar/sair
é a existente. Uma página substitui a anterior e mantém a simulação pausada.

![Opções com rolagem numa janela pequena](oficina/opcoes-telefone.png)

## Produção e verificação

- CrownSkin gera molduras modulares; CrownIcons usa matrizes nativas pequenas.
  Madeira, ferro, latão e tecido bordô partilham uma paleta. Filtro nearest nos
  elementos gráficos; fonte pixel existente nos botões e leitura escalável no corpo.
- Não há mudança na resolução do mundo, nos sprites, nos preços ou nos saves.
- Testes: crown_hud, royal_wheel, immersive_hints, hud_layout, hud_copy, atlas,
  pause_navigation e touch_input_lifecycle. Os testes de roda, toque e navegação
  também foram executados com o servidor gráfico e renderer ativos.
- Capturas em 1280×720 e 844×390; exportação web real concluída. A suíte integral e
  os portões do repositório são requisitos para integrar. A publicação deve ser
  verificada pelo commit servido em /versao.json e pelo fumo de produção.
- As capturas pequenas são simulações de viewport, não ensaios num telefone físico.
  Os conceitos gerados anteriormente orientam o aspeto; não são usados como provas.
