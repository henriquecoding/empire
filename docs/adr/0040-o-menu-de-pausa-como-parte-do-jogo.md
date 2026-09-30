# ADR 0040 — O menu de pausa como parte do jogo

- Estado: aceite (pedido do dono, 30/09/2026)
- Data: 2026-09-30
- Secções: §24, §26, §27, §42, §62; Q-164
- Tarefa: UX-01

## Problema
A pausa era um formulário de opções seguido das ações. O `CenterContainer`
centrava uma caixa de altura ilimitada: na captura enviada pelo dono, a
confirmação de recomeço saía da janela. A mesma composição afetava a derrota.
O utilizador pediu reformulação baseada em Kingdom Two Crowns, com duas
capturas do próprio jogo como referência de navegação e acabamento.

## Referência e interpretação
Nas capturas fornecidas, Two Crowns mantém o cenário visível, usa ações
principais numa coluna e abre opções num painel próprio, com Voltar explícito.
O anúncio oficial da versão 2.3 confirma a reorganização de opções e nomes
para melhorar a navegação:
https://store.steampowered.com/news/posts/?appids=701160&enddate=1760104934&feed=steam_community_announcements

É uma análise da interface observada, não do código interno de Kingdom.
O Empire conserva as suas ações e regras; não acrescenta serviços de nuvem,
multijogador ou botões para funcionalidades inexistentes.

## Decisão
- Pausa principal, opções, controlos e confirmação são páginas distintas.
- Retomar recebe o foco inicial. Voltar, Esc e B sobem um nível; só na pausa
  principal retomam. A derrota continua sem Retomar.
- A confirmação de recomeço substitui a navegação principal. Cancelar recebe
  o foco e devolve-o à ação de origem; o wipe transacional continua intacto.
- Os painéis têm altura limitada pelo espaço disponível, área rolável que
  acompanha o foco e botão Voltar fora da área de opções.
- A UI compensa a redução do canvas em janelas pequenas. Botões mantêm alvos
  de toque utilizáveis; o brasão decorativo sai no modo estreito.
- Molduras retas em píxeis, botões de madeira com estados visíveis e brasão
  geométrico próprio, sem copiar imagens de Kingdom nem alterar `art/`.
- Usa-se Silkscreen, já licenciada para o site (ADR 0025), nos títulos e ações
  do menu. Texto corrido mantém a fonte legível do motor. A cópia TrueType
  conserva os desenhos da fonte; licença OFL junto do ficheiro e no NOTICE.
- Sair grava durante o dia; se a gravação falhar, mantém o jogo aberto. À noite
  explica-se que o retorno usa a última gravação. No Web sai para a home.
  A ponte usa o objeto `window`, sem `eval`, para conservar a CSP estrita.

## Limites
A simulação, o autosave noturno, o legado e as mecânicas não mudam. Os controlos
mostram os gestos implementados; remapeamento e volumes continuam fora desta
alteração. A composição usa recursos nativos do Godot e não traz bibliotecas
novas de runtime.
